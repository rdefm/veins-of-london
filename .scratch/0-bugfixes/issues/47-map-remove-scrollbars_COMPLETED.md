# 47 — Map: remove scrollbars

**What to build:** `scenes/screens/map.gd:194-199` wraps the map diagram in `TouchScrollContainer` (a custom `ScrollContainer` subclass added specifically for touch-drag panning) with `horizontal_scroll_mode`/`vertical_scroll_mode` set to `SCROLL_MODE_AUTO` (`map.gd:196-197`), which renders native scrollbars whenever content exceeds the viewport — true at any zoom above fit-to-screen. Remove the visible scrollbars while keeping touch-drag panning intact (switch to `SCROLL_MODE_HIDDEN` or equivalent, not `SCROLL_MODE_DISABLED` — panning must keep working).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `horizontal_scroll_mode`/`vertical_scroll_mode` on the map's `TouchScrollContainer` changed so scrollbars no longer render, while drag-to-pan still works.
- [ ] Manual check noted for the human: confirm no scrollbar is visible on the right/bottom of the map tab at any zoom level, and that dragging to pan still works.
