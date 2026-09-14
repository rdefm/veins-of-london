# 31 — [needs-info] Mixed one-off delivered-proportion formula

**What to build:** Nothing — this is a decision ticket. It blocks
ticket 32.

**Blocked by:** None — can start immediately.

**Status:** needs-info

business-spec.md leaves this open: for a mixed one-off (more than one
requested type), is the delivered proportion used at settlement weighted by
unit count or by quoted value across the requested types?

- [ ] Get a human decision on the weighting method before ticket 32 can be
  scoped.
- [ ] Record the approved formula in `docs/REFERENCE.md` (or wherever
  business-spec.md's formulas ultimately get promoted to canon) once
  decided.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
