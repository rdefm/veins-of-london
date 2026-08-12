# 11 — Tapping a station or district on the map does nothing until the filter drawer has been opened once

**What to build:** On-device, tapping a station or district on the Network diagram does nothing at all — until the map filter drawer (hamburger button, `map_controls.gd`) has been opened once, after which taps start working normally for the rest of the session. Root-cause and fix the underlying hit-test/initialization ordering bug so taps work immediately on a fresh map load, every time, with no workaround needed.

This is a standalone bug fix, independent of `10-map-interaction-model`'s new bubble-menu interaction model (tickets 03/04 there build on top of this being fixed first, but this ticket's job is just to make today's existing tap-to-open-sheet behaviour work correctly).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] On a fresh map load (no prior interaction with the filter drawer), tapping a station opens its site sheet immediately.
- [ ] On a fresh map load, tapping a district opens its district panel immediately.
- [ ] Root cause identified and documented in the fix (not just papered over by e.g. forcing a drawer rebuild on load).
- [ ] Existing map/hit-test tests still pass; add a regression test that exercises a tap before any drawer interaction if the current suite doesn't already cover this path.
