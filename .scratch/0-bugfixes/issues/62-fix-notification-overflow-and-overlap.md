# 62 — Fix notification overflow/overlap

**What to build:** Two positioning bugs in `scenes/components/notification_toast.gd`:

1. **Right-edge overflow.** Each entry sets `entry.text` directly on a plain `Button` (`notification_toast.gd:77-78`) with no autowrap configured — Godot `Button` text is single-line by default and will clip/truncate rather than reflow, so a long notification string can run off the visible area rather than wrapping.
2. **Top-bar overlap.** `_entries_container` anchors with `offset_top = UI.top_bar_clearance()` (`ui.gd:493-494`, `TopBar.BAR_HEIGHT (40) + safe_area_top_inset()`), which assumes the global 40px `TopBar` is showing. On the Map screen specifically, the global `TopBar` is hidden (`scenes/Main.gd:71`, `TOP_BAR_HIDDEN_SCREENS`) and replaced by `MapScreen`'s own shorter top row (`scenes/screens/map.gd:143`, `margin_top = 8 + safe_area_top_inset()`, ~40px tall icon buttons) — leaving roughly an 8px band where the toast's first entry overlaps the map screen's own hamburger/title/bag row. Toast `Button`s have `mouse_filter = MOUSE_FILTER_STOP` (`notification_toast.gd:79`), so a toast in that band can intercept taps meant for the map screen's own buttons.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Notification entry text wraps within the container width instead of clipping/overflowing (enable autowrap or switch to a `Label`-based layout that supports it).
- [ ] Toast top offset is screen-aware: on screens where the global `TopBar` is hidden (currently just `map`), the toast clears that screen's own top row instead of assuming the global 40px bar.
- [ ] Manual check noted for the human: trigger a long notification and confirm it wraps fully on-screen; open the Map screen with a notification showing and confirm it doesn't overlap/intercept taps on the map's own top-row buttons.
