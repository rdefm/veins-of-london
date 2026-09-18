# 15 — Dial needle points true at empty/full charge

**What to build:** The charge-reserve needle overlay on the Dial view
currently reads ~11 o'clock at zero charge, confirmed against a live
screenshot — it should read exactly 12 o'clock. `HqDialScreen`'s
`NEEDLE_MIN_DEG`/`NEEDLE_MAX_DEG` consts are corrected by the measured
offset (`-90 → -60`), shifting the full-charge end by the same amount
(`+90 → +120`) to preserve the existing sweep width. The full-charge
endpoint hasn't been visually confirmed (no seeded+charged Dial screenshot
exists yet) — flag it `ART-REVIEW` same as the file's other measured consts,
for a human to eyeball once a Movement is seated and charged and correct
further if needed.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [x] `NEEDLE_MIN_DEG` corrected so 0 charge renders at 12 o'clock
- [x] `NEEDLE_MAX_DEG` shifted by the same offset
- [x] `tests/test_hq_dial.gd`'s needle-rotation assertions updated to the new consts
- [x] Full-charge endpoint left flagged `ART-REVIEW` in the file's own comments for on-device confirmation
