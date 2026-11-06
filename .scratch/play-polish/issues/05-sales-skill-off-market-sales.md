# 05 — Sales skill: off-market sales

**What to build:** A better salesperson can place extra stock with private buyers outside London's market. Those units earn the normal price but don't lower it, so levelling Archie's Sales skill directly raises passive income without destabilising the market.

**Rule (user-approved, all in `data/market.json`)**

- Off-market units per day = on-market daily limit × `0.10 × (salesSkill − 1)`, rounded down. Sales skill tops out at level 5, so that's nothing at level 1, +10% at level 2, +20% at level 3, +30% at level 4, +40% at level 5.
- They come only from surplus left after on-market sales, and the same protected floor and minimum price apply.
- Payment matches an on-market sale: quote × quality multiplier.
- They skip the market supply record, so stock and price don't move.
- The Morning report and the ticket 04 live line show them separately, e.g. "+2 placed privately".

**Also approved:** off-market units don't count toward London market share. Skill comes from `Contacts.sales_contact()`.

Add the rule to `docs/REFERENCE.md` in the same commit.

**Blocked by:** 03 — Daily auto-sell pass. The live-line part also needs 04; if 04 isn't done, add it there instead.

**Relevant files:** `systems/auto_sell.gd`, `systems/contacts.gd` (`sales_contact`), `systems/contracts.gd`, `systems/offers.gd` (`sales_skill`), `systems/market.gd`, `systems/shares.gd`, `systems/morning_accounts.gd`, `scenes/phone_apps/bizbrief_app.gd`, `data/market.json`; REFERENCE §3.6 Selling, §3.13

**Status:** ready-for-agent

- [ ] Level 1 gives no off-market sales
- [ ] Higher levels sell more per day at the expected rate
- [ ] Off-market units leave the London price and stock unchanged
- [ ] They never breach the protected floor, the minimum price or the available surplus
- [ ] Report and live line show them separately
- [ ] Numbers come from data
- [ ] `tests/test_auto_sell.gd` covers the above
- [ ] REFERENCE updated
