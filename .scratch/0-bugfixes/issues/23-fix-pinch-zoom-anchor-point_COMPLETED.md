# 23 — Pinch-to-zoom anchors to upper-left instead of pinch point

**What to build:** Pinch-to-zoom on the Network Map zooms toward the map's upper-left corner rather than the point between the player's fingers. `MapCanvas._update_pinch()` (`scenes/components/map_canvas.gd`) computes a new `zoom_level` and calls `_set_zoom()`, which resizes/rescales content with no compensating scroll offset to keep the pinch midpoint stationary. `MapZoom.scroll_target(point, zoom, viewport_size, content_size)` (`systems/map_zoom.gd`) already exists (built for programmatic pan-to-point) — wire pinch-zoom through it.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `_update_pinch()` computes the pinch midpoint in map-content space and calls `MapZoom.scroll_target()` (or equivalent) to adjust the `ScrollContainer` offset so that point stays under the fingers as zoom changes.
- [ ] Zoom stays within existing clamped bounds (`MapZoom.clamp_zoom`).
- [ ] `map_zoom` tests updated/added covering scroll-offset compensation during a pinch centered away from the origin.
- [ ] Manual check noted for the human: pinch-zoom anywhere on the map (not just top-left) and confirm the zoom centers on the pinch point.
