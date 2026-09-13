# 11 — Manual recurring contracts

**What to build:** Players manage and fulfil recurring orders in BizBrief with visible obligations, due dates, payment and shortfall consequences.

**Blocked by:** 03 — Morning accounts; 10 — Contract and staff rules.

**Status:** ready-for-agent

- [ ] Implement the approved initial catalogue and lifecycle, showing quantity/progress, distinct due day, payment and remaining obligations before explicit delivery.
- [ ] Add contract planning and delivery to BizBrief's Operations area, extending the reporting app rather than creating another business app or parallel ledger.
- [ ] Use a shared business fulfilment operation suitable for later staff execution; enforce approved stock, partial-delivery, action-cost and deadline rules.
- [ ] Store period and fulfilment identity as pure data; repeated settlement/load cannot double-pay or consume stock twice.
- [ ] Advance recurring periods and surface missed-order exceptions according to ticket 10; preserve the approved daily processing order.
- [ ] Test public operations for overlapping periods, insufficient stock, deadlines, repeat settlement and save/load; device QA checks contract planning and delivery screens.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
