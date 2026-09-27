# 03 — Ticker drives item demand; ore follows item shortages

**What to build:** The Ticker moves item demand, not prices. Barometer state effects lose `orePrice` and every `<type>Premium` key and gain `demandAll` (multiplier on every item's demand) and `itemDemand` (`{recipeKey: fraction}`), hand-authored per state as the interim table (war → shield, blast, healingBurst, blackHole; festival's old physics bump → physics items; crisis's old fate bump → fate items; boom/recession/inflation/regulation → `demandAll`). Election's `effectMod` scales the new keys. Barometer's ore-price functions are deleted. In Market's reprice, items reprice before ores; each ore's daily demand = its stand-in baseline + Σ over recipes `max(0, normalStock − itemStock) × ingredient qty × conversion rate`, split by ingredient weight. Effects build over a few days via smoothing. Ticker influence actions (incl. `floodMarket`) are unchanged. Spec §Barometer / Ticker (interim mapping), §Market "Ore demand derives from item shortages".

Feel target: a strong item-demand effect with nobody filling the gap moves the affected ore +50–100% over a few days.

**Blocked by:** 02 — Every lane reads the London price.

**Relevant files:**
- `systems/barometer.gd` (`get_effective_ore_price`, `get_ore_price_modifier` ~line 190 — delete; `get_merged_effects`)
- `systems/market.gd` (demand multipliers, item-before-ore ordering, derived ore demand)
- `data/barometer.json`, `data/recipes.json` (ingredients), market JSON (conversion rate)
- `tests/test_barometer.gd`, `tests/test_market.gd`
- `docs/REFERENCE.md` §1.9 `data/barometer.json`, §3.2 Barometer (remove ore-price formula), Market section

**Status:** ready-for-agent

- [ ] No `orePrice` / `*Premium` keys remain in data or code
- [ ] Rollover: war state → shield price rises; physics ore rises over following days
- [ ] Recording player shield supply dampens the physics rise
- [ ] Mixed-ingredient recipe shortage lifts both ingredient ores
- [ ] `demandAll` state lifts/lowers every item's demand; election `effectMod` scales the new keys
- [ ] REFERENCE.md §1.9, §3.2, Market section updated
