# 02 — Contract with stock on hand not delivered or paid: diagnose + fix

**What to build:** Playtest report: the player accepted a Sales contract for Time Pearls and held enough pearls. The due date passed, the pearls were still in inventory, and no cash arrived. It's unknown whether Sales was staffed, whether Production's personal target was reserving the pearls, or whether the contract was an assay (min-tier) one.

Diagnose first. Reproduce headlessly across the candidate causes:
- no staffed Sales room (deliveries need `has_staffed_sales`)
- Production personal-target reserve excluding stock (`_shared_stock_for_line`)
- `minTier` excluding lower-ranked pearls
- tiered vs `_multi` inventory keys
- the daily tick or settle order around the due day
- settlement paid into the pot (the player sees no cash until payday)

Then fix any real bug. Where the behaviour is by design, the player must be able to see why: e.g. the contract card or Brief row says "not delivering: no Sales staff", "pearls reserved for personal target", or "needs rank N+". Don't change payment rules without asking.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/contracts.gd`, `systems/business.gd`, `systems/rooms.gd`, `systems/crafting.gd`, `systems/daily_brief.gd`, `scenes/components/contract_card.gd`. REFERENCE.md §3.10 "Business pot and payday", "Offer sourcing", "Assay commissions"

**Status:** ready-for-agent

- [ ] Diagnosis written into this ticket: which cause(s) reproduce, with the failing scenario
- [ ] Regression test in `tests/test_contracts.gd` covering the reproduced case
- [ ] Contract with sufficient deliverable stock delivers and settles; payment lands in pot or cash per R§3.10
- [ ] Any by-design non-delivery is explained to the player on the contract card or the Brief
