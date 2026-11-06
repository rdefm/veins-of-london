# 16 — Price persistence tracking and outside-craft trigger

**What to build:** The market remembers how many consecutive days each item has been priced above a trigger multiple of its base price (x). Any day at or below x resets the count. Once a good has stayed above x for a grace period (y days), it becomes eligible for crafting by factions that do not list it. Specialists (any faction listing the item in `crafts` or `craftTargets`) are never held back by the grace period. Values x, y and a per-faction daily cap live in data. Recipes can opt out (Keystone) via a flag, not a hard-coded id. No crafting behaviour yet — this ticket delivers the tracked, saved, queryable state only.

**Blocked by:** 15.

**Relevant files:** `systems/market.gd`, `data/market.json`, `data/factions.json`, `data/recipes.json`, `autoload/GameData.gd` (market/factions validators), `tests/test_market.gd`, `tests/test_gamedata.gd`, REFERENCE.md §3.13 (Pinned values), CODEMAP.md.

**Status:** ready-for-agent

- [ ] Per-good consecutive-days-above-x counter lives in market state as plain data and survives save/load
- [ ] Counter increments daily above x, resets on any day at or below x
- [ ] Query: "is good G eligible for faction F to outside-craft" is true only for non-specialists, after y consecutive days, when the recipe has not opted out
- [ ] Keystone opted out via a recipe flag
- [ ] x, y, per-faction daily cap, skill/tier penalty and wallet floor are in data and validated
- [ ] REFERENCE.md and CODEMAP.md updated
