# 32 — Add "Load Game" button to title screen

**What to build:** `TitleScreen` (`scenes/screens/title.gd`) only offers "New Game" and "Debug Start". Add a "Load Game" entry point alongside them, reusing the existing save-slot API (`autoload/SaveManager.gd`: `slot_exists()`, `slot_summary()`, `load_from_slot()`) already used by the Phone's Save/Load app (`scenes/screens/phone.gd::_build_save_load()`).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] "Load Game" button appears on the title screen alongside "New Game"/"Debug Start".
- [ ] If no save slots exist, the button is disabled or clearly indicates there's nothing to load (human's call on exact treatment if unspecified).
- [ ] Tapping it presents the save slots (day/cash summary via `SaveManager.slot_summary()`) and loads the chosen slot via `SaveManager.load_from_slot()` into a running session, matching the existing in-session load behavior.
- [ ] `title` tests cover: button presence, disabled/empty state with no saves, successful load path.
