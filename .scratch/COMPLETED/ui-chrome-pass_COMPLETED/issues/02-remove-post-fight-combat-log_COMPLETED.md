# 02 — Remove post-fight combat log

**What to build:** `scenes/screens/combat.gd::_sync_footer()` currently
renders a 6-line dot-matrix recap (`_build_log()`) alongside the outcome
button once a fight ends. Human direction: drop it entirely — the mid-fight
ticker (routed live into the notification board per field-kit-chrome
ticket 03) already shows everything as it happens; a static recap
afterward is redundant. The footer should show only the outcome button
once the fight resolves.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `_sync_footer()` no longer builds or shows a post-fight log board
- [ ] `_build_log()` and `OUTCOME_LOG_LINES`/`OUTCOME_LOG_DOT_SIZE` removed if no longer used anywhere else
- [ ] Outcome button still appears in the same place/timing as before (only once playback has fully finished)
- [ ] `tests/test_combat_screen.gd` updated to drop assertions on the removed log, and to assert it's absent
