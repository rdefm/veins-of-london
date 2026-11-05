# 05 — Root Feed want and use

**What to build:** Factions want Root Feed according to the veins they own. Want = owned veins × `wantDays` × faction `wantMult`, capped, and it adds to the Root Feed reserve. Factions buy it from London, keep it up to their want, and apply it to their veins, which raises growth and strengthens harvests. Applying feed is the real consumption, so no `consumes` entry is added. Feeding skips tiers worth 0 days. Root Feed crafting supply rises to meet want.

Spec: `.scratch/london-market/spec.md`, "Root Feed", delivery step 5. Stories 71-79.

**Blocked by:** 04

**Relevant files:** `systems/faction_sim.gd`, `systems/cultivating.gd`, `data/factions.json`, `data/vein_growth.json`, `data/market.json`, `tests/test_faction_sim.gd`, `scripts/sim_faction_economy_impl.gd`, REFERENCE.md §1.8 `data/factions.json`, §3.4 Cultivating & pruning

**Status:** ready-for-agent

- [ ] Want follows owned veins, with `wantMult` highest for `producer` factions and lower for crafting factions
- [ ] Want stops at the cap
- [ ] Want stays steady as veins are fed, so a faction does not sell and rebuy feed daily
- [ ] Factions buy Root Feed from London up to want and do not sell it back below want
- [ ] Applied feed raises vein growth, and fed faction veins harvest more in the sim
- [ ] Tier 0 feed cannot block a faction using better feed
- [ ] No `consumes` entry is added for Root Feed
- [ ] The Collective can buy like any other faction
- [ ] Faction data gains `wantMult`; vein growth data gains `wantDays` and the cap, as placeholders
- [ ] REFERENCE.md §1.8 and §3.4 are updated
