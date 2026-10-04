# 04 — Rooms move with HQ

**What to build:** Moving HQ (rent/buy, up or down, incl. forced arrears downgrade) keeps installed rooms instead of wiping them. Rooms whose minTier is above the new tier are dropped. If the new tier's `maxRooms` is below the remaining count, keep the most expensive (cost incl. bought seat upgrades) and drop the rest. Bought seat upgrades whose own minTier exceeds the new tier are dropped. Every dropped room/seat upgrade refunds 50% of what was paid. Staff seated in dropped rooms/seats are unseated. Security behaviour unchanged (already carries over, dropped by minTier). Harrow's move confirmation lists rooms kept, rooms dropped and refund total.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/home.gd` (`change_tier`, `_remove_room_effects`, `rent_to`, `buy_to`, `downgrade`, `security_lost_moving_to`), `systems/time_system.gd` (`_force_downgrade`), `systems/contacts.gd` (room seats), `data/home.json` (rooms, seatUpgrades, maxRooms), `scenes/phone_apps/property_app.gd`, `scenes/screens/hq_floorplan.gd`, `docs/adr/0006-property-bills-and-arrears.md` (amend), `docs/REFERENCE.md` §1.7, §3.3, §3.10 "Room seats"

**Status:** ready-for-agent

- [ ] Upgrade move keeps all rooms and seat upgrades
- [ ] Downgrade drops minTier-ineligible rooms, then keeps most expensive up to maxRooms
- [ ] 50% refund credited to cash and notified
- [ ] Forced arrears downgrade follows same rules
- [ ] Staff in dropped rooms unseated cleanly (no dangling assignedRoom)
- [ ] Harrow's confirmation shows kept/dropped/refund before committing
- [ ] ADR 0006 amended, REFERENCE.md updated, tests pass
