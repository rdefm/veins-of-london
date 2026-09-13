# 108 — Combat Dial: increase size 1.75x and close the gap to the animation square

**What to build:** The Dial in the combat command dock is too small, and the current gap between it and the animation square is oversized. Increase the Dial's display size by 1.75x, and adjust the surrounding layout so the gap between the Dial and the animation square shrinks to something snug — without the two overlapping. This requires updating the layout spacing math in the command dock, not just the Dial's size constant, since simply scaling the Dial up in place would keep (or worsen) the existing gap or cause overlap.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] The Dial renders at ~1.75x its current display size.
- [ ] The Dial does not overlap the animation square at any supported screen size.
- [ ] The gap between the Dial and the animation square is visibly tighter than before, not just preserved at the same absolute size.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file.
- [ ] Manual check noted for the human: on-device, confirm the Dial reads as substantially bigger, sits close to (but never overlapping) the animation square, across the combat screens where it appears.
