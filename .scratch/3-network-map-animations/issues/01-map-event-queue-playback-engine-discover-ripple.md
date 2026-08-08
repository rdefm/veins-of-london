# 01 — Map event queue, playback engine, camera pan-to-point (tracer bullet: discover ripple)

**What to build:** The full map-animation pipeline end to end, proven with the simplest visual (site discovery). When a site is discovered (via `Sites.prospect`), a map event record is queued instead of drawn immediately. The queue is not drained on the spot — it waits silently, with no forced tab-switch. The next time the player navigates to the Map tab, queued events play back sequentially: for each event, the camera pans/zooms to that event's map location, then its animation plays (here: a soft ring pulses outward once from the site, then the unclaimed tick-mark glyph pops in at its centre). The player can tap to skip the currently-playing event, which snaps it to its end state and immediately advances to the next queued event. Once the queue is empty, the Map tab behaves exactly as it does today.

This ticket also builds the underlying programmatic "pan+zoom to a point" capability on `MapCanvas`/`MapZoom` (today zoom is only ever pinch-driven) — it has no standalone value outside this pipeline, so it's built here rather than as a separate ticket.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A map event queue exists as pure data (Dictionaries/Arrays only) reachable from `GameState.state`, so it survives save/load and Rewind snapshots like the rest of state.
- [ ] `Sites.prospect`'s discovery path appends a "discover" event record (type, location, before/after state as needed for the visual) to the queue instead of the change simply appearing on the next redraw.
- [ ] Visiting the Map tab (not any other tab) drains and plays the queue if it's non-empty; visiting any other tab, or an empty queue, changes nothing about current behaviour.
- [ ] Queued events play strictly sequentially — never simultaneously — each preceded by a programmatic camera pan/zoom to that event's location on `MapCanvas`.
- [ ] Default pacing is deliberate (~1-2s per event); the per-event duration is a single parameter the playback engine reads, so ticket 06 can later swap it without touching this engine.
- [ ] Tapping during playback skips the current event (snaps to its end state) and immediately advances to the next queued event, which still plays at normal pace unless also tapped.
- [ ] The discover event's visual is implemented: a soft ring pulses outward once from the location, then the unclaimed tick-mark glyph pops in at its centre — matching what's drawn today at rest, just no longer appearing instantly.
- [ ] After the queue finishes draining, the Map tab's normal `state_changed`-driven redraw is unaffected — no regression to existing map rendering, pinch-zoom, or tap handling.
- [ ] Tests cover: event queuing on discovery, queue draining exactly once per Map-tab visit, sequential (not simultaneous) playback ordering, and skip-advances-to-next behaviour.
