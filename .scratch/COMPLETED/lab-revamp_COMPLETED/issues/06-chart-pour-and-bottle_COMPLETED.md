# 06 — Slice B: resonance chart, pour and bottle

**What to build:** In the Chart slice, the player picks a recipe and sees a 2D chart with the marker at the origin. Each recipe is an authored circular region with a bullseye at its centre. Base knowledge reveals the region but not the bullseye.
- **Pour:** hold a calc jar and the marker slides along that type's fixed direction for as long as you hold (life →, time ↑). Calc is spent per unit of distance from the Chart slice's own pool.
- **Bottle:** ends the run. Bullseye radius = base_radius × (1 + skillFactor × craftingSkill).
- **Score:** 100 inside the bullseye, falling linearly to rank 1 at the region edge, and 0 outside the region.

The run feeds the shared core (rank, bonus, flavour, Rewind, ledger). The screen reports raw hold durations; the system moves the marker and charges calc. See spec §Slice B.

**Blocked by:** 01 — Sandbox core + Debug launcher.

**Relevant files:** `.scratch/lab-revamp/spec.md` §Slice B; bench prototype system/screen/data/tests from 01; `docs/ui-vision.md` (palette).

**Status:** ready-for-agent

- [ ] Region centres, radii, bullseye base radii and pour directions/costs for all 3 recipes are in data.
- [ ] Placeholder `_draw` chart: marker, revealed regions, path trail.
- [ ] Hold-to-pour moves the marker and spends calc per distance. Running out of calc stops the pour.
- [ ] Bottle scoring is unit-tested: bullseye = 100, edge = rank-1 threshold, outside = 0, and skill widens the bullseye.
- [ ] Human check list: does hold-to-pour feel good on a phone, and is the cost readable?
