# 07 — Short-pay menu

**What to build:** While a guard shortfall is pending, the player can open a short-pay menu, a BizBrief sub-view.

- **Reached from:**
  - a Brief attention row
  - tapping the Monday morning notification, which deep-links into BizBrief at this view
- **The menu** lists HQ and each guarded vein with its guard count. The player sets how many guards to keep at each (0..N). It shows, live:
  - the total cost (kept × weeklyWage)
  - the reserve
  - the cash needed on top
- **Confirm** calls a system function:
  - Kept guards are paid from the reserve first, then player cash.
  - Unkept guards walk immediately, following the drop rule: newest extra first, tier guard last.
  - Leftover reserve goes to the float (pot era) or cash (pre-pot).
  - The shortfall clears.
  - If cash can't cover the difference, confirm is refused and nothing changes.
- Screens only call the system function.

**Blocked by:** 06 — Guard shortfall: grace day and auto-drop.

**Relevant files:**
- `systems/guard_upkeep.gd` (confirm function)
- `scenes/phone_apps/bizbrief_app.gd` (Brief attention row, sub-view host), new sub-view scene/script under `scenes/phone_apps/`
- `systems/phone_nav.gd`, `scenes/phone_apps/phone_app_registry.gd`, `systems/notify.gd` (notification deep link)
- `tests/test_guard_upkeep.gd`
- CODEMAP.md
- Spec §Short-pay flow (Menu, Confirm)

**Status:** ready-for-agent

- [ ] Confirming with keep counts pays from the reserve first, then cash, with a bank record for the cash part
- [ ] Unkept guards walk immediately per place; a vein keeping 0 loses its tier (`guarded` → `warded`)
- [ ] Leftover reserve goes to the float or cash; the shortfall clears
- [ ] Refused when cash can't cover the difference; state unchanged
- [ ] The Brief attention row and the morning notification both open the menu
- [ ] New strings flagged PROSE-REVIEW; CODEMAP updated

**Human QA on device:**
- The attention row appears during a shortfall.
- The steppers for each place update the total, reserve and cash-needed live.
- Confirm is disabled or refused when cash is short.
- Tapping the notification lands on the menu.
