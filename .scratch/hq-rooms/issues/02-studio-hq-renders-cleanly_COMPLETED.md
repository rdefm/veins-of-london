# 02 — Studio HQ renders cleanly on its own art

**What to build:** A player whose home tier is Studio sees `studio_room.png` with its zones baked into the art: no grey placeholder boxes over it. Every traced zone opens its menu. The rest caption sits on the bed. Raid state stays visible. Today it shows only through the placeholder label ("Security — RAID"), which disappears once placeholders are off, so a replacement indicator is needed. **Ask the human which indicator to use before building it**, e.g. the selected-zone outline drawn round the security polygon. The security-lock installed-image swap does nothing on Studio, since Studio has no `installedImage`, and must not error.

**Blocked by:** 01 — HQ taps use traced zone polygons

**Relevant files:**
- `data/hq_visuals.json` — `rooms.studio` (set `placeholder: false` on its regions)
- `scenes/screens/hq.gd` — `_build_room_view()`, `_hostile_door_plate()`, `_security_lock_installed_plate()`
- `scenes/components/hq_diorama.gd` — `_draw()`, `_should_draw_placeholder()`, caption placement in `build()`
- `assets/hq/studio_room.png`
- `tests/test_hq_screen.gd`
- `docs/hq-diorama-vision.md` §3.1, §9

**Status:** ready-for-agent

- [ ] A Studio-tier player gets the Studio plate; no placeholder boxes are drawn
- [ ] Each Studio zone (security, lab, dial, rest, gym) opens its menu
- [ ] Raid state is visible on Studio via the indicator the human chose
- [ ] A lock installed on Studio causes no error and no visual change
- [ ] Bedsit is unchanged
- [ ] On-device check block for the human in the report
