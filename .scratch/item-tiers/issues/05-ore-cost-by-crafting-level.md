# 05 — Ore cost tied to crafting level

**What to build:** Ore cost to craft an item scales with the player's crafting level and no longer depends on the item's tier.

**Blocked by:** 01 — Tier state and progress-bar experiments.

**Relevant files:** `systems/crafting.gd` (ingredient cost, ~line 33), `data/recipes.json` (`ingredients`), `data/constants.json`, `scripts/sim_faction_economy.gd` (consumers of `ingredients`), REFERENCE §3.5. Propose the scaling formula in the report.

**Status:** ready-for-agent

- [ ] Cost = f(crafting level), independent of tier; formula in data/constants
- [ ] Faction craft sims and sell quotas still consistent (or re-tuned and noted)
- [ ] Tests pass
