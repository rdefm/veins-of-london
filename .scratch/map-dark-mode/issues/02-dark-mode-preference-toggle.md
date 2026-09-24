# 02 — Dark-mode preference + Map toggle

**What to build:** Add `Preferences.set_map_dark_mode(enabled: bool)` writing `GameState.state["meta"]["mapDarkMode"]` and emitting `state_changed`, the same pattern as `set_reduced_motion`. Put a toggle in the Map controls drawer (the hamburger sheet that holds the filter chips), wired to that setter from the button handler. The screen never mutates state directly. The label is new UI copy: keep it in data and flag it `PROSE-REVIEW:`. The setting is per save file, defaults to `false`, and must survive save/load. It must never be flipped by any Rewind/snapshot restore. `autoload/Snapshots.gd` is a generic stack and each system's `rewind()` decides what gets restored, so audit every `rewind()` and every whole-state restore for `meta` replacement.

After this ticket, toggling redraws the canvas via the existing `state_changed` → `MapCanvas._rebuild`. Overlays may still show light until ticket 04, and dark values are identical to light until ticket 03.

**Blocked by:** 01

**Relevant files:** `systems/preferences.gd`, `scenes/phone_apps/settings_app.gd` (toggle pattern, L11-18), `scenes/components/map_controls.gd`, `autoload/SaveManager.gd` (meta handling ~L209, L437), `autoload/Snapshots.gd`, `systems/events.gd` (`rewind` ~L202), `systems/combat_prototype.gd` (`rewind` ~L826), `tests/`.

**Status:** ready-for-agent

- [ ] Setter + toggle in the map controls drawer; toggle reflects the current value on open
- [ ] Tests: default false; set → save → load round-trips; a Rewind after toggling leaves it unchanged
- [ ] `PROSE-REVIEW:` flag for the toggle label
