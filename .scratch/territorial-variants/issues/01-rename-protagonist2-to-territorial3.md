# 01 — Rename protagonist2 to territorial3

**What to build:** The protagonist sprite set currently called `protagonist2` becomes `territorial3` everywhere: asset folder, asset filenames, combat-visuals template key, and the fresh-save `player.model` default. Existing saves whose `player.model` is `"protagonist2"` load as `"territorial3"`. On-screen, the player looks and animates exactly as before. This renames things so later tickets can treat all `territorialN` sets the same way.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `assets/combat/protagonist2/` → `assets/combat/territorial3/` (files `protagonist2_*.png` → `territorial3_*.png`; move with their `.import` sidecars and fix the paths inside them, or delete the sidecars and let Godot re-import)
- `data/combat_visuals.json` — `templates.protagonist2` entry and its image paths; the `templateRule` note that cites `'protagonist2'` as its example
- `autoload/GameState.gd` — `player.model` default in `new_game_state()`
- `autoload/SaveManager.gd` — add a load-time migration alongside `_migrate_vein_station_veins` / `_migrate_nadia_supply_order` (same pattern: no `SAVE_VERSION` bump)
- `tests/test_combat_screen.gd` — test that sets `player.model = "protagonist2"`
- `tests/` save-migration tests (wherever the existing `_migrate_*` functions are tested)
- `CODEMAP.md` — any row naming protagonist2
- `docs/REFERENCE.md` §2 STATE SCHEMA (document `player.model`: a combat-visuals template key), §6 SAVE FORMAT

**Status:** ready-for-agent

- [ ] No `protagonist2` string is left in `assets/`, `data/`, `autoload/`, `systems/`, `scenes/`, or `tests/` (the `android/build` copies are build output and are ignored).
- [ ] A fresh game's `player.model` is `"territorial3"`, and combat renders the player with the territorial3 idle/attack/hit/throw art.
- [ ] Loading a save whose `player.model` is `"protagonist2"` gives `"territorial3"`; saves with any other value are left alone. A test covers this.
- [ ] `player.model` is documented in REFERENCE.md §2.
- [ ] The syntax check is clean and all tests pass.
