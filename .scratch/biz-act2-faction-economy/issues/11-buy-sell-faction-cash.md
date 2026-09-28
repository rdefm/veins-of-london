# 11 — Faction buying/selling + real cash

**What to build:** Factions trade in London. Reserve = the next few days' craft ingredient needs + target item holdings + expected kit use. Shortfall below reserve is bought at the London quote while quote ≤ `maxBuyMult` × base and the faction has cash (partial buys allowed; London is abstract, not limited by Market stock); purchases record as demand with the faction id as source. Holdings above reserve sell at `sellFraction` per day at the quote, recorded as supply; the faction holds when quote < `minSellMult` × base unless holdings exceed a hard cap. `resources` is real £: in from London sales, shop sales to the player and industry income; out on London buys, buying from the player and security upgrades; floored at £0. Industry income retuned smaller (Conclave high). Security upgrades stop when cash runs out. A faction's single-day buy or sell above the dump threshold is annotated with the faction's name. A faction that can't buy its shortfall crafts less.

Placeholders: few days' reserve, 2×, 50%, 0.8×, hard cap — pinned in JSON per archetype where needed.

Spec: §Buying and selling, §Faction cash, §Annotations.

**Blocked by:** 09 — Consumption, fight reorder, kit burns; 05 — Contract deliveries.

**Relevant files:**
- `systems/faction_sim.gd`, `systems/market.gd` (`record_supply` / `record_demand`, `_annotate_day` dump line), `systems/factions.gd` (`apply_passive_income`, `INDUSTRY_INCOME`, `apply_security_upgrades`)
- `systems/time_system.gd`, `data/factions.json`, `data/market.json`
- `scenes/phone_apps/ticker_app.gd` (annotation label shows faction name)
- Tests: `tests/test_faction_sim.gd`, `tests/test_market.gd`, `tests/test_factions.gd`
- REFERENCE.md §1.8, §3.1, §3.13

**Status:** ready-for-agent

- [ ] A faction buys its shortfall and the quote rises
- [ ] It refuses to buy above the ceiling and then crafts less
- [ ] It can't overspend; `resources` never negative
- [ ] It sells above reserve gradually; holds when quote under the floor
- [ ] Security upgrades stop when cash runs out
- [ ] A delivery reduces the buyer's next London buy
- [ ] Big faction buys/sells annotated with the faction's name (PROSE-REVIEW)
- [ ] REFERENCE.md updated
