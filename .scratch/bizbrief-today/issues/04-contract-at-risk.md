# 04 — Contract-at-risk Urgent row

**What to build:** An active contract whose current period can't be met by end of period from stock plus reserved production shows as an Urgent row naming the buyer and the shortfall, with an action to the Sales view in BizBrief Manage. Filled/locked periods and expired/cancelled contracts never appear.

**Blocked by:** 01 — Tracer: DailyBrief projection + Today card.

**Relevant files:** `systems/contracts.gd` (`remaining_qty`, `is_period_filled`, `calc_need`, period start/close), `systems/rooms.gd` (`contract_need`, production), `systems/offers.gd`, `scenes/phone_apps/bizbrief_app.gd` (Manage/Sales), `systems/daily_brief.gd`, `tests/test_daily_brief.gd`, `tests/test_contracts.gd`. REFERENCE.md §3.10 "Contacts, rooms, jobs" (Sales/contracts), §3.1 (block-end delivery).

**Status:** ready-for-agent

- [ ] At-risk rule (stock + reserved production < remaining by period end) tested both ways
- [ ] Filled, expired and cancelled contracts excluded
- [ ] Action routes to the Sales view
- [ ] Row drops off when stock/production covers the period
