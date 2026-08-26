# 76 — Map: fix pinch-zoom drift (still erratic)

**What to build:** Pinch-zooming the map still moves the view around erratically, even with slow, careful finger movement. This is the third pass at this bug — two prior tickets (one fixing anchor-point drift, one a broader jitter investigation) didn't fully resolve it. Confirmed specific to touchscreen pinch (not other zoom controls). The pinch handler currently re-bases its anchor off the live two-finger midpoint on every single frame, intentionally, to avoid a jump when a finger lifts and a new one lands mid-gesture — but that same continuous re-basing is a plausible source of the drift, since any small asymmetry between how the two fingers move frame-to-frame shifts the midpoint and re-centers the map on it each frame, even during a slow pinch. Investigate that mechanism specifically rather than starting from scratch.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Root-cause the drift, with the live-midpoint-rebasing-every-frame mechanism as the primary suspect — document the actual cause found, including why the two prior fix attempts didn't fully resolve it.
- [ ] Fix such that pinch-zoom tracks finger movement smoothly at any gesture speed, slow or fast, uneven two-finger movement included, without visible drift or jumping.
- [ ] The existing behaviour this mechanism was protecting against (no jump when a finger lifts and a new one lands mid-gesture) is preserved.
- [ ] Manual check noted for the human: pinch-zoom at various speeds and finger-movement patterns (slow/careful, fast, uneven, finger-swap mid-gesture) and confirm the view tracks smoothly with no drift in any case.
