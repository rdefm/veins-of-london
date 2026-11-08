# Vein — Senior Code Review: Speed, Efficiency, Robustness

Date: 2026-11-08 · Scope: `autoload/`, `systems/`, `scenes/`, `project.godot`, `export_presets.cfg`, the shipped APK · ~80k lines GDScript, 250 test files.

All numbers below were **measured** on this machine (Windows desktop, Godot 4.7, `--headless`) unless marked *estimate*. Expect a mid-range Android phone to be roughly 3–5× slower (*estimate*, not measured). Every recommendation keeps the formulas and data unchanged, and keeps the one-way data flow (CLAUDE.md "Architecture"). None of them redesigns a mechanic.

---

## 0. TL;DR — do these first

| # | Change | Why (measured) | Effort |
|---|---|---|---|
| 1 | **Batch `state_changed`** so the UI redraws once per frame, not once per emit | End-of-day on the Map: **1,573 ms**, of which ~1,400 ms is 24 full Map rebuilds | M |
| 2 | **Cache `MapCanvas._rebuild()`** when the sites/veins haven't changed | **46 ms** per call, and it runs on every state change anywhere | S |
| 3 | **Replace `GameState.deep_copy()` with native `duplicate(true)`** | 10.3 ms → **2.4 ms** (4.3×). Runs on every time block, plus twice per event card | S |
| 4 | **Stop copying event snapshots twice** | `_snapshot_before_mutation` copies, then `Snapshots.push` copies the copy again | S |
| 5 | **Leave unused reference art out of the APK** | APK is **301 MB** (it was 27 MB in Aug). `reference-plates` (57 MB) and `character-references` (22 MB) are never loaded by code | S |
| 6 | **Compress the event stills** | 79 event images = **92 MB**, lossless, ~2 MB each | S–M |
| 7 | **Make save writes atomic**, and save when the app goes to the background | One kill in the middle of a write corrupts that slot. Android kills background apps, and nothing saves on pause | S |
| 8 | **Handle the Android Back button** | `quit_on_go_back` is at its default (true), so Back quits the game with no save | S |
| 9 | **Stop drawing IDs from the gameplay RNG** | Each `Notify.push`, bank record, site or vein id calls `Rng.randi_range`, which shifts every later gameplay roll | S |
| 10 | **Save the binary format to disk** (`store_var`), and keep JSON only for export | Removes ~600 lines of hand-written int restoring, which is a whole class of bugs. Serialising is 4.5× faster | M |

Items 1–4 together should take end-of-day on the Map from **~1.6 s to ~0.15 s** on desktop (*estimate* = 147 ms logic + one cached rebuild).

---

## 1. Baseline measurements

Measured with `scripts/profile_block_end.gd` (it already exists, warm=60 days) plus scratch benches that boot `Main.tscn` headless.

### 1.1 Logic only (no UI)

| Operation | ms |
|---|---|
| `advance_time_block()` mid-day | 10.3 (almost all `Rewind.mark_block_start` deep copy) |
| `advance_time_block()` rollover | 147 |
| `do_rest()` | 127 |
| `SaveManager.autosave()` | 10.2 |
| `JSON.stringify(state)` | 17.4 |
| `GameState.deep_copy(state)` | 10.3 |
| `state.duplicate(true)` | 2.4 |
| `var_to_bytes(state)` | 3.9 |
| JSON round-trip (stringify + parse) | 17.4 |

Slowest daily-tick steps: `FactionSim.trade` 28.9, `FactionSim.craft` 15.4, `Intel+Diplomacy+Partners` 12.4, `FactionAI.pressure/stances/wars` 11.9, `Market.daily_reprice` 5.7, `FactionAI.apply_escalation` 4.3.

### 1.2 With the real UI attached (`Main.tscn`, day 30)

| Screen | listeners | one `state_changed` emit | rollover incl. UI |
|---|---|---|---|
| Map | 14 | **55 ms** (`map_canvas._rebuild` = 46 ms) | **1,573 ms** |
| Phone | 8 | 11 ms (`phone._refresh` = 11.9 ms) | 404 ms |
| HQ | 7 | 2 ms | 193 ms |

