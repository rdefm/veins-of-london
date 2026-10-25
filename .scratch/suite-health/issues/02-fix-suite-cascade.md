# 02 — Stop one erroring case from poisoning the suite

**What to build:** Apply the fix for the cause found in 01 so a case that errors mid-run cannot leave GameState freed or scripts unloaded for later files. A full run is deterministic and its log is normal size.

**Blocked by:** 01 — Find the first break in the full suite.

**Relevant files:** `tests/test_base.gd`, `tests/test_runner.gd`, `autoload/GameState.gd`, plus whatever 01 names (likely `systems/events.gd` or the opening-chain test).

**Status:** ready-for-agent

- [ ] No `Nonexistent function` or null-Dictionary SCRIPT ERRORs in a full run
- [ ] `test_district_events.gd` and `test_demo_fight.gd` run to completion
- [ ] Full-run log back to a normal size (tens of thousands of lines at most)
- [ ] Regression test or runner assertion covers the cause
