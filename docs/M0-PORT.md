# M0 — The Port & Foundations

**Goal:** the HTML prototype, at feature parity, in Godot 4.4, on the new 5-ore roster, with the four engine foundations (snapshots, autosave, data-driven events, effect pipeline stub) — runnable and testable entirely headless.

Execute tasks **in order**. Each task = one commit. A task is done when its Acceptance list passes and `scripts/run_tests.sh` is green. Rules of engagement: `CLAUDE.md`. All numbers: `docs/REFERENCE.md` (cited as R§n).

---

## T00 — Repo, engine bootstrap, test harness
- Godot 4.4 project: `project.godot` (portrait 390×844 base, `canvas_items` stretch, `expand` aspect), folder skeleton per CLAUDE.md architecture + `tests/`, `scripts/`, `data/`, `reference/`.
- Copy the prototype HTML into `reference/london-orichalchum.html` (read-only prose quarry).
- `scripts/setup_godot.sh`: if no `godot` on PATH, download the official godotengine GitHub release for the host OS (Linux or Windows), unzip to `.godot-bin/`, and wire up `./godot` (a real symlink on Linux; a small exec-wrapper script on Windows, since Godot's win64 console binary refuses to run under any name but its own). Idempotent.
- `scripts/check_all.sh`: runs `scripts/check_runner.gd` (a `-s` SceneTree script, so autoloads resolve) over every `.gd` file, exits non-zero on any failure. Also takes explicit paths for single/multi-file checks: `godot --headless -s scripts/check_runner.gd -- path/to/file.gd`.
- Test harness (no external framework): `tests/test_runner.gd` extends `SceneTree`; discovers `tests/test_*.gd`; each test file extends a tiny `tests/test_base.gd` providing `assert_eq(a,b,msg)`, `assert_true`, `assert_almost_eq(a,b,eps)`, `run_case(name, fn)`; runner prints `PASS/FAIL` per case and exits non-zero on any failure. `scripts/run_tests.sh` = `godot --headless -s tests/test_runner.gd`.
- Seeded RNG helper for tests: systems must take randomness ONLY from `Rng.gd` autoload wrapping a `RandomNumberGenerator` with `set_seed(n)` — this is what makes probabilistic systems testable. Add `Rng.randi_range`, `Rng.randf`, `Rng.chance(p)`, `Rng.rand_from(array)`.
**Acceptance:** `setup_godot.sh` then `run_tests.sh` passes with one trivial test on a clean machine with no Godot preinstalled.

## T01 — Data files + loader
- Author every table in R§1 as JSON under `data/` (exact keys/values). Verbatim-description fields: extract from the named HTML consts, applying R§7 renames.
- `autoload/GameData.gd`: loads all JSON at boot into typed constants (`GameData.ORE_TYPES` etc.); `validate()` asserts required keys per table and cross-references (recipe ingredient types exist, room minTiers exist, barometer pref states exist).
**Tests:** validation passes; deliberately corrupt fixture fails validation; spot-check 10 values (e.g. fate basePrice 90, townhouse maxRooms 3, enhancementPowder ingredient "life").

## T02 — GameState, EventBus, Rng
- `autoload/GameState.gd`: `state` built from a `new_game_state()` factory matching R§2 exactly; `reset()`; helper `read_path(p)` (named `read_path`, not `get_path` — that name collides with `Node`'s native `get_path() -> NodePath` and fails to compile)/no fancy accessors needed beyond direct dict access. `deep_copy(v)` util (recursive; duplicates dicts/arrays).
- `autoload/EventBus.gd`: signals `state_changed`, `screen_changed(screen)`, `day_ticked(day)`, `notification_pushed`.
- Convention helpers in `systems/notify.gd`: `push(text)` (id = str(Time.get_ticks_usec()) + random suffix), `dismiss(id)`.
**Tests:** new_game_state matches R§2 defaults (assert ~20 representative fields); deep_copy independence (mutate copy, original unchanged).

## T03 — Time system + barometer
`systems/time_system.gd`: advance_time_block, is_time_exhausted, do_rest per R§3.1 (daily_tick calls stubs for not-yet-built systems; wire them as tasks land — keep the exact order R§3.1 lists).
`systems/barometer.gd`: init/ensure progress, faction nudges, drift, resolution, manual push/pull, merged effects, effective mug chance and ore price — all per R§3.2.
**Tests (seeded):** 3 blocks tick a day; rest heals 20% capped; daily cost applies inflation multiplier; drift with seed produces deterministic sequence; a state force-fed to 100 flips active and zeroes the old; push costs £2000, respects cooldown, +20 progress; effective price: fate under economic=crisis = round(90 × (1 − 0.35 + 0.5)) = 104.

## T04 — Home system
`systems/home.gd` per R§3.3: raid chance, daily raid roll, upgrade, add security (with securityContactUnlocked ×0.7 pricing), add room (body bonus immediate), workshop bonus.
**Tests:** raid chance floor 0.002; 3-day raid spacing; safeRoom quarters vs halves loss (seeded); minTier and slot caps enforced; discount math.

## T05 — Cultivating + harvest
`systems/cultivating.gd` per R§3.4. Location generator: port the two string arrays verbatim from HTML `generateLocationName`.
**Tests (seeded):** seed deducts 40 always; success creates Lv1 vein with devBar = 1+skill; XP thresholds level the skill at exactly 80; cultivate fills bar and levels up at devBarMax; full harvest drains devBar and triggers level-down at ≤0; Lv1 level-down deletes the vein; Lv5 is the cap (no hospitability in M0).

## T06 — Crafting + devices
`systems/crafting.gd`, `systems/devices.gd` per R§3.5.
**Tests (seeded):** craftChance at skill 3 with workshop = min(0.95, 0.40+0.26+0.08); calcCost floor 1; ore deducted on failure; device build progress ladder 10→100 in 18 successes; break at ≤0; charge reset on new day; device level 2 at 50 XP grants 2 charges.

## T07 — Selling + mugging economics
`systems/economy.gd` per R§3.6 (sale execution, 50/50 split, pendingSaleCut, consumable-sale trigger flag). No UI yet — combat entry is a call into T08.
**Tests (seeded):** gross math with barometer premiums; consumable gate flag flips exactly once; mugged path defers payout until muggingWon.

## T08 — Combat
`systems/combat.gd` per R§3.7 + snapshot/rewind per R§3.9 (Snapshots autoload created here, generic enough for T13 reuse). onWin dispatch via `match` on String.
**Tests (seeded):** mugger generation bands for count 1..3; freeze skips enemy turn and decrements; motion grants 2 or 3 attacks by power; flee 65% with seed; loss revives at 30% hpMax; rewind restores oldest snapshot, grants evade 2 turns @0.50, stack cleared; evade consumes turns and can miss; home_raid loss halves carried + stored ore.

## T09 — Contacts, rooms, James jobs
`systems/contacts.gd`, `systems/rooms.gd`, `systems/jobs.gd` per R§3.10.
**Tests (seeded):** recruit gating; room exclusivity; lab crafts to threshold with contact skill and stops when ore runs out; veinStation harvests charged and cultivates uncharged; job qty bands by relation; fulfil deducts and pays.

## T10 — Save/load/autosave
`autoload/SaveManager.gd` per R§6. `user://saves/` for slots, `user://autosave/` rotation of 3.
**Tests:** save→mutate→load round-trip equality (deep compare); export string reimports; migrate() table dispatch; missing-key backfill from defaults.

## T11 — Theme + UI shell
`theme/main_theme.tres` from R§4 tokens; `scenes/Main.tscn` with a `ScreenManager` swapping `scenes/screens/*` on `EventBus.screen_changed`; bottom `NavBar` component (5 tabs, hidden on the R§2.2 excluded screens); `NotificationToast` layer (stack, tap to dismiss); `ModalLayer` (dim + centred card, `modal.type` dispatch).
**Acceptance:** boots to title; Debug Start (R§5) enters home; nav switches screens; a test notification renders and dismisses. Report exactly what the human should eyeball on device.

## T12 — Screens & modals (split into ≤4 sub-commits)
Rebuild every screen listed in R§2.2 except `event` (T13), matching prototype layout intent (390px column, cards, amber accents): title, home (stats collapsible, to-do list per R§3.11, actions incl. Rest), veins (+seed flow), inventory (3 tabs; equip/unequip; device build UI), crafting (recipes with live chance/cost/power; device start/build), contacts (actions gated by flags per R§3.11; james job offer/fulfil), sms_archie & sms_archie_2 (staged message reveal — use `await get_tree().create_timer(...).timeout` in the SCREEN, delays 0.6/0.9s pattern; the reveal step counter may live in screen-local vars, it is presentation not game state), world (barometer summary, property card, faction bars, save link), property, factions, barometer (states, progress bars, push/pull buttons, greyed influence actions with costs), stats, save (slots/export/import/new game), combat (log, HP bars, Attack / Use Item / Flee, item modal, Rewind button when available).
All modals from the prototype: seed_result, cultivate_result, craft_result, sell_menu (qty steppers per line, live total), sale_result, room_detail, james_job_offer/short/complete, combat_items, event_items, confirm dialogs.
**Acceptance per sub-commit:** headless checks green + a human-check list. Full debug-start feature tour possible by end.

## T13 — Event framework + tutorial content migration
- `systems/events.gd` + `data/events/*.json`. Card schema:
  `{ type: "narration|speaker|tension|resolution|craft", label: String|null, speaker: String|null, text: String }`
  Event schema: `{ id, cards: [...], on_complete: [effect] }` where effects are data ops executed by `apply_effects()`: `{op:"set_flag", flag, value} | {op:"add", path, value} | {op:"add_ore", type, qty} | {op:"add_item", item, qty} | {op:"relation", contact, value} | {op:"grant_vein", vein:{...}} | {op:"set_screen", screen} | {op:"notify", text} | {op:"set_stage", value}`.
- Runner: `start_event(id)` sets `state.event`, screen "event"; Continue advances `cardIndex`, snapshotting full state per card (Snapshots stack "event", bound 8); Rewind (if player has rewind consumable/charged device) pops one card-frame; final Continue runs on_complete then clears.
- Event screen: bottom-anchored `ScrollContainer` + `VBoxContainer` so new cards push old ones up (this natively kills the prototype's scroll bug); action bar pinned below, always visible; card styles per type (tension = danger accent, craft = amber panel).
- Content: create the 8 tutorial event JSONs (intro, buyer, james_meeting, archie_craft_chat, home_raid_intro, home_raid_debrief_win, home_raid_debrief_loss, archie_motion, james_motion — 9 files) + the two SMS scripts, by extracting prose per `docs/CONTENT-GUIDE.md` §2 and encoding the completion effects exactly per R§3.11 and R§3.8. **Do not port `JAMES_CRAFT_CARDS` — dead content.** Combat-sandwiched events (home raid) chain: intro event → `start_home_raid_combat` effect op → combat exit routes to the correct debrief.
**Tests:** runner advances/rewinds without state corruption (deep-compare a rewound state to its snapshot); every on_complete effect op unit-tested; loading all 9 event files validates against the schema; a scripted headless playthrough of the full tutorial (drive system calls in sequence, assert every flag/stage/inventory change of R§3.11 lands).

## T14 — Autosave wiring + full-game headless playthrough
Wire autosave triggers (R§6). Write `tests/test_playthrough.gd`: seeded end-to-end — new game → tutorial (as T13) → seed a vein, cultivate to Lv2, harvest, craft pearls, sell (force both mug and no-mug branches via seed), buy security, join no faction, 10 daily ticks — asserting invariants each step (cash ≥ 0, hp in range, state matches schema keys, save/load mid-run round-trips).
**Acceptance:** playthrough test green 20 consecutive runs across 20 seeds (`scripts/soak.sh`).

## T15 — Mobile export prep
Export preset for Android (debug). Document (README section) the human steps: install export templates, `godot --headless --export-debug Android build/vein.apk`. If templates are unavailable in the sandbox, produce the preset + docs and mark the build step HUMAN-ACTION.

---

### M0 exit criteria (from the vision doc, restated)
1. Full tutorial-to-freeplay run on device without touching the old HTML.
2. Autosave + manual slots + export/import all functional.
3. Debug "undo turn" (Rewind) works in combat and in events, no state corruption over the soak test.
4. All tests green; `check_all.sh` clean.