One rollover fires `state_changed` **24 times**. A mid-day block advance fires it once.

### 1.3 State size

About 120 KB of JSON at day 60 and ~128 KB at day 200 (not counting `blockStart`). **Logs are properly bounded. Good.**

### 1.4 Boot

`GameData.load_all()` takes 245 ms and `validate()` 40 ms. Wall time from engine start to the first script line was **~8.9 s** headless. The remaining ~8.5 s is **not yet explained**. The likely cause is GDScript compiling the whole class graph that the autoloads pull in (`GameState.new_game_state()` references ~40 system classes). **This needs an on-device trace before anyone acts on it** (see §5.4).

---

## 2. Runtime speed

### 2.1 [P0] Batch `state_changed` into one redraw per frame

**Problem.** There are 290 `EventBus.state_changed.emit()` call sites. Most screens respond by **tearing down and rebuilding all their UI** (`phone.gd:_refresh` frees every child, and `map_canvas._rebuild` re-partitions and re-routes every stop). A daily tick emits 24 times, so the Map rebuilds 24 times in one frame. `Bank.record()` alone emits once per cash change.

**Fix.** Make the redraw cheap to request and run it once per frame:

```gdscript
# autoload/EventBus.gd
signal state_changed          # listeners: redraw. Fires at most once per frame.
var _dirty := false

func mark_changed() -> void:
	if _dirty:
		return
	_dirty = true
	_flush.call_deferred()

func _flush() -> void:
	_dirty = false
	state_changed.emit()

# Tests and the rare caller that needs a synchronous redraw.
func flush_now() -> void:
	if _dirty:
		_flush()
```

- Replace `EventBus.state_changed.emit()` with `EventBus.mark_changed()` in `systems/` and `autoload/`. It's a mechanical find-and-replace. Listeners don't change.
- Tests that check UI right after an action call `EventBus.flush_now()`. Tests that only check state are unaffected.
- `CONNECT_DEFERRED` is **not** a fix: it queues every emission, so you still get 24 calls.
- Guard `_refresh` handlers with `if is_queued_for_deletion(): return`, because a screen that was just swapped out with `queue_free` still receives the flush.

**Expected:** Map rollover drops from ~1,573 ms to ~200 ms (one rebuild). Taps that emit several times (purchases, crafting) get faster everywhere.

### 2.2 [P0] Cache `MapCanvas._rebuild()`

`scenes/components/map_canvas.gd:419` runs `MapLayout.assign_all_slots()`, `_partition_stops()`, the multi-pass `_apply_crossing_nudges()` and the pin rebuild on **every** state change, even when only cash changed. Fix: compute a cheap signature first and return early when nothing changed:

```gdscript
var sig := [Sites.layout_signature(), MapEvents.pending_site_ids(), MapEvents.pending_vein_ids(),
		MapEvents.pending_join_line_vein_ids(), MapPins.active_contact_pins(), MapPalette.is_dark()]
if sig == _last_sig:
	queue_redraw(); return
_last_sig = sig
```

`Sites.layout_signature()` is a new helper: the site/vein ids, owners and growth bands concatenated (whatever `_partition_stops`, `assign_slots` and `growth_band` read). It belongs in the system layer so the screen stays read-only. Expected: 46 ms → <1 ms for every emit that doesn't touch the map.

### 2.3 [P0] Native deep copy

`autoload/GameState.gd:618` implements `deep_copy` as recursive GDScript. For pure data (Dictionaries, Arrays, primitives), `duplicate(true)` gives the same result in native code:

```gdscript
static func deep_copy(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value
```

Measured 10.3 ms → 2.4 ms. It is used by `Rewind.mark_block_start()` (every time block), event snapshots (every card) and `SaveManager`. Add one test that asserts `deep_copy(s) == s` and that mutating the copy leaves the original untouched (no shared sub-dicts).

### 2.4 [P1] Event snapshot is copied twice

`systems/events.gd:1910 _snapshot_before_mutation()` deep-copies the whole state, then `Snapshots.push()` (`autoload/Snapshots.gd:17`) deep-copies that copy again. That's ~20 ms per card today, or ~2.4 ms after the fix. Two options:
- add `Snapshots.push_owned(stack_id, stack, snapshot)`, which appends without copying, or
- have callers pass the live value and let `push` do the only copy.

