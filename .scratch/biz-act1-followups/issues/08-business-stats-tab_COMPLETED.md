# 08 — BizBrief Stats tab: 10-day business performance graphs

**What to build:** A new BizBrief tab, "Stats", available from Owen's join (business pot activation).

- Line graphs over the past 10 days for: revenue (contract settlements into the pot), expenses (wages, Sales calc purchases, etc.), ore collected, and items produced.
- The ore graph has a toggle between **cultivator output** and **player-collected ore** (player harvests/prunes).
- Days with no activity plot as zero.
- The system records a daily business stats snapshot at rollover into state (10-day rolling window). The screen just renders it.

**Blocked by:** 06 — Production log (items-produced figures come from its daily production records).

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd` (tab strip), `systems/business.gd` (pot receipts/expenses), `systems/morning_accounts.gd` (rollover capture), `systems/rooms.gd` (cultivator output), `systems/cultivating.gd` (player harvest/prune ore), new chart component under `scenes/components/`, `tests/test_business.gd`, REFERENCE.md §2 STATE SCHEMA (new path), §3.10 "Business pot and payday", `docs/ui-vision.md`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Stats tab is hidden before Owen joins and shown after.
- [ ] Daily snapshot of revenue, expenses, cultivator ore, player ore and items produced, rolling 10 days. Old saves start empty.
- [ ] Four line graphs, with the ore toggle switching series. Readable at phone width. Chart colours come from palette tokens.
- [ ] The screen only reads state.
- [ ] Tests cover snapshot capture, the 10-day trim and the cultivator/player ore split. On-device QA block.
