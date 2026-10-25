# 01 — Black Hole leaves enemies Stunned

**What to build:** When the player (or an ally) uses a Black Hole in combat, every enemy it hits should end up with the Stunned status, the same one a landed Stun gives, and not a freeze. The lost actions should read as Stunned everywhere: the combatant's status line ("Stunned: loses next N action(s)"), the lost-action overlay on the stage and turn-order strip, and the play-by-play. The system already charges Black Hole's actions to the lost-actions pool and not to the Time Pearl freeze, so this ticket confirms that end to end, fixes any place that shows or treats it as Frozen/Open, and pins it with a test. Time Pearl keeps its freeze.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/combat_rounds.gd` (ITEM_BLACK_HOLE resolve, frozenActions vs actionsLost, guard_marker / is_open, status_badges), `data/combat_rounds.json` (blackHole item, tooltip, beat text), `data/combat_visuals.json` (blackHole visual), `scenes/screens/combat_rounds.gd` (_position_loss, status labels), `tests/test_combat_rounds.gd`; REFERENCE §3.7b.

**Status:** ready-for-agent

- [ ] After a Black Hole, each enemy hit has lost actions and none frozen; it reads Guarded/Open exactly as a stunned enemy would, not held Open
- [ ] Combatant detail shows "Stunned: loses next N action(s)" and never "Frozen"
- [ ] Its lost positions show the "Lost" overlay/strip text, never "Frozen"
- [ ] Test covers a Black Hole on 2+ enemies: actionsLost set, frozenActions 0
- [ ] Time Pearl behaviour unchanged (existing tests pass)
