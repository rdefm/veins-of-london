# 21 — Arrears visibility

**What to build:** The player can see their financial pressure.
- The next-morning account shows what happened overnight:
  - A shortfall added to arrears (amount and new balance).
  - Interest charged.
  - A forced downgrade (from/to tier, rooms lost, arrears cleared or kept).
  - While in arrears, how many days remain until interest starts or until the downgrade.
- The account's `expenses` total is the cash actually paid (arrears payment + today's bill).
- Harrow's Property app shows the current arrears balance and the days until the next consequence.

**Blocked by:** 20 — Arrears, interest and forced downgrade

**Relevant files:**
- `docs/adr/0006-property-bills-and-arrears.md` (Morning account and notifications)
- `systems/morning_accounts.gd` (`exceptions`, `finish_rollover`, BizBrief routing)
- The BizBrief rendering screen (find via CODEMAP.md `morning_accounts.gd`/BizBrief rows)
- `scenes/phone_apps/property_app.gd`
- `autoload/SaveManager.gd` (morningAccounts key validation, if exception kinds are validated)
- Tests: `tests/test_morning_accounts.gd`, `tests/test_phone_bizbrief.gd`, `tests/test_phone_property.gd`
- REFERENCE.md §2 STATE SCHEMA (`morningAccounts`), §3.1
- CODEMAP.md

**Status:** ready-for-agent

- [ ] New exception kinds for arrears shortfall, interest and forced downgrade are recorded in `morningAccounts.latest` as plain data. Older saved accounts without them still load.
- [ ] An account with any arrears exception auto-opens/routes the same way as other exceptions.
- [ ] The days-until-interest/downgrade line appears only while in arrears. It is omitted at the bedsit for the downgrade.
- [ ] The Property app shows the arrears balance and the next consequence. The screen only reads state.
- [ ] New prose is drafted against CONTENT-GUIDE.md and flagged PROSE-REVIEW.
- [ ] REFERENCE.md §2 and CODEMAP.md are updated.
- [ ] Syntax check clean, full suite passes. The device check list covers the BizBrief and Property app.
