# 12 — Coherence sweep: KO, reorder, outcome, Rewind, persistence

**What to build:** Every way the fight can change shape leaves the queue, selection and cursor coherent. A KO removes that combatant's future occurrences and, if it was selected, moves the selection per ticket 01's clamp rule. Frozen/Motion/ability-lock changes reorder the projection without duplicate or orphaned cards. Victory, loss and flee leave no interactive occurrences and disable the command rows while the outcome button shows. Rewind restores cursor, selection and projection to the snapshot's decision point and plays the queue back to match. Save/load and combat snapshots round-trip every new field (cursor, selection, `locationKey`); older saves load with safe defaults. Finishes with the spec's full acceptance checklist run headless and an on-device QA block for the human.

**Blocked by:** 03 — Resumable turn progression; 06 — Queue advancement; 07 — Command validation; 11 — Receding staging.

**Relevant files:**
- `systems/combat.gd` — `_clamp_focused_enemy_index` (generalised), `_restore_from_snapshot`, `push_combat_snapshot`, `_try_failsafe`, `exit_combat`, `_maybe_win_from_direct_damage`, `_enemy_attack_ally` (ally KO path), projection query
- `autoload/GameState.gd` — save/load, migration defaults for new combat fields
- `systems/snapshots.gd` — bounded stack behaviour
- `scenes/screens/combat.gd` — `_sync_footer`, `_build_outcome_button`, `_on_combat_rewind_played`
- `scenes/components/turn_order_strip.gd`, `scenes/components/combat_command_dock.gd`
- `tests/test_combat.gd`, `tests/test_combat_screen.gd`, `tests/test_turn_order_strip.gd`, `tests/test_combat_director.gd`
- `docs/REFERENCE.md` — §2 combat schema, §3.7a Targeting (auto-clamp), §3.9 Snapshots & Rewind
- `.scratch/combat-refining/spec.md` — "Testing Decisions" acceptance checks 1–11
- `CODEMAP.md`

**Status:** ready-for-agent

- [ ] KO of the selected enemy: selection clamps per 01, no card for the KO'd combatant remains, Attack row availability follows the new selection
- [ ] Ally KO mid-fight: its occurrences vanish; if selected, selection clamps; no invalid index reaches any system call
- [ ] Freezing / Motion / ability-lock changes: projection has no duplicate occurrence ids and no gap
- [ ] Win, loss and flee: zero interactive cards, command rows disabled, outcome button present
- [ ] Rewind: cursor, selection and projection equal the snapshot's; strip ends at that projection's front
- [ ] Save → load with a mid-fight state restores cursor, selection, `locationKey`; a save lacking the fields loads with defaults and a valid projection
- [ ] Spec acceptance checks 1–10 each map to a passing headless test (list the mapping in the report)
- [ ] `scripts/check_all.sh` and `scripts/run_tests.sh` pass; CODEMAP current for every touched file
- [ ] Report ends with the on-device QA block covering acceptance check 11
