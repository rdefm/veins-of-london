# 15b — Fix remaining test failures and clean up debug scratch files

**What to build:** `tests/test_combat_prototype.gd` (extended for ticket 15's squad/item/wave work) passes cleanly end to end, with no unexplained failures and no known-bug results left standing.

**Blocked by:** None — continues directly from ticket 15's in-progress work (`systems/combat_prototype.gd`, `data/combat_prototype.json`, `scenes/screens/combat_prototype.gd`, and `tests/test_combat_prototype.gd` are already rewritten for squads/items/waves; most of an initial 8-failure batch was already root-caused and fixed in-session, including a real rewind-ordering bug — item/Dial spend now happens after the round's snapshot is pushed, not before).

- [ ] Root-cause and fix `frozen_and_exhausted_stack_as_two_separate_skipped_turns_not_one` (last observed failure: `got 86, expected 100` — "enemy 0 never got an actual turn across either round"; determine whether the bug is in `_resolve_enemy_entry`'s frozen/exhaustion ordering or in the test's own setup).
- [ ] Investigate `mixed_squad_fixed_strategy_simulation_runs_and_produces_a_real_outcome_mix` (last observed result: 0 wins / 60 losses / 0 fled against `mixedCrew` with a Dodge-the-Brawler/Heavy-the-Knife-Fighter/Dodge-the-Enforcer repeat strategy). Determine whether this is a bug in the simulation harness or the round engine, or a real finding about the roster/strategy — fix if it's a bug. Do not carry an unexplained result into ticket 15d's write-up.
- [ ] Re-run the full test file after fixes; confirm 0 failures.
- [ ] Confirm no stray debug/scratch files remain in the working tree from this investigation.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
