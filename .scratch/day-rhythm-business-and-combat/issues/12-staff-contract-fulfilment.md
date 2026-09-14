# 12 — Staff contract fulfilment

**What to build:** Players configure staff fulfilment in BizBrief and manage exceptions while its Morning Brief reports successful routine work.

**Blocked by:** 03 — Morning accounts; 11 — Manual recurring contracts.

**Status:** wontfix (deprecated — superseded by tickets 26, 28 and 30)

- [ ] Expose approved delegation, reserve quantities, priorities and spending limits; enforce approved unlock, capacity and wage/cost rules.
- [ ] Place staff controls and contract exceptions in BizBrief's Operations area; do not create a second staff-management app.
- [ ] Build on existing room/contact daily processing and the shared fulfilment operation; manual and staff execution enforce identical obligations.
- [ ] Respect reserve stock, budgets and affordability in the approved ordering, including competing contracts and limited capacity.
- [ ] Record successful output/payment in morning accounts and surface shortfalls for attention; routine successes do not trigger urgent auto-opening or haptics.
- [ ] Persist configuration and period identity; tests cover reserves, priority conflicts, spending limits, shortfalls and save/load without duplicate settlement.
- [ ] Device QA checks controls, account summaries and actionable exceptions.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
