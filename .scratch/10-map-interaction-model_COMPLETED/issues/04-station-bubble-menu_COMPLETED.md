# 04 — Station bubble menu

**What to build:** Tapping a station (vein) on the Network map camera-pans/focuses to that point and shows the anchored bubble (ticket 02) with **Cultivate**, **Harvest**, and **Manage** options, instead of today's bottom sheet. Cultivate and Harvest run inline in the bubble with their own procedural tween success/fail animations — no new art assets. Manage transitions into the existing site sheet (already has tap-outside-to-close) for anything needing more room, such as adding security.

**Blocked by:** 02 (anchored map bubble component), `0-bugfixes` ticket 11 (map tap dead until drawer opened).

**Status:** ready-for-agent

- [ ] Tapping a station camera-pans/focuses the map to that vein's point and shows the bubble menu, diagram still visible behind it.
- [ ] Cultivate runs the existing cultivate logic inline; disabled with a reason label if the vein is at max effective level (per `10-map-interaction-model` ticket 01). Distinct tween animation on success vs. fail.
- [ ] Harvest runs the existing harvest logic inline (cautious/full as applicable), with its own success animation showing the vein was harvested.
- [ ] Manage opens the existing site sheet unchanged, for security/other management actions.
- [ ] Bubble closes appropriately after an action or on tap-outside.
- [ ] Faction-claimed and unclaimed sites (not yet a player vein) show the appropriate subset of options or route to the district-level Prospect flow instead, consistent with current claim-state rules (`docs/M1-LONDON.md` §D2).
- [ ] Test coverage for the new tap → bubble → action flow at the system level (not just visual).
