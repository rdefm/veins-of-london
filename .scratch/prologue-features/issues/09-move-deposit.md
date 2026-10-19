# 09 — Move deposit on rented moves

**What to build:** Moving to a rented home costs a **deposit** up front (N weeks' rent, placeholder in data), returned when the player moves out of that tenancy. Harrow's shows the deposit on each listing and refuses a rented move the player can't cover. This gives the post-flat-raid "earn enough to move somewhere safer" goal a real number. First, confirm the current rent/bills model and fix the stale docs: REFERENCE §1's property table still says rent is `dailyCost`, and ADR 0006 says "daily bill". Source: `docs/story-restructure.md` "Motivation spine", "Features to build" item 5.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/home.gd` (`change_tier` L298, `rent_up` L439, `rent_to` L455, `bill_base_for` L188), `scenes/screens/property_app.gd` (Harrow's), `data/constants.json`, `docs/adr/0006-property-bills-and-arrears.md`. REFERENCE §1 property table, §3.3 Home "Tier moves", Bills.

**Status:** ready-for-agent

- [ ] REFERENCE §1/§3.3 and ADR 0006 describe the actual current rent/bills model. If the code and docs disagree, stop and ask before changing either.
- [ ] A rented move charges the deposit, held in state, and refunds it on the next move out of that tenancy (to any tier/tenure).
- [ ] A rented move is refused when cash is below the deposit, with a clear reason. Buying is unchanged.
- [ ] Harrow's shows the deposit per rentable listing.
- [ ] Deposit weeks are in data. Tests cover charge, refund, refusal and save round-trip.
