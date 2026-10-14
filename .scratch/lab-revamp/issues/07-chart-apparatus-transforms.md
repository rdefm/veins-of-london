# 07 — Slice B: apparatus transforms

**What to build:** Apparatus buttons on the chart:
- **Heat:** rotates the next pour 45° counter-clockwise.
- **Grind:** halves its speed.
- **Compress:** doubles its speed.
- **Distil:** immediately pulls the marker 25% back toward the origin.

Heat, grind and compress stack until the next pour consumes them: heat ×2 = 90°, grind + compress cancel out. The screen shows what's queued for the next pour. These are human-decided semantics; see spec §Slice B "Moving the marker".

**Blocked by:** 06 — Slice B: resonance chart, pour and bottle.

**Relevant files:** `.scratch/lab-revamp/spec.md` §Slice B; chart system/screen/tests from 06.

**Status:** ready-for-agent

- [ ] Rotation, speed stacking, consume-on-pour and immediate distil are unit-tested.
- [ ] Queued transforms are visible before pouring.
- [ ] Rewind restores the marker, the queue and calc.
- [ ] Human check list: are there interesting alternative routes, and is navigating fun?
