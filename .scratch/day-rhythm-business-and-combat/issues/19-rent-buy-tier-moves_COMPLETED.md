# 19 — Rent/buy tier moves

**What to build:** In Harrow's Property app the player can:
- Move up one tier by **renting** (no up-front cost) or **buying** (the tier's buy price: £200k / £500k / £800k / £2m / £4m).
- **Buy out** their currently rented tier at the full buy price. The tier doesn't change, so rooms are kept.
- **Downgrade** one tier by choice. The player chooses rent or buy at the lower tier; the bedsit is rent only.

Every tier change goes through one shared system operation, which the forced downgrade in ticket 20 reuses. That operation:
- Wipes all installed rooms with no refund.
- Auto-unassigns any staff assigned to a wiped room.
- Reverts the Home Gym's `+hpMax` bonus if the gym was wiped, and clamps `hp` to the new max.
- On a downgrade, removes each security upgrade whose `minTier` is above the new tier. Everything else is kept. Guards follow the same `minTier` rule as their row.
- Sets the tenure.

The old `upgradeCost` purchase path is replaced.

**Blocked by:** 18 — Tenure-aware daily bill

**Relevant files:**
- `docs/adr/0006-property-bills-and-arrears.md` (Approved rules, Follow-up decisions)
- `systems/home.gd` (`upgrade_tier`, `get_next_tier_id`, `add_room` for the body-bonus shape, `add_security`/`guardCount`)
- `systems/contacts.gd` (`assignedRoom`, `assign_to_room`)
- `scenes/phone_apps/property_app.gd`
- `data/home.json`
- `autoload/GameData.gd` (drop the `upgradeCost` requirement if the key is removed)
- Tests: `tests/test_home.gd`, `tests/test_phone_property.gd`, and any contacts/rooms test that asserts room survival across an upgrade
- REFERENCE.md §1.7 `data/home.json` (including "Stackable HQ guards"), §3.3 Home, §3.10 Contacts, rooms, jobs
- CODEMAP.md (`home.gd`, `property_app.gd` rows)

**Status:** ready-for-agent

- [ ] Renting up costs nothing up front and sets `tenure: "rented"`. Buying up deducts the buy price, is refused when cash is short, is bank-logged, and sets `tenure: "owned"`.
- [ ] Buy-out converts a rented tier to owned at the full buy price. The tier, rooms and staff are unchanged. It is unavailable at the bedsit or when already owned.
- [ ] A voluntary downgrade moves one tier down with the player's choice of rent or buy. Buy is not offered at the bedsit, and there is no downgrade from the bedsit.
- [ ] Any tier change:
  - Empties `home.rooms` with no refund.
  - Unassigns staff whose room was wiped.
  - Reverts the gym bonus, with hp clamped.
  - On a downgrade, removes security (and guards) whose `minTier` exceeds the new tier.
  - Keeps everything else.
- [ ] The shared operation is callable by other systems, so ticket 20 can reuse it for the forced downgrade (forced downgrade = rented at the lower tier).
- [ ] The Property app offers rent/buy for the next tier, buy-out, and downgrade, each with its bill preview. The screen only calls system functions.
- [ ] New UI strings are flagged PROSE-REVIEW.
- [ ] REFERENCE.md §1.7/§3.3/§3.10 and CODEMAP.md are updated.
- [ ] Syntax check clean, full suite passes. The device check list covers the Property app.
