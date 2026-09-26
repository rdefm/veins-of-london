# 13 — Menu restyle batch D: bag drawer, map bubble

**What to build:** Parent 08, batch D. Convert `bag_drawer.gd` and `map_bubble.gd`'s text-option rows / icon-label button per 07's audit to `MapCardStyle` pieces; final grep that no placeholder button style remains outside Phone-OS apps.

**Blocked by:** 10.

**Relevant files:** audit list in `07-menu-restyle-audit-and-first-menus_COMPLETED.md`, `scenes/components/map_card_style.gd` (shared pieces), `scenes/components/ui.gd`, `docs/ui-vision.md` §4–§7.

**Status:** ready-for-agent

- [x] Both components converted
- [x] Grep-verified: no placeholder `UI.button`/`UI.symbol_button`/`UI.card` left in audited files
- [x] No behaviour change; full suite passes
