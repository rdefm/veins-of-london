# 33 — [needs-info] Author scripted/random offer data catalogue

**What to build:** Nothing — this is a content/decision ticket. It blocks
ticket 34.

**Blocked by:** None — can start immediately.

**Status:** needs-info

business-spec.md leaves this open: the exact roster of scripted/random offer
templates — which requests exist, their request kinds, weekdays, quantity
picks within the approved bands, and scripted expiry/deadlines.

- [ ] Get the human-approved template roster (scripted and random) before
  ticket 34 can be scoped.
- [ ] Land the approved catalogue as `data/*.json` content once decided,
  matching the schema ticket 24 built the engine against.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
