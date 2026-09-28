# 08 — FactionSim: crafting toward target

**What to build:** Factions craft their specialist items from their ore. Per crafted item, target holding = next week's consumption + expected raid-kit use + sell quota (JSON). Below target, the faction attempts crafts up to the gap, limited by ore on hand. Each attempt uses the player's craft chance at the faction's `craftSkill` (seeded Rng). A failure burns its ingredients; a success adds one item at quality tier = `craftSkill` (same fixed rule as the player's) and credits crafting share by ingredient weight. Guild high craft skill; Network and Conclave low.

Spec: §Crafting, §Rollover order (step 4).

**Blocked by:** 07 — FactionSim: tend + real prune.

**Relevant files:**
- `systems/faction_sim.gd`, `systems/crafting.gd` (`craft_chance`, `calc_cost`, `quality_tier`, `recipe_ore_types`), `systems/shares.gd`
- `data/factions.json` (`craftSkill`, per-item target split), `data/recipes.json`
- Tests: `tests/test_faction_sim.gd`
- REFERENCE.md §1.8, §3.5

**Status:** ready-for-agent

- [ ] Holdings below target lead to craft attempts, capped by ore on hand
- [ ] A failure burns ore and adds no crafting share
- [ ] A success adds the item at tier `craftSkill` and credits crafting share split by ingredient weight
- [ ] At target, no crafts
- [ ] REFERENCE.md updated
