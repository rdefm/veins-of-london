# 10 — Per-vein kit allocation

**What to build:** After consumption, each faction's defensive item holdings are assigned out to its veins' guards in a fixed order. When stock is short, veins go without in a fixed order: least valuable vein first (tie-break by site id). Each faction vein stores its current kit (pure state), readable per site for 4b intel and 4a combat. Hidden from the player. Old saves backfill vein kits.

Spec: §Per-vein kit allocation, Further Notes "Kit allocation → intel".

**Blocked by:** 09 — Consumption, fight reorder, kit burns.

**Relevant files:**
- `systems/faction_sim.gd`, `systems/cultivating.gd` (`combined_magnitude` for value), `data/factions.json` (defend kit)
- `autoload/SaveManager.gd`
- Tests: `tests/test_faction_sim.gd`, SaveManager tests
- REFERENCE.md §1.8, §6

**Status:** ready-for-agent

- [ ] Every faction vein carries a kit after the tick
- [ ] A short faction leaves its least valuable veins without kit first; ties by site id
- [ ] A read returns a site's vein kit
- [ ] Vein kits survive save/load; old saves backfill
- [ ] REFERENCE.md updated
