# 17 — Slow down combat animation pacing

**What to build:** Attack/hit/KO transform playback (`StageSlot`'s keypose+
transform tweens, driven by the beat-queue director) currently runs too fast
to read who's acting before a turn resolves. Slow the pacing (tween durations
/ per-beat hold time) so a player can follow which combatant is acting and
what happened before the next beat starts.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Attack, hit, and KO beats each hold long enough on-screen to identify
      the acting combatant and the outcome before the next beat begins.
- [ ] Full-round pacing (a round with multiple beats) doesn't feel sluggish
      overall — this is a legibility fix, not a general slow-down; tune
      holistically, not just per-beat.
- [ ] Verified on-device across a multi-beat round (not just a single
      isolated beat) since pacing reads differently in sequence.
