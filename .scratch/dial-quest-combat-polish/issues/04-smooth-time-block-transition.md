# 04 — Time-block transition runs smoothly on Android

**What to build:** The time-block transition plays smoothly, at its normal speed, from first frame to last. Reported on an Android phone, on every block end: while the sun is moving, the animation starts a bit slow and stutters, then reaches normal speed and smooths out.

Diagnose before fixing. Suspects, none verified:
- heavy work on the frames just after a block ends (daily or staff-block processing, screen rebuilds, saving) landing during playback
- low-processor mode (recently enabled) affecting frame pacing on Android
- the per-frame delta cap turning slow frames into slow motion
- first-use cost of drawing the sky, bodies and foreground
- sun position not being snapped to whole pixels

The diagnosis loop skill applies. Keep the idle battery saving from low-processor mode when nothing is animating.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/components/time_transition.gd` (`_process`, `_render_frame`, `_sky_frame`, `_draw`)
- `data/daily_cycle.json` (`durationSeconds`, `entrySeconds`, `exitSeconds`, `outcomeHoldSeconds`)
- `systems/time_system.gd` (`advance_time_block`, `do_rest`, `time_advanced` emit order)
- `project.godot` (`[application]` low-processor mode)
- `.scratch/COMPLETED/perf-cleanup_COMPLETED/issues/03-idle-frames-low-processor_COMPLETED.md`
- `tests/test_time_transition.gd`, `tests/test_state_replaced.gd`
- REFERENCE.md §3.1 Time, rest, daily tick

**Status:** ready-for-agent

- [ ] Report names the cause, with the measurement or evidence behind it
- [ ] Sun moves at constant speed with no hitch at the start, on ordinary and overnight transitions
- [ ] Total duration, entry, exit and hold timings unchanged
- [ ] Reduced motion behaves as today
- [ ] Idle screens still stop redrawing
- [ ] Test covers the cause where it can be tested headless
- [ ] Syntax check clean on touched files; full suite passes
- [ ] Report lists on-device checks; human confirms smoothness on the Android phone before the ticket is marked completed
