# 19 — Wire all new items into economy, factions, recipe shops and the Lab

**What to build:** Once every new item is implemented, each one is fully part of the economy:
- **Market / stock market**: stock and civilian demand entries, plus barometer `itemDemand` hooks where brainstorm §6 suggests (for example, a crisis raises Stiff Upper Lip; a boom raises Nostalgia and Introduction). Lore goods have buyers.
- **Factions craft them**: each faction's `crafts` / `consumes` / `craftTargets` are assigned by its ore focus (brainstorm §5's faction table as the starting point), and gift prefs where they fit.
- **Recipes purchasable**: every recipe resolves to a seller under the existing rule (James for time/life, Wren as default), has a master source, and can be bought rung by rung.
- **Crafting all 5 tiers**: every item has a Lab procedure (ideal, base, hint1/hint2/master hints) so it can be crafted from rank 1 up to rank 5 through the rung ceilings.

**Blocked by:** 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 13, 14, 16, 18

**Relevant files:** `data/market.json`, `data/barometer.json`, `data/factions.json`, `data/recipe_knowledge.json`, `data/lab.json`, `data/recipes.json`, `systems/market.gd`, `systems/barometer.gd`, `systems/faction_sim.gd`, `systems/recipe_knowledge.gd`, `systems/lab.gd`, `systems/crafting.gd`; REFERENCE §1.8 `data/factions.json`, §1.9 `data/barometer.json`, §3.2 Barometer.

**Status:** ready-for-agent

- [ ] Every new item is listed in the market with stock/demand and trades
- [ ] Each faction crafts and consumes new items matching its ore focus; the faction sim produces them
- [ ] Every new recipe is buyable from its seller (base → hint1 → hint2) and has a master source
- [ ] Every new item has a Lab procedure; a test crafts each at rank 1 and reaches rank 5 with all rungs owned
- [ ] Hint/procedure prose flagged PROSE-REVIEW; numbers tagged for balance
