# 10 — Map zoom range doesn't allow zooming in far enough

**What to build:** On the Map tab's Network diagram, pinch-zooming in stops at a maximum that's too close to the default zoom level to be useful — `systems/map_zoom.gd` currently has `MIN=0.35`, `MAX=1.0`, `DEFAULT=0.85`, leaving almost no zoom-in headroom. Raise the maximum zoom so closely-packed station clusters can be read comfortably on a phone screen.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `MapZoom.MAX` raised to roughly double the current value (~1.75–2.0) — exact final value may be tuned on-device after landing, so don't treat the number as sacred.
- [ ] Pinch-zoom can reach the new maximum smoothly; existing pan/zoom clamping (`MapZoom.clamp_zoom`, `scroll_target`) still behaves correctly at the new bound.
- [ ] Existing `MapCanvas`/`MapZoom` tests updated for the new bound; add coverage for the new max if none currently exercises the zoom ceiling.
