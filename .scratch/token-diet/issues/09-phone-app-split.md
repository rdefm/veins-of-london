# 09 — Phone app split

**What to build:** The Phone tab becomes a shell (home grid, app-open routing, back handling) with each app's view in its own script under a phone-apps directory: alarms, messages/conversation, notes, factions, ticker, profile, save/load, notifications, BizBrief (brief/manage/production/procurement/sales/bank/operations/attention), bank, and any debug app. The app→script mapping is a table, mirroring the modal registry from ticket 06. Every app looks and behaves exactly as now.

**Blocked by:** 04 — Comment strip: scenes/screens/.

**Relevant files:** `scenes/screens/phone.gd`, new `scenes/phone_apps/`, `systems/phone_apps.gd`, `systems/phone_nav.gd`, `scenes/components/app_tile.gd`, `scenes/components/contact_cards.gd`, `tests/test_phone_*.gd` (all), `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Every phone app opens, renders and navigates identically; back/home behaviour unchanged.
- [ ] Phone shell script ≤ 300 lines; one script per app; adding an app is one script + one table row.
- [ ] Syntax check and full test suite green; CODEMAP updated.
