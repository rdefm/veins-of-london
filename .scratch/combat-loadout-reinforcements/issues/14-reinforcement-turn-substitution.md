# 14 — Reinforcement turn substitution, save and Rewind

**What to build:** When a KO'd fighter still had an unresolved occurrence this round, the entrant takes one occurrence, placed among the remaining ones by its own speed and the existing tie-break rules; if the KO'd fighter had already acted, the entrant first acts next round. Motion extra occurrences and Rewind snapshots never create duplicate or lost turns on substitution. The turn-order strip projects active occurrences only. Save/load, autosave, snapshots and Rewind round-trip the active/queued roster and turn cursor, consistent with existing Rewind scope while preserving spent resources and ally-KO persistence.

**Blocked by:** 13

**Relevant files:** `systems/combat.gd` (`turnCursor`, `project_queue`, `prime_`/`conclude_decision_point`, rewind), `scenes/components/turn_order_strip.gd`, `autoload/SaveManager.gd`, `autoload/GameState.gd` (snapshots), `tests/test_combat.gd`, `tests/test_savemanager.gd`, `tests/test_combat_screen.gd`. Update REFERENCE §3.7a, §3.9 with the change.

**Status:** ready-for-agent

- [ ] Unresolved-vs-spent occurrence cases both tested with seeded initiative
- [ ] Motion extra turns survive substitution without duplicates or losses
- [ ] Rewind across a substitution restores roster + cursor; spent items stay spent
- [ ] Save/load mid-fight with queued fighters round-trips exactly
- [ ] Strip shows active occurrences only
