# 04 — Recurring ore offers from Owen's join (Beat 3)

**What to build:** Today the Beat 2 starter chain stops once the market is proven, and recurring offers only start at Beat 6. So from Owen's join until James is in, the business pot gets little income and Owen's wage falls on the player's cash.

Fix that gap: from `bizA1OwenJoined`, Archie issues the existing recurring **ore** offers (`biz_recurring_time_ore`, `biz_recurring_life_ore`) with the same reissue/decline/never-expire handling the existing recurring issuer already uses.

- Before the new James beat (ticket 07), recurring offers are **ore-only**. The Time Pearl recurring offer isn't issued yet.
- One-off offers for items the player can make still appear as normal.
- Reconcile Beat 6's existing "two ore choices, not reissued while either runs" rule in the spec update, now that they start earlier. Keep the player choosing one if the spec intent still holds. If unsure, ask the human rather than guess.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/business_quest.gd` (`maybe_issue_recurring`, `maybe_issue_starter`, rollover hook), `systems/offers.gd`, `data/offers.json` (`biz_recurring_*`), `data/events/biz_a1_owen.json` (optional one-line Archie mention), `tests/test_business_quest.gd`, `.scratch/biz-act1/spec.md`, REFERENCE.md §3.10 "Business Empire questline (Beats 1–7)", `CODEMAP.md` (business_quest / offers.json rows).

**Status:** ready-for-agent

- [ ] From `bizA1OwenJoined`, rollover issues recurring ore offers when none is pending or active, respecting `recurringReissueDay`.
- [ ] No recurring item (Time Pearl) offer is issued before ticket 07's gate.
- [ ] Random and one-off item offers are unaffected.
- [ ] Existing saves already past Beat 3 start receiving the offers on the next rollover without breaking.
- [ ] REFERENCE.md and the biz-act1 spec are updated to the new issuance window.
- [ ] Tests cover the Beat 3 start, ore-only before the James beat, and decline → reissue next day.
