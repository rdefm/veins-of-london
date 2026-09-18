# 09 — Phone app split

**What to build:** The Phone tab becomes a shell (home grid, app-open routing, back handling) with each app's view in its own script under a phone-apps directory: alarms, messages/conversation, notes, factions, ticker, profile, save/load, notifications, BizBrief (brief/manage/production/procurement/sales/bank/operations/attention), bank, and any debug app. The app→script mapping is a table, mirroring the modal registry from ticket 06. Every app looks and behaves exactly as now.

**Blocked by:** 04 — Comment strip: scenes/screens/.

**Relevant files:** `scenes/screens/phone.gd`, new `scenes/phone_apps/`, `systems/phone_apps.gd`, `systems/phone_nav.gd`, `scenes/components/app_tile.gd`, `scenes/components/contact_cards.gd`, `tests/test_phone_*.gd` (all), `CODEMAP.md`.

**Status:** ready-for-agent

- [x] Every phone app opens, renders and navigates identically; back/home behaviour unchanged.
- [x] Phone shell script ≤ 300 lines; one script per app; adding an app is one script + one table row.
- [x] Syntax check and full test suite green; CODEMAP updated.

## Implementation notes

- Shell `scenes/screens/phone.gd` is 123 lines; 12 app scripts + `phone_app.gd` base + `phone_app_registry.gd` under `scenes/phone_apps/`. Per-app view state (bizbrief tab, alarms confirm id, messages reveal index, save/load boxes) lives on the app instance, which the shell caches per id for the screen's lifetime — same lifetime as before.
- Full suite: 2465 pass, 1 fail (`test_playthrough` save-roundtrip) — identical failure on stashed baseline, pre-existing and unrelated.
- New `class_name`s need `.godot/global_script_class_cache.cfg` rebuilt (`godot --headless --editor --import --quit`) before `check_runner.gd` resolves them.
