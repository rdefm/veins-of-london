# 04 — Migrate test_events.gd to card keys

**What to build:** The core event-runner tests assert on card keys instead of indexes wherever the fixture cards define keys (adding keys to fixtures where missing).

**Blocked by:** 01

**Relevant files:** `tests/test_events.gd` (~39 `cardIndex` sites), `systems/events.gd`.

**Status:** ready-for-agent

- [ ] Index assertions replaced by key assertions, or by looked-up indexes
- [ ] Indexes that are the thing under test (e.g. jump arithmetic) are kept and noted with a comment why
- [ ] File passes alone
