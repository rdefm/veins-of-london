# 10 — Contract and staff rules

**What to build:** Define a complete recurring-contract and staff lifecycle that implementation can execute without inventing balance.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

This ticket authorizes investigation, decision capture and only the explicitly bounded prototype described below. Unresolved rules require human input; ready-for-agent means work can begin, not that proposed mechanics are approved.

- [ ] Obtain an approved initial catalogue with quantities, payments, cadence, distinct due days, partial-delivery policy, missed-order consequences and time costs.
- [ ] Specify period/fulfilment identity, settlement idempotency, stock commitment, manual-versus-staff behaviour and save/load migration.
- [ ] Set staff unlocks, capacity, costs/wages, selected-contract delegation, reserves, priorities, spending limits and affordability policy.
- [ ] Specify exact daily ordering relative to production, raids, existing room/contact processing and settlement, including deadline boundaries and shortfalls.
- [ ] Provide worked examples for overlapping orders, limited stock/budget, partial delivery, missed deadlines and reload; record approvals in canonical mechanics as appropriate.
- [ ] Do not change production economics or complete this ticket while required policy or numbers remain unresolved.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

