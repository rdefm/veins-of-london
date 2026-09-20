# 09 — Compact map bubble UI

**What to build:** Tapping a vein on the Network Map opens a small bubble anchored above its pin showing: basic identity, `Lv current/max` with `max` level segments (`current` filled), a slim horizontal condition bar with a distinct 50 marker and a marked 90+ development range (special-ceiling veins show their actual ceiling while keeping the 90 threshold), and a compact, non-color-only cue for development eligibility and raised raid exposure. Two round icon actions — Harvest and Cultivate, with short captions — sit separately from the bubble's information area; tapping the information area (not the action icons) opens the larger detail panel (ticket 11). Routine time-cost labels are omitted after the tutorial (display only, no cost change).

Reference mockups (design reference only, not implemented Godot UI): `.scratch/cultivation-refining/vein-map-bubble.png`, `.html`, `.fragment.html`.

**Blocked by:** 01, 02, 04, 05, 06, 07 (needs real level, condition, eligibility, and raid-exposure data to render).

**Relevant files:**
- `scenes/screens/map.gd` (Map tab: diagram + district panel + sheet)
- `systems/station_bubble.gd` (site/vein-stop tap-bubble decision layer)
- `scenes/*/cultivate_result_modal.gd` (Cultivate-attempt result card — Cultivate action still executes immediately, no confirmation step)
- `docs/M1.5-NETWORK-MAP.md`, `docs/ui-vision.md` (glyph grammar, chrome/palette — do not redesign the map or override these)

**Status:** ready-for-agent

- [ ] Bubble shows `Lv current/max` and exactly `max` segments with `current` filled
- [ ] Condition bar shows a distinct 50 marker and the 90+ development zone, using the vein's actual ceiling (100 or 120) while keeping the threshold at 90
- [ ] Development eligibility and raised raid exposure are shown compactly and not by color alone
- [ ] Harvest and Cultivate are separate round icon actions with captions; tapping them does not open the detail panel
- [ ] Tapping the bubble's information area (not an action icon) opens the larger detail panel
- [ ] Cultivate executes immediately with no recurring confirmation step
- [ ] Routine time-cost labels are hidden post-tutorial
- [ ] Device QA checklist (for the human): bubble anchoring at portrait mobile width, readable pips/markers, distinct info-vs-action hit targets, no tap-through, immediate cultivate feedback, capped/emergency/120-ceiling states read correctly
