# 02 — Export save to file

**What to build:** Add an "Export save file" button to the Save/Load app. It writes the current game state to a timestamped file named `vein-save-day<N>-<YYYYMMDD-HHMM>.json`, somewhere the player can reach from Android's Files app or over USB, so the file can be shared. Try the public Downloads folder first, then Documents, then the app's external files folder. The card shows the full path written, or why the write failed. The file holds exactly what the clipboard export holds today, as plain JSON. File writing lives in SaveManager; the screen only calls it and shows the result.

Don't add any Android permission (for example `MANAGE_EXTERNAL_STORAGE`) without asking the human first. If no permission-free location works on device, stop and report.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `autoload/SaveManager.gd` (`export_string()`, `_saveable_state()`, `_write_json()`)
- `scenes/phone_apps/saveload_app.gd` (`_build_export_card()`)
- `export_presets.cfg` (Android preset `permissions/*`, package `com.veinsoflondon.vein`)
- `tests/` (existing SaveManager export/import tests)
- `CODEMAP.md` (SaveManager and saveload_app rows)

**Status:** ready-for-agent

- [ ] "Export save file" writes a timestamped `.json` and shows the path, or a readable failure reason
- [ ] The written file's contents import back to identical state (headless test writing to a temp path)
- [ ] The fallback order works: if a folder can't be written, the next one is tried (headless test with an unwritable path injected)
- [ ] No new Android permissions, or the human approved one
- [ ] CODEMAP rows updated
- [ ] On-device check (human): on Android, export a mid-game save, find it in the Files app (Downloads or wherever the card says), and share it
