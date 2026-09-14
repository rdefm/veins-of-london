# 23 — BizBrief Manage tab shell

**What to build:** BizBrief gains a second tab alongside the existing morning-
account view, ready to host Sales/Production/Procurement.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] BizBrief exposes two tabs: **Brief** (the existing Morning Brief view,
  unchanged) and **Manage**.
- [ ] Manage shows three section entry points: **Sales**, **Production**,
  **Procurement** — each a placeholder pending tickets 24-27.
- [ ] No existing BizBrief behaviour regresses; this is additive navigation
  only.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
