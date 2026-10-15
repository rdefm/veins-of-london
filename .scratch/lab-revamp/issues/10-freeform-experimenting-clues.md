# 10 — Experimenting clues in the freeform run

**What to build:** Experimenting works again under the freeform run.

- **Clues.** After Finish, the result on the docked book lists a clue per performed step, ore-aware:
  - ✓ in band;
  - ~ right step, wrong amount, plus a direction word;
  - ✗ no effect;
  - "something changed".
- **Learning.**
  - An off-book step that matches a hidden ideal step (apparatus + ore, at that point in the sequence) becomes a **vague hint**: "something changed · new vague hint".
  - Three ✓ hits on a vague step upgrade it to **exact**, shown as "n/3 toward exact" and then "now exact".
- **Docked book.** The book reflects knowledge live:
  - exact steps show their band;
  - vague steps show the faded wide region plus the direction note;
  - unknown steps are not shown.
- Debug hint toggles on the back page and learned hints share the same state, so either source updates the book.

**Blocked by:** 09 — Freeform manual run

**Relevant files:**
- `systems/bench_prototype.gd` (`notebook_clues`, `_known_matches_kept`, `_direction`, `_learn`, `_sync_plan_knowledge` → replace the plan sync, `hidden_ideal_steps`, `known_procedure`, `step_region`)
- `scenes/screens/bench_prototype.gd` (result clue list, docked step rows with vague region + note)
- `data/bench_prototype.json` (`vagueToExactHits`, gauge `directionWords`, hint notes)
- `tests/test_bench_prototype.gd`
- `.scratch/lab-revamp/spec.md` §Slice A Experimenting / Knowledge display

**Status:** ready-for-agent

- [ ] Tests:
  - clue per performed step for each of the 4 kinds;
  - an off-book matching step grants a vague hint;
  - 3 ✓ hits upgrade vague to exact;
  - wrong ore never yields ✓ or "something changed"
- [ ] The result shows clues with learn suffixes. The docked book shows vague steps faded with a note and hides unknown steps
- [ ] Debug-granted and learned hints display identically
- [ ] check_all + full suite green
- [ ] On-device checklist in the report (clue legibility, vague region readable on gauge)
