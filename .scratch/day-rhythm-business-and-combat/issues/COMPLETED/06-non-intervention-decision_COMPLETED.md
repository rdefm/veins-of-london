# 06 — Non-intervention decision

**What to build:** Resolve what deliberately leaving a raid undefended means before introducing that response.

**Blocked by:** None — can start immediately.

**Status:** complete

This ticket authorizes investigation, decision capture and only the explicitly bounded prototype described below. Unresolved rules require human input; ready-for-agent means work can begin, not that proposed mechanics are approved.

- [x] Present current pending-defence timing and consequences, then obtain an explicit choice between immediate resolution and recording non-intervention until the existing deadline.
- [x] Specify confirmation copy requirements, reversibility, stale responses, simultaneous raids, save/load and interaction with existing defence eligibility.
- [x] Record the approved rule and public-operation acceptance examples, including when warnings disappear and consequences occur.
- [x] Do not change production raid timing or mark this decision complete without the human decision.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.

## Approved rule — 2026-09-13

The human chose immediate resolution. **Leave undefended** requires confirmation, then resolves the selected live pending raid now. Hired guards still receive their usual repel roll before the already-rolled claim/loot outcome applies.

Confirmation must identify the vein, say that the raid resolves immediately, and state its specific claim/loot consequence. Cancel, close, and Back mean **Decide later**: no state change, no deadline extension. The confirmation itself is presentation-only and is not saved.

The public operation revalidates the selected pending record at confirmation. A stale, duplicate, expired, resolved, or otherwise ineligible response no-ops; it cannot start defence or apply a second result. It consumes only the selected raid, leaving simultaneous records, their rows, badges, and pinned warning intact. On confirmation the selected row/warning disappears because its pending record is consumed; its guard-repel notification or loss notification occurs immediately. A pending record saved before confirmation remains actionable after load; a committed result saved after confirmation never repeats. Existing alarm/security/defence eligibility is unchanged.

### Acceptance examples

1. One pending loot raid: open Leave undefended, cancel, and the same alarm remains defendable until its ordinary deadline.
2. One pending claim raid: confirm Leave undefended, its row and pinned count disappear immediately; guards either repel it or the recorded claim resolves once.
3. Two pending raids: confirm Leave undefended for one; only that row clears and the other still warns and can be defended.
4. A duplicate confirmation after the first: no extra guard roll, loss, notification, combat, or state change.
5. Save with an open alarm, load, then confirm: resolve once. Save after confirmation, load: do not replay the resolution.

PROSE-REVIEW: proposed confirmation labels and consequence wording are UI copy requirements, not final authored copy.
