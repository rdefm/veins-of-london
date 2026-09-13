# 06 — Non-intervention decision

**What to build:** Resolve what deliberately leaving a raid undefended means before introducing that response.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

This ticket authorizes investigation, decision capture and only the explicitly bounded prototype described below. Unresolved rules require human input; ready-for-agent means work can begin, not that proposed mechanics are approved.

- [ ] Present current pending-defence timing and consequences, then obtain an explicit choice between immediate resolution and recording non-intervention until the existing deadline.
- [ ] Specify confirmation copy requirements, reversibility, stale responses, simultaneous raids, save/load and interaction with existing defence eligibility.
- [ ] Record the approved rule and public-operation acceptance examples, including when warnings disappear and consequences occur.
- [ ] Do not change production raid timing or mark this decision complete without the human decision.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

