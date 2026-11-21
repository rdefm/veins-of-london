# Vein — code review: streamline / speed / robustness

Date: 2026-11-21. Scope: `autoload/`, `systems/`, `scenes/`, `scripts/`, project config (~83k src lines, ~87k test lines).
Constraint: **zero gameplay change**. Every perf item below must be verified with a same-seed golden run (`scripts/sim_faction_economy.gd` / `profile_block_end.gd`, seed fixed) producing a byte-identical `JSON.stringify(GameState.state)` before vs after.

## Measured baseline (headless desktop, `profile_block_end.gd` / `profile_ui_refresh.gd`)

| Thing | Day 120 | Day 365 |
|---|---|---|
| State size (JSON) | 125 KB | 130 KB (flat — no unbounded growth) |
| Day rollover (`advance_time_block` → `daily_tick` + autosave) | **140 ms** (194 ms with UI flush on Map) | 137 ms |
| Mid-day block advance | 3.6 ms | — |
| Phone screen, one `state_changed` | **13.5 ms** | — |
| Map / HQ screen, one `state_changed` | 1.9 ms | — |

Rollover top costs: `FactionSim.trade` 33–37 ms · `Intel+Diplomacy+Partners` 16–19 · `FactionAI.pressure/stances/wars` 15–18 · `FactionSim.craft` 12 · `SaveManager.autosave` 12–13 · `FactionAI.apply_escalation` 7 · `Market.daily_reprice` 6.
Mid-range Android is typically 3–5× slower than desktop GDScript → **~0.5–0.9 s freeze every day end**, ~50 ms per Phone refresh.

What's already good (don't touch): `EventBus.mark_changed()` coalescing; atomic save (tmp → bak → rename) + backup fallback + 3-slot autosave rotation; `snapshot_state()` excluding nested snapshots; map_canvas signature gating; typed GDScript (~99% of vars); `GameData.validate()` covered by tests; systems never touch Nodes; RNG routed through `Rng`/fight-local RNG.

---

## P1 — Robustness (data safety)

### 1. Day rollover has no failure guard, then autosaves the result
`time_system.gd:170` `daily_tick()` runs ~90 steps then `SaveManager.autosave()` unconditionally. A GDScript runtime error aborts only the failing function; the tick carries on with a half-applied step, and the damaged state is written into the autosave rotation. With 3 autosaves, three bad days overwrite every good one.
**Fix:** a cheap `StateCheck.ok(state) -> Array[String]` (required top-level keys, `cash` is int ≥ 0, ids in maps resolve to GameData, no NaN floats) run before every autosave/manual save. On failure: skip the write, keep previous autosaves, log + push a notification. Optionally keep one "last known good" autosave that is never rotated out.
Gameplay impact: none.

### 2. Test runner tolerates up to 200 SCRIPT ERRORs
`scripts/run_tests.sh:21` only aborts above `MAX_SCRIPT_ERRORS=200`; below that a run "passes" while runtime errors (null derefs, bad keys — exactly the class in #1) go unnoticed.
**Fix:** fail the suite on any `SCRIPT ERROR` not matched by an explicit allowlist of intentionally-provoked errors (tests that feed corrupt saves/data). Current count: see note at bottom.

### 3. `.import` files are gitignored
`.gitignore` excludes `*.import`, so texture import settings (lossy WebP from `set_lossy_imports.sh`, filter, mipmaps, VRAM compression) live only on this machine. Fresh clone / CI / second machine → different (lossless) imports, bigger APK, different look. Godot's own guidance is to commit `.import` files.
**Fix:** un-ignore `*.import`, commit them. Currently 209 imports lossless vs 98 lossy.

### 4. GameData tables are mutable at runtime
Nothing stops a system doing `var t: Dictionary = GameData.RECIPES[k]; t["x"] = …` — the mutation silently survives into the next new game / test case. Nothing does it today (grep clean), but there are hundreds of `var x: Dictionary = GameData.…` aliases that one careless edit turns into a cross-game leak.
**Fix:** at end of `GameData.load_all()`, recursively `make_read_only()` every Dictionary/Array (debug builds at least). Any write then errors loudly in tests. `_merge_candidate_contacts()` must run before the freeze.

### 5. One screen mutates state directly
`scenes/phone_apps/factions_app.gd:38` writes `GameState.state["phoneNav"]["selectedFaction"]`. `PhoneNav.select_faction()` exists and is unused. Swap the line for the system call. (Constitution rule 4.)
Also worth a lint rule in `lint_tokens.sh`: reject `GameState.state[...] =` / `.append/.erase` under `scenes/`.

---

## P2 — Speed

### 6. Day-rollover CPU: memoize per tick, precompute static faction data
Hot paths recompute GameData-derived facts per call, per good, per faction:
- `FactionSim.trade()` calls `traded_goods()` twice per faction; `reserve()` → `ore_reserve()` → `Crafting.calc_cost_shared()` + `craft_target()` per (faction × good).
- `FactionAI.pairs_overlap()` / `_faction_ores()` loop recipes/ores per pair per call — pure function of GameData, never changes.
- Ad-hoc caches already exist (`Shares.begin_cache/end_cache`, `FactionAI.begin_withhold_cache`, `Crafting._cost_cache`) — each with its own manual begin/end; an early return skips `end_*` and leaves a stale cache on.
**Fix:**
a) Build once at `GameData.load_all()` (or lazy static): faction ore sets, overlap matrix, traded-goods source lists, per-skill craft costs.
b) Replace begin/end pairs with one `TickCache` (static Dictionary keyed by a counter bumped at the start of `daily_tick()` and on every state mutation entry point that matters), so caches can't go stale or stay on.
c) Re-profile `Intel+Diplomacy+Partners` with a finer split (the profiler groups them) before touching.
Target: rollover < 60 ms desktop. Verify via golden state hash.

