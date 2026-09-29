# 10 — BizBrief expenses breakdown

**What to build:** While the pot is active, the BizBrief Stats tab gets an expenses breakdown.

- Expenses per day, split by kind, over the existing stats window, using the per-kind tally from 01:
  - staff wages
  - guard wages (hire advances + Monday bills)
  - calc purchases
- The guard wages series is tappable. Ticket 11 wires the tap to Guard Costs.

**Blocked by:** 01 — Guard upkeep prefactor; 05 — Monday guard bill inside payday.

**Relevant files:**
- `scenes/phone_apps/bizbrief_app.gd` (Stats tab charts), `systems/business_stats.gd` (zero-filled chart series)
- `tests/test_business.gd` or existing BusinessStats tests
- Spec §Visibility (BizBrief expenses breakdown); ui-vision.md for chart styling

**Status:** ready-for-agent

- [ ] Per-kind series are zero-filled over the stats window and sum to the existing expense series
- [ ] The Stats tab shows the breakdown only while the pot is active
- [ ] New labels flagged PROSE-REVIEW; CODEMAP updated if responsibilities change

**Human QA on device:**
- The Stats tab shows staff, guard and calc expense lines with a legend.
- The guard series has a tap affordance.