Combat's `_push_snapshot` (`systems/combat_rounds.gd:2973`) builds a shallow frame, so its single copy inside `push` is correct. Leave it.

### 2.5 [P1] Daily-tick hot spots: memoise pure lookups within a pass

The profile shows `FactionSim.trade` (29 ms) and `craft` (15 ms) leading. The pattern is repeated recomputation of values that are constant for the whole pass:
- `reserve()` → `ore_reserve()` loops every craft recipe and calls `Crafting.calc_cost()` (which allocates a new Dictionary each time) for every good, for every faction, twice (sell pass, then buy pass).
- `FactionAI.is_withholding()` scans the full `withholds` array on every call.
- `traded_goods(faction_id)` is rebuilt in both passes, using `Array.has` dedupe.

Fixes, none of which change any formula:
- Cache `calc_cost(recipe, skill)` in a static Dictionary keyed `"%s|%d"`. Data is immutable after boot. Return a duplicate if any caller mutates the result.
- At the start of `trade()`, build a `withholding` set once: `{ "faction|kind|good": true }`.
- Compute `traded_goods` once per faction per `trade()`.
- **Do not** cache `held()`/`reserve()` values that trades mutate during the pass.

**Verify equivalence:** run `scripts/sim_faction_economy.gd` with a fixed seed before and after, and compare `JSON.stringify(GameState.state).hash()`. It must be byte-identical. Expected: daily tick 147 ms → ~100 ms (*estimate*).

### 2.6 [P1] Load event card images in the background

`scenes/screens/event.gd:942` calls `load(image_path)` synchronously when a card shows. Each still is ~2 MB, which means a decode hitch on the main thread on mobile. When a card renders, call `ResourceLoader.load_threaded_request()` for the next card's image (the next keys are known from `goto`/options), and use `load_threaded_get` when it's needed. Once §3.2 is done this matters much less.

### 2.7 [P1] Enable low-processor mode (battery)

This is a menu-driven mobile game, but `project.godot` has no `application/run/low_processor_mode`. Turn it on, so frames only redraw when something changes. Then check that the always-on `_process` users stop requesting redraws while idle:
- `map_halos.gd:157 ChargeHalo` calls `queue_redraw()` every frame while a wild/rampant halo exists. Acceptable, but each one keeps the device awake. Consider a Tween on `modulate`/`scale` instead of `_draw`.
- `alarm_presentation.gd:66` processes every frame. `set_process(pending_open)` is enough.

### 2.8 [P2] Phone app rebuilds

`phone.gd:_refresh` destroys and rebuilds the active app (12 ms) on every emit. After §2.1 this happens once per frame, which is fine for now. Longer term, let apps update in place, because the rebuild also resets scroll position and focus.

### 2.9 [P2] Small stuff
- `Rng.stable_unit()` allocates a `RandomNumberGenerator` per call. Deriving the value straight from `key.hash()` works, but it changes the values, which is a balance change, so ask first. Low gain anyway.
- `FactionSim.trade_order()` and others allocate via `GameData.FACTIONS.keys()` on every call. Cache the id arrays as constants after load.

---

## 3. Build size and memory

### 3.1 [P0] Unused folders ship in the APK

`export_presets.cfg` uses `export_filter="all_resources"` with an empty `exclude_filter`. Breakdown of `build/vein-26-11-06-2.apk` (301 MB):

| Source | In APK |
|---|---|
| `assets/events` | 92.0 MB (79 textures) |
| `assets/reference-plates` | **56.8 MB, no references in code or data** |
| `assets/character-references` | **22.1 MB, no references in code or data** |
| `assets/hq` / `assets/combat` | 14.7 / 12.7 MB |
| Godot `lib/` | 77.6 MB |
| `tests/`, `tools/`, `scripts/`, `addons/godot_ai` | ~4 MB (test `.gdc`s, fixtures, `lint_refs.json`) |

