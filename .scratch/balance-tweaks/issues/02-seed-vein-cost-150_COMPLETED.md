# 02 — Seeding a vein costs 150 calc

**What to build:** Seeding a vein on a site needs **150** ore of the site's own ore type, up from 100. Same rule otherwise. Every place that shows or checks the cost follows the data value.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `data/vein_growth.json` (`seedOreCost`)
- `systems/sites.gd` (seed check/spend)
- `autoload/GameData.gd` (`SEED_ORE_COST`)
- any UI or prose that names "100" for seeding (grep screens/data/events)
- tests covering seeding (`tests/test_sites*.gd`)
- REFERENCE §3.4 seeding, and the `SEED_ORE_COST = 100` line in the cultivating constants

**Status:** ready-for-agent

- [ ] Seeding needs and spends 150 of the site's ore type; 149 is refused (tests)
- [ ] No hard-coded 100 left for seeding in code, UI strings or tutorial text
- [ ] REFERENCE updated
