# 05 — Events draw on the stash

**What to build:** Events count and spend stashed items and ore through the player spend seam. This covers event requirements, mods, item offers and costs.

**Blocked by:** 04

**Relevant files:** `systems/events.gd`, `systems/event_items.gd`, `systems/stash.gd`, `tests/test_events.gd`, `tests/test_event_items.gd`, `tests/test_stash.gd`, REFERENCE.md §3.9a Event choice checks

**Status:** ready-for-agent

- [ ] An item or ore requirement is met by stashed stock alone
- [ ] Mods, item offers and costs can spend stashed stock
- [ ] Shared is spent first and tiers are preserved
- [ ] Item tier scaling reads the unit actually spent
- [ ] REFERENCE.md §3.9a is updated
