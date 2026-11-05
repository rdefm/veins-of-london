# 06 — Audit remaining suite ERROR noise and leaks

**Status:** needs-triage

**What to build:** After tickets 01-05, review a full `scripts/run_tests.sh` log for remaining `ERROR:`/`SCRIPT ERROR` lines. Many (`Events: goto ...`, `Parse JSON failed`, `b64_decode`) are expected output from negative-path tests; confirm and list them. Investigate the exit-time warning "1106 ObjectDB instances were leaked" and RID leaks, and fix only if they reflect real leaks in tests (see memory: run_case frees GameState). Report findings; don't silence real errors.

**Blocked by:** 01, 02, 03, 04, 05

**Relevant files:** `tests/test_base.gd`, `tests/test_runner.gd`, `scripts/run_tests.sh`

- [ ] Full suite log has no unexplained ERROR lines
- [ ] Leak warning explained or fixed
