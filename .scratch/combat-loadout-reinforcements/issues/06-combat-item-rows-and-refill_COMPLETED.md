# 06 — Combat item rows, read-only Bag, post-fight refill

**What to build:** In combat the command dock replaces the generic Item action with the player's two item rows, always visible. A filled row shows icon, name and tier; an empty or unusable row stays visible and disabled. Using a row spends that slot (Rewind from a slot spends the slot; Rewind from a Dial still spends only charge) and obeys selection, effect eligibility, playback lock and one-occurrence cost, with Rewind/Failsafe keeping their reactive timing. The Bag is read-only during combat. Nothing refills mid-fight. At settlement, a used slot refills from the highest available tier of its recipe in shared inventory (slot 1 before slot 2); if that fails it stays empty and later stock does not auto-fill it. Unused units stay equipped after win, loss, flight or KO. Rewind does not refund units.

**Blocked by:** 01, 04

**Relevant files:** `scenes/components/combat_command_dock.gd`, `scenes/components/bag_drawer.gd`, `scenes/screens/combat.gd`, `systems/combat.gd` (settlement, `selection_block_reason`), `systems/consumables.gd`, `systems/event_items.gd` (Rewind), `tests/test_combat.gd`, `tests/test_combat_screen.gd`, `tests/test_bag_drawer.gd`, `CODEMAP.md`. Update REFERENCE §3.7, §3.7a, §3.9 with the change.

**Status:** ready-for-agent

- [ ] Dock shows two item rows; no Item action; empty rows disabled (scene test)
- [ ] Bag offers no combat use and no loadout change while combat is active
- [ ] Full, partial and no refill cases; highest tier chosen; failed slot stays empty after later stock gain
- [ ] Unused units retained after win/loss/flee/KO; Rewind refunds nothing
- [ ] On-device QA block in report
