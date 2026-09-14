# 28 — Payroll, wages and staff daily phase

**What to build:** Assigned roles cost a daily wage, and the daily tick's
staff processing runs in the spec's exact order.

**Blocked by:** 21 — Contact roles: Sales skill + unified role assignment;
24 — Offer sourcing, quoting and acceptance; 25 — Manual fulfilment and
settlement; 26 — Sales delegation automation.

**Status:** ready-for-agent

- [ ] An assigned role's daily wage is `£100 + £50 × (role skill − 1)`,
  applied to all three roles — Sales, Production, **and** Procurement.
  Production/Procurement wages are new costs for assignments that are free
  today (business-spec.md grilling decision 2); no migration handling is
  needed for existing saves.
- [ ] Living costs are paid first, then wages.
- [ ] If remaining cash cannot cover every wage: pay affordable roles
  automatically in priority order that rollover (business-spec.md grilling
  decision 1 — the "default-then-review" model, not a mid-tick blocking
  pause), then present a summary the player can review/override before the
  next rollover. Unpaid roles do no work that day, accrue no debt, remain
  assigned, and are retried next rollover.
- [ ] The staff phase replaces the current lab-then-vein-station ordering at
  daily-tick step ⑥, running in exactly this order:
  1. Procurement processes Vein Station work.
  2. Production crafts effective targets.
  3. Sales completes any now-fully-stocked delegated periods, then makes
     partial deliveries in contract priority order.
  4. Due periods settle; recurring periods renew.
  5. Sales sources at most one new random offer.
- [ ] This phase still runs after existing raid/faction processing and
  before Dial regen, objectives, accounts completion, `day_ticked`, and
  autosave.
- [ ] Payroll state (decision/pause state per the chosen model) is pure
  serializable state; a reload cannot re-charge or re-skip a wage already
  resolved that rollover.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
