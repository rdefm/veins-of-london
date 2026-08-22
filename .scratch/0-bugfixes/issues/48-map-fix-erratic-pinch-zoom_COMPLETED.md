# 48 — Map: fix erratic pinch-zoom

**What to build:** Human's repro: while pinch-zooming, the view "jumps around all over the map," slightly less erratic when zooming very slowly. A prior ticket (`.scratch/0-bugfixes/issues/23-fix-pinch-zoom-anchor-point_COMPLETED.md`) already fixed pinch-anchor drift by wiring `_update_pinch()` (`scenes/components/map_canvas.gd:1366-1388`) through `MapZoom.scroll_target()` (`systems/map_zoom.gd:56-60`) — that fix appears intact in current code, so this is not the same anchor bug regressing. The jumpiness-that-worsens-with-speed points more toward per-frame jitter in how pinch distance/midpoint deltas are sampled and applied (e.g. `zoom_level` or scroll offset being recomputed from a noisy/rebasing reference each `_update_pinch()` call rather than smoothed or clamped per-frame) — needs direct investigation in `map_canvas.gd`'s pinch handling and `map_zoom.gd`'s clamping (`MIN`/`MAX`, `map_zoom.gd:12-17`).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Root-cause the jitter (likely candidates: noisy per-frame pinch-distance/midpoint sampling, zoom-level rebasing each update instead of relative-to-gesture-start, or clamp interaction at zoom min/max) — document the actual cause found.
- [ ] Fix such that zoom smoothly tracks finger movement at any gesture speed, slow or fast, with no visible jump/snap.
- [ ] Manual check noted for the human: pinch-zoom at various speeds (slow, fast, uneven two-finger movement) and confirm the view tracks smoothly with no jumping.
