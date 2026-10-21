# 07 — Practice rack: list picker

**What to build:** In the spar preparation sheet, tapping a practice-rack slot opens a list of the available rack items to pick from. This replaces tapping repeatedly to cycle through every item. The list includes an "empty" option.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/combat_prep.gd` (spar practice-rack slot cycler), `systems/combat_prep.gd`, `systems/sparring.gd` (`rack_items()`), `scenes/components/map_card_style.gd` (option rows), `tests/test_combat_prep.gd`, `tests/test_sparring.gd`.

**Status:** ready-for-agent

- [ ] Tapping a rack slot opens a selectable list of rack items (icon + name)
- [ ] Picking an item sets that slot and closes the list; the current pick is marked
- [ ] Tap-to-cycle removed
- [ ] The screen calls system functions only and never mutates state directly
- [ ] Headless test: opening the picker and selecting an item sets the slot
