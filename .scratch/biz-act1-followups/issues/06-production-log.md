# 06 — Production log under Manage → Production

**What to build:** BizBrief's Manage → Production section gets a production log.

- It covers the last 10 days, batched by day. Older than 10 days is dropped.
- Each day is a collapsed row (e.g. day + short summary "7 made · 2 failed").
- Tapping a day expands to show each block's entries: who crafted, what they made (item, quality), what they attempted and failed, and a note on any block where a crafter stopped because of insufficient ore (naming the ore short).
- The log is written by the system during the staff step, so it's part of the pure state tree (save/Rewind-safe).

**Blocked by:** 05 — Uncapped crafting (the log records its per-attempt outcomes and ore-out stops).

**Relevant files:** `systems/rooms.gd` (staff step writes log entries), `systems/morning_accounts.gd`, `scenes/phone_apps/bizbrief_app.gd` (Manage → Production), GameState load/migration for the new state path, `tests/test_rooms.gd`, REFERENCE.md §2 STATE SCHEMA (new path), §3.10 "Producer (per block)", `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] A new state path holds per-day, per-block production records (made, failed, ore-short stop reason), trimmed to 10 days at rollover.
- [ ] Old saves load with an empty log.
- [ ] Manage → Production shows days collapsed, and tap expands a day. The screen only reads state.
- [ ] An ore-short stop shows a clear per-block note.
- [ ] REFERENCE.md §2 is documented.
- [ ] Tests cover logging, the 10-day trim and the ore-short note. On-device QA block.
