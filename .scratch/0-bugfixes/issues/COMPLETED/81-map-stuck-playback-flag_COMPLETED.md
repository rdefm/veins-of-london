# 81 — Map: fix stuck animation-queue flag (veins fail to connect, taps go dead)

**What to build:** Fix the shared root cause of two reported bugs: (a) a seeded vein sometimes doesn't show its connecting line until the player leaves and re-enters the Map tab, and (b) after a while on the Map tab, tapping a district/vein sometimes silently does nothing until the player leaves and returns. Both are caused by the map's animation-queue "playing" guard getting stuck true whenever a queued animation is interrupted by something other than leaving the Map tab (which is the only path that currently clears it) — while stuck, pending veins stay excluded from the static line draw, and taps route into a no-op "skip" handler instead of normal handling. Find every interruption path (not just tab teardown) that can stop a queued animation mid-flight, and make sure all of them clear the guard the same way leaving the tab does.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Every code path that can interrupt/abandon a queued map animation (not just navigating away from the Map tab) properly clears the playback guard.
- [ ] A vein queued for connection always shows its connecting line promptly, without requiring a tab leave/return, regardless of what interrupted the animation.
- [ ] Taps on the Map tab keep working normally after an animation is interrupted mid-flight by any means, without requiring a tab leave/return.
- [ ] Regression test: start a queued animation, interrupt it via the newly-found interruption path (a district-deck event firing mid-tween is the prime suspect), and confirm the playback guard recovers to false and a subsequent tap is handled normally.
