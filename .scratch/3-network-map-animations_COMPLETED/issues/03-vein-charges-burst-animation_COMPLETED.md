# 03 — Vein finishes charging animation (burst, then settle into idle halo)

**What to build:** When a vein finishes recharging during the daily tick (`Cultivating.recharge_veins`, the moment `charged` flips to `true`), a "charge" map event is queued using the pipeline from ticket 01. During playback, the camera pans to the vein's stop and plays a brighter one-shot burst/flash at the stop, then settles into the existing continuous idle pulse loop (`ChargeHalo`) — that loop itself is unchanged, this ticket only adds the one-shot moment that precedes it.

**Blocked by:** 01 — Map event queue, playback engine, camera pan-to-point (tracer bullet: discover ripple)

**Status:** ready-for-agent

- [ ] `Cultivating.recharge_veins` queues a "charge" event (vein id, location) for each vein whose `charged` flips from `false` to `true` that tick — not for veins already charged.
- [ ] Playback for this event type pans the camera to the vein's stop, plays a brighter one-shot burst/flash (visually distinct from, and preceding, the steady-state `ChargeHalo` pulse), then leaves the vein in exactly the same continuous `ChargeHalo` state it's in today.
- [ ] Tap-to-skip during this event snaps straight past the burst into the steady-state `ChargeHalo` and advances to the next event.
- [ ] No changes to `ChargeHalo`'s own loop (radius, period, colour, scale/alpha curve) — confirmed unchanged by test/inspection.
- [ ] Tests cover: the event is queued only on the false→true transition (not every tick a vein stays charged), and playback ends with the same halo state `_rebuild_halos` already produces for a charged vein.
