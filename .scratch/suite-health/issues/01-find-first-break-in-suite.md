# 01 — Find the first break in the full suite

**What to build:** A diagnosis of why the full suite now cascades into thousands of script errors and 7 FAILs. First error in a full run: `Events.is_awaiting_choice()` crashes because `state.event` is null in the opening-chain test (gym step). Everything after (`'objectives'`/`'flags'`/`'player'` on a Dictionary, `Nonexistent function` on FactionAI/Intel statics) looks like a freed GameState and unloaded scripts. Establish whether that first error is the root cause or a symptom, whether `run_case` freeing the live GameState is involved (see memory project_full_suite_segfault, tickets 116/124), and which commit introduced it (candidates: storyboard-fast-wire 02/03, observation 08). No fix in this ticket; write the finding into this file.

**Blocked by:** None — can start immediately.

**Relevant files:** `tests/test_events.gd` (opening chain ~L1901–1978), `tests/test_base.gd` (`run_case`, EventBus cleanup), `tests/test_runner.gd`, `systems/events.gd` (`is_awaiting_choice` L~87, `start_event`), `autoload/GameState.gd` (`reset`). Use a fork subagent and redirect logs to a file; grep for the first `SCRIPT ERROR`.

**Status:** ready-for-agent

- [ ] First-error site reproduced in isolation (single file run) or shown to need the full run
- [ ] Root cause stated, with bisected commit if a regression
- [ ] Finding says which of the 7 FAILs and the test_demo_fight/test_district_events errors are cascade vs independent
