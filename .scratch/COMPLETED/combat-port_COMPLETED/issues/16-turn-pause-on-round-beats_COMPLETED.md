# 16 — Turn pause between actions in round fights

**What to build:** `CombatDirector.is_turn_boundary()` holds `pacing.turnPause` between two combatants' turns by comparing each beat's `occurrence.occurrenceId`. Round-fight beats (`CombatRounds._beat()`) carry no `occurrence`, so every boundary reads false and the pause never fires — a pick's beats play back to back. Round beats do carry `round`, `turnActor` and `turnIndex` (the resolving timeline entry). Make the boundary test read those instead: a boundary sits between two beats whose (`round`, `turnActor`, `turnIndex`) differ. Beats with no turn (round-boundary beats such as reinforcement `enter`) count as their own turn, as now. Rewind's reversed queue pauses the same (direction-agnostic). Drop the `occurrence` read once nothing produces it.

**Blocked by:** None

**Relevant files:** `scenes/components/combat_director.gd` (`play()`, `is_turn_boundary()`, `_occurrence_id()`); `systems/combat_rounds.gd` (`_beat()` — `turnActor`/`turnIndex` from `cp.cursor`; check which beats are pushed with cursor actor -1, e.g. round-end/admission beats); `scenes/screens/combat_rounds.gd` (`_play_beats()`, its own `_SETTLE_KIND` closing beat — must not trigger an extra pause); `tests/test_combat_director.gd` (boundary cases built on `occurrence`); `tests/test_combat_rounds.gd` (a round fight's real beats); `data/combat_visuals.json` `pacing.turnPause`; `docs/combat-animation-vision.md` (pacing doctrine); `CODEMAP.md` combat_director row

**Status:** ready-for-agent

- [ ] Two consecutive beats of one action play with no turn pause; beats of different actions (different actor or timeline index) get one
- [ ] Round-boundary beats and the screen's settle beat behave as specified; Rewind playback pauses the same way
- [ ] Director tests rebuilt on round-beat fields; no `occurrence` read remains
- [ ] Full suite and `scripts/check_all.sh` clean; CODEMAP row current
