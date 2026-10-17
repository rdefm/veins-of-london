# 10 — Time/life procedures

**What to build:** Full authored four-rung procedures for rewind, prophetsBreath and enhancementPowder, so each is craftable at the new bench with the same mastery path as every other recipe. Content is fixed, provisional and tagged for balance. Spec: `.scratch/lab-port/spec.md` § Content (P1, P2), Further Notes.

**Blocked by:** 09

**Relevant files:**
- `data/lab.json`, `data/recipes.json`
- `tests/test_lab_content.gd`
- existing procedures in `data/lab.json` (timePearl, healingSalve, healingBurst) as authoring prior art

**Status:** ready-for-agent

- [ ] rewind, prophetsBreath, enhancementPowder each have a procedure passing the content test (schema, rung tags, ≥1 step per rung, base calc = ingredients, perfect-run bands)
- [ ] Any new clue text / direction words flagged `PROSE-REVIEW:`
