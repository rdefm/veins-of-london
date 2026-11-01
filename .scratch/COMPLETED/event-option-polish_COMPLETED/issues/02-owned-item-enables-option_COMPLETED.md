# 02 — Owned item makes item option usable

**What to build:** An option gated on an optional item (e.g. raid_shop "Open a Wormhole", Prophet's Breath) is no longer greyed out when the player owns the item. It shows enabled with the item pre-toggled; tapping it commits the option and spends the item exactly as committing with a manual toggle does today. Not owning the item keeps today's disabled state and ? reason. The player can still untoggle the item in the ? modal (option then greys if the item was what unlocked it).

**Blocked by:** None — can start immediately

**Relevant files:** `systems/events.gd` (`option_gate`, `_requires_met`, `active_toggles`, `item_toggles`, `_optional_mods`, `choose`), `scenes/screens/event.gd` (`_build_item_toggle`, `_restore_context_modal`, `_fill_options`), `data/events/raid_shop.json` (~L333, ~L542), `tests/test_events.gd`. REFERENCE §3.9a Event choice checks.

**Status:** ready-for-agent

- [ ] Owned unlock-item → option display "show", item counted as toggled by default
- [ ] Tapping commits and consumes the item once
- [ ] Not owned → disabled with reason, as now
- [ ] Bonus-only items (e.g. Enhancement Powder) not auto-toggled — confirm/keep current behaviour
- [ ] Rewind restores item + toggle state
- [ ] Tests for owned / not owned / commit spends
