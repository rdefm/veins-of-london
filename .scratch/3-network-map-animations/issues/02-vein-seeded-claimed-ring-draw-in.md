# 02 — Vein seeded/claimed animation (ring draws in progressively)

**What to build:** When a vein is seeded (player action via `Sites.attempt_seed`) or claimed by a faction (`Sites.roll_faction_vein_growth`'s claim-tick creating a new vein), a "seed/claim" map event is queued using the pipeline from ticket 01. During playback, the camera pans to the new vein's stop and its coloured ring draws itself in progressively around the stop — like a loading-spinner filling from 0 to 360° — reusing the existing `draw_arc` primitive already used for vein rings, animated over the arc's `0 -> TAU` sweep instead of appearing at full circumference instantly.

**Blocked by:** 01 — Map event queue, playback engine, camera pan-to-point (tracer bullet: discover ripple)

**Status:** ready-for-agent

- [ ] `Sites.attempt_seed`'s success path queues a "seed/claim" event (vein id, location, owner).
- [ ] `Sites.roll_faction_vein_growth`'s claim-tick path (creating a new faction vein) also queues a "seed/claim" event, same shape, owner set to the claiming faction.
- [ ] Playback for this event type pans the camera to the vein's stop, then draws the ring's arc sweeping from 0 to `TAU` over the event's duration, ending in exactly the same steady-state ring the stop draws today (colour/width per `MapStyle`, unaffected by filter mode).
- [ ] Tap-to-skip during this event snaps the ring straight to its full steady-state circumference and advances to the next event.
- [ ] Tests cover: both trigger points (player seed, faction claim-tick) produce a queued event of the correct shape, and the arc-sweep animation reaches the same end state the static ring draw already produces.
