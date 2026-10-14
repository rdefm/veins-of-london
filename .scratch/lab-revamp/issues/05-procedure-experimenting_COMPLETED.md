# 05 — Slice A: experimenting and notebook

**What to build:** Before a run, the player can insert any apparatus at any position, or nudge a step's target. After the run, a notebook shows one clue per step:
- ✓ in band
- ~ right step, wrong amount, plus a direction
- ✗ no effect
- "something changed": an inserted step matches a hidden ideal step at that position

"Something changed" turns that step into a vague hint. Scoring ✓ on a vague step in 3 runs upgrades it to exact. Hints earned this way persist in the Procedure slice's state, and Rewind rolls them back too. See spec §Slice A "Experimenting".

**Blocked by:** 04 — Slice A: hints and knowledge display.

**Relevant files:** `.scratch/lab-revamp/spec.md` §Slice A; bench prototype system/screen/tests from 01–04.

**Status:** ready-for-agent

- [ ] Procedure editor: insert apparatus at a position, remove an inserted step, nudge a target. All edits go through system calls.
- [ ] Notebook clue derivation is unit-tested for all four clue types.
- [ ] Discovery → vague, and 3 ✓ runs → exact, are tested. Rewind undoes the progress.
- [ ] Human check list: is the feedback enough to deduce from, and is a 2nd/3rd run still satisfying?
