# 07 — Multi-target at tier 3 + craft checkbox

**What to build:** From tier 3, crafting offers a single-target / multi-target checkbox. The multi-target version hits all enemies (all allies for heals/shields). Black Hole is always multi-target. Pan items are handled in `pan-variants` ticket 04.

**Blocked by:** 04 — Per-tier effects for every item.

**Relevant files:** `systems/crafting.gd`, `systems/combat.gd` (`TARGETING_*`, ~line 105), `systems/combat_prototype.gd`, crafting screen (`CODEMAP.md`), `tests/test_crafting.gd`. Inventory must distinguish single vs multi versions.

**Status:** ready-for-agent

- [ ] Checkbox appears only at tier ≥ 3; hidden for Black Hole
- [ ] Crafted unit records its target mode; combat honours it
- [ ] Tests for single vs multi per item type
- [ ] Human UI check list in report
