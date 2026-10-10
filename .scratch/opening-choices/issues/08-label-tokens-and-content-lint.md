# 08 — Card label tokens and event content lint

**What to build:** Card labels may use tokens for the current weekday/date and relative day so they can't drift. A data test over every event file fails when: a label's time words ("tonight", "morning", "tomorrow"…) contradict the event's `at`; a `goto` doesn't target a later card in the same event; a modifier or `requires` references an unknown flag, item, contact or state path; an option has both fixed `result_text` and a `check`.

**Blocked by:** 05 — requires/goto; 06 — event timing.

**Relevant files:** `systems/events.gd` (label resolution in `current_card`/`revealed_cards`), `systems/calendar.gd`, `data/events/*.json`, new `tests/test_event_content_lint.gd` (style of `tests/test_district_events.gd`), `data/recipes.json`, `data/constants.json` (known items/contacts), `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Tokens resolve from calendar + current block; documented in REFERENCE.md.
- [ ] Lint covers all four rules and runs in `scripts/run_tests.sh`.
- [ ] Opening-chain violations are expected (fixed by 12–21): mark them as a known list the content tickets shrink, not an allowlist that hides new ones.
- [ ] Violations in non-opening events: report; fix only if trivial, else list for owner.
