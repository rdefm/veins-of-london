# 11 — Lab bench: 3 stops → 2 (books+ore / apparatus)

**What to build:** Merge the Lab bench's three pan stops (books / ore /
apparatus) into two: books+ore share stop 0, apparatus keeps stop 1. Arrow
nav pans between them with a tween animation instead of the current instant
jump. This is the mechanical/infrastructure slice — it does not finalize
the apparatus half's slot layout (that's ticket 13) or drop in real art for
the books+ore half (that's ticket 12); it just needs the merged plate to be
valid and everything that already worked to keep working.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `LabBenchNav.STOPS` has exactly 2 entries (`"books"`/`"ore"` collapse
      into one stop; `"apparatus"` stays the other) and `step()` clamps
      correctly at both ends
- [ ] `data/hq_visuals.json`'s `labBench` plate width is 780 (2×390); every
      region's x/y is remapped so books+ore regions sit within stop 0
      (0–390) and apparatus regions sit within stop 1 (390–780), still
      passing `GameData._validate_hq_visuals()` (≥44×44, non-overlapping)
- [ ] Arrow nav animates the pan (tween) rather than snapping instantly
- [ ] Existing interactions — notebook tap, ore-container select, apparatus
      arm/run, the ore→apparatus drag flourish — and their existing tests
      keep passing unmodified in behaviour
