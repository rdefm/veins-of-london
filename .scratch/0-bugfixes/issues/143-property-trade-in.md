# 143 — Property trade-in: your current home counts toward the new one

**What to build:** When the player owns their home and moves to another tier, the current home is sold at its full buy price and that value goes to the player. Buying another tier costs its price minus the current home's value (own the £200k flat, buy the £800k place → pay £600k); if the new place is cheaper, the player is paid the difference. Moving from owned to rented credits the full value. Each move shows in the bank ledger (sale credit + purchase). The affordability check uses the net cost. Harrow's listings and particulars make the maths clear when the player owns their home, e.g. "£800k · Sell your flat −£200k · You pay £600k" (or "You receive £X" on a downgrade), and the rent option shows the sale credit. Rooms are still wiped on any move (unchanged). A rented home has no value — no change there.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/home.gd` (`_buy_move`, `buy_to`, `rent_to`, `downgrade`, `buy_price`, `change_tier`), `scenes/phone_apps/property_app.gd` (~L181, L199, L376, L447 price display + buy button), `systems/bank.gd` (`Bank.record`), `docs/adr/0006-property-bills-and-arrears.md`; REFERENCE.md §3.3 "Home", §1.7 `data/home.json`. Update REFERENCE §3.3 with the trade-in rule.

**Status:** ready-for-agent

- [ ] Owned → buy pricier tier: pays net difference; tested
- [ ] Owned → buy cheaper tier: receives difference; tested
- [ ] Owned → rent any tier: receives full value; tested
- [ ] Rented → buy: pays full price (unchanged); tested
- [ ] "Not enough cash" uses net cost; tested
- [ ] Ledger records the sale credit and the purchase
- [ ] Listings/particulars show price, sale credit and net pay/receive when owned
- [ ] PROSE-REVIEW: any new listing/notification strings
- [ ] Human on-device: own a flat, open Harrow's — each listing shows the breakdown; upgrade and check cash moves by the net amount
