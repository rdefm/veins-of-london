# 04 — Per-tier effects for every item

**What to build:** All craftable items have 5 tier values in data, with reduced base effects (e.g. Time Pearl: T1 freezes 1 turn, T2 2, T3 3…). Combat and consumable use read the tier. Agent proposes all numbers; human approves before landing.

**Blocked by:** 01 — Tier state and progress-bar experiments.

**Relevant files:** `data/recipes.json`, `systems/combat.gd` (frozenTurns, motionTurns, item effects), `systems/combat_prototype.gd` (`ITEM_RECIPE_KEYS`), `systems/consumables.gd`, `systems/event_items.gd`, `systems/dial.gd` (complications), REFERENCE §3.5, §3.7, §3.7a, `docs/calc-effects.txt`. Update REFERENCE tables.

**Status:** ready-for-agent

- [ ] 5 tier values per item in data; no numbers in code
- [ ] Combat/consumable/event uses read tier; tests per item
- [ ] Proposed number table in report for review
- [ ] REFERENCE.md updated
