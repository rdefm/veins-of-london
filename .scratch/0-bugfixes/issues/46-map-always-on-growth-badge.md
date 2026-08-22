# 46 — Map: always-on vein growth badge

**What to build:** Vein growth is already visually encoded on the map (ring colour/width by `value_tier`, a growth-gauge arc, risk-band arc textures — all in `systems/map_style.gd` and `scenes/components/map_canvas.gd`), but the days-to-wall/band countdown badge only renders under the Growth filter (`map_style.gd:128-132`, drawn `map_canvas.gd:986-990`). Per the human, this should be always-on regardless of which map filter is active, so growth is readable "at a glance" without switching filters.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] The days-to-wall/band badge (`map_canvas.gd:986-990`, `map_style.gd:128-132`) renders on every vein stop regardless of active map filter, not just under Growth.
- [ ] Confirm it doesn't visually clash/overlap with other filter-specific glyphs when a different filter is active — adjust layering/positioning if needed.
- [ ] Existing map-canvas draw tests updated/extended to cover badge rendering outside the Growth filter.
- [ ] Manual check noted for the human: switch through all map filters and confirm the growth badge stays visible on every vein stop.
