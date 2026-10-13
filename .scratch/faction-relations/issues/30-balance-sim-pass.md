# 30 — Balance sim pass

**What to build:** The faction-economy sim proves the new turf/perk/harassment/warmonger loop stays healthy over a long run:
- turf changes hands over time
- no faction is reduced to zero turf permanently
- the weakening floor still holds
- live-control claim weighting plus turf perks don't snowball

TBD numbers get proposed values for the human tuning pass. The agent doesn't finalise them.

**Blocked by:** 03, 04, 13, 14, 17, 20

**Relevant files:** `scripts/sim_faction_economy.gd`, `scripts/sim_faction_economy_impl.gd`, `tests/test_faction_sim.gd`, all TBD entries in REFERENCE.md (Turf, Perks, Harassment, Grudges, Warmonger/aid, Ambush §§), `data/factions.json`, turf config.

**Status:** ready-for-agent

- [ ] Sim reports turf spread per faction over time, flips count, min turf per faction
- [ ] Sim asserts no permanent zero-turf faction and no runaway leader over the run
- [ ] Report of proposed TBD values with sim evidence, for human sign-off
- [ ] No TBD marker removed without human approval
