# 03 — Horizontal zoom pill

**What to build:** Replace the two vertically stacked zoom buttons with one horizontal cream pill ordered `−  +`. Use charcoal glyphs/text, a subtle border and shadow, rounded outer corners, and restrained pressed/disabled feedback matching the Photo 3 site-detail card. Keep both halves as accessible independent buttons and preserve all zoom behaviour.

**Mockup:** [Photo 3](../mockups/03-site-card-map.jpg) is the material/palette reference only. The requested horizontal `−  +` pill overrides [Photos 2](../mockups/02-expanded-faction-key-map.jpg)–[4](../mockups/04-faction-key-states.jpg)'s vertical controls. Do not copy Photo 4's separate orange buttons.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `scenes/components/map_zoom_buttons.gd`; `scenes/components/ui.gd`; `scenes/screens/map.gd`; `scenes/components/map_canvas.gd`; `systems/map_zoom.gd`; `tests/test_map_zoom_buttons.gd`; `tests/test_map_zoom.gd`; `docs/ui-vision.md`

- [ ] One cream horizontal pill renders at the map's bottom-right, ordered minus then plus, with a subtle internal divider if needed for affordance.
- [ ] Charcoal controls, restrained hover/pressed/disabled feedback, subtle border/shadow, and rounded shape match the Photo 3 card family; no orange button fill.
- [ ] Each half has at least the existing `UI.ICON_BUTTON_SIZE` touch target in both dimensions and neither glyph clips.
- [ ] Minus calls `step_zoom(-1)`; plus calls `step_zoom(1)`; bounds disable only the unavailable half exactly as today.
- [ ] No changes to zoom step/range, centring tween, camera persistence, map pan, or saved view.
- [ ] Pill remains clear of safe-area/nav chrome and does not block important map interactions at supported phone widths.
- [ ] `tests/test_map_zoom_buttons.gd` verifies horizontal order/layout, minimum touch targets, glyph visibility, callback directions, and live disabled-state updates.
- [ ] Godot 4.7 syntax checks pass for touched `.gd` files; full suite passes.
- [ ] Human QA: comfortable one-handed taps, no overlap with nav/safe area, readable disabled state, visual match to cream card family. Report exact on-device checks.
