# 01 — Map palette prefactor

**What to build:** Every colour the Map tab draws with comes from one Map palette: a data-driven light set and dark set, resolved at draw/build time by a small presentation-side accessor. The player sees no change. The light set holds today's exact colours, and the dark set is a copy of light until ticket 02 fills it in. Faction and ore colours still come from their own data, with an optional dark-only override per id. The filter re-style math stays pure and receives the colours it needs as inputs instead of owning its own copies. The canvas, halos, popup cards, bubbles, legend, zoom buttons, controls drawer and scrims all read the palette. Duplicated literals (the same ink, muted, border and amber values repeated across files) collapse into single tokens. The three distinct paper tones (diagram, cards, legend/zoom chrome) stay three separate tokens. Fix the canvas's stale "see _draw_paper() for why" comment.

The colour inventory and suggested token keys are in `.scratch/playtest-2026-09-24/issues/01-map-dark-mode-estimate_COMPLETED.md` §1–2.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/map_canvas.gd`, `scenes/components/map_halos.gd`, `systems/map_style.gd`, `scenes/components/map_card_style.gd`, `scenes/components/map_bubble.gd`, `scenes/components/map_legend.gd`, `scenes/components/map_zoom_buttons.gd`, `scenes/components/map_controls.gd`, `scenes/screens/map.gd`, `autoload/GameData.gd` (`_load_palette`, `MANIFEST`), `data/palette.json`, `data/factions.json`, `data/ore_types.json`, `tests/test_map_style.gd`, `CODEMAP.md`, `docs/M1.5-NETWORK-MAP.md`.

**Status:** ready-for-agent

- [ ] Map palette data loads at boot and is validated: every entry is a valid colour, and the light and dark sets have identical keys
- [ ] No hard-coded colours remain in the Map-tab files, apart from the transparent tap-catcher
- [ ] Filter re-style tests pass with colours supplied as inputs, and light-mode results are unchanged
- [ ] Tests: every token resolves in both modes; faction and ore colours fall back to their data colour when no dark override exists
- [ ] CODEMAP updated for new files
- [ ] Human check: the Map tab looks the same as before in every filter mode
