# 99 — Map: remove pinch-zoom, fix invisible zoom-in icon

**What to build:** Pinch-zoom on the Network Map is unusable and should be removed entirely — zoom becomes button-only (the existing +/− floating buttons), with a fixed step per tap, same as today's button behaviour. Single-finger drag-to-pan and every other map-navigation behaviour must be left untouched — this ticket only removes the pinch gesture and does not touch panning. Separately, the zoom-in button's "+" glyph is not visible to the player (the "−" on the zoom-out button is visible) — find and fix the actual cause (likely a text/background contrast issue between the button's font color and its panel style) rather than restyling the whole control.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Pinch-to-zoom gesture is removed from the map canvas; two-finger input no longer changes zoom.
- [ ] Single-finger drag-to-pan and all other map-navigation behaviour is unchanged.
- [ ] The zoom-in button's "+" is clearly visible against its background in the same way the zoom-out button's "−" already is.
- [ ] Zoom in/out buttons still step zoom by the same fixed increment as before.
- [ ] Regression test coverage for pinch-zoom removal (a pinch gesture no longer changes zoom state) and for the button zoom step behaviour continuing to work.
