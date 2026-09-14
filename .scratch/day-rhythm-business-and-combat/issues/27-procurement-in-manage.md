# 27 — Procurement in BizBrief Manage

**What to build:** The existing Vein Station selection/target controls move
into BizBrief's new Manage > Procurement section.

**Blocked by:** 23 — BizBrief Manage tab shell.

**Status:** ready-for-agent

- [ ] Relocate the existing Vein Station vein-selection and growth-target
  controls into Manage > Procurement. No mechanical change — Procurement
  preserves the existing Vein Station behaviour exactly (selected veins and
  targets tended/pruned, yield into shared stock).
- [ ] Wherever these controls previously lived, either remove them or leave
  a pointer into Manage > Procurement — no duplicate control surface.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
