# 136 — Android status bar always visible

**What to build:** During gameplay the phone's own status bar (time, battery, Wi-Fi) only shows if you swipe down. Make it visible all the time: turn off immersive mode for the Android export so the system status bar stays up. Game UI starts below it (top safe-area inset) so nothing, including the top bar, is covered. The Android nav buttons that briefly appear when you swipe are out of scope.

**Blocked by:** None — can start immediately.

**Relevant files:** `export_presets.cfg` (`screen/immersive_mode`), `project.godot` (window/display settings), `scenes/components/ui.gd`, `scenes/components/top_bar.gd`, main scene root layout.

**Status:** ready-for-agent

- [ ] Immersive mode off in the Android preset
- [ ] Top safe-area inset applied (DisplayServer safe area); nothing drawn under the status bar
- [ ] Web export not affected
- [ ] Human on-device: status bar visible on the title, map, combat and phone screens; top bar fully visible below it
