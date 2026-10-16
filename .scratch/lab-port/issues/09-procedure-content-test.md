# 09 — Procedure content test; prototype recipes mastered

**What to build:** A content test that guards every procedure (P1/P2), plus the three prototype recipes brought up to full four-rung mastery so the test passes. Ingredient amounts get a single source shared by procedures and recipes data. Spec: `.scratch/lab-port/spec.md` § Content (P1, P2), § Testing Decisions Seam 4.

**Blocked by:** 02

**Relevant files:**
- `data/lab.json`, `data/recipes.json`
- new `tests/test_lab_content.gd`
- `autoload/GameData.gd` (procedure validation)
- `systems/lab.gd` (scoring for the simulated perfect run)

**Status:** ready-for-agent

- [ ] For every recipe with a procedure: schema valid (`ideal` apparatus/ore/target/weight summing to 100, `base` calc summing to base calc, `baseTolerance`), multi-ore recipes have every ingredient ore in `base`
- [ ] Every hidden step has one rung tag (`hint1`/`hint2`/`master`) and inserts a step or corrects a base target; ≥1 step per rung
- [ ] Simulated perfect max-skill run per knowledge level lands in band: base 40–59, +hint1 60–74, +hint2 75–89, all 90–100
- [ ] Base calc matches recipe ingredients; one of the two is the single source (other derived/validated)
- [ ] timePearl, healingSalve, healingBurst have master step(s) and pass
