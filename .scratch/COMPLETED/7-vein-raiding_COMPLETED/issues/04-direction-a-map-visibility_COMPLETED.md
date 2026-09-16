# 04 — Direction A: map visibility for raid-driven claims

**What to build:** A successful raid claim (ticket 03's claim resolution, ticket 02's ops) queues the same map event type the network-map-animations pipeline already uses for a vein changing hands — the "seed/claim" event (network-map-animations ticket 02), same reuse Chunk 6 ticket 05 established for rivalry-driven ownership changes. During playback, this plays the existing ring-draw-in animation at the vein's stop, now in the player's colour — no new animation asset, this ticket only wires the new trigger point (a raid-driven ownership change on an existing vein).

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] A successful raid claim queues a map event of the same shape/type used for faction vein claims (`MapEvents.queue_seed_claim`), referencing the vein's location and the player as new owner
- [ ] Playback renders the existing ring-draw-in animation at the vein's stop in the player's colour — reuses the existing visual as-is, no new animation
- [ ] Tap-to-skip behaves the same as the existing seed/claim event
- [ ] Tests cover: a raid claim queues an event of the correct shape/location/owner; playback end-state matches the static ring already drawn for player ownership
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes
