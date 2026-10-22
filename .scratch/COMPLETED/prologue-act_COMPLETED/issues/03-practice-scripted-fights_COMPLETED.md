# 03 — Practice scripted fights (guided spar)

**What to build:** An event can run a **winnable, coached fight with fixed enemy plans** under spar rules, for the Prologue's guided spar at Flip Reverse (R1 Guard, R2 Feint → Strike, R3 Stun on an Open target). The scripted fight's Rewind lock, lock prompt and post-Rewind script become optional. With no lock, the pre-Rewind restrictions (nobody drops except forced KOs, Leg it fails) don't apply, the fight can end normally, and every outcome (win/loss/fled) returns to the event at its resume card. A `practice: true` flag applies spar rules: free, unlimited Rewinds; HP and items restored on exit, as Spar does; Combat XP with the spar win bonus; normal move XP; no loot or cash. A practice fight does **not** use one of the 3 free spar sessions. Reuse the Spar code paths rather than duplicating them. Proven with a test fixture event. Source: `.scratch/prologue-act/spec.md` "Guided spar"; `docs/story-restructure.md` Prologue step 5.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/combat.gd` (`start_scripted_fight` ~L401, `_scripted_roster`, `_exit_scripted` ~L1620, spar exit/restore path, `round_rewind`), `systems/combat_rounds.gd` (script phase rules, coach), `systems/sparring.gd` (spar XP + end-rewind restore), `systems/events.gd` (`start_scripted_fight` op validation ~L844), `data/combat_rounds.json` (`spar` block), `tests/test_scripted_fight.gd`, `tests/test_coach_marks.gd`. REFERENCE §3.7b "Scripted fights", "Spar", "Coach marks". Update REFERENCE §3.7b and `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] A script without lock/post validates and plays as a normal fight with fixed enemy plans and coach marks.
- [ ] Win, loss and fled all resume the event at the right card.
- [ ] `practice: true`: Rewind free and unlimited; HP/items restored on exit; Combat XP + win bonus and move XP awarded; no loot; spar session count unchanged.
- [ ] Existing locked scripted fights behave exactly as before.
- [ ] Tests: unlocked win path, practice rules, fixed plans leave the R3 target Open. Save/load mid-fight keeps position.
