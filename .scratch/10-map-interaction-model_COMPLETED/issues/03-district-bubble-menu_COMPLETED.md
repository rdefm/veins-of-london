# 03 — District bubble menu

**What to build:** Tapping a district on the Network map camera-pans/focuses to that point (reusing `MapCanvas.pan_to()`) and shows the anchored bubble (ticket 02) with **Prospect** and **View Veins** options, instead of today's behaviour of hiding the whole diagram and replacing it with a full-screen district list panel. Prospect runs the existing prospect action inline, right there in the bubble, with a procedural tween success animation and a distinct procedural tween fail animation — no new art assets. View Veins transitions into the existing full-screen district panel (reused as-is) for browsing the district's full site list.

**Blocked by:** 02 (anchored map bubble component), `0-bugfixes` ticket 11 (map tap dead until drawer opened).

**Status:** ready-for-agent

- [ ] Tapping a district camera-pans/focuses the map to that district's point and shows the bubble menu, with the diagram still visible behind it — the full-screen district panel is no longer shown as the immediate result of a tap.
- [ ] Prospect option runs the existing prospect logic (`Sites`/`Cultivating` per current REFERENCE.md/M1-LONDON.md rules) inline; a distinct tween animation plays on success vs. fail (e.g. scale/fade/shake-style effects via `create_tween()`, matching the style already used for the charged-vein pulse in `docs/M1.5-NETWORK-MAP.md`).
- [ ] View Veins option opens the existing full-screen district panel unchanged.
- [ ] Bubble closes appropriately after an action or on tap-outside.
- [ ] Blocked district actions (e.g. `siteCap` reached) are represented sensibly in the bubble (disabled with reason, consistent with this repo's existing disabled-not-hidden pattern).
- [ ] Test coverage for the new tap → bubble → action flow at the system level (not just visual).
