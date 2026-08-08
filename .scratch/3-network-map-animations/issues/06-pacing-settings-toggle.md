# 06 — Pacing settings toggle (deliberate vs. quick)

**What to build:** A player-facing settings toggle that switches map-event playback pacing between the default **deliberate** speed (~1-2s per event, ticket 01's default) and a **quick/snappy** speed (~200-500ms per event) for repeat playthroughs. This is UI-local preference, not saved and not written to `GameState` — same treatment as `filter_mode`'s "not saved, not in GameState" handling in N4/`map_canvas.gd`. Exact placement is left to implementation, alongside other player-facing toggles.

**Blocked by:** 01 — Map event queue, playback engine, camera pan-to-point (tracer bullet: discover ripple)

**Status:** ready-for-agent

- [ ] A toggle exists somewhere in the settings-equivalent UI that switches between "deliberate" and "quick" pacing.
- [ ] The toggle's value is UI-local state only — never written to `GameState.state`, never persisted across app restarts (consistent with `filter_mode`'s precedent).
- [ ] Switching the toggle changes the per-event duration the ticket 01 playback engine reads, taking effect on the next event played (mid-event switches don't need to retroactively rescale an animation already in flight).
- [ ] Quick pacing lands in the ~200-500ms per event range; deliberate stays at ticket 01's ~1-2s default.
- [ ] Tests cover: toggling pacing changes the duration the playback engine uses, and the default on fresh load is deliberate.
