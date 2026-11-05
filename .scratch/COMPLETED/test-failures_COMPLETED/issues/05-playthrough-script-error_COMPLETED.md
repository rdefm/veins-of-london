# 05 — Diagnose and fix test_playthrough SCRIPT ERROR

**Status:** ready-for-agent

**What to build:** The full run logs `SCRIPT ERROR: Invalid access to property or key 'life' on a base object of type 'Dictionary'` at `tests/test_playthrough.gd:483` (case starting line 457). The case is aborted mid-way, so it may hide a real failure while reporting PASS. Diagnose and fix so the case runs fully.

**Relevant files:** `tests/test_playthrough.gd`

- [ ] No SCRIPT ERROR from test_playthrough
- [ ] The case's assertions all execute
