# 89 — Map: floating +/- zoom buttons

**What to build:** Add a floating +/- zoom control to the Network map, TfL/Citymapper-style, as a reliable alternative to the pinch gesture (which has a history of drift bugs — see #88). Tapping + or - steps the zoom level in/out by a fixed increment, animated (not an instant snap), staying within the existing zoom bounds.

**Where:** `scenes/components/map_canvas.gd` (`_set_zoom`, `pan_to` — reuse the existing tween machinery, same idiom as the programmatic zoom used for queued-event playback), `systems/map_zoom.gd` (`MIN` 0.35, `MAX` 1.75, `clamp_zoom`). Placement: floating over the map canvas itself, bottom-right corner — not inside the `MapControls` hamburger drawer, not in the top bar.

**Blocked by:** None — can start immediately. Touches the same zoom system as #88 (pinch drift fix) — coordinate if worked in parallel, but neither blocks the other.

**Status:** ready-for-agent

- [ ] A floating +/- button pair renders over the map canvas, bottom-right corner, visible whenever the Map tab is open.
- [ ] Tapping + or - steps `zoom_level` by a fixed increment, clamped to `MapZoom.MIN`/`MapZoom.MAX`, animated via the existing tween-based zoom path (reusing `pan_to()`'s or `_set_zoom()`'s machinery) rather than snapping instantly.
- [ ] The step anchors on the viewport centre (not a pinch midpoint — there are no fingers to anchor to here).
- [ ] Buttons visually disable (or no-op) at the min/max bounds rather than erroring or animating past them.
- [ ] Step size value is proposed by the implementer and flagged **needs visual sign-off** — pick something that reaches full zoom range in a reasonable number of taps (roughly 5-8), for the human to eyeball and adjust.
- [ ] Test coverage: tapping + / - steps zoom by the chosen increment and clamps correctly at both bounds.
- [ ] Manual check noted for the human: confirm the buttons feel responsive, don't overlap other map UI (legend, growth badge, hamburger/bag icons), and the step size feels right.
