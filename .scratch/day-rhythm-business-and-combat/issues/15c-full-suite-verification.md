# 15c — Full-suite verification

**What to build:** Confirm the ticket 15 squad/item/wave rewrite of `systems/combat_prototype.gd` (and its schema changes in `autoload/GameState.gd`/`autoload/SaveManager.gd`/`autoload/GameData.gd`) hasn't regressed anything elsewhere in the project.

**Blocked by:** 15b — fixing the known test failures first so this run isolates *new* regressions rather than re-surfacing already-diagnosed ones.

- [ ] Run `scripts/check_all.sh` (or the per-file `check_runner.gd` sweep) across every file touched by ticket 15 and confirm clean.
- [ ] Run `scripts/run_tests.sh` (the full project suite, not just `test_combat_prototype.gd`) and confirm 0 failures. Pay particular attention to `tests/test_save_manager.gd`/save-load round-trip coverage and anything exercising `GameState.state["combatPrototype"]`'s old singular-`enemy` shape, since that schema changed to an `enemies` array this ticket.
- [ ] If the full run is slow, isolate rather than assume a regression (per this project's own known "full suite perf" note — `test_playthrough.gd`'s soak case is the usual slow one, unrelated to this ticket).
- [ ] Record the final pass count in this ticket's own notes before closing it out.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
