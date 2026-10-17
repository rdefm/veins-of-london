# 08 — Rename Notes app to ToDo

**What to build:** The Notes phone app becomes ToDo everywhere: label, app id, file/class names, routing, badge config, tests. Saved phone order/badge state referencing the old id migrates on load. The lab bench's per-pairing "notes" (survey notebook) is a different thing and stays as is.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/phone_apps/notes_app.gd`, `scenes/phone_apps/phone_app_registry.gd`, `systems/phone_apps.gd`, `systems/phone_nav.gd`, `systems/todo.gd`, `autoload/GameState.gd`, `autoload/SaveManager.gd`, `data/phone_home.json`, `tests/test_app_tile.gd`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] No "Notes" app id/label/file remains (lab bench notes untouched)
- [ ] Old saves with the old id load and show ToDo in the same grid slot
- [ ] CODEMAP updated
