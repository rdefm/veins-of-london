# 20 — Combat dial widget needle calibration

**What to build:** `DialWidget` (`scenes/components/dial_widget.gd`, used by
`combat.gd`) has its own `NEEDLE_MIN_DEG`/`NEEDLE_MAX_DEG` consts, currently
`-90`/`90` — the same values `HqDialScreen`'s consts held before ticket 15
corrected them against a live screenshot. This widget likely has the same
~11-o'clock-at-zero miscalibration, unconfirmed. Correct
`NEEDLE_MIN_DEG`/`NEEDLE_MAX_DEG` by the same measured offset ticket 15 used
(`-90 → -60`, `+90 → +120`) unless a fresh live combat-screen screenshot
shows the needle art sits at a different offset in this widget, in which
case measure and use that offset instead.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `NEEDLE_MIN_DEG` corrected so 0 charge renders at 12 o'clock, confirmed against a live combat-screen screenshot
- [ ] `NEEDLE_MAX_DEG` shifted by the same offset to preserve the existing sweep width
- [ ] `tests/test_dial_widget.gd`'s needle-rotation assertions updated to the new consts
- [ ] Full-charge endpoint left flagged `ART-REVIEW` in the file's own comments if not visually confirmed
