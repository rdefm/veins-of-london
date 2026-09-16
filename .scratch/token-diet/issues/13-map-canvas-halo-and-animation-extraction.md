# 13 — Map canvas halo/animation extraction

**What to build:** The Network map canvas keeps layout, stops, lines and hit-testing; the halo rebuild (the single 388-line function) and the event-playback animations (discover ripple, ring draw-in, charge burst, drain collapse, join growth) move to a dedicated drawing component the canvas delegates to. Rendering output is pixel-identical, verified by the existing draw-spy tests.

**Blocked by:** 05 — Comment strip: scenes/components/.

**Relevant files:** `scenes/components/map_canvas.gd`, new `scenes/components/map_halos.gd` (or `map_animations.gd`), `systems/map_events.gd`, `systems/map_style.gd`, `systems/map_layout.gd`, `tests/test_map_canvas.gd`, `tests/test_map_events.gd`, `tests/support/draw_spy.gd`, `CODEMAP.md`. Glyph/halo contract: `docs/M1.5-NETWORK-MAP.md`.

**Status:** ready-for-agent

- [ ] Map canvas script ≤ 1,400 lines; no function over 120 lines in either file.
- [ ] Draw-call sequences recorded by the draw spy are unchanged for the existing test scenarios.
- [ ] Playback animations (all five) and pacing toggle behave identically; syntax check and full test suite green.
- [ ] Human on-device check: seed a vein, watch ring draw-in and burst; open filters.
