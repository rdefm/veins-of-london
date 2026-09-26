# 04 — Wire TIER HQ plate

> **TEMPLATE — to use for a new property tier:**
> 1. Duplicate this file and rename it: `NN-wire-TIER-hq-plate.md` → e.g. `05-wire-flat-hq-plate.md` (**NN** = next free number, **TIER** = the tier id from `data/home.json` `tierOrder`: `flat`, `townhouse`, `safehouse`, `compound`, `mansion`).
> 2. In the copy, replace every **TIER** (filenames, headings, text) with the tier id and **NN** with the number.
> 3. Add the art as `assets/hq/TIER_room.png` (e.g. `assets/hq/flat_room.png`). Same naming as the Harrow's `TIER_external.png`.
> 4. Run the mapper (`godot --path . res://tools/hq_region_mapper.tscn`), pick **TIER**, trace every zone the tier should offer, and save. **A zone left unset means that menu is not reachable on this tier.**
> 5. Delete this template block, then hand the copy to an agent.
>
> Leave this original file (04) as the template. Don't implement it.

**What to build:** A player whose home tier is **TIER** sees `assets/hq/TIER_room.png` as the HQ room view, with no placeholder boxes. Every zone the human traced opens its menu, taps outside the traced shapes do nothing, and zones the human left unset are absent. The rest caption, if Rest is traced, sits legibly on the bed art. The raid indicator (ticket 02) shows on this tier's security zone.

**Blocked by:** 01 — HQ taps use traced zone polygons; 02 — Studio HQ renders cleanly on its own art

**Relevant files:**
- `assets/hq/TIER_room.png`
- `data/hq_visuals.json` — `rooms.TIER` (set `placeholder: false` on each region)
- `data/home.json` — `tierOrder`, `tiers.TIER`
- `scenes/screens/hq.gd` — `_build_room_view()`, `_on_zone_tapped()`
- `scenes/components/hq_diorama.gd`
- `tests/test_hq_screen.gd`
- `docs/hq-diorama-vision.md` §3.1, §3.2

**Status:** ready-for-agent

- [ ] `rooms.TIER` exists in `data/hq_visuals.json`, points at `assets/hq/TIER_room.png`, and passes the data check
- [ ] Every TIER region has `placeholder: false`
- [ ] A TIER-tier player gets the TIER plate (test)
- [ ] Each traced zone routes to its menu (test per zone)
- [ ] The raid indicator shows on TIER's security zone, if Security is traced
- [ ] Other tiers are unchanged
- [ ] On-device check block for the human in the report