Set both presets to:
```
exclude_filter="assets/reference-plates/*, assets/character-references/*, tests/*, tools/*, scripts/*, docs/*, reference/*, plans/*, .scratch/*, addons/godot_ai/*"
```
(See §4.8 for the addon.) This saves ~83 MB right away. Better still: set `importer=keep` / "Do not import" on those reference folders, so the editor stops generating `.ctex` files for them at all.

### 3.2 [P1] Compress the large stills

All textures use `compress/mode=0` (lossless). Event stills run 941×1672 to 1024×1536 at ~2 MB each. I checked: these are **not** grid-aligned pixel art (a 2× nearest-neighbour downsample differs on ~12% of pixels, and one still has 320k colours), so lossy compression is visually safe in principle.
- **Disk/APK:** set `assets/events/**` and the large HQ backdrops to `compress/mode=1` (Lossy WebP, quality ~0.85). Expect ~4–8× smaller (*estimate*). The human must check for banding on a device.
- **GPU memory:** lossless and lossy both decompress to RGBA8, about 6.3 MB of VRAM per still. If several are cached at once, VRAM-compressed (ASTC/ETC2, already enabled via `import_etc2_astc`) cuts that to ~1.6 MB. Pick this if memory warnings show up on low-end devices.
- Keep small UI icons and sprites lossless.

---

## 4. Robustness

### 4.1 [P0] Atomic saves with error checks

`SaveManager._write_json()` (`autoload/SaveManager.gd:141`) opens with `WRITE` (which truncates the file), calls `store_string`, never checks `get_error()`, and relies on garbage collection to close. If the app is killed mid-write, that save is empty or half-written. Autosave rotation leaves two other copies, but a **manual slot has only one**.

```gdscript
func _write_json(path: String, data: Dictionary) -> Dictionary:
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return { "ok": false, "reason": "Could not open %s (error %d)." % [tmp, FileAccess.get_open_error()] }
	file.store_string(JSON.stringify(data))
	file.close()
	if file.get_error() != OK:
		return { "ok": false, "reason": "Write failed for %s." % path }
	if FileAccess.file_exists(path):
		DirAccess.rename_absolute(path, path + ".bak")
	var err := DirAccess.rename_absolute(tmp, path)
	return { "ok": err == OK, "reason": "" if err == OK else "Rename failed (%d)." % err }
```

On load, if the main file fails to parse, fall back to `.bak` and tell the player.

### 4.2 [P0] Save when the app is backgrounded or closed

Nothing handles `NOTIFICATION_APPLICATION_PAUSED`, `NOTIFICATION_APPLICATION_FOCUS_OUT` or `NOTIFICATION_WM_CLOSE_REQUEST`. Autosave only runs on the daily tick, purchases, combat exit and event completion, so everything since the last one is lost when Android kills the app in the background. Add this to `SaveManager`:

```gdscript
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST]:
		if GameState.state.get("currentScreen") != "title":
			autosave()
```

Whether a save taken mid-event or mid-combat should resume there is **a design decision. Ask before choosing.** The save format already carries `event` and `combat`.

### 4.3 [P0] Android Back button

`quit_on_go_back` is at its default (`true`), so the system Back gesture exits the app immediately. Set `application/config/quit_on_go_back=false`, then handle `NOTIFICATION_WM_GO_BACK_REQUEST` in `Main.gd` and route it to the screen's own Back (modal close → nav back → title). Which Back target each screen gets is a UX decision for the human.

### 4.4 [P1] IDs consume the gameplay RNG and depend on launch time

`bank.gd:13`, `notify.gd:38`, `messages.gd:107`, `sites.gd:26` and `cultivating.gd:796` build ids as `str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))`.
- **Each call advances the global gameplay RNG.** Adding one notification anywhere changes every later roll. That breaks seeded tests and balance sims in hard-to-trace ways, and makes balance depend on UI chatter.
- `get_ticks_usec()` restarts at zero on every launch, so ids aren't unique across sessions. A collision is unlikely but possible.

