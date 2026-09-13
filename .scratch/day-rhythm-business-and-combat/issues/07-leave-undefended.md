# 07 — Leave undefended

**What to build:** Players explicitly accept non-intervention with its consequences explained before commitment.

**Blocked by:** 04 — Persistent raid alarms; 06 — Non-intervention decision.

**Status:** ready-for-agent

- [ ] Implement the approved timing from ticket 06 alongside Go and defend and Decide later, with three clearly distinct responses.
- [ ] Explain the affected vein, deadline and consequence before commitment; closing/back remains deferral.
- [ ] Revalidate eligibility and make repeat/stale responses harmless; apply consequences exactly once at the approved time.
- [ ] Persist the approved non-intervention state and render badges/warnings according to the approved lifecycle.
- [ ] Test commitment, cancellation/back, expiry, duplicate response and save/load; device QA verifies that deferral cannot accidentally abandon defence.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

