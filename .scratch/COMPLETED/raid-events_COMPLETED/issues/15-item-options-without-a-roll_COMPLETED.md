# 15 — Item options without a roll

**What to build:** An event option that needs an item but has no roll (e.g. Blast blows the window in; Prophet's Breath tells you exactly when the guards come) spends the item when the player commits it and applies the item's effect. Today a toggled item is spent only from a roll's modifiers, so a no-roll option would use the item without spending it. The greyed `?` modal still names the missing item when the player has none. Same rules as rolled options: spent on commit, Rewind refunds it, and the effect resolver takes a payment source (ticket 12 adds the Dial).

An item effect can also leave a **next-check-only lasting mod**: e.g. Time Pearl's freeze-and-rush-past is certain, but the next check in the event takes −0.15 (proposal §1.5). It shows in that check's odds breakdown under the item's name and is gone after that one check, whether it passed or failed.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (`choose()` ~L359–411 consume-on-commit, `item_toggles()` / `toggle_item()` ~L742–807, `apply_item_effect()` ~L808, `option_gate()` ~L588), `scenes/screens/event.gd` (toggle row for a no-roll option), `tests/test_event_items.gd`, REFERENCE.md §3.9a Event choice checks, §3.9 Snapshots & Rewind.

**Status:** ready-for-agent

- [ ] Schema for an item effect on a no-roll option documented in R§3.9a
- [ ] Tests: item spent on commit with no roll; effect applied; not spent when the option is only viewed; Rewind refunds; locked reason lists the missing item; a next-check-only mod applies to the next check only and shows in its breakdown
- [ ] Human on-device check: a no-roll item option shows the item and its count drops after commit