### 7. Autosave serialises on the main thread
Every rollover: deep copy (~7 ms) + `JSON.stringify` (~18 ms) + file write, all blocking.
**Fix:** take the `snapshot_state(true)` copy on the main thread (must be synchronous for consistency), then hand stringify + gzip/write + rename to `WorkerThreadPool.add_task`. Serialise saves through one in-flight task (queue the next if one is running) and `wait` on quit / before manual load. Keeps atomic tmp/rename. ~20 ms off every day end.

### 8. Screens tear down and rebuild their whole tree on every `state_changed`
`phone.gd:34 _refresh()` frees every child and re-`build()`s the active app — 13.5 ms per emit at day 120, and it fires after every mark_changed from any system. Only `map_canvas.gd` (of 28 listeners) gates its rebuild with a signature. Same full-rebuild shape in `hq_lab_bench`, `combat_prep`, `hq_dial`, `bag_drawer`, `modal_layer`, `contacts`, `security`, `vein_list`, `hq_*`.
**Fix:** copy the map_canvas pattern: each listener computes a cheap `_render_signature()` (the state slices it reads) and returns early when unchanged. For Phone, put `render_key()` on `PhoneApp` (default: hash of `phoneNav` + the app's own slice). Side benefit: fewer lost scroll positions / tween restarts. Visual QA needed per screen.

### 9. Big textures load synchronously at transitions
`event.gd:992` (`load(image_path)` per card), `combat_stage.gd:2778–2811` (sprite sheets, backdrop), `hq_diorama.gd:50/70`, `floorplan_view.gd:45`. 98 PNGs > 1 MB in `assets/`. Each first-time load stalls the frame on device.
**Fix:** `ResourceLoader.load_threaded_request()` the next card's still(s) when a card opens, and the fight backdrop/sheets when combat prep opens; `load_threaded_get()` at show time (falls back to sync if not ready). Shaders in `combat_stage.gd:431/469/2171/2684` → `preload` constants.

### 10. Mobile battery: idle frames
- `project.godot` has no `application/run/low_processor_mode=true`. For a menu-driven game this is the single biggest battery/thermals win: Godot only redraws when something changes. Tweens, `_process` animations and `queue_redraw` still work.
- `alarm_presentation.gd:66` and `time_transition.gd:63` run `_process` every frame forever just to call `_sync_session()` (`is_same(session, GameState.state)`). Emit a `EventBus.session_replaced` from `GameState.reset()` / `SaveManager` load instead, and `set_process(false)` when idle.
- `MapHalos.ChargeHalo` `queue_redraw()`s every frame per halo; make sure halos stop processing while the Map is hidden/covered by a modal.
Visual QA: transitions, halos, ticker, tweens still animate with low-processor mode on.

---

## P3 — Streamlining / maintainability

### 11. SaveManager backfill boilerplate
`backfill_defaults()` does a shallow top-level fill, then 20 hand-written `_backfill_*` + 16 `_migrate_*/_remap_*` functions, plus ~8 `if not save.has(...)` lines. Every new state key = another function.
**Fix:** one `_fill_missing(dst: Dictionary, defaults: Dictionary)` recursive merge, applied to an explicit allowlist of *schema* subtrees (`world`, `player`, `home`, `business`, `flags`, `combat`, `barometer`, …), never to id-keyed maps (`contacts`, `factions`, `sites`) — those keep a per-id fill. Replaces most `_backfill_new_*_keys`. Lock down first with a fixture test: load each old save fixture, compare output before/after refactor.

### 12. Dead code + clutter
- Unreferenced anywhere (src or tests): `GuardUpkeep.hire_cost_text`, `Home.current_bill_base`, `Modal.set_return`, `MorningAccounts._positive_delta`, `Muscle.security_score`, `Muscle.hq_security_score`, `Muscle.faction_total`, `Perks.active_turf_for_site`, `PhoneNav.select_faction` (← use it, see #5).
- ~35 more system funcs referenced only from tests — review; keep if they're deliberate test seams.
- Orphan `.uid` files (script deleted): `scenes/screens/{crafting,lab,property,veins}.gd.uid`, `scripts/_probe.gd.uid`, `tests/test_{inventory,ore_stock,sms_screens,veins_screen}.gd.uid`.
- Tracked one-offs: `_smoke_propagation.gd` (root), `bugs-26-08-18.txt`, `bugs-28-08-26.txt`, `scripts/_tmp_insight_shots.gd`, `scripts/diagnose_115_timing.gd` (ticket 115/116 resolved), `output/imagegen/*.png`. Move to `.scratch/` or delete.

### 13. Mega-files
`combat_stage.gd` 3.3k, `GameData.gd` 3.2k, `combat_rounds.gd` (system) 3.2k, `faction_ai.gd` 2.8k, `events.gd` 2.7k, `bizbrief_app.gd` 2.3k, `scenes/screens/combat_rounds.gd` 2.1k, `combat.gd` 2.1k. Not a runtime cost, but every edit/review pays the read. Split along existing seams with pure moves (no logic edits), e.g. `faction_ai` → stances / wars / conclave / escalation; `GameData` validators → `game_data_validate.gd`; `combat_stage` inner classes → own files. One file per commit, tests unchanged.

### 14. Lock in typing
Typing is already ~99% (150 untyped `var x =` left). Turn on `debug/gdscript/warnings/untyped_declaration` and `unsafe_*` as warnings so new code stays typed (typed GDScript is also faster).

### 15. Minor
- `.gitignore` names `Godot_v4.4-*` binaries; a 4.4 console exe sits in the repo root while the target is 4.7 — delete locally to avoid running the wrong engine.
- `bank.gd:13` builds ids from `Time.get_ticks_usec()` — fine today, but non-reproducible; `Rng`-only would make same-seed runs byte-identical (helps the golden-hash checks in #6).

---

## Needs a decision (not changing gameplay without your call)

- **Global `Rng` stream isn't in the save or in Rewind.** `Rng._rng` lives in the autoload, outside `GameState.state`; fights use their own saved `rngState`, but world rolls (raids, offers, NPC claims…) after a load or a time-block Rewind draw from a different stream than before. If "Rewind then redo gives the same outcome" (or reload-proof rolls) is intended, the RNG state should go into state. If re-rolling on Rewind is a feature, leave it — say which.

---

## Suggested order
1 → 2 → 5 → 3 → 4 (cheap safety) · 10 (one setting, big win) · 6 + 7 (rollover hitch) · 8 · 9 · then P3 as background chores.

Suite note (full run 2026-11-21): 5082 passed / 0 failed; **0 SCRIPT ERRORs** — so #2 costs nothing today (set `MAX_SCRIPT_ERRORS=0`). 36 engine `ERROR:` lines, all from tests that deliberately feed corrupt events/saves (fine; allowlist them if #2 is extended to `ERROR:`). Exit also reports **1132 leaked ObjectDB instances + 17 resources in use** — test-side node leaks (un-freed screens/components), the same family as the earlier ticket 115/116 hang. Low priority, but worth a `run_case()` orphan check (`Node.print_orphan_nodes()` / `Performance.OBJECT_ORPHAN_NODE_COUNT` delta per case) so new leaks get flagged.
