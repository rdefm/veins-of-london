# 03 — Nav shell + BagDrawer

**What to build:** the 5-tab nav (Map · HQ · Phone · Bag · You) with a persistent top bar (cash · day/time-blocks · bag button) replacing the M0 bottom nav, per D4. Tab content for HQ/Phone/You may be a stub screen at this point (they're built out in tickets 06/07); the Bag tab and the global `BagDrawer` bottom-sheet must be fully functional per D4.4, including `format_cost_label(cost, holdings)`.

**Blocked by:** None — can start immediately, independent of tickets 01/02.

**Status:** ready-for-agent

- [ ] 5-tab nav present and navigable; persistent top bar shows cash, day/time-blocks, bag button on every screen
- [ ] `BagDrawer` opens as a bottom sheet from ANY screen, including mid-event and mid-combat, without costing a turn/block/advancing anything
- [ ] BagDrawer shows ore counts (all 5, with symbols), consumable counts, equipped weapon/device, device charges remaining; read-only outside combat/itemHook contexts
- [ ] `format_cost_label(cost, holdings)` helper implemented and unit-tested; produces strings like "Seed — 40 physics (have 52)"
- [ ] Human visual QA: navigate all 5 tabs; open BagDrawer from at least two different screens
- [ ] `godot --headless --check-only --script` clean on all touched files
