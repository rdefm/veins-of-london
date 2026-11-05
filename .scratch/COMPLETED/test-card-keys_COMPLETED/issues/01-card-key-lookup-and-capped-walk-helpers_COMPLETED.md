# 01 — Card-key lookup and capped walk helpers

**What to build:** Tests can find a card's index from its key, read the live card's key, and walk an event to a named card or to its end with a hard iteration cap that fails with a clear message instead of hanging. Purely additive; no existing test changes.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (`live_cards`, `_goto_index`), `tests/test_base.gd`, `tests/test_events.gd`, REFERENCE.md event cards section (grep `key`).

**Status:** ready-for-agent

- [ ] Public lookup from event id + card key to index; unknown key is an error, not -1 silently
- [ ] Public read of the live event's current card key
- [ ] Test-base helpers advance to a named card and finish an event, both capped and failing with the event id, target key and last key seen
- [ ] Helpers have their own tests, including the cap tripping
- [ ] `_goto_index` reuses the public lookup (no duplicate logic)
