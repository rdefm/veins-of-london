# 127 — Combat Item bag lists only combat-usable items

**Status:** ready-for-agent

**Blocked by:** None. Can start immediately.

**What to build:** In combat, the Item action (`combat_command_dock.gd:146` → `Bag.open()`) opens the full Bag drawer. `BagDrawer._build()` (`scenes/components/bag_drawer.gd:61`) shows Ore, **every** consumable (including ones at 0), Equipped weapon/Dial, and only then the "Use an item" buttons. While `combat.active` is true, the drawer should show **only** the combat-usable items the player has in stock, as use buttons.

Human decision:
- In combat: no Ore section, no full Consumables list, no Equipped/Dial summary.
- Keep what `_add_combat_use_buttons()` (`bag_drawer.gd:174`) already does: one button per combat item with qty > 0. The button is greyed with the reason appended when `Combat.selection_block_reason()` blocks it. Shield is greyed while `shieldPool > 0`. Rewind is greyed when there are no snapshots.
- Keep the "Bag" heading (or retitle it to match the Item action) and the Close footer.
- Out of combat (management mode, event item-hook mode): unchanged.

UI-only change. It must not change which items are usable. That rule stays with `Combat.COMBAT_ITEM_KEYS` / `has_usable_item()` (`systems/combat.gd:99`, :551).

**Relevant files:**
- `scenes/components/bag_drawer.gd`: `_build()` :61, `_add_combat_use_buttons()` :174, `_combat_use_button()` :218
- `scenes/components/combat_command_dock.gd` :146 (Item action)
- `systems/combat.gd`: `COMBAT_ITEM_KEYS` :99, `has_usable_item()` :551, `selection_block_reason()` :539
- `tests/test_bag_drawer.gd`
- REFERENCE.md §3.7 (combat item uses, ally-effect table)

- [ ] With `combat.active`, the drawer shows no Ore rows, no Consumables qty list, and no Equipped/Dial lines. It shows only the in-stock combat item buttons.
- [ ] Items at qty 0 and non-combat consumables (e.g. `healingSalve`) don't appear in combat.
- [ ] Greyed-with-reason behaviour stays as it is now.
- [ ] Management-mode and event item-hook drawers are unchanged.
- [ ] `tests/test_bag_drawer.gd` covers the combat-mode contents.
- [ ] Manual check for the human: in a fight, tap Item and confirm that only usable items show. Then open the bag out of combat and confirm the full view.
