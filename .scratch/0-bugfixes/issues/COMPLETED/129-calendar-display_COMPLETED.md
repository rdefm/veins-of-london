# 129 — Calendar display

**What to build:** Replace the bare day counter with a calendar date everywhere the player sees one. Format `MON 3 JAN`. Months are 4 weeks (28 days), 12 per year, named JAN–DEC. Day 1 of a new game = `MON 1 APR`. Year 1 shows no year. From the first 1 JAN onward it shows `Y2`, `Y3`, … (e.g. `MON 3 JAN Y2`). One shared pure helper converts `world.day` → {weekday, dayOfMonth, month, year} and the display string. The underlying `world.day` integer and save format stay the same. Every player-facing "Day N" string uses the helper: top bar, notifications, bank records, Morning Brief/accounts, save slots, BizBrief.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/time_system.gd`, `scenes/components/top_bar.gd`, `scenes/phone_apps/bizbrief_app.gd`, `scenes/phone_apps/bank_app.gd`, `scenes/phone_apps/saveload_app.gd`, `scenes/phone_apps/notifications_app.gd`, `scenes/components/line_chart.gd`, `scenes/components/vein_detail_panel.gd`, `scenes/modals/lab_bench_notes_modal.gd`, `scenes/screens/title.gd`, `systems/raid_alarms.gd`, `data/constants.json` (calendar constants: start month, month names, days per month); REFERENCE.md §3.1 "Time, rest, daily tick", §2 `world` schema.

**Status:** ready-for-agent

- [ ] Helper tested: day 1 → `MON 1 APR`; day 8 → `MON 8 APR`; day 29 → `MON 1 MAY`; last day of DEC in year 1 → no year; the next day → `MON 1 JAN Y2`; a day deep into year 3 formats correctly
- [ ] Calendar constants live in JSON, not code
- [ ] No player-facing "Day %d" strings left (grep clean outside tests)
- [ ] REFERENCE.md §3.1 documents the calendar
- [ ] Human on-device: top bar shows `MON 1 APR` on a new game; advance days and check it rolls over to the next month
- [ ] Assumption to confirm with the human before merging: Y2 starts at the first 1 JAN (after 9 months), not 12 months after the start