Fix: one counter in state, the same pattern `sales.nextOfferId` already uses:
```gdscript
static func next_id(prefix: String) -> String:
	var meta: Dictionary = GameState.state["meta"]
	meta["nextId"] = int(meta.get("nextId", 1)) + 1
	return "%s%d" % [prefix, meta["nextId"]]
```
Backfill `nextId` on load. Existing string ids stay valid. **Note:** removing the RNG draw shifts seeded outcomes, so golden tests or sims may need re-baselining. Flag that in the ticket.

### 4.5 [P1] The gameplay RNG stream isn't part of the state

`Rng._rng` lives outside `GameState.state`. Save/load and both Rewinds restore everything **except** the RNG position. Consequences:
- An exported save can't reproduce a bug report exactly.
- Reloading re-rolls daily outcomes (save-scumming).

Persisting `_rng.state` in `state.meta` would fix both. But the event Rewind "re-roll with advantage" rules may depend on a fresh stream. **That's a design call. Ask before changing it.** The minimum step is to include `Rng` state in exported saves for debugging.

### 4.6 [P1] Saving JSON forces ~600 lines of hand-written int restoring

JSON turns every int into a float. `SaveManager._restore_int_types()` and its helpers (from `SaveManager.gd:1001` on) restore ints **field by field**, and RNG states are saved as strings (`_encode_rng_states`). Any new int field that someone forgets comes back as a float after load. That breaks `==` against ints, `%d` formatting, and `match`, and it only shows up after a save/load cycle.

Fix: write on-disk saves with `FileAccess.store_var(state)` / `var_to_bytes`, which keeps int and float types and is 4.5× faster than JSON (3.9 ms vs 17.4 ms). Keep JSON plus base64 only for `export_string()`, or base64 the `var_to_bytes` output there too.
- Use `bytes_to_var` (never `bytes_to_var_with_objects`) so an imported string can't create objects.
- Migration: the loader tries binary first and falls back to the current JSON path. Old JSON saves still go through `_restore_int_types`, which then becomes frozen legacy code that never needs another line.
- Int dictionary keys survive the binary format but not JSON. Check that nothing relies on JSON's int→string key conversion.

### 4.7 [P1] Whole-state snapshots are fragile

