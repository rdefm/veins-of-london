# 90 — Audit the `SCRIPT ERROR`s in the suite log

**What to build:** The full run logs `SCRIPT ERROR` lines even where cases pass: missing keys `voice`, `enemyQueue`, `intro`, `moves`, `type`; array index 17; `questline` (from `Todo.get_questline_sections` with synthetic objective defs in test_objectives); `art_size`/`band_low` on Nil. For each, decide: a real bug (fix it) or a deliberate negative-path test (make the fixture complete so the log is quiet).

**Blocked by:** 87 (save-state errors may disappear once it lands).

**Relevant files:** `tests/test_objectives.gd`, `systems/todo.gd`, `tests/test_runner.gd`, `scripts/run_tests.sh` (`MAX_SCRIPT_ERRORS` fail-fast), full-suite log grep for `SCRIPT ERROR`

**Status:** ready-for-agent

- [ ] Each error has a recorded disposition
- [ ] Full run logs zero `SCRIPT ERROR` lines
