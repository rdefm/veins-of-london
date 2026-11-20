# 07 — Fate lens: event check roll shown as a range

**What to build:** Spec `.scratch/lenses/spec.md` "Fate: roll range". With a Fate lens loaded and Sense >= world gate, `Events.roll_range(i)` returns `{low, high, needed}` (d100, high is good) for a shown check option: band width `fateRangeWidthByTier` (placeholder `[0,40,30,20,15,10]`), always containing the real `check_roll(i)` d100 at a seeded offset (`Rng.stable_unit`, own key, not centred), recomputed live like `revealed_roll` so toggles shift it. The screen shows "Roll 40-60 · need 55+" in the `?` modal and under the option. A bought Dejà Vu reveal replaces it. Strings PROSE-REVIEW.

**Blocked by:** 01

**Status:** ready-for-agent

**Relevant files:**
- `systems/events.gd`
- `systems/lenses.gd`
- `scenes/screens/event.gd`
- `data/constants.json`
- `tests/test_events*.gd`
- `docs/REFERENCE.md` §3.9a

**Acceptance:**
- [ ] Range always contains the committed roll (test across seeds and toggles).
- [ ] Width follows tier; offset is not always centred.
- [ ] Hidden without lens or below the Sense gate; Dejà Vu shows exact instead.
- [ ] Human QA: range line on check options.
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
