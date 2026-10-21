# 15 — Prologue end-to-end test

**What to build:** One headless test that plays a new game through the whole Prologue (all 9 beats and the ending), asserting each beat's objective completes in order and the final state is right: rent paid, deposit goal set, gym unlocked, first vein claimed, Ticker article and emotion rise active, Des text queued. Keeps the chain from silently breaking when later content lands.

**Blocked by:** 06–14.

**Relevant files:** `tests/` (pattern: `tests/test_business_quest.gd`, `tests/test_col_a1_closer.gd`), `systems/events.gd`, `systems/combat.gd` (driving scripted/practice/demo fights headless), `systems/time_system.gd`.

**Status:** ready-for-agent

- [ ] Test passes on a fresh new game.
- [ ] Runs in seconds; no leaked EventBus connections (see `run_case`).
