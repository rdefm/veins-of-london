# 34 — Ship authored contract catalogue

**What to build:** Real scripted and random offer templates replace the
placeholder/test fixtures ticket 24 shipped the engine with.

**Blocked by:** 24 — Offer sourcing, quoting and acceptance; 33 —
[needs-info] Author scripted/random offer data catalogue.

**Status:** needs-info (blocked on ticket 33's decision)

- [ ] Author the approved template roster from ticket 33 as `data/*.json`
  content — request kind(s), weekday (for recurring), quantities within the
  approved bands, and expiry/deadline per template.
- [ ] Remove/retire the placeholder test fixtures ticket 24 used once the
  authored catalogue is live.
- [ ] PROSE-REVIEW any new player-facing offer copy against
  `docs/CONTENT-GUIDE.md`.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
