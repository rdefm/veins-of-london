# 01 — HQ taps use traced zone polygons

**What to build:** A tap on the HQ room view resolves to the zone whose traced polygon contains it. A zone with no polygon keeps hit-testing its rect, so the Bedsit behaves exactly as today. A tap inside a zone's bounding box but outside its polygon opens nothing, e.g. on Studio where the Security and Dial boxes overlap but their shapes don't. The "Debug regions" overlay outlines each zone's polygon, falling back to the rect, so the human can check hit shapes on-device.

Polygons are authored with the HQ region mapper tool and stored per region as `polygon: [[x, y], ...]` in plate display space; x/y/width/height stays the sprite/placeholder rect. The data check already validates polygons (size by bounding box, overlap by shape).

**Blocked by:** None — can start immediately

**Relevant files:**
- `scenes/components/hq_diorama.gd` — `region_rects()`, `_draw()`, `_draw_debug_region()`
- `scenes/screens/hq.gd` — `_on_diorama_gui_input()`
- `scenes/screens/hq_lab_bench.gd` — also calls `region_rects()`; must keep working
- `tools/hq_region_mapper_logic.gd` — `region_contains()` / `regions_at()` already implement the hit rule; reuse or move rather than re-derive
- `autoload/GameData.gd` — `_validate_hq_plate()`, `_hq_region_polygon()`
- `data/hq_visuals.json` — `meta.polygonRule`, `rooms.studio`
- `tests/test_hq_screen.gd`, `tests/test_hq_region_mapper.gd`
- `docs/hq-diorama-vision.md` §3.2

**Status:** ready-for-agent

- [ ] A tap inside a zone's polygon routes to that zone
- [ ] A tap inside the bounding box but outside the polygon routes to nothing
- [ ] Zones without a polygon (all of Bedsit) hit-test their rects exactly as before
- [ ] The debug overlay outlines polygons when present, rects otherwise
- [ ] The Lab bench sub-view is unaffected
- [ ] Tests cover all of the above
