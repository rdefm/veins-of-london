# 10 — Raid depth and site-scoped claim

**What to build:** `loot_raid_vein` gains an optional depth. It lowers the vein's growth by that depth, floored at 0, and pays ore through the existing prune-yield formula. With no depth it uses a new data constant tuned so expected ore is close to today's fixed amount. Other consequences are unchanged. Raid and claim work in any event with a site. Claim still transfers to the player only.

**Blocked by:** 09

**Relevant files:** `systems/raiding.gd`, `systems/events.gd`, `systems/cultivating.gd`, `data/constants.json`, `tests/test_raiding.gd`, `tests/test_events.gd`, REFERENCE.md event action list

**Status:** ready-for-agent

- [ ] Depth lowers growth, floored at 0, and pays the prune-yield amount
- [ ] Default loot with no depth stays close to today's expected ore, and drains growth
- [ ] The four existing `loot_raid_vein` uses still work
- [ ] Caught and relation consequences are unchanged
- [ ] Raid and claim work in a non-raid event with a site
- [ ] Claim transfers to the player only
- [ ] REFERENCE.md is updated
