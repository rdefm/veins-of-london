# 16 — Cultivation proposal evaluation

**What to build:** Evaluate whether guaranteed modest cultivation progress plus a possible bonus improves early maintenance pressure.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

This ticket authorizes investigation, decision capture and only the explicitly bounded prototype described below. Unresolved rules require human input; ready-for-agent means work can begin, not that proposed mechanics are approved.

- [ ] First obtain a decision on whether to explore guaranteed progress and approve bounded candidate baseline/bonus growth and XP parameters; current canonical production formulas remain unchanged.
- [ ] Compare the current model and approved candidates using the existing growth/drift model and three-block budget.
- [ ] Measure time to stabilise the first vein, failed-feeling actions per day, available bill-paying opportunities and pressure from a second vein.
- [ ] Preview guaranteed and bonus outcomes separately in the prototype; distinguish measured results from assumptions and test deterministic scenarios.
- [ ] Record the human evaluation and any approved next step; do not promote a candidate into production or claim unmeasured balance benefits.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

