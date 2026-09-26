# 03 — Rooms and Ore store on Studio

**What to build:** A Studio player can reach the floorplan (Rooms zone) and the ore readout (Ore store zone) from the HQ room view. The saved Studio plate currently has neither zone, so both menus are unreachable on Studio. The human traces both zones on `studio_room.png` with the HQ region mapper (`godot --path . res://tools/hq_region_mapper.tscn`) and saves. An agent then sets `placeholder: false` on both, confirms the data check passes, and adds tests that both zones route correctly on Studio.

Overlaps playtest ticket 07 (Studio floorplan design): that ticket owns the floorplan's slot layout; this one only owns the HQ tap zone that opens it.

**Blocked by:** 01 — HQ taps use traced zone polygons (for the agent half; the human can trace any time)

**Relevant files:**
- `tools/hq_region_mapper.tscn`
- `data/hq_visuals.json` — `rooms.studio.regions`
- `scenes/screens/hq.gd` — `_on_zone_tapped()`
- `tests/test_hq_screen.gd`
- `.scratch/playtest-2026-09-24/issues/07-studio-floorplan-design.md`

**Status:** ready-for-human

- [ ] Human: Rooms and Ore store traced on Studio and saved
- [ ] Rooms opens the floorplan on Studio
- [ ] Ore store opens the ore readout on Studio
