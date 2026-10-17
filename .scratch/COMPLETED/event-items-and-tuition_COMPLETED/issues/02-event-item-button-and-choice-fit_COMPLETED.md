# 02 — Event Item button replaces Rewind; choices fit or stack

**What to build:** Two event-screen changes, in both the VN and non-VN layouts.

1. **Item button.** The Rewind button becomes an Item button in the same position. Tapping it opens a popup menu listing the consumables and Dial complications usable right now in this event, each with its inventory qty or remaining charges. Picking one applies its effect. Which items and Dial effects are event-usable is a hardcoded list (a small registry: id, source consumable/Dial, eligibility check, effect), built so later items plug in without touching the screen. For now only Rewind is wired up, via the Rewind consumable or a loaded Dial Rewind complication, and it behaves exactly as Rewind does today (same snapshot pop and same spend rules). The Item button is hidden when nothing in the list is usable: no stock/charge, or nothing to rewind to yet.
2. **Choices fit or stack.** Choice buttons stay side by side in a row when all of them plus the Item button fit the width. When they don't fit, choices stack vertically, one full-width button each, so every option is visible and tappable. `col_a1_firm_intimidation` and `col_a2_hostile_member`, which have 3 choices, must show all options on a phone-width screen.

The screen only renders and calls system functions. Eligibility and effects live in systems, per the one-way data flow.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `scenes/screens/event.gd` (`_build_rewind_button`, non-VN action bar, `_build_vn_controls_row`, `_build_choice_button`); `systems/events.gd` (`can_rewind`, `rewind`); `systems/dial.gd` (`find_loaded_rewind_complication_index`, `cast_complication`); `systems/crafting.gd` (`inventory_qty`); `data/recipes.json` (`eventUsable`); `data/dial.json`; `data/events/col_a1_firm_intimidation.json`; `data/events/col_a2_hostile_member.json`; `tests/test_event_screen.gd`; `tests/test_events.gd`; other tests referencing the event Rewind button (grep `tests/`); `docs/REFERENCE.md` §1.3, §1.4, §3.5 Crafting & the Dial, §3.9 Snapshots & Rewind; `docs/ui-vision.md`; `CODEMAP.md`.

- [ ] Both layouts show an Item button where Rewind was. No standalone Rewind button remains.
- [ ] Tapping Item opens a popup listing each usable entry with its qty/charges. Choosing Rewind rewinds exactly as before, spending the consumable or Dial charge under the existing rules.
- [ ] The event-usable list is hardcoded in a system and contains only Rewind (consumable plus Dial). Adding a new entry needs no event-screen changes.
- [ ] The Item button is hidden when no entry is usable, including on the first card with nothing to rewind to and when there's no stock or charge.
- [ ] Choices and the Item button stay in one row when they fit. Otherwise choices stack vertically, full-width, in both layouts, and all 3 options of `col_a1_firm_intimidation` and `col_a2_hostile_member` are visible and tappable at phone width.
- [ ] The Continue path on non-choice cards is unchanged apart from the button swap.
- [ ] Tests cover eligibility (visible/hidden), Rewind via the popup (consumable and Dial), and the stack-vs-row decision. Syntax check clean, full suite passes.
- [ ] Report on-device checks: Item popup look and position in both layouts, the 2-choice row, the 3-choice stack, and the button hidden when nothing is usable.
