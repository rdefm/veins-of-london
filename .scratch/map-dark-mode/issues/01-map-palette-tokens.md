# 01 — Map palette tokens (no visual change)

**What to build:** Move every Map-tab colour into one token source, keeping today's values exactly, so light mode looks the same as it does now. Add `data/map_palette.json` with a `light` set (a `dark` set identical to `light` for now, so ticket 03 only changes values). GameData loads and validates it; follow the bespoke `_load_palette()` pattern or add a MANIFEST row. Add a presentation-side `MapPalette` accessor (`get(key) -> Color`, plus `faction_colour(id)` / `ore_colour(id)` that apply dark overrides when present). It reads `GameState.state["meta"].get("mapDarkMode", false)`. Migrate every literal in the inventory table to it. `systems/map_style.gd` stays pure: drop its colour consts and take `muted`/`ink`/`danger` as parameters. Inner-class `const COLOUR := MapCanvas.X` in `map_canvas.gd`/`map_halos.gd` become runtime values set at spawn. Fix the stale "see _draw_paper() for why" comment at `map_canvas.gd:13`. Suggested token keys are in the estimate's §2.

The three different "paper" values (`#ffffff` canvas, `#f0eee6` cards, `#faf8f3` legend/zoom) stay as three distinct tokens. Don't merge them.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/map_canvas.gd` (consts L13-21, uses L493-742, inner classes L868/L898), `scenes/components/map_halos.gd` (L75-77, L139-143, L152, L176, L236), `systems/map_style.gd`, `scenes/components/map_card_style.gd`, `scenes/components/map_legend.gd` (L13-15), `scenes/components/map_zoom_buttons.gd` (L8-11), `scenes/components/map_controls.gd` (L39, L134), `scenes/components/map_bubble.gd`, `scenes/screens/map.gd` (L328, L386, L462-470), `autoload/GameData.gd` (`_load_palette` ~L366, MANIFEST ~L184), `tests/test_map_style.gd`, `CODEMAP.md`, estimate: `.scratch/playtest-2026-09-24/issues/01-map-dark-mode-estimate_COMPLETED.md`.

**Status:** ready-for-agent

- [ ] `data/map_palette.json` + GameData load/validation (every key a valid colour; `light` and `dark` have identical key sets)
- [ ] `MapPalette` accessor; no `Color(` literals left in the Map-tab files above except the transparent tap-catcher in `map_bubble.gd:26`
- [ ] `MapStyle` takes colours as params; tests updated, light results identical
- [ ] Tests: every token resolves in both modes; faction/ore fall back to data colour when no override exists
- [ ] CODEMAP rows for new files
