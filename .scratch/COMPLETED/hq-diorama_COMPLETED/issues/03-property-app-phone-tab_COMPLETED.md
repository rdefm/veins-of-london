# 03 — Property app on the Phone tab

**What to build:** Tier stats and the upgrade action leave the HQ tab and
become a property app on the Phone tab, alongside `Reynard's` and `VfL` — a
parody property portal listing the current place with its stats (daily
cost, raid risk, rooms) and the next place up, with the upgrade action.
Mechanics (`Home.upgrade_tier()` and the tier table) are unchanged; this is
purely a relocation of the front-end.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] New Phone-tab app shows current tier's stats (daily cost, raid risk, rooms)
- [ ] Shows the next tier up and its upgrade cost/requirements
- [ ] Upgrade action calls the existing `Home.upgrade_tier()` system function unchanged
- [ ] `hq.gd`'s old `_build_upgrade_card()` and its call sites are removed
- [ ] No tier/stat/upgrade UI remains reachable from the HQ tab
