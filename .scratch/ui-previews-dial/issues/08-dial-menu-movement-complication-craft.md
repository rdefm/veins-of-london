# 08 — New Dial menu: Movement and Complication sections, Craft

**What to build:** Bring the Movement and Complication sections of the new Dial menu (07) to the same interaction as the Lens section: zoom in, open beat, seated component(s), scrollable right-hand side list of held components, tap → info tag, drag/Fit loads immediately, dropping on a filled socket swaps, dragging off unloads.

- **Movement section:** the zoom frames the face and needle together with the grip, so the charge is readable. The grip hatch opens (placeholder beat) to show the Movement seat. **Wind** is done here: tap the ore intake on the grip. With 2+ Lenses loaded, the existing ore choice comes first. Winding cost and rules are unchanged, and the needle sweeps up to the new charge.
- **Complications section:** the canopy and tip drop away from the lens collar. That shows the canopy's cut face from the same high 3/4 angle: a cross-section with **4 quadrant chambers**. Complications load into chambers. Chambers above `capacityMax` are blanked. Chamber i matches face stud i (for combat triggering later).

Each section's side list has a **Craft** button. It opens the existing crafting flow for that component kind and returns to the same section afterwards. With this done, HQ Dial no longer uses DialLoadoutMenu. Layout and beats come from the 06 art spec.

**Blocked by:** 07 — New Dial menu: overview, zoom, Lens section

**Relevant files:**
- `.scratch/ui-previews-dial/dial-art-spec.md` (§2.1 grip/canopy/chamber anchors, §3 offsets, §4 beats 3, 5, 8, 9)
- `scenes/screens/hq_dial.gd` + the new Dial menu component from 07
- `scenes/modals/craft_components_menu_modal.gd`, movement craft modal, `scenes/modals/dial_socket_modal.gd`
- `scenes/modals/dial_wind_modal.gd`
- `systems/dial.gd` (Movements, Complications including the multi-target variant, wind, craft)
- REFERENCE §1.4, §3.5
- tests: `tests/test_hq_dial.gd`

**Status:** ready-for-agent

- [ ] Movement section shows the charge (face/needle), the hatch-open beat, and Wind via the intake (ore choice when 2+ Lenses are loaded)
- [ ] Complications section: canopy-drop beat, 4-chamber cross-section, locked chambers blanked, chamber index = stud index
- [ ] Movement + Complication load/swap/unload behave like the Lens section
- [ ] Craft button per section opens the existing craft flow and returns to that section
- [ ] HQ Dial no longer builds DialLoadoutMenu (Profile/combat prep still do until 10)
- [ ] Tests cover Movement and Complication load/swap/unload, and Wind
- [ ] CODEMAP updated
