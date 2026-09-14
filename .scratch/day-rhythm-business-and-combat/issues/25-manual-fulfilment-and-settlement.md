# 25 — Manual fulfilment and settlement (single-type contracts)

**What to build:** Players track, prioritise, and manually fulfil accepted
single-request-type contracts through to settlement.

**Blocked by:** 22 — Personal stash; 23 — BizBrief Manage tab shell;
24 — Offer sourcing, quoting and acceptance.

**Status:** ready-for-agent

- [ ] A contract tracks delivered quantity separately per requested type
  (one type, for this ticket — mixed one-offs are ticket 32).
- [ ] Manual delivery costs one time block per delivery action regardless of
  quantity, and may be partial. Manual delivery is available only for
  non-delegated contracts (delegation is ticket 26).
- [ ] The player drag-reorders active contract cards in BizBrief Manage >
  Sales; this single priority order is stored as pure state and will drive
  both Production allocation (ticket 30) and Sales partial delivery
  (ticket 26).
- [ ] At deadline: a complete contract pays its full snapshotted quote; an
  incomplete contract settles for `quote × delivered proportion × 0.80`
  (rounded to whole pounds; zero delivery pays £0). A recurring period then
  creates its next weekly period even after a short settlement; a one-off
  closes permanently.
- [ ] Sales XP: 20 XP for a completed contract, 10 XP for a penalised
  partial settlement.
- [ ] Every offer, contract, period, and settlement has a stable id.
  Settlement records its id before cash is credited, so reload/resume/retry
  cannot double-pay or double-renew.
- [ ] Active-contract reference/history is visible in BizBrief Manage >
  Sales.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
