# 26 — Sales delegation automation

**What to build:** A staffed Sales contact fulfils delegated contracts
automatically, without a manual delivery action.

**Blocked by:** 21 — Contact roles: Sales skill + unified role assignment;
25 — Manual fulfilment and settlement.

**Status:** ready-for-agent

- [ ] Delegation is an exclusive Sales automation assignment per contract —
  a delegated contract is not manually deliverable, and vice versa.
- [ ] Sales has no delivery-cap limit; it handles every delegated contract in
  the player-set priority order from ticket 25.
- [ ] After every increase in shared stock (crafting, Procurement, or
  unstashing), a staffed Sales immediately rechecks delegated contracts: if
  all remaining requested types for one can be supplied, it delivers them
  and closes that period immediately.
- [ ] At daily rollover, Sales also makes partial deliveries from available
  shared stock in priority order.
- [ ] Sales earns 5 XP for sourcing an offer (wire this here since it's the
  first ticket where a staffed Sales contact meaningfully exists;
  declined/expired offers earn no XP).

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
