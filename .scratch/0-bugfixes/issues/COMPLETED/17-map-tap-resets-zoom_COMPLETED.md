# 17 — Map tap resets zoom instead of preserving it

**What to build:** Tapping a vein, district, or station on the Map tab's Network diagram currently snaps the camera to a fixed zoom level (`MapZoom.EVENT_ZOOM`, 0.8) before showing the bubble/modal — discarding whatever zoom the player had set (pinch-zoom, up to `MapZoom.MAX`). This happens on every tap-to-open, regardless of the player's current zoom. Tapping should preserve the player's current zoom and pan to the tapped point at that zoom, not reset it.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `pan_to()` (`MapCanvas`) defaults its target zoom to the current `zoom_level` instead of `MapZoom.EVENT_ZOOM` when no explicit zoom is requested.
- [ ] Tapping a district, vein/station stop, or any other bubble-opening target pans to the tapped point without changing zoom.
- [ ] Any caller that legitimately wants a specific zoom on open (if one exists) still gets it explicitly — this change should not silently break an intentional forced-zoom case, if one is found.
- [ ] Existing `MapCanvas`/pan/zoom tests updated; add coverage asserting zoom is unchanged across a tap-to-open at a non-default zoom.
