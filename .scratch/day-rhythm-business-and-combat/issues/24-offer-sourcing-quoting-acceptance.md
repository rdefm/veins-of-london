# 24 — Offer sourcing, quoting and acceptance

**What to build:** Offers appear (scripted or randomly generated), carry a
locked-in quote, and the player can explicitly accept one into the active
Sales ledger.

**Blocked by:** 21 — Contact roles: Sales skill + unified role assignment.

**Status:** ready-for-agent

- [ ] Support both scripted offers (authored request/deadline) and randomly
  generated offers drawn from authored templates. Real template content is
  out of scope here — use minimal synthetic/test templates; ticket 33/34
  cover the authored catalogue.
- [ ] Pending, unaccepted offers are capped at four. When fewer than four
  exist, at most one random offer may appear per day, at
  `20% + 10% × (salesSkill − 1)` capped at 60%. This roll runs regardless of
  whether anyone is assigned to Sales — an unassigned Sales role uses skill
  1 for the roll (business-spec.md grilling decision 3: offer sourcing is
  passive/ambient, not gated on staffing).
- [ ] Random offers expire 3-14 days after appearing; scripted-offer expiry
  is authored per template. Declining or expiry frees the pending slot.
- [ ] Recurring templates carry a fixed request, weekly cadence, and a fixed
  weekday. One-off templates are single-period. (Mixed multi-type one-offs
  are ticket 32 — this ticket handles single-request-type offers of both
  contract types.)
- [ ] Initial quantity bands: weekly recurring 3-6 units; single-type one-off
  4-10 units.
- [ ] An accepted random one-off gets a base deadline 3-7 days after
  acceptance; scripted one-offs use their authored deadline. A recurring
  template's first due date is the next occurrence of its weekday strictly
  after acceptance (accepting on that weekday means the first due date is
  seven days later). Cadence is weekly only.
- [ ] Quote snapshot, captured at offer creation and never repriced: ore
  units at the current Barometer-effective price; a crafted item's base is
  its `CONSUMABLE_PRICES` value, dynamically modified by the ingredient-
  quantity-weighted average of its recipe's ore-type modifiers. Total
  payment = requested live value × 1.25 contract multiplier × (+5% per
  Sales level above 1, determined at offer creation, no bonus at level 1),
  rounded to whole pounds. (The +20%-per-extra-type bonus applies only to
  mixed one-offs — ticket 32.)
- [ ] Crafted-item quality tier never affects contract eligibility or price.
- [ ] The player explicitly accepts an offer (Sales sources but never
  accepts). Accepting moves it into the active Sales ledger and frees its
  pending slot.
- [ ] BizBrief Manage > Sales lists pending offers with an Accept action.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
