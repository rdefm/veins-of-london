# 03 — Map hamburger doesn't open the filter drawer

**What to build:** Tapping the hamburger button in the Map tab's top bar does nothing visible — the map controls drawer never appears. The button is a shared tap button that toggles the drawer, so a double fire (see 01) would open and close it in the same frame. After 01, verify one tap opens the drawer and another closes it; if it's still dead, find and fix the real cause.

**Blocked by:** 01 — One tap fires twice

**Relevant files:** `scenes/screens/map.gd` (`_menu_button`, ~line 107), `scenes/components/map_controls.gd` (`toggle()`), `scenes/components/tap_button.gd`, `tests/test_map_screen.gd`

**Status:** ready-for-agent

- [ ] Simulated device tap (touch + emulated-mouse twin) on the hamburger leaves the drawer open; a second tap closes it (test)
- [ ] Human checks on device: hamburger opens the drawer on first tap, closes on second
