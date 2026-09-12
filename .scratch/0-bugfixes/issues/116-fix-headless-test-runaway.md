# 116 — Fix runaway/hanging headless test run

**What to build:** Using ticket 115's confirmed root cause, make
`scripts/run_tests.sh` finish end-to-end again without manual intervention.
Fix the actual mechanism found — if it turns out to be a pattern shared
across multiple off-tree screen tests (not just one file), fix the pattern
(e.g. a shared teardown/disconnect helper in `tests/test_base.gd` that every
off-tree `Screen.new(); screen._ready()` test can call), not just the one
symptom ticket 115 happened to point at first.

**Blocked by:** 115 (its written diagnosis is the input to this ticket's
approach).

**Status:** ready-for-agent

- [ ] `scripts/run_tests.sh` completes end-to-end without manual
      intervention or a timeout wrapper; note the resulting wall-clock time
      in the ticket
- [ ] Fix addresses the root cause identified in ticket 115 — if systemic
      across off-tree screen tests, the fix covers the pattern, not just
      `tests/test_event_screen.gd`
- [ ] No test coverage lost (case count before/after matches, modulo any
      cases legitimately restructured as part of the fix)
- [ ] `scripts/check_all.sh` and the individual affected test files still
      pass after the fix
