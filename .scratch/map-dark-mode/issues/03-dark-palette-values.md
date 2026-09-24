# 03 — Dark palette values

**What to build:** Write the real `dark` set in `data/map_palette.json`: dark paper, river, track, labels (`slate`), `ink` as the light foreground (the Growth ramp then runs `muted`→light), card/legend/zoom/drawer chrome, scrims, and halos.

Stop centres and pin-head knockouts keep white, and ore glyphs keep charcoal. That means the glyph colour needs its own token (e.g. `glyph`) separate from `ink`, if 01 didn't already split it.

Add dark-only overrides for every colour below 3:1 against the dark paper. From the estimate (vs `#1b2124`):
- Fail: faction `#9b2335` and `danger` (2.1), `ui_action_red` (2.8), emotion ore `#9b4a7a` (2.8).
- Marginal: guild/`guarded` `#3a7a52` (3.2).

`ui_action_red` comes from `data/palette.json` via `UI.action_colour()`, so the Map-card button path (`MapCardStyle.style_button`) needs a map-palette override for it in dark mode.

Amend `docs/M1.5-NETWORK-MAP.md` §N4 to describe the Growth ramp as `muted`→foreground, and add a one-line dark-variant note wherever it names white fill / charcoal glyph (unchanged) and the river/paper colours.

**Blocked by:** 01

**Relevant files:** `data/map_palette.json`, `data/factions.json`, `data/ore_types.json`, `data/palette.json` (`ui_action_red`), `scenes/components/map_card_style.gd` (`style_button`), `scenes/components/ui.gd` (`action_colour` ~L446), `docs/M1.5-NETWORK-MAP.md` (L19-50), `docs/ui-vision.md` §4.

**Status:** ready-for-agent

- [ ] Dark values authored; a test asserts every line/arc/danger/action colour has ≥3:1 contrast against dark `paper`, and ≥4.5:1 for card text against dark card paper
- [ ] M1.5 doc amended; ui-vision §4 notes that Family 3 has a player-toggled dark variant
- [ ] Report lists every dark hex for human palette sign-off
