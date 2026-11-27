# 09 — Time lens: ambush forewarning

**What to build:** Spec `.scratch/lenses/spec.md` "Time: ambush forewarning". Ambush rolls are already seeded per district (`Ambush._unit`). Add a pure `Ambush.due_today()` returning the districts whose roll would trigger today (same inputs as `maybe_trigger`, no state change). With a Time lens and Sense >= world gate, the morning brief / a Notify names those districts. Must not change whether or when ambushes happen. Strings PROSE-REVIEW.

**Blocked by:** 01

**Status:** ready-for-agent

**Relevant files:**
- `systems/ambush.gd`
- `systems/daily_brief.gd`
- `systems/notify.gd`
- `systems/lenses.gd`
- `tests/test_ambush.gd`
- `docs/REFERENCE.md` §3.1d

**Acceptance:**
- [ ] `due_today()` agrees with `maybe_trigger` outcomes for the day (test).
- [ ] Forewarning only with Time lens + gate; ambush outcomes identical with and without the lens.
- [ ] Prophet's Breath suppression respected (decide: suppressed district not warned, or marked safe; document it).
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.
