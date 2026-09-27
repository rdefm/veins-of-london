# 130 — Monday cadence: payday, room-hire payroll, recurring due day

**What to build:** Every weekly business obligation falls due on the rollover into Monday (the 1st day of each week, per the 129 calendar). The business payday, owed-wage retry, room-hire wages (weekly now, no longer daily) and recurring contract due days all line up on Monday. Room hires still only work while paid up. Pick the simplest rule for a hire's first part-week (paid at hire, or prorated at the next Monday) and write it in REFERENCE. Recurring offers/contracts use Monday as their weekday. Existing saves migrate: active recurring contracts move their due day to the next Monday.

**Blocked by:** 129 — Calendar display.

**Relevant files:** `systems/business.gd` (payday `day % interval`), `systems/payroll.gd`, `systems/offers.gd` (`_next_weekday_strictly_after`, `weekday`), `systems/contracts.gd` (renewal `dueDay + 7`), `data/offers.json` (`weekday`), `data/constants.json`, `systems/time_system.gd` daily_tick ⑥, `autoload/SaveManager.gd`, `scenes/phone_apps/bizbrief_app.gd` (Staff tab pay terms: daily → weekly); REFERENCE.md §3.10 "Business pot and payday", "Staff roles", "Staff block step".

**Status:** ready-for-agent

- [ ] Payday fires only on the rollover into a Monday; tested over 2+ weeks
- [ ] Room-hire wages charged weekly on Monday; an unpaid hire stops working; tested
- [ ] New recurring contracts fall due on Monday; renewal lands on the next Monday
- [ ] Old save with a recurring contract due mid-week migrates to Monday; save round-trip test
- [ ] BizBrief Staff tab shows weekly pay for room hires
- [ ] REFERENCE.md §3.10 updated
