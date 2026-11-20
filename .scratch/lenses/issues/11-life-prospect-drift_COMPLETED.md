# 11 — Life lens: better prospecting + drift forecast

**What to build:** Spec `.scratch/lenses/spec.md` "Life: prospect + drift". With a Life lens and Sense >= world gate: `Sites.prospect` shifts site-tier weights toward higher tiers by `lifeProspectShiftByTier` (placeholder, in `sites.json`), stacking with Be A Lady's best-of-two; the vein sheet shows tonight's drift range and collapse risk, read from the functions the daily tick already uses (no new formula). Strings PROSE-REVIEW.

**Blocked by:** 01

**Status:** ready-for-agent

**Relevant files:**
- `systems/sites.gd`
- `systems/cultivating.gd`
- `data/sites.json`
- `systems/lenses.gd`
- `scenes/screens/map.gd`
- `tests/test_sites.gd`
- `docs/REFERENCE.md` prospecting/sites, §3.4

**Acceptance:**
- [ ] Tier distribution shifts up with the lens (seeded test); unchanged without.
- [ ] Forecast range brackets the actual nightly drift (test).
- [ ] Human QA: vein sheet forecast line.
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
