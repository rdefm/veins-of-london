# 01 — Find the first break in the full suite

**What to build:** A diagnosis of why the full suite now cascades into thousands of script errors and 7 FAILs. First error in a full run: `Events.is_awaiting_choice()` crashes because `state.event` is null in the opening-chain test (gym step). Everything after (`'objectives'`/`'flags'`/`'player'` on a Dictionary, `Nonexistent function` on FactionAI/Intel statics) looks like a freed GameState and unloaded scripts. Establish whether that first error is the root cause or a symptom, whether `run_case` freeing the live GameState is involved (see memory project_full_suite_segfault, tickets 116/124), and which commit introduced it (candidates: storyboard-fast-wire 02/03, observation 08). No fix in this ticket; write the finding into this file.

**Blocked by:** None — can start immediately.

**Relevant files:** `tests/test_events.gd` (opening chain ~L1901–1978), `tests/test_base.gd` (`run_case`, EventBus cleanup), `tests/test_runner.gd`, `systems/events.gd` (`is_awaiting_choice` L~87, `start_event`), `autoload/GameState.gd` (`reset`). Use a fork subagent and redirect logs to a file; grep for the first `SCRIPT ERROR`.

**Status:** ready-for-agent

- [ ] First-error site reproduced in isolation (single file run) or shown to need the full run
- [ ] Root cause stated, with bisected commit if a regression
- [ ] Finding says which of the 7 FAILs and the test_demo_fight/test_district_events errors are cascade vs independent

## Finding (2026-10-25)

Full run at HEAD 2b097bc6 (~5 min): `TOTAL: 4160 passed, 0 failed`, 284 SCRIPT ERRORs, **no cascade, no Nonexistent-function, 0 FAILs**. Ticket's "7 FAILs / thousands of errors / freed GameState" NOT reproduced.

**Environmental suspect:** C: was 100% full (44M free of 119G) during the run; a worktree attempt failed with ENOSPC. The ticket's cascade run likely happened under disk exhaustion (saves/caches/script reload failing → unloaded scripts, freed state). Not confirmed; re-check ticket 02+ only after freeing disk. Also stale worktree `../vein-preregression` (196M) and 7.5G in repo dir (.godot etc.).

**First error is a symptom/noise, not root cause, and reproduces in isolation** (`godot --headless -s tests/test_runner.gd -- test_events.gd` → 27x events.gd:89, 113 pass, 0 fail). Cause: gym step loop (test_events.gd ~L1962-1978) runs fixed `range(30)`, no break; once the event ends `state.event == null`, and the `elif Events.is_awaiting_choice()` is evaluated before the `event != null` guard → typed-assign Nil error. Loop pre-dates the window (gym loop from 3078b65e prologue-act 10; `var event_state: Dictionary = ...["event"]` from cac7fcf2 M1-LONDON-T08). Not a regression from storyboard-fast-wire 02/03 or observation 08. Bisect via worktree not possible (disk full).

**Error attribution by file (all independent, none cascade):**
- test_playthrough.gd 241: events.gd:233 `_continue` / :793 `_snapshot_before_mutation` with null event (driver advancing after event end; same class as above).
- test_events.gd 27: gym loop above.
- test_train_live_tree.gd 9 (card_theme.gd null nodes), test_ticker_news.gd 3, test_lab_screen.gd 1 (`_assert_gauge_band` band_low on Nil): test-side null derefs, each ran green.
- test_gamedata.gd 3: expected — corrupt-fixture tests (`_validate_combat_rounds` moves, etc.) intentionally feed bad data; assertions PASS.
- test_demo_fight / test_district_events: no SCRIPT ERRORs this run (only expected push_error lines).
- run_case freeing GameState (116/124): not implicated this run.

Follow-up suggestions (not done): guard `is_awaiting_choice`/`_snapshot_before_mutation` callers in tests with `event != null` / break; free disk then re-run full suite for the 7-FAIL claim.
