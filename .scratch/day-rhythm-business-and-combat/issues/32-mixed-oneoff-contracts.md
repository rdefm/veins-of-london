# 32 — Mixed one-off contract support

**What to build:** One-off offers can request more than one item type, with
the payment/deadline/settlement adjustments that come with that.

**Blocked by:** 25 — Manual fulfilment and settlement.

**Status:** ready-for-agent

- [ ] Mixed requests are allowed only for one-offs (recurring contracts stay
  single-type). Each requested type carries its own quantity; initial
  quantity band is 2-5 units per type in a mixed one-off.
- [ ] Every extra requested type beyond the first adds two days to the
  one-off's deadline and a 20% payment bonus at quote time.
- [ ] Settlement uses quoted-value-weighted delivered proportion across
  requested types for partial payment:
  `Σ(delivered_units × unit_value) / total_quote_value` (see
  business-spec.md, Fulfilment and settlement).
- [ ] Manual delivery and Sales delegation (tickets 25/26) both handle mixed
  requests without special-casing at the call site — the shared fulfilment
  operation absorbs the per-type bookkeeping.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.
