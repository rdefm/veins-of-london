# 07 — Costs tab, Short Pay checklist, BizBrief links

**What to build:** Guard Costs moves from BizBrief into the Security screen's **Costs** tab: next Monday bill, this week's wages and training spend, and a per-place history (HQ / each vein / Reserve, plus a training line) expandable per guard. BizBrief keeps guard totals and Brief rows that deep-link to Costs.

**Short Pay** becomes a per-person keep checklist grouped by post, each row with wage, and a running total against what the player can pay. Short Pay works without the Security Office. Auto-resolve drop order: Reserve first (injured included), then posts on the least valuable vein first, then HQ; lowest level first within a place. Walked guards go to former. The shortfall record holds guard ids, not place counts.

**Blocked by:** 06 — XP, levels, training and the Muscle daily tick.

**Relevant files:**
- `systems/guard_upkeep.gd` (`start_shortfall`, `_auto_resolve`, `short_pay_places`, `short_pay_quote`, `confirm_shortfall`, `_drop_guards`, `drop_vein_guards`, `record_payment`, `cost_series`, `cost_places`)
- `scenes/phone_apps/guard_costs_view.gd`, `scenes/phone_apps/short_pay_view.gd`, `scenes/phone_apps/bizbrief_app.gd`, Security screen Costs tab
- `systems/cultivating.gd` (vein value order)
- Tests: `tests/test_guard_upkeep.gd`, `tests/test_phone_bizbrief.gd`
- REFERENCE.md §1.6 (upkeep); CODEMAP.md (Guard Costs view's new home)

**Status:** ready-for-agent

- [ ] Costs tab shows next bill, this week's wages + training, per-place history with per-guard expansion
- [ ] BizBrief no longer hosts Guard Costs; its totals/rows deep-link to Costs
- [ ] Short Pay checklist keeps exactly the ticked guard ids; quote updates the running total
- [ ] Auto-resolve drops in the specified order; walked guards land in former
- [ ] Short Pay works with the room lost
- [ ] On-device check listed: Costs tab, BizBrief links, Short Pay checklist
