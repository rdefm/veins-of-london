# 03 — Migrate fight-op tests to card keys

**What to build:** Event-fight, scripted-fight and demo-fight tests express win/lose/resume destinations and post-fight assertions by card key.

**Blocked by:** 01

**Relevant files:** `tests/test_event_fight.gd` (`WIN_CARD`, `LOSE_CARD`), `tests/test_scripted_fight.gd`, `tests/test_demo_fight.gd`, REFERENCE.md §3.7b Event fights / Scripted fights / Demo fights.

**Status:** ready-for-agent

- [ ] No raw card-index constants or `cardIndex ==` literals remain in the three files
- [ ] Where a test checks an index passed to an op (`winCard`, `resumeCard`), it compares to the looked-up key index
- [ ] All three files pass alone
