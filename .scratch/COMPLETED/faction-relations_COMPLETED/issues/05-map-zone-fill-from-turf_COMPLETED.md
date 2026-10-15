# 05 — Map zone fill from turf

**What to build:** District map zones are tinted by the live controller instead of the static heritage presence: controller colour at full fill alpha, a neutral/striped treatment when contested, the player line colour when the player controls the district. Footholds are not drawn. The fill respects the dark-map contrast rules.

**Blocked by:** 01 — Turf core

**Relevant files:** `scenes/components/map_canvas.gd`, `scenes/components/map_palette.gd`, `data/map_palette.json`, `systems/map_layout.gd` (`faction_first_presence_anchor` — line anchors stay heritage-based), `systems/map_style.gd`, `tests/test_map_palette.gd`, `tests/test_map_style.gd`, `tests/test_map_canvas.gd`, `tests/test_map_dark_overlays.gd`. `docs/M1.5-NETWORK-MAP.md` (zone fills, dark-map contrast), `docs/ui-vision.md`.

**Status:** ready-for-agent

- [ ] Zone fill colour comes from the `state.turf` controller
- [ ] Contested gets a neutral/striped treatment; player control uses the player line colour
- [ ] Light and dark modes both meet M1.5 contrast rules (tests)
- [ ] A turf flip re-tints after rollover
- [ ] On-device QA list in the report
