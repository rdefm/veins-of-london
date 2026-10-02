# 02 — All staff wages through the business (prefactor)

**What to build:** Staff wages are never paid from player cash. The Monday cash payroll path is removed, along with the HQ room card's "Pay now" button. A contact works unless the business owes them a wage (founders as today). The BizBrief payday shortfall prompt "Pay from your own cash?" becomes "Top up the float by £X?": Yes moves cash into the float and immediately retries the owed wage from pot, then float; No leaves them unpaid. The BizBrief Staff tab "Pay now" does the same. Old saves drop the `payroll` state.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/payroll.gd`, `systems/business.gd` (`pay_owed_from_cash`, `decline_wage_prompt`, `pay_terms`, `staff_status`, `_draw`), `systems/time_system.gd` (~L109 ⑥ `Payroll.pay_wages`), `systems/offers.gd` (~L63), `systems/contracts.gd` / `systems/rooms.gd` / `systems/contact_texts.gd` (`Payroll.is_working` callers), `scenes/screens/hq_floorplan.gd` (~L179-187), `scenes/phone_apps/bizbrief_app.gd` (~L116, L307, L637), `autoload/GameState.gd`, `autoload/SaveManager.gd`, `tests/test_payroll.gd`, `tests/test_business.gd`, spec §8 + §10 R10, REFERENCE.md §2 + §3.10 "Business pot and payday".

**Status:** ready-for-agent

- [ ] No code path debits player cash for staff wages
- [ ] Float top-up prompt replaces the cash prompt; Yes funds the float and clears the owed wage, No keeps them unpaid
- [ ] Staff tab "Pay now" routes through a float top-up
- [ ] `payroll` state removed and old saves load cleanly
- [ ] Tests updated; REFERENCE + CODEMAP updated
- [ ] Human check: Owen unpaid at payday → BizBrief shows the top-up prompt; Yes resumes his work
