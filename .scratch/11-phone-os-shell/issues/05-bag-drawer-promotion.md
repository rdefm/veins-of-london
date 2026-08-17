# 05 — Bag drawer promotion

**What to build:** Promote the bag drawer from read-only quick-peek to full inventory management, so it can safely absorb everything the standalone inventory screen does today.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Player can equip/unequip weapon from the drawer
- [ ] Player can equip/unequip device from the drawer
- [ ] Player can start, attempt to build, and abandon a device from the drawer
- [ ] Drawer opens from any screen, as it does today
- [ ] During combat, the drawer reverts to read-only contents plus legal Use buttons only — management controls hidden
- [ ] During an event card carrying item hooks, same read-only-plus-Use-buttons gating applies
- [ ] Outside combat/events, the drawer is taller and scrollable, and does not swallow drag-to-scroll
- [ ] Tests cover: equip/unequip and device lifecycle actions produce identical state changes to today's inventory screen; management controls confirmed hidden during combat and during item-hook events; drag-to-scroll works outside those contexts
