# 06 — Audit remaining suite ERROR noise and leaks

**Status:** done

**What to build:** After tickets 01-05, review a full `scripts/run_tests.sh` log for remaining `ERROR:`/`SCRIPT ERROR` lines. Many (`Events: goto ...`, `Parse JSON failed`, `b64_decode`) are expected output from negative-path tests; confirm and list them. Investigate the exit-time warning "1106 ObjectDB instances were leaked" and RID leaks, and fix only if they reflect real leaks in tests (see memory: run_case frees GameState). Report findings; don't silence real errors.

**Blocked by:** 01, 02, 03, 04, 05

**Relevant files:** `tests/test_base.gd`, `tests/test_runner.gd`, `scripts/run_tests.sh`

- [ ] Full suite log has no unexplained ERROR lines
- [ ] Leak warning explained or fixed

## Findings (full suite: 4753 passed, 0 failed, ~5m47s)

31 ERROR lines, all expected negative-path output, no real errors:
- `Events: goto ...` / `hub card ... no forward exit` / `no card keyed 'nope'` / `start_fight ... win or lose card` / `kit guardKit` / `unknown event id 'no_such_event'` — test_events fixtures (`test_gated_event`, `test_routed_event`, `test_walk_event`, `test_event_fight_event`, `demo_hub_questions`) exercising validators.
- `Combat: unrecognized context 'raidd'` — deliberate typo test.
- `Parse JSON failed ... 'not'`, 2x `b64_decode` — savemanager corrupt-save tests.

Exit-time leaks (1106 ObjectDB, 383 CanvasItem RIDs, 294 shaped-text, 17 textures/resources): off-tree Control/screen nodes instantiated by UI tests (test_app_tile, test_bag_drawer, test_combat_command_dock, ...) and not freed before `quit()`. Test-only, process exits right after TOTAL line; no GameState/EventBus leak (run_case handles those). Not fixed: per-test freeing is churn with no behavioural payoff, and freeing risks the use-after-free class seen in ticket 116/124.
