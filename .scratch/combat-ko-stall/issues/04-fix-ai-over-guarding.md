# 04 — Fix combat AI over-guarding

**What to build:** Implement the fix option the human chose from the ticket 03 diagnosis. Afterwards, allies and enemies mix their moves so that fights resolve in a reasonable number of rounds, and an ally-vs-enemy matchup can't stall indefinitely. Any number, pattern or rule change is written to REFERENCE.md in the same commit (REFERENCE is canonical, and data follows it).

**Blocked by:** 03 — Diagnose combat AI over-guarding (and the human's choice of fix option).

**Relevant files:**
- `.scratch/combat-ko-stall/ai-guard-diagnosis.md` (chosen option)
- `systems/combat_rounds.gd` (`_ally_action()`, `_plan_allies()`, `_pick_pattern()`, enemy guard reply)
- `data/combat_rounds.json`
- `docs/REFERENCE.md` §3.7b
- `tests/test_combat_rounds.gd`, ticket 03 sim harness

**Status:** needs-info

- [ ] Chosen option implemented exactly as approved
- [ ] Re-running the ticket 03 sim shows the guard share and rounds-to-outcome improved versus the baseline; numbers in the report
- [ ] Ally-vs-enemy (player KO'd) sims reach an outcome within a cap
- [ ] REFERENCE.md updated for any rule/number change; existing combat tests pass
