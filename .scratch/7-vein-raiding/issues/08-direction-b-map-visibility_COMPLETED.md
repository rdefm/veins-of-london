# 08 — Direction B: map visibility for player vein losses

**What to build:** A Direction-B vein loss — whether resolved off-screen (ticket 06) or after a lost defend-encounter (ticket 07) — queues the same map event type used elsewhere for a vein changing hands (`MapEvents.queue_seed_claim`, same reuse as ticket 04 and Chunk 6 ticket 05). During playback, this plays the existing ring-draw-in animation at the vein's stop in the attacking faction's colour, so the player can see the loss reflected on the Network Map the next time they open it, consistent with the Ticker notification (tickets 06/07) that already tells them it happened.

**Blocked by:** 06, 07

**Status:** ready-for-agent

- [ ] A vein loss from either the off-screen path (06) or the lost defend-encounter path (07) queues a map event of the correct shape/location/new-owner
- [ ] Playback renders the existing ring-draw-in animation at the vein's stop in the attacking faction's colour — no new animation
- [ ] Tests cover: both loss paths queue an equivalent map event; playback end-state matches the static ring already drawn for that faction's colour
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes
