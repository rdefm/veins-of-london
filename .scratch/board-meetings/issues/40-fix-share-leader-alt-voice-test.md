# 40 — Fix: share_leader_has_james_alt_voice test aborts the suite

**What to build:** `tests/test_board_meetings.gd:230` (`share_leader_has_james_alt_voice_with_same_goal`) throws `SCRIPT ERROR: Invalid access to property or key 'voice' on a base object of type 'Dictionary'` at line 239 and halts `scripts/run_tests.sh` after 106 passes, so later tests never run.

**Diagnosis so far:** `BoardMeetings._build_card()` (`systems/board_meetings.gd:153`) returns `{}` when the ore/faction fails to resolve (`_resolve_ore` / `Overlaps.resolve_faction`). In the test's fresh `_enabled_game()` state the `share_leader` rung's ore doesn't resolve, so `a["voice"]` is missing. Not caused by ticket 24 (prose-only). Not yet checked against a clean checkout.

**Fix:** make the test set up state so the ore resolves (or assert on a resolvable ladder), or fix `_build_card` if resolution is wrongly failing. Then confirm the full suite runs to the end.

**Also (same sweep):** `scripts/check_all.sh` flags `CODEMAP.md:102` (row 414 chars, cap 400) and `tests/test_board_meetings.gd:215` (comment uses history vocabulary). Fix both.

**Relevant files:**
- `tests/test_board_meetings.gd`, `systems/board_meetings.gd`, `systems/overlaps.gd`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Test passes; full suite runs to completion
- [ ] `scripts/check_all.sh` clean
