# 18 — Factions apply Root Feed; Collective burn replaced

**What to build:** Each faction holding Root Feed applies one to its lowest-growth unfed vein in a daily step, up to a data-driven limit. The Collective's `consumes` entry is replaced by real use, and `kitUse` takes over the same amount so its craft target is unchanged. The Collective therefore stops counting as a Root Feed consumer wherever `consumes` is read as demand or reserve, including offers to it. This side effect was approved.

**Blocked by:** 17

**Relevant files:** `systems/faction_sim.gd`, `systems/factions.gd`, `systems/offers.gd`, `systems/overlaps.gd`, `systems/faction_ai.gd`, `systems/time_system.gd`, `data/factions.json`, `tests/test_faction_sim.gd`, REFERENCE.md §1.8 `data/factions.json`, daily order

**Status:** ready-for-agent

- [ ] A holding faction feeds its lowest-growth unfed vein, up to the limit
- [ ] Only Root Feed is used by faction AI
- [ ] The Collective's craft target for Root Feed is unchanged
- [ ] No abstract weekly burn of Root Feed remains
- [ ] The Collective no longer appears as a Root Feed buyer in offers or overlaps
- [ ] New quantities are data-driven
- [ ] REFERENCE.md §1.8 and the daily order are updated
