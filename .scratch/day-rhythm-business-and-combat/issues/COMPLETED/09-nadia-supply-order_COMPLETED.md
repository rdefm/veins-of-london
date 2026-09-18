# 09 — Nadia supply order

**What to build:** Players explicitly supply Nadia’s approved cumulative order and continue into the existing vein-sale story.

**Blocked by:** 08 — Nadia order decisions.

**Status:** ready-for-agent

- [ ] Implement approved thirty-unit time-calc requirement through an explicit supply operation, with delivered/required/remaining quantities and payment visible before delivery.
- [ ] One or several deliveries count equally; validate stock, eligibility, partial/over-delivery policy and action costs from ticket 08.
- [ ] Progress, stock and cash update consistently; repeated settlement cannot duplicate payment or completion rewards.
- [ ] Apply approved migration to partial saves, preserve completed objectives and continue into the existing vein-sale request without replaying rewards.
- [ ] Keep unrelated trades independent; test public deliveries, insufficient stock, repeated settlement and migration fixtures.
- [ ] Device QA checks supply/progress/payment presentation; flag new player-facing prose for review.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

