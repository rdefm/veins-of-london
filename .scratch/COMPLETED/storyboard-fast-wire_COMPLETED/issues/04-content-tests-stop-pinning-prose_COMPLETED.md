# 04 — Content tests stop pinning prose

**What to build:** Tests over live events assert on what the event does — which card key is reached, which flags/effects land, which ending plays — never on exact text or card position. Tests that play an event through pick options by option id, not position. A text-only edit to any live event leaves the suite green; a structural change fails only tests that care about that structure.

**Blocked by:** 02 — Live cards carry stable keys.

**Relevant files:** `tests/test_col_a1_archie_pry.gd`, `tests/test_col_a1_closer.gd`, `tests/test_col_a1_des_report.gd`, `tests/test_col_a1_nadia_done.gd`, `tests/test_col_a1_weather.gd`, `tests/test_prologue_chain.gd`, `tests/test_cold_open.gd`, `tests/test_wren_introduction.gd`, `tests/test_gym_event.gd`, `tests/test_playthrough.gd`, live-event cases in `tests/test_events.gd`, `tests/test_base.gd` (shared helpers), `systems/events.gd` (`choose`, `hub_exit_index`).

**Status:** ready-for-agent

- [ ] No test asserts exact prose or `cards[N]` positions of a live (`data/events/`) event; synthetic test fixtures may keep theirs
- [ ] Play-through tests choose by option id via a shared helper
- [ ] Demonstrated: a throwaway text edit to a live event's card keeps the suite green (revert after)
- [ ] Full suite + `scripts/check_all.sh` green
