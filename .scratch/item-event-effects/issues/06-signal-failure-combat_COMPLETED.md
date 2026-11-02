# 06 — Signal Failure (reinforcement delay)

**What to build:** In combat, Signal Failure delays the arrival of enemy reinforcements by N rounds (brainstorm §3.4). Its event use is authored content only (see 22).

**Blocked by:** 01

**Relevant files:** `systems/combat_rounds.gd`, `systems/combat.gd`, `data/combat_rounds.json`, `tests/test_combat_rounds.gd`; REFERENCE §3.7a Squad, reinforcements and Combat Skill.

**Status:** ready-for-agent

- [ ] A scheduled reinforcement arrives N rounds later; stacking rule documented
- [ ] Behaviour when no reinforcements are pending is documented and tested
