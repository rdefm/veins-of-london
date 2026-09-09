# 16 — HQ dial view: consolidated top block

**What to build:** The Dial screen's top chrome collapses the level readout
and the Movement section into one block: Dial level, the seated Movement (or
"inert" state), a "Craft new Movement" button that opens the `movement_craft`
modal directly (rather than the general `craft_components_menu`), and a
"Swap" button that opens a picker over `player.movementInventory` to seat a
different already-crafted Movement. This replaces today's layout, where
every inventory Movement renders as its own standalone "Seat" card below the
seated one — the picker is what those cards become, moved behind one button
tap instead of always-rendered.

Wind/charge readouts and the Unseat action stay as they are today, just
inside this consolidated block.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] Top block shows Dial level + seated Movement (or the inert-state copy) in one place
- [ ] "Craft new Movement" opens `movement_craft` directly
- [ ] "Swap" opens a picker listing `movementInventory`, seating the chosen entry via `Dial.seat_movement` (unchanged system call)
- [ ] The old always-rendered per-inventory-item "Seat" card list is removed
- [ ] Unseat/Wind actions still work, unchanged behaviour
- [ ] `tests/test_hq_dial.gd` updated for the new layout
