# 01 — Map dark mode: estimate spike

**What to build:** A written estimate (no code) of how big a lift it is to add a manual light/dark toggle to the Map tab. Cover: which colours are hard-coded vs tokenised, what the diagram/glyph/bubble/card layers need, whether the palette/mood rules in ui-vision allow a dark variant, where the toggle lives and persists, and a rough ticket breakdown with sizes. Append the answer to this file under `## Answer`.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/map.gd`, `systems/map_view.gd`, `systems/map_style.gd`, `scenes/components/map_card_style.gd`, `scenes/components/map_bubble.gd`, `systems/preferences.gd`, `docs/M1.5-NETWORK-MAP.md`, `docs/ui-vision.md`.

**Status:** ready-for-agent

- [x] Inventory of every colour source the Map tab draws with (token vs literal)
- [x] Proposed approach for a dark variant + where the toggle sits and persists
- [x] Size estimate (S/M/L) with a draft ticket list
- [x] Any spec/vision conflicts called out as questions for the human

## Answer

**Verdict: M overall (~5 tickets, 1 S prerequisite + 3 S/M + 1 QA).** Nothing on the Map tab is tokenised today — every colour is a per-file `const` or a data colour — so most of the work is a centralise-then-swap refactor, not new rendering. The canvas draws in immediate mode (`_draw()`), so a palette swap + `queue_redraw()` is all the diagram needs; no textures to re-author (the M1.5 paper texture never landed — `_draw_paper()` is a flat `#ffffff` rect).

### 1. Colour-source inventory

"Token" = one shared source; "literal" = hard-coded in that file.

| Layer | File | Source | Values |
|---|---|---|---|
| Paper / river / track / labels | `scenes/components/map_canvas.gd:13-21` | literal consts | PAPER `#ffffff`, RIVER `#d4cfc4@60%`, MUTED `#8a8a8a`, TRACK `#d4cfc4`, INK `#1a1a1a`, SLATE `#4a5568`, PLAYER `#c8873a`, WARDED `#7b68ee`, GUARDED `#3a7a52` |
| Stop centres, pin heads, pin padlock | `map_canvas.gd:573,709-727` | PAPER_COLOUR | white — also the "knockout" colour inside pins |
| Ore glyph in stop | `map_canvas.gd:640` → `OreGlyphs.draw` | INK_COLOUR (param) | charcoal; glyph code already takes colour as arg |
| Zone fills, faction lines | `map_canvas.gd:502,535` | **data** `factions.json` colour | 5 hexes, 8% alpha zones |
| Type-mode arcs | `map_canvas.gd:627` | **data** `ore_types.json` colour | 5 hexes |
| Filter re-style math | `systems/map_style.gd:19-21` | literal consts (dupes of canvas) | MUTED, INK, DANGER `#9b2335`; Growth ramp = MUTED→INK |
| Inner halo classes | `map_canvas.gd:868,898` | `const COLOUR := MapCanvas.X` | GUARDED, DANGER — compile-time consts, must become runtime reads |
| Halos / growth anim | `scenes/components/map_halos.gd:152,176,236` | literals + MapCanvas consts | amber `#c8873a` (dup), gold `#ffe8b1`, MUTED; ring fill = PAPER |
| Popup cards (bubbles, district panel, site sheet) | `scenes/components/map_card_style.gd:8-13` | literal consts — closest thing to a token set | PAPER `#f0eee6`, INK `#252e30`, DIM `#65716c`, LINE `#c0c8bb`, GOLD `#957019`, SAGE `#dedfd3`; shadow black |
| Bubble + map.gd card text | `map_bubble.gd:98,107`, `scenes/screens/map.gd:243-501` | MapCardStyle.* (good) + MapStyle.DANGER + faction colour | — |
| Legend | `scenes/components/map_legend.gd:13-15` | literal consts | CREAM `#faf8f3`, BORDER `#d4cfc4`, CHARCOAL `#1a1a1a` |
| Zoom buttons | `scenes/components/map_zoom_buttons.gd:8-11` | literal consts (dup of legend) | same + 35% charcoal |
| Controls drawer (filter chips) | `scenes/components/map_controls.gd:39,134` | scrim literal + faction data + **global theme** via `UI.*` | black 50% |
| Top row icons (hamburger/bag/search) | `map.gd:120-162` → `UI.icon_button` | **global theme** `font_color` | — |
| Action buttons | `MapCardStyle.style_button` → `UI.action_colour()` | `data/palette.json` `ui_action_red` | `#c8102e` |
| Scrims | `map.gd:328`, `map_controls.gd:39` | literal | black 50% |

Findings: three different "paper" values (`#ffffff` canvas, `#f0eee6` cards, `#faf8f3` legend/zoom); `#1a1a1a` duplicated in 4 files, `#8a8a8a` in 4, `#d4cfc4` in 4, amber in 2. Stale comment: `map_canvas.gd:13` says "see _draw_paper() for why" but `_draw_paper()` has no rationale.

**Data colours on a dark ground** (WCAG non-text min 3:1; tested vs `#1b2124`):
- Fail: faction `#9b2335` / DANGER (2.1), `ui_action_red` (2.8), emotion ore `#9b4a7a` (2.8).
- Marginal: guild/GUARDED `#3a7a52` (3.2).
- Fine: player amber (5.4), fate (5.2), teal/blue factions (~4.5-5), warded (3.9), muted (4.7).

