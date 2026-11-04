# 90 — Audit the `SCRIPT ERROR`s in the suite log

**What to build:** The full run logs `SCRIPT ERROR` lines even where cases pass: missing keys `voice`, `enemyQueue`, `intro`, `moves`, `type`; array index 17; `questline` (from `Todo.get_questline_sections` with synthetic objective defs in test_objectives); `art_size`/`band_low` on Nil. For each, decide: a real bug (fix it) or a deliberate negative-path test (make the fixture complete so the log is quiet).

**Blocked by:** 87 (save-state errors may disappear once it lands).

**Relevant files:** `tests/test_objectives.gd`, `systems/todo.gd`, `tests/test_runner.gd`, `scripts/run_tests.sh` (`MAX_SCRIPT_ERRORS` fail-fast), full-suite log grep for `SCRIPT ERROR`

**Status:** done

- [ ] Each error has a recorded disposition
- [ ] Full run logs zero `SCRIPT ERROR` lines

## Dispositions
- questline (66): fixture bug, `_objective()` + 2 raiding fixtures lacked `questline`.
- voice: fixture, no market ore for `$ore` placeholder -> `_build_card` returned {}.
- enemyQueue: stale case, 0-guard squad starts no fight; case now `guarded`/0 extras. Stale comment in events.gd fixed.
- index 17 / type: test leaked cold-open scripted fight into gym; helper `_finish_scripted_fight`.
- intro: stale event id -> `prologue_cold_open`.
- moves: REAL validator bug, `_validate_combat_rounds` indexed missing moves/items; now `.get`.
- art_size: stale node name (`DockedBook`); + stale panel-count assertion.
- band_low: test ignored bench tap guard window.
- observation choices/display: test needed `advance()` after Rewind.
- card_theme set_stylebox: `Main.new()` has no theme; test sets one.
- text on Nil (turn order): REAL bug, `badge_label` never assigned so badge never flipped.
- VBoxContainer->Button: Manage is last action, not index 3.
