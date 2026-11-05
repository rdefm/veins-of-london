# 02 — Migrate James and Wren event tests to card keys

**What to build:** The James experiment and Wren introduction tests assert on card keys and use the capped helpers, so inserting or reordering cards in those events no longer breaks them.

**Blocked by:** 01

**Relevant files:** `tests/test_james_experiment.gd` (`CHOICE_CARD`, `_play_to_bench`, `_finish_event`, `seen.has(N)`), `tests/test_wren_introduction.gd`, `data/events/james_experiment.json`, `data/events/wren_introduction.json`.

**Status:** ready-for-agent

- [ ] No raw card-index constants or literals remain in either file
- [ ] Walk loops use the capped helpers
- [ ] Both files pass alone
