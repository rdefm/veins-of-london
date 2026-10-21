# 04 — Offer variety: every item and calc type, ramp to random by day 30

**What to build:** Random Sales offers are currently dominated by Time Pearls and Enhancement Powder. Random offers should be able to request every recipe item and all five calc types (`time`, `physics`, `life`, `fate`, `emotion`), including items the player doesn't know yet, as an incentive to learn recipes.

Weighting ramps linearly with in-game day:
- Early: heavily weighted to known recipes, with Time Pearls over-represented.
- By day 30 (and after): a uniform random pick over all items and calc types.

Expose the ramp as a shared helper so ticket 05 reuses it. Put the ramp parameters (end day, starting weights) in `data/offers.json`, never in code. Update REFERENCE.md "Offer sourcing" to match.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/offers.gd`, `data/offers.json`, `systems/lab.gd` (`is_known`), `data/recipes.json`, `docs/REFERENCE.md` §3.10 "Offer sourcing"

**Status:** ready-for-agent

- [ ] Random templates/catalogue cover every recipe item and every calc type
- [ ] Day 1 distribution favours known recipes and Time Pearls; day ≥ 30 distribution is uniform (seeded statistical test)
- [ ] Ramp is linear between those points, parameters in JSON
- [ ] REFERENCE.md updated
