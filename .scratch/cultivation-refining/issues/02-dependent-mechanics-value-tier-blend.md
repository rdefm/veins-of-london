# 02 — Blend earned level into value_tier() consumers

**What to build:** Every existing consumer of `Cultivating.value_tier(vein)` (raid stealth odds, faction raid targeting, faction vein income, rivalry weighting, combat scaling, the map's Strength filter, and the rampant-at-ceiling self-seed threshold) reads a combined magnitude that factors in the vein's new earned level, not condition alone.

Resolved formula (from the cultivation-refining grilling session):
`combined_magnitude = value_tier(condition) + (level - 1)`. A level-1 vein behaves exactly as it does today (no change); each level above 1 adds +1. Uncapped at this layer — each consumer clamps to its own valid range if it indexes a fixed-size table (e.g. combat scaling arrays).

**Blocked by:** 01 (needs the `level` field to exist).

**Relevant files:**
- `systems/cultivating.gd` (add the combined-magnitude helper alongside `value_tier()`)
- `systems/raiding.gd` (stealth odds, raid targeting)
- `systems/factions.gd` (faction vein income, rivalry weighting, self-seed threshold at ceiling)
- `systems/combat.gd` (combat scaling by vein magnitude, if it reads value_tier directly)
- `scenes/screens/map.gd` (Strength filter)
- `systems/vein_trade.gd` (valuation/trade price)
- `docs/REFERENCE.md` §3.4 (value_tier consumer list)

**Status:** ready-for-agent

- [ ] A combined-magnitude helper exists: `value_tier(condition) + (level - 1)`
- [ ] Every listed consumer (raiding, factions, combat, map Strength filter, vein_trade) reads the combined magnitude instead of raw `value_tier()`
- [ ] Any fixed-size table a consumer indexes by magnitude clamps the combined value to its valid range
- [ ] Tests confirm a level-1 vein's combined magnitude matches today's `value_tier()` output exactly (no behavior change for un-leveled veins)
- [ ] Tests confirm a leveled-up vein produces a higher combined magnitude and that downstream consumers (e.g. raid targeting) respond to it
