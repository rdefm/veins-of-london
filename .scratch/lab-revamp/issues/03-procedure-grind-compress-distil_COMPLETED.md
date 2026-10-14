# 03 — Slice A: grind, compress and distil gauges

**What to build:** The remaining three step types become interactive, so all three recipes are fully playable by hand.
- **Grind:** tap a counted number of strokes, each with a timing window on a swinging pestle meter.
- **Compress:** hold to build pressure and release in the band. Overshooting cracks the vessel and ends the run (calc spent is lost).
- **Distil:** drips fall on a beat; tap to collect each one. A stray tap spoils the step.

The screen reports raw values and tap timings only; the system turns them into per-step accuracy. See spec §Slice A "Executing a step".

**Blocked by:** 02 — Slice A: procedure run, heat only.

**Relevant files:** `.scratch/lab-revamp/spec.md` §Slice A; bench prototype system/screen/tests from 01–02.

**Status:** ready-for-agent

- [ ] Grind, compress and distil each have a placeholder `_draw` gauge, and input is reported raw to the system.
- [ ] System-side scoring for stroke timings, pressure release (including the crack → run ends, calc lost) and drip taps (including stray tap → spoiled) is unit-tested.
- [ ] All 3 recipes are playable end to end with no auto-passed steps.
- [ ] Human on-device check list included in the report (gauge feel on phone).
