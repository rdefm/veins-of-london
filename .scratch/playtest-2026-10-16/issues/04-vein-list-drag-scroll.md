# 04 — View veins list: touch-drag scroll

**What to build:** Map tab → "View veins": the list can't be scrolled by dragging. A finger drag on the list scrolls it like a normal phone list (with momentum). A drag must not trigger a row tap; a clean tap still opens the row.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/vein_list.gd`, `systems/vein_list.gd`, `scenes/screens/map.gd`

**Status:** ready-for-agent

- [ ] Drag anywhere on the list (incl. over rows/buttons) scrolls it
- [ ] Drag does not fire row actions; tap does
- [ ] Works in light and dark map modes
- [ ] On-device check listed in report
