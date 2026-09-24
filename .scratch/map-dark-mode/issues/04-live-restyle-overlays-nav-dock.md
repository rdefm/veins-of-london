# 04 — Live restyle of Map overlays + nav dock

**What to build:** When `meta.mapDarkMode` flips while the Map tab is open, every Map-tab surface must switch immediately, without leaving the tab. That covers district panel / site sheet cards, station/vein bubbles, legend, zoom buttons, controls drawer, top-row icon buttons (hamburger / bag / search), and scrims. These build their styleboxes once at construction, so either restyle them in place or have `map.gd._refresh` rebuild overlay nodes when the flag changed. Pick whichever keeps open bubbles/sheets and filter state intact.

The top-row icons use the global theme's `font_color` via `UI.icon_button`, so give them a map-local colour override. The bottom nav dock (`scenes/components/nav_bar.gd`) renders its dark variant while the current screen is `map`, and its normal look everywhere else. The dock's colours come from the map palette's chrome tokens only while on Map.

Presentation only: no system reads the flag except `Preferences`.

**Blocked by:** 01, 02

**Relevant files:** `scenes/screens/map.gd` (`_refresh` L49, top row L120-162, overlays), `scenes/components/map_bubble.gd`, `scenes/components/map_legend.gd`, `scenes/components/map_zoom_buttons.gd`, `scenes/components/map_controls.gd`, `scenes/components/map_card_style.gd`, `scenes/components/ui.gd` (`icon_button` ~L250), `scenes/components/nav_bar.gd`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Toggling with a bubble / site sheet / legend open restyles it in place (or reopens it identically); the filter mode is kept
- [ ] Nav dock is dark on Map in dark mode and normal on Phone/HQ
- [ ] Test (live tree): after toggling, the overlay styleboxes' `bg_color` equals the dark tokens; the nav dock's colour switches with the current screen
