# 29 — [needs-info] Production target/contract-need combination formula

**What to build:** Nothing — this is a decision ticket. It blocks
ticket 30.

**Blocked by:** None — can start immediately.

**Status:** resolved

business-spec.md left this open: how does Production's personal inventory
target combine with outstanding contract need for the same item? For
example, does a personal target of 5 plus a contract need of 10 require 10
items in stock before Sales can draw stock, or 15?

**Decision:** additive, with the personal-target portion reserved. Production
crafts toward target+need combined (5+10=15). Sales may only draw the
contract-need portion; the personal-target reserve is never touched by
contract deliveries.

- [x] Get a human decision on the combination rule (additive, max-of, or
  another approach) before ticket 30 can be scoped.
- [x] Record the approved rule in `docs/REFERENCE.md` (or wherever
  business-spec.md's formulas ultimately get promoted to canon) once
  decided. Recorded in business-spec.md's "Production and Procurement"
  section (not yet promoted to REFERENCE.md — the feature hasn't landed
  there yet).

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
