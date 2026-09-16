# 14 — Shared test helpers

**What to build:** Helpers re-implemented across test files — playing an event through to completion, playing to a choice and finishing after it, building a synthetic site or vein, synthesising a tap — exist once under the test support directory and every test file uses that copy. Behaviour of every test is unchanged; the suite runs in the same time.

**Blocked by:** None — can start immediately.

**Relevant files:** `tests/support/` (new helper script(s)), `tests/test_base.gd`, and the duplicating files: `tests/test_col_a1_*.gd`, `tests/test_events.gd`, `tests/test_event_screen.gd`, `tests/test_district_events.gd`, `tests/test_sites.gd`, `tests/test_raiding.gd`, `tests/test_map_*.gd`, `tests/test_hq_lab_bench.gd`. Find the full set with a grep for duplicate `func _` names across `tests/`.

**Status:** ready-for-agent

- [ ] No private helper function name is defined in more than one test file.
- [ ] Same number of test cases run and pass as before; suite wall-clock within 10%.
- [ ] `tests/test_base.gd` or a support script documents the shared helpers in a one-line-each header.
