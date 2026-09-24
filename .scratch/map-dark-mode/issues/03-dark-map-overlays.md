# 03 — Dark Map overlays

**What to build:** With Map dark mode on, every overlay on the Map tab renders dark and legible. That covers station/vein bubbles, district panel, site sheet, faction/vein cards, legend, zoom buttons, the controls drawer, the top-row icon buttons (menu, bag, search) and dim scrims. Action buttons on Map cards use a dark-mode action colour that keeps ≥4.5:1 text contrast. Map-card body text and dim text keep ≥4.5:1 against the dark card paper. Toggling while an overlay is open restyles it in place, or rebuilds it identically. The open bubble/sheet stays open and the current filter mode is kept. Light mode is unchanged. The rest of the game's chrome is untouched: the top-row icons get a Map-local colour, not a global theme change.

**Blocked by:** 02

**Relevant files:** `scenes/screens/map.gd` (`_refresh`, top row, district panel, site sheet), `scenes/components/map_bubble.gd`, `scenes/components/map_card_style.gd`, `scenes/components/map_legend.gd`, `scenes/components/map_zoom_buttons.gd`, `scenes/components/map_controls.gd`, `scenes/components/ui.gd` (`icon_button`, `action_colour`, `style_action_button`), `data/palette.json` (`ui_action_red`), `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Live-tree test: after toggling, the overlay backgrounds and text colours match the dark tokens; after toggling back, they match light
- [ ] Test: dark card text, dim text and action colour meet ≥4.5:1 against dark card paper
- [ ] An open bubble/sheet and the selected filter survive a toggle
- [ ] Human check: bubbles, district panel, site sheet, legend, zoom, drawer and top-row icons are dark and legible; buttons are readable; disabled states are distinguishable
