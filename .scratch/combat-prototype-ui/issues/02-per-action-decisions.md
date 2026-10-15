# 02 — Prototype system: per-action decisions + rewind to last pick

**What to build:** Change the Combat Prototype from "plan the whole round, then commit" to "pause at each of the player's actions", like live combat, while enemies and allies still commit their round plans up front.

- At round start, enemy plans (and ally plans) are committed and visible as intents, unchanged.
- The round resolves in timeline order (action index, then speed, then tie-break) up to the player's next position, then pauses. The player picks one move or loadout item + target. It resolves, and play continues to the next player position or round end.
- The player chooses with the actual state in front of them (KOs, stuns, guard changes that already happened). Retargeting a KO'd enemy still applies if the target dies between pick and resolution within the same step.
- Multi-action moves (Lure, cost 2) take the current and next player position from one pick. Enhancement Powder's extra position is appended as now.
- If the player is KO'd, stunned or frozen out of a position, play skips it without pausing.
- Rewind restores the state at the previous player decision point (not round start), with that pick undone and replayable. Rewinding past a round boundary restores the prior round's pre-rolled plans.
- Every resolution step returns its beats so the screen can play them back.
- The plain prototype screen moves to one pick at a time at the paused position (minimal change; ticket 03 replaces the fight view).
- Balance sim: policies (naive, reader) become a decision callback invoked at each pause; output table unchanged.
- Update the combat-revamp spec's Solution / Implementation Decisions to record the per-action model and rewind-to-last-pick.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/combat_prototype.gd` (`start`, `set_plan_action`, `set_plan_item`, `plan_block_reason`, `timeline`, `resolve_round`, `rewind`, `_push_snapshot`), `tests/test_combat_prototype.gd`, `tests/test_combat_prototype_screen.gd`, `scripts/sim_combat_prototype_impl.gd`, `scripts/sim_combat_prototype.gd`, `scenes/screens/combat_prototype.gd`, `.scratch/combat-revamp/spec.md`, `CODEMAP.md`. For the cursor pattern: `systems/combat.gd` `turnCursor` / `prime_decision_point` / `conclude_decision_point` (REFERENCE.md §3.7a).

**Status:** ready-for-agent

- [ ] State stays pure data; the resumable cursor lives in `combatPrototype` state.
- [ ] Test: an enemy KO'd before the player's 2nd position is not offered as a target at that pause.
- [ ] Test: Stun on the player removes their next position, with no pause for it.
- [ ] Test: Lure consumes two positions from one pick.
- [ ] Test: Powder's extra position pauses for a pick in the same round.
- [ ] Test: Rewind returns to the previous pick with HP/guard/plans as they were; a second Rewind goes one pick further back (within the snapshot cap).
- [ ] Existing outcome tests (guard/chip, feint, stun, lure, leg it, items, crits, sight, sandbox isolation) adapted and passing.
- [ ] Sim runs headless to completion; reader still beats naive in matched fights.
- [ ] Plain screen playable start to finish.
