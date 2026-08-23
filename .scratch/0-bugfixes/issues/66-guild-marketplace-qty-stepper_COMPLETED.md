# 66 — Guild marketplace: quantity stepper for buy/sell

**What to build:** The Guild marketplace currently has no quantity selection at all — every row is a hardcoded "Buy 1"/"Sell 1" button. Add a `-`/qty/`+` stepper to each goods row, mirroring the Lab's existing crafting-quantity pattern, so the player can buy or sell N units in one action instead of tapping repeatedly.

**Blocked by:** 65 (UI autowrap default fix) — build this on the corrected label/button default rather than adding another one-off workaround.

**Status:** ready-for-agent

- [ ] Each marketplace goods row has a `-`/qty/`+` stepper, qty starts at 1.
- [ ] Qty cannot go below 1.
- [ ] Buy-side qty is capped at what the player can currently afford at the row's price.
- [ ] Sell-side qty is capped at what the player currently holds of that good.
- [ ] The action button reflects the chosen qty and total price (e.g. "Buy ×N (£total)" / "Sell ×N (£total)"), executing the existing purchase/sale call with that qty.
- [ ] No vertical/one-letter-per-line text anywhere in the new stepper (verifies 65 actually covers this case).
- [ ] Test coverage for qty clamping at both bounds (min 1, max affordability/stock).
- [ ] Manual check noted for the human: open Guild marketplace, buy and sell at various quantities including the affordability/stock ceiling, confirm totals are correct.
