# 04 — Fail fast on a runaway or poisoned test run

**What to build:** The test runner aborts non-zero when SCRIPT ERRORs repeat past a threshold, so a poisoned run fails in seconds instead of writing a 200k-line log or hanging.

**Blocked by:** 02 — Stop one erroring case from poisoning the suite.

**Relevant files:** `tests/test_runner.gd`, `scripts/run_tests.sh`, `tests/test_base.gd`.

**Status:** ready-for-agent

- [ ] A deliberately poisoned run exits non-zero within seconds
- [ ] A normal full run is unaffected
