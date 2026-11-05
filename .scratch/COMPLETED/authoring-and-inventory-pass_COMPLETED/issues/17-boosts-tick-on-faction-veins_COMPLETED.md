# 17 — Boosts tick on faction veins

**What to build:** The daily tick runs boosts on faction veins too, after drift, with the same rates and ceiling. Boosts stored on a vein follow it on transfer. Faction veins gain growth and existing fieldwork pruning turns growth above `pruneFloor` into holdings. No separate output multiplier is added.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/cultivating.gd`, `systems/faction_sim.gd`, `systems/time_system.gd`, `systems/raiding.gd`, `tests/test_faction_sim.gd`, `tests/test_cultivating.gd`, REFERENCE.md §3.4 Cultivating & pruning, daily order

**Status:** ready-for-agent

- [ ] Faction boosts tick after drift and respect the ceiling
- [ ] Boosts stay with a vein after transfer
- [ ] Over N days, a fed faction vein produces more ore than an identical unfed one
- [ ] REFERENCE.md §3.4 and the daily order are updated