So dark mode needs dark variants of **data** colours, not just chrome.

### 2. Proposed approach

1. **One Map palette token table**, e.g. `data/map_palette.json` → `{ "light": {...}, "dark": {...} }`, loaded by GameData. Keys: `paper, river, track, ink, muted, slate, player, warded, guarded, danger, haloAmber, haloGold, cardPaper, cardInk, cardDim, cardLine, cardGold, cardSage, chromeFill, chromeBorder, chromeInk, scrim`, plus an optional `dark` override map for faction/ore colours (`factionColour.<id>`, `oreColour.<id>`) so data files keep their current single `colour`.
2. **Accessor** `MapPalette.get(key) -> Color` (scenes/components, presentation-only) reads `GameState.state["meta"].get("mapDarkMode", false)`. All Map-tab files swap `const X_COLOUR` for `MapPalette.get("x")`; inner-class `const COLOUR :=` become vars set at spawn.
3. **`MapStyle` stays pure**: `vein_ring_colour()` gets `muted`/`ink` passed in instead of its own consts (tests pass explicit colours; light-mode results unchanged).
4. **Stop grammar in dark**: keep stop centres white + charcoal glyphs (reads as lit stations on a night diagram, and keeps M1.5's "white fill / charcoal silhouette" rule intact). Only paper, river, track, labels, halos, cards and chrome flip. Pin-head knockouts stay white too. Growth ramp becomes MUTED→light (`ink` token inverts) — **spec change, see Q3**.
5. **Redraw**: toggle emits `state_changed`; `map.gd._refresh` and `MapCanvas._rebuild` already listen, so the canvas redraws; card/legend/zoom/controls styleboxes are built at construction, so those need a restyle pass or the map screen rebuilds its overlays on change (cheapest: rebuild overlay nodes in `_refresh` when the flag flips).
6. **Toggle placement**: in the Map controls drawer (`map_controls.gd`, behind the hamburger) next to the filter chips — Map-only setting, sits where Map options already live. Optionally mirrored in the phone Settings app (`settings_app.gd`) beside reduced motion.
7. **Persistence**: `Preferences.set_map_dark_mode(enabled)` writing `meta.mapDarkMode`, same pattern as `reducedMotion`. Caveat: `meta` is per-save state, so it resets on New Game and — unverified — may be captured by snapshots/Rewind (see Q5).

### 3. Draft tickets

| # | Ticket | Size | Notes |
|---|---|---|---|
| A | Map palette tokens: `map_palette.json` (light = today's exact values) + `MapPalette` accessor + GameData load/validation; migrate canvas, halos, MapStyle params, card style, legend, zoom, scrims off literals | M | Pure refactor, zero visual change in light — test: every key resolves; MapStyle tests updated to pass colours |
| B | `Preferences.set_map_dark_mode` + `meta.mapDarkMode` + toggle in map controls drawer (+ Settings app mirror if wanted); verify Rewind/save don't flip it | S | Tests: pref round-trips save/load; rewind leaves it |
| C | Dark values: author the `dark` table incl. faction/ore overrides passing 3:1; canvas + halos consume | S | Needs human palette sign-off (PROSE-REVIEW-equivalent visual gate) |
| D | Live restyle of overlays (cards, bubbles, legend, zoom, drawer, top-row icons) on toggle without leaving the tab | S-M | Top-row icons use the global theme — needs a map-local override |
| E | Visual QA pass per filter mode × light/dark, on device | S (human) | 5 filters × 2 modes; halos/growth anims; pins |

Spec/doc updates ride with A/C: M1.5-NETWORK-MAP §colour lines, ui-vision §4 (Family 3 dark variant), CODEMAP rows for new files.

### 4. Questions for the human

1. **Family distinctness (ui-vision §4/§10):** Family 2 (Phone-OS) is specified as the dark family. Does a dark Map blur the "four distinct chrome families" rule, or is a user-chosen night variant fine? ui-vision's "not dark-noir" is scoped to Family 1 pixel art only, so there's no outright ban.
2. **Stop centres:** keep white centres + charcoal glyphs in dark mode (my recommendation, keeps M1.5's stop spec), or invert to dark centres + light glyphs (touches every stop/pin/halo and M1.5 §stops)?
3. **Growth filter ramp:** M1.5 §N4 says `--muted`→`--ink`; on dark this has to run muted→light. OK to amend the spec as "muted→foreground"?
4. **Data colour overrides:** crimson faction/`--danger`, emotion ore and `ui_action_red` fail 3:1 on dark. OK to add dark-only lighter variants (breaks "one colour per faction" identity slightly), or should the dark ground be a mid-slate instead of near-black so current hexes pass?
5. **Persistence scope:** per-save (`meta`, like reducedMotion — resets on New Game) or device-wide (a small user:// config outside game state)? Device-wide keeps it out of Rewind by construction and is arguably right for a display preference.
6. **Scope:** Map tab only (as ticket says) — including the bottom nav dock (Family 4) while on Map, or does the dock stay light?
