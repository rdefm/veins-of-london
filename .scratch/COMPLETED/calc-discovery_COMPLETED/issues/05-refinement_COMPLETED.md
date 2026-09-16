# 05 — Refinement: tiers, cost/odds curves, refineStep

**What to build:** Re-experimenting an already-found effect to push it through uncapped tiers, each tier costing more ore and rolling at lower (but floored, never zero) odds than the last, applying an effect-specific `refineStep` on success.

**Blocked by:** 04 — systems/bench.gd core: keys, cell state, census, probe roll, pity.

**Status:** ready-for-agent

- [ ] `systems/bench.gd` extended: a separate refinement roll — its own chance/cost curve per vision-doc §7 (provisional constants, implemented as specified), rising ore cost per tier, falling-but-floored success odds, uncapped tier count. Refinement only operates on `found` cells; `inert` and `hot` cells are never refinable.
- [ ] On refinement success: cell's `refine` tier incremented, recipe's `refineStep` (e.g. `{"field": "effectPower", "add": 3}`) applied to the discovered recipe — the effect that field changes is defined per-effect, not by a universal formula.
- [ ] Ore always deducted on a refinement attempt regardless of outcome, matching probe precedent.
- [ ] `tests/test_bench.gd` extended: refinement tier/cost/odds progression (cost rises, odds fall but never hit zero, tiers uncapped); `refineStep` correctly mutates the target recipe field on success; attempting refinement on an `inert` or never-found cell is rejected/impossible.
- [ ] Syntax check clean on all touched `.gd` files.
