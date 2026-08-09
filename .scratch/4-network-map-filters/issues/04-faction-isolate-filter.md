# 04 — Faction isolate filter

**What to build:** A 6th entry, **Faction**, added to the filter drawer (ticket 03) alongside the existing 5 modes. Tapping it reveals a secondary picker listing the 5 canonical factions (from `GameData.FACTIONS`) plus a way to clear back to "all" (inline within the drawer, or a nested step — implementer's call given the drawer shape ticket 03 lands). Picking a faction dims everything else and highlights just that faction's line and owned stops, reusing the same alpha-fade pattern the existing Charge mode already uses (`MapStyle.CHARGE_FADE_ALPHA`, 35%) rather than inventing a new fade value. This is purely additive — the existing 5 filter modes (Ownership/Type/Strength/Charge/Security) are unchanged in behaviour, and filter selection stays UI-local state (not saved, not in `GameState`), same as `filter_mode` today.

**Blocked by:** 01 — Background & glyph contrast pass (so faction colours are tuned against the finalized background before this ticket relies on them reading correctly at both full and dimmed alpha); 03 — Filter drawer (Faction needs the drawer to live in)

**Status:** ready-for-agent

- [ ] `MapStyle.FILTER_MODES` (or an equivalent mechanism) gains a `"faction"` mode alongside a selected-faction-id concept; pure re-styling functions added/extended in `systems/map_style.gd` with unit tests in `tests/test_map_style.gd` — no `GameState`/`GameData` access from `map_style.gd`, same purity discipline as the existing 5 modes.
- [ ] `MapCanvas` (`scenes/components/map_canvas.gd`) consumes the new mode: the selected faction's line and owned stops draw at full colour/alpha; every other line, stub, and stop (player's own line, other factions, NPC-claimed, unclaimed ticks) fades to the same 35% alpha Charge mode uses.
- [ ] The filter drawer (ticket 03) adds a 6th "Faction" row. Selecting it reveals a picker listing all 5 factions by name/colour plus a "clear/all" option, within the drawer's UI shape.
- [ ] Selecting a faction in the sub-picker sets the map to faction-isolate mode for that faction; selecting "clear/all" (or re-tapping the active faction, if that's the chosen UX) returns to the previously active top-level filter mode (or Ownership default) with no faction highlighted.
- [ ] Faction selection is UI-local state only — never written to `GameState.state`, never persisted across app restarts, consistent with `filter_mode` and the pacing toggle's precedent.
- [ ] Tap targets (stop, district zone/label, pin) are unaffected — this filter only re-styles, exactly like the existing 5 modes (N4: "never hide stops, never change tap behaviour").
- [ ] Tests cover: the faction-isolate re-styling maths in `map_style.gd` (selected faction's elements get full alpha, everything else gets 35%), and that switching away from Faction mode restores normal styling.
- [ ] Report lists exactly what a human should check on-device (sub-picker usability/tap targets on a real phone width, dim/highlight legibility per faction colour, that clearing back to "all" works).
