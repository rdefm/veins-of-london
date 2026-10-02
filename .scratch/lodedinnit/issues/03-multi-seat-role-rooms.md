# 03 — Multi-seat role rooms

**What to build:** Role rooms can hold more than one staffer. Each room has a seat count (default 1), upgraded from the HQ room card. Each extra seat costs 50% of the room's build cost (Station £4,000, Lab £7,500), capped by HQ tier: Station safehouse 1 / compound 2 / mansion 3; Lab compound 2 / mansion 3. Assigning to a room no longer evicts anyone while a seat is free. Founders still hold no seat.

**Blocked by:** 02 — All staff wages through the business.

**Relevant files:** `data/home.json` (`rooms.<id>.seatUpgrades`), `systems/home.gd`, `systems/contacts.gd` (`get_contact_in_room` → `contacts_in_room`, `assign_to_room`), `systems/rooms.gd`, `scenes/screens/hq_floorplan.gd`, `autoload/GameState.gd`, `autoload/SaveManager.gd`, `tests/test_rooms.gd`, `tests/test_contacts.gd`, spec §5, REFERENCE.md §2 + §3.10.

**Status:** ready-for-agent

- [ ] `home.roomSeats` in state, backfilled to 1 per room
- [ ] Seat upgrade purchase checks tier cap and cost; tested at each tier
- [ ] All single-occupant callers moved to `contacts_in_room()`
- [ ] Assigning into a full room is refused (no silent eviction)
- [ ] REFERENCE + CODEMAP updated
- [ ] Human check: HQ room card shows seats used/total and an upgrade button gated by tier