Whole-state copies have to manually exclude `blockStart` and `event.snapshots`, or the stacks nest inside each other recursively (that's the CAUTION note in `Snapshots.gd`). Three call sites each repeat the dance. Add one helper:

```gdscript
# GameState: the transient keys never captured in a whole-state copy.
const SNAPSHOT_EXCLUDE := ["blockStart"]
func snapshot() -> Dictionary:
	var shallow := state.duplicate()
	for k in SNAPSHOT_EXCLUDE: shallow[k] = null
	if shallow["event"] is Dictionary:
		shallow["event"] = shallow["event"].duplicate()
		shallow["event"]["snapshots"] = []
	return shallow.duplicate(true)
```

Use it from `Rewind.mark_block_start`, `Events._snapshot_before_mutation` and `SaveManager._saveable_state`. Then remove the "empty the stack first" warning.

### 4.8 [P1] The MCP debug addon is live in release

`_mcp_game_helper` (`addons/godot_ai/runtime/game_helper.gd`) is a project autoload, so it runs in the shipped APK. It registers a logger capture, runs `_process` every frame, and ships 1.1 MB of addon code. Options:
- Add `if not OS.is_debug_build(): queue_free(); return` at the top of its `_ready`, or
- remove it from the release export with an `EditorExportPlugin`, combined with the exclude filter in §3.1. If you exclude only the files, the autoload path is missing at boot and errors.

### 4.9 [P2] Engine-clock timestamps stored in state

`lab.gd:599/739/804` stores `Time.get_ticks_msec()` (`startedMsec`) in state. After a save/load or app restart, that value means nothing, and `maxi(0, …)` hides the negative durations it produces. Use `Time.get_unix_time_from_system()` if a duration has to survive a restart. Otherwise mark the field transient and reset it on load.

### 4.10 [P2] Autosave rotation uses file modification times

`_find_autosave_slot_to_write()` picks the slot with the oldest mtime. Mtimes have one-second resolution and change when the device clock or timezone changes, so a clock jump can overwrite the newest autosave. Store a sequence number instead (in `meta` or a tiny index file) and rotate on that.

### 4.11 [P2] Test-only fallbacks in production code

`phone_device_shell.gd:76`, `bizbrief_app.gd:217` and `todo_app.gd:87` fall back to `Image.load_from_file(globalize_path(res://…))` so headless runs work without an import pass. In an exported build that raw file doesn't exist, so the fallback does nothing and can hide a missing import. Better: run `godot --headless --import` once in `setup_godot.sh` / CI, delete the fallbacks, and put all texture loading behind one `TextureCache.get(path)`.

---

## 5. Maintainability (the parts that block the fixes above)

### 5.1 God files
`combat_stage.gd` 3,297 lines · `GameData.gd` 3,207 · `combat_rounds.gd` 3,075 · `faction_ai.gd` 2,822 · `events.gd` 2,602 · `bizbrief_app.gd` 1,808 · `SaveManager.gd` 1,641. These are where profiling and review get hard. Suggested splits, along seams the files already have:
- `faction_ai.gd` → pressure / stances / wars / escalation / conclave
- `events.gd` → flow (advance/choose/rewind) / effects / checks
- `SaveManager.gd` → io / migrations / backfill / legacy-int-restore
- `GameData.gd` → the manifest loader stays; validators move to `GameDataValidate.gd`

### 5.2 Emit discipline
After §2.1, add a lint rule (`lint_tokens.sh`) that rejects `state_changed.emit()` in `systems/`, so new code goes through `mark_changed()`.

### 5.3 Repo hygiene
- Orphan `.uid` files whose script is gone: `scenes/screens/{crafting,lab,property,veins}.gd.uid`.
- Tracked scratch files: `_smoke_propagation.gd`, `scenes/_tmp_icon_preview.tscn`, `bugs-26-08-18.txt`, `bugs-28-08-26.txt`.
- `.git` pack is 273 MB and has leftover `tmp_obj_*` garbage. Run `git gc`. Large art should move to Git LFS.
- `Godot_v4.4-stable_win64_console.exe` in the root is stale; the target is 4.7.

### 5.4 Add a permanent UI profiler
The 55 ms/emit Map finding was invisible to the existing logic-only profiler because headless has 0 listeners. Add `scripts/profile_ui_refresh.gd`: boot `Main.tscn`, visit each screen, and print per-listener ms (the scratch version of this review did exactly that). Track it alongside `profile_block_end.gd`. For boot, capture `adb logcat` timestamps on device from process start to `GameData._ready` to settle the ~8.5 s question in §1.4.

---

## 6. What's already good (keep it)

- Pure-data state with a single owner per subtree. That's what makes every fix here mechanical.
- Logs and histories are capped. State size is flat from day 60 to day 200.
- ~99% static typing coverage (10,993 typed vars vs 149 untyped; 1 function without a return type).
- Data validation at boot, with errors collected rather than crashing.
- Profiling and balance-sim scripts already exist (`profile_block_end.gd`, `sim_*`).
- `Rng` already isolates seeded randomness; `fresh_seed()` keeps it off the global stream.

---

## 7. Suggested order (one ticket each)

1. §2.3 native deep copy + §2.4 single snapshot copy *(S, no behaviour change)*
2. §2.1 batched `state_changed` + §5.2 lint *(M; touches tests that check UI synchronously)*
3. §2.2 Map rebuild cache *(S)*
4. §3.1 export excludes + §4.8 strip the MCP addon from release *(S)*
5. §4.1 atomic save + §4.2 pause save + §4.3 Back button *(S each; §4.2/§4.3 need a design answer)*
6. §3.2 texture compression *(S config, human visual QA on device)*
7. §4.4 counter ids *(S; re-baseline seeded goldens)*
8. §2.5 FactionSim memoisation *(M; verify with a same-seed state hash)*
9. §4.6 binary save format + §4.7 snapshot helper *(M)*
10. §2.6, §2.7, §4.5, §4.9–4.11, §5.1, §5.3 as capacity allows

**Decisions needed from the human:** §4.2 (resume a save taken mid-event or mid-combat?), §4.3 (where Back goes on each screen), §4.5 (should Rewind or reload re-roll?), §2.9 (`stable_unit` value change).
