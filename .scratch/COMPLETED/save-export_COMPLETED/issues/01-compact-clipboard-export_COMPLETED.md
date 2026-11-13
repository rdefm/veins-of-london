# 01 — Compact clipboard export

**What to build:** "Copy to clipboard" in the Save/Load app currently copies the whole save JSON. On Android a real mid-game save is too big for the clipboard, so there's no way to get a save off the phone, and a save is needed to diagnose bugs like the at-war Firm that never raids. The copy should produce a compressed string instead: gzip the JSON, base64 it, and add a version prefix `VEIN1:`. That should be about a tenth the size. Import accepts both the prefixed compressed form and plain JSON, so old exports still load. The exported content is exactly what the export gives today, with no new state. The encode and decode logic lives in SaveManager; the screen only calls it.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `autoload/SaveManager.gd` (`export_string()`, `import_string()`, `_saveable_state()`, `_load_save_dict()`)
- `scenes/phone_apps/saveload_app.gd` (`_build_export_card()`, `_on_export_pressed()`, `_on_copy_pressed()`, `_build_import_card()`)
- `tests/` (existing SaveManager export/import tests)
- `CODEMAP.md` (SaveManager and saveload_app rows)

**Status:** ready-for-agent

- [ ] Copy to clipboard produces a `VEIN1:`-prefixed gzip+base64 string
- [ ] Importing that string restores identical state (headless round-trip test)
- [ ] Import still accepts plain-JSON export strings (headless test)
- [ ] Malformed or truncated compressed input fails with a readable reason, never a crash (headless test)
- [ ] CODEMAP rows updated
- [ ] On-device check (human): on Android, copy a mid-game save, paste it into a note or email, and confirm it isn't truncated and imports back
