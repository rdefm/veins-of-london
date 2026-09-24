# 30 — Production contract-coverage toggle

**What to build:** Production can craft toward accepted-contract needs on
top of the player's personal inventory targets.

**Blocked by:** 21 — Contact roles: Sales skill + unified role assignment;
25 — Manual fulfilment and settlement; 29 — [needs-info] Production
target/contract-need combination formula.

**Status:** needs-info (blocked on ticket 29's decision)

- [ ] Production preserves the existing Lab repeated-attempt model: it keeps
  attempting configured crafted-item targets until all targets are met or
  shared ore is exhausted, using the assigned contact's existing crafting
  chance. Every successful NPC-produced item's quality tier equals the
  contact's `craftingSkill`.
- [ ] Add a per-item toggle to also cover accepted-contract needs, counting
  only the undelivered quantities of active current periods (never future
  recurring periods).
- [ ] Combine personal target and contract need per ticket 29's approved
  formula.
- [ ] When shared ore is scarce, the contract-card priority order (ticket 25)
  wins, then player-set inventory-target priority.
- [ ] Surface these controls in BizBrief Manage > Production.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
