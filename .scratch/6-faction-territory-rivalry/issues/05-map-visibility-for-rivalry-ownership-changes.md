# 05 — Map visibility for rivalry-driven ownership changes

**What to build:** A successful rivalry resolution (ticket 04) queues the same map event type the network-map-animations pipeline already uses for a faction claiming a vein (the "seed/claim" event, network-map-animations ticket 02), referencing the vein's location and new owner. During playback, this plays the existing ring-draw-in animation at the vein's stop, in the new owner's colour — no new animation asset is built here, this ticket only confirms/extends the queue to accept this new trigger point (an ownership change on an *existing* vein, not only a brand-new vein being seeded/claimed from unclaimed land), closing the PRD's explicit open question about whether the animation queue needs any change to pick this up.

**Blocked by:** 04

**Status:** ready-for-agent

- [ ] A successful rivalry resolution (ticket 04) queues a map event of the same shape/type used for faction vein claims, referencing the vein's location and new owner
- [ ] Playback renders the existing ring-draw-in animation at the vein's stop in the new owner's colour — reuses network-map-animations ticket 02's visual as-is, no new animation
- [ ] Tap-to-skip behaves the same as the existing seed/claim event (snaps to full steady-state ring, advances to the next queued event)
- [ ] Multiple same-tick rivalry transfers each queue their own event and play back sequentially, same as any other multi-event tick
- [ ] Tests cover: a rivalry-driven transfer queues an event of the correct shape/location/owner; playback end-state matches the static ring already drawn for that owner's colour
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes
