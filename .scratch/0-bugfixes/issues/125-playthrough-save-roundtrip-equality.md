# 125 — Fix playthrough save/load equality

**What to build:** Diagnose and fix `test_playthrough.gd`'s
`full_playthrough_tutorial_economy_ticks_and_save_roundtrip` failure. A
manual-slot JSON round trip must restore the exact pure state tree produced
by the playthrough, including numeric types and persisted nested fields.

**Blocked by:** None.

**Relevant files:** `tests/test_playthrough.gd`, `autoload/SaveManager.gd`,
`docs/REFERENCE.md` §2 and §6.

**Status:** ready-for-agent

- [ ] A narrow reproducible comparison identifies the first differing state path.
- [ ] Save/load restores that persisted value and type exactly.
- [ ] Regression coverage passes; full suite green.

## Comments

2026-09-16: Full isolated suite: 2458 passed, 1 failed. The sole failure is
this playthrough save-roundtrip assertion; it predates token-diet ticket 05
and is unrelated to comment removal. Earlier ticket 124 recorded the same
failure.
