# 10 — Vein list: drag to scroll

**What to build:** Map → "View veins" opens the vein list, which can't be scrolled by dragging. A finger drag anywhere on the list (including over cards and buttons) must scroll it like a normal phone list, while a still tap still opens the row.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/vein_list.gd`, `systems/vein_list_nav.gd`, `scenes/components/tap_button.gd` (drags bubble to scroller), `scenes/screens/map.gd`, `scenes/components/map_canvas.gd` (map may be eating input)

**Status:** ready-for-agent

- [ ] Drag scrolls from anywhere on the list
- [ ] Still tap on a row still opens it; a drag doesn't trigger it
- [ ] Map underneath doesn't pan while scrolling the list
