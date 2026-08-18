# 22 — Other factions lose veins too quickly/often

**What to build:** Non-player faction veins are being abandoned too fast and too often. `Sites.npc_abandonment_chance()` (`systems/sites.gd`) rolls `clamp(0.05 + 0.01*age_days, 0.0, 0.15)` per faction vein, every daily tick (`time_system.gd` step ⑤c) — on a hit the site and its `factionVein` are deleted outright. With the day-one roster seeding dozens of faction veins (`Factions.seed_day_one_veins()` — Conclave 7, Guild 7, Network 4, etc.), this compounds into frequent, visible faction vein loss. Retune the abandonment rate/roll frequency so factions retain veins at a pace that reads as stable rather than constantly churning.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `npc_abandonment_chance()` and/or its roll cadence in `time_system.gd` is retuned so faction-held veins persist noticeably longer on average (get sign-off from the human on the new curve/numbers if not specified — don't guess at final values silently).
- [ ] Existing `sites`/`time_system` tests updated to reflect the new rate; add a test asserting the new lower bound/ceiling behavior.
- [ ] Manual check noted for the human: play several in-game days and confirm faction vein counts don't collapse rapidly.
