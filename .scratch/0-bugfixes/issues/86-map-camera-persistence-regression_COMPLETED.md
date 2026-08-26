# 86 — Map: fix camera position/zoom no longer persisting

**What to build:** Reopening the Map tab used to restore the same pan/zoom position (built by tickets 53 and 67, both already completed); it now resets to default every single time, no exceptions. This is a regression, not a missing feature — restore the exact behavior those tickets already specified. Deterministic (always-fails, not intermittent) failure pattern points at a layout timing race: zoom is applied first (resizing the canvas), then scroll position is set in the same call, but the scroll container may not recompute its valid scroll range from the resized child until a frame later — so the scroll set lands before the range updates and gets clamped back toward zero.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Reopening the Map tab restores the exact pan/zoom position it was left at, every time, matching tickets 53/67's original behavior (including persistence across app restart).
- [ ] Timing-race theory (scroll set before the scroll container's range recomputes post-resize) is confirmed or ruled out by testing a deferred scroll-restore; if it doesn't fully explain the deterministic failure, root cause is chased further rather than shipping a partial fix.
- [ ] Whatever manual/automated check tickets 53/67 originally used to confirm persistence is re-run (or extended) to confirm this regression is now fully closed.
