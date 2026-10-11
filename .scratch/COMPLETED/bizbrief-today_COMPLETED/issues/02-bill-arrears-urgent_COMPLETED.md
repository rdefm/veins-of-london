# 02 — Rent/bill shortfall and arrears as Urgent rows

**What to build:** When the next home bill (rent or utilities) is due within the data-set day window and cash won't cover it, the Today card shows an Urgent bill row with the shortfall ("short £270 for Monday"). Arrears show as an Urgent row with the countdown to the next consequence. Both act by opening the relevant place (Bank / Property). No new consequences — only existing countdowns are surfaced.

**Blocked by:** 01 — Tracer: DailyBrief projection + Today card.

**Relevant files:** `systems/home.gd` (`current_bill_base`, `weekly_bill_base`, `arrears_countdown` ~L188-213), `systems/morning_accounts.gd` (`capture_bills`, `arrears_label`), `data/home.json`, `systems/daily_brief.gd`, `data/daily_brief.json`, `tests/test_daily_brief.gd`, `tests/test_home*.gd`. REFERENCE.md §1.7 "`data/home.json`", §3.3 "Home", §3.1.

**Status:** ready-for-agent

- [ ] Bill row only when due within the window AND cash < bill; consequence shows the shortfall
- [ ] Shortfall/due-day maths agrees with Home's own bill and countdown reads (test)
- [ ] Arrears row countdown matches `arrears_countdown`
- [ ] Rows drop off once cash covers the bill / arrears clear
- [ ] Day window lives in `data/daily_brief.json`
