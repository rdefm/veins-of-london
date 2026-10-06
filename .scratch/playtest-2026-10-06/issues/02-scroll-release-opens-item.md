# 02 — Scrolling opens the item under the finger on release

**What to build:** Since build 26-10-05, on all screens: dragging a finger on a menu option scrolls the list correctly, but lifting the finger then opens the option it was on. A press that moves past the shared tap slop must only scroll and never open anything; a still press-release still opens. Check whether the emulated-mouse release (see 01) bypasses the drag tracking before adding new logic.

**Blocked by:** 01 — One tap fires twice

**Relevant files:** `scenes/components/tap_button.gd`, `scenes/components/touch_scroll_container.gd`, `scenes/components/ui.gd`, `scenes/phone_apps/*`, `tests/support/ui_sim.gd`, `.scratch/playtest-2026-10-04/issues/11-scroll-tap-vs-drag-cards_COMPLETED.md`

**Status:** ready-for-agent

- [ ] Drag beyond slop then release on a tappable item inside a scroll surface does not fire it (test with touch + emulated-mouse event sequence)
- [ ] Still tap still fires exactly once
- [ ] Human checks on device: scroll lists in phone apps and other menus by dragging on options; nothing opens on release
