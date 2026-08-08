# 05 — Vein joins a line animation (line segment grows)

**What to build:** When a vein stop joins its owner's line — a new player vein extending the player's own routed line, or a new faction vein extending that faction's routed line — a "join-line" map event is queued using the pipeline from ticket 01. During playback, the camera pans to the new stop and the connecting line segment visibly grows from the nearest existing point on that owner's line to the new stop, over the event's duration — not a snap to the final routed shape. This is the direct answer to the original animation ask: the connection process itself is shown, not just the end state.

**Blocked by:** 01 — Map event queue, playback engine, camera pan-to-point (tracer bullet: discover ripple). **Also externally blocked by Chunk 2 (`network-map-districts`)**, which is not yet built: today `map_canvas.gd` only routes and draws a real line for the player (`MapRouting.build_line` + `MapLayout.home_anchor()`); non-player veins are drawn as unconnected grey stubs (`_npc_stops`, see `_draw_lines`' own comment), so there is no faction line to grow a segment onto yet. Do not start this ticket until Chunk 2 lands multi-faction line routing (`MapLayout.faction_first_presence_anchor()` wired up, per-faction lines drawn and coloured).

**Status:** ready-for-agent

- [ ] A new player vein (seed) queues a "join-line" event carrying enough to compute the segment: the new stop's position and the nearest existing point on the player's routed line at the time it joined.
- [ ] A new faction vein (claim-tick) queues the same shape of event for that faction's line, using the same nearest-existing-point + elbow-routing logic Chunk 2 applies per-faction (no new routing algorithm here).
- [ ] Playback for this event type pans the camera to the new stop and grows the connecting segment from the nearest existing point to the new stop over the event's duration, ending in exactly the routed line shape `_draw_lines`/`MapRouting` already produce at rest.
- [ ] Tap-to-skip during this event snaps the segment straight to its full routed shape and advances to the next event.
- [ ] Tests cover: both the player-line and at least one faction-line case queue the correct event shape, and playback's end state matches the existing static routed line exactly.
