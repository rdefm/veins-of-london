# 15c — Full-suite verification

**What to build:** Confirm the ticket 15 squad/item/wave rewrite of `systems/combat_prototype.gd` (and its schema changes in `autoload/GameState.gd`/`autoload/SaveManager.gd`/`autoload/GameData.gd`) hasn't regressed anything elsewhere in the project.

**Blocked by:** 15b — fixing the known test failures first so this run isolates *new* regressions rather than re-surfacing already-diagnosed ones.

- [x] Run `scripts/check_all.sh` (or the per-file `check_runner.gd` sweep) across every file touched by ticket 15 and confirm clean.
- [x] Run `scripts/run_tests.sh` (the full project suite, not just `test_combat_prototype.gd`) and confirm 0 failures. Pay particular attention to `tests/test_save_manager.gd`/save-load round-trip coverage and anything exercising `GameState.state["combatPrototype"]`'s old singular-`enemy` shape, since that schema changed to an `enemies` array this ticket.
- [x] If the full run is slow, isolate rather than assume a regression (per this project's own known "full suite perf" note — `test_playthrough.gd`'s soak case is the usual slow one, unrelated to this ticket).
- [x] Record the final pass count in this ticket's own notes before closing it out.

## Notes

- `scripts/check_all.sh`: 242 files, clean.
- `scripts/run_tests.sh` first pass: 2382 passed, 1 failed — `test_gamedata_validate.gd`'s `real_data_loads_and_validates`: `objectives.col_a1_nadia_supply: unknown type 'supplied_to_contact'`. Confirmed via `git log` this predates ticket 15 entirely (already broken at commit `3273a39` "M0-T09: Nadia supply order", before `c9b4d1d`/`bfaebe7`/`ca5d7d9`/`014aa9b` — ticket 15's combat-prototype commits) — not a regression from the squad/item/wave rewrite. Root cause: `systems/objectives.gd` already implements the `supplied_to_contact` objective type (used live by `systems/collective.gd`'s `supply_nadia`/`nadia_supply_status`), but `autoload/GameData.gd`'s `OBJECTIVE_TYPES`/`OBJECTIVE_TYPE_PARAMS` validation table was never updated to include it — an oversight from that earlier commit, not a spec question. Fixed by adding `"supplied_to_contact": ["contactId", "factionId", "oreType", "qty"]` (matching the params `data/objectives.json`'s `col_a1_nadia_supply` entry and its consuming systems already use).
- `scripts/run_tests.sh` second pass (after the fix): **2383 passed, 0 failed.**
- No regressions from ticket 15's `systems/combat_prototype.gd` squad/item/wave rewrite or its `GameState.gd`/`SaveManager.gd`/`GameData.gd` schema changes anywhere in the suite.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
