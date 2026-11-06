# 17 — Opportunistic outside crafting (all five factions)

**What to build:** Each daily rollover, every faction ranks the goods eligible to it (ticket 16) by margin — price minus the market cost of the ingredients — buys the missing ore on the market, and crafts, up to its daily cap. Items outside its own `crafts` and `craftTargets` are made at a lower tier or skill (data knob). A wallet floor stops poor factions gambling. No recipe-knowledge gate. Ore buying uses the existing buy path and `maxBuyMult` gate. The effect: a pinned good draws in crafters and the market corrects itself.

**Blocked by:** 16.

**Relevant files:** `systems/faction_sim.gd` (`craft`, `_buy`, `_buy_shortfall`), `data/factions.json` (`trading`, `crafts`, `craftTargets`), `systems/crafting.gd` (`calc_cost`, `faction_craft_chance`), `scripts/sim_faction_economy_impl.gd` (add an outside-craft line to the report), `tests/test_faction_sim.gd`, REFERENCE.md §3.1, §3.13, CODEMAP.md.

**Status:** ready-for-agent

- [ ] A non-specialist faction with wallet above the floor buys ore and crafts an eligible good, at the lowered tier
- [ ] Never crafts a good that is not yet eligible, nor an opted-out good
- [ ] Respects the daily cap and the `maxBuyMult` gate
- [ ] Specialists keep crafting their own goods as before
- [ ] Sim report shows outside-craft units per faction per good
- [ ] REFERENCE.md and CODEMAP.md updated
