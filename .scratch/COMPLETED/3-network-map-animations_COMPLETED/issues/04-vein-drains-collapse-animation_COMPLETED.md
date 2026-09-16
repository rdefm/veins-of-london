# 04 — Vein drains animation (halo collapses and fades)

**What to build:** When a charged vein is harvested (`Cultivating.harvest_full` or `Cultivating.harvest_cautious`, the moment `charged` flips to `false`), a "drain" map event is queued using the pipeline from ticket 01. During playback, the camera pans to the vein's stop and its halo visibly collapses/shrinks inward and fades out — the reverse shape of ticket 03's charge burst — marking the moment it stops, rather than the halo just disappearing as it does today.

**Blocked by:** 01 — Map event queue, playback engine, camera pan-to-point (tracer bullet: discover ripple)

**Status:** ready-for-agent

- [ ] `Cultivating.harvest_full` and `Cultivating.harvest_cautious` each queue a "drain" event (vein id, location) on the transition where `charged` flips from `true` to `false`.
- [ ] Playback for this event type pans the camera to the vein's stop and plays the halo collapsing inward + fading out, ending with the halo fully gone — matching what `_rebuild_halos` already does at rest for an uncharged vein, just no longer an instant disappearance.
- [ ] Tap-to-skip during this event snaps straight to "halo gone" and advances to the next event.
- [ ] Tests cover: both harvest paths queue the drain event on the true→false transition, and playback's end state matches the existing uncharged-vein halo state (none).
