# 107 — Stackable Hired Guards at HQ

**What to build:** HQ's "Hired Guard" security upgrade is currently a single boolean purchase. Make it stackable, the same way veins already support multiple `extraGuards`: the player can purchase additional guards at HQ beyond the first, tracked as a count rather than a yes/no flag. This ticket is purely about the purchase mechanic and stored count — it does not yet change raid odds or add any new combat/repel behaviour beyond whatever the existing single-guard `raidReduction` already contributes (see ticket 108 for the missed-defend repel-chance mechanic that will consume this count).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Player can purchase more than one Hired Guard at HQ; the HQ screen shows the current guard count and the cost/action to hire another.
- [ ] Guard count persists in save data (same durability guarantee as other HQ upgrades).
- [ ] Existing single-guard behaviour (e.g. `raidReduction` contribution to HQ's raid chance) is preserved for a guard count of 1, and scales sensibly for higher counts consistent with how veins' `extraGuards` scale their own raid-resist stat.
- [ ] Regression test covering purchasing multiple guards and the count persisting through a save/load.
