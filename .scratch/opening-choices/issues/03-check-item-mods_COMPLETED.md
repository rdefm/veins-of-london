# 03 — Check item modifiers: equipped and optional consumables

**What to build:** Checks can be modified by items. An `equipped` item mod counts when the item is in the player's loadout. An `optional` item mod shows as a toggle under its option; it counts only while toggled on, and with `consume: true` the item is removed only when that option is committed. Toggle state lives in the event's state (pure data) so save and Rewind capture it, and the toggled set feeds the roll hash, so changing preparation after a Rewind can change the outcome.

**Blocked by:** 02 — Check core.

**Relevant files:** `systems/events.gd`, `systems/loadout.gd` (`player.loadout`), `systems/event_items.gd`, `scenes/screens/event.gd`, `scenes/components/item_icons.gd`, `tests/test_event_items.gd`, `tests/test_events.gd`, `tests/test_event_screen.gd`, `CODEMAP.md`. Spec "Item toggle in state", "Deterministic rolls".

**Status:** ready-for-agent

- [ ] `{ "item": "timePearl", "equipped": true, "add": …, "label": … }` counts only when equipped.
- [ ] Optional toggle stored in event state; odds query reflects current toggles; toggle unavailable when item not held.
- [ ] Consumed only on commit of the owning option; toggle-then-pick-other or rewind loses nothing (tests).
- [ ] Toggled item set is part of the roll key (alongside the roll count, REFERENCE §3.9a); changed toggle can change the roll (test).
- [ ] Toggle renders under its option in the existing card style.
- [ ] REFERENCE.md check-schema section updated.
