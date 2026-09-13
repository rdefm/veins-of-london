# 17 — Bills decision

**What to build:** Resolve financial-pressure and recovery rules before scheduling any production bills change.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

This ticket authorizes investigation, decision capture and only the explicitly bounded prototype described below. Unresolved rules require human input; ready-for-agent means work can begin, not that proposed mechanics are approved.

- [ ] Compare current fixed-base daily charging, property tier cost data and zero-cash behaviour against canonical mechanics.
- [ ] Obtain explicit decisions on property-based costs, arrears or their absence, zero-cash consequences and recovery opportunities; do not select numbers implicitly.
- [ ] Specify daily ordering, affordability boundaries, migration and how morning accounts would explain consequences.
- [ ] Record approved rules and worked examples for sufficient cash, zero cash, repeated shortfall and recovery, or explicitly record retaining current behaviour.
- [ ] Leave production bills unchanged; any resulting implementation requires a separately scoped ticket.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

