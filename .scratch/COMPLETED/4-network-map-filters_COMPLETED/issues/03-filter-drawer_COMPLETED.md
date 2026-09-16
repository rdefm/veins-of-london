# 03 — Filter drawer (replaces chip row)

**What to build:** Replace `MapControls`' filter chip row (`scenes/components/map_controls.gd` — currently 5 mode buttons + pacing toggle + "?" legend button, all inline) with a drawer opened by the hamburger button from ticket 02's new Map-local top bar. The drawer lists the 5 existing filter modes (Ownership/Type/Strength/Charge/Security) as a radio-style list (one active, tap to switch, matching the reference screenshot's "Day Map/Night Map" grouping), with the pacing toggle and legend ("?" → `Modal.open("network_reference")`) grouped below as separate list rows. No behaviour change to what any of the 5 modes or the pacing toggle do — this ticket only moves where you reach them from. `filter_mode` and `pacing_mode` stay UI-local state exactly as today, just read/written from the drawer instead of the chip row.

**Blocked by:** 02 — Map-local top bar & default zoom-in (needs the hamburger button to open from)

**Status:** ready-for-agent

- [ ] Hamburger button (ticket 02) opens a drawer/side panel listing: the 5 filter modes (radio-style, active one indicated), then the pacing toggle, then the legend row — sectioned similarly to the reference screenshot.
- [ ] Selecting a filter mode in the drawer calls `map_canvas.set_filter()` exactly as the old chip row did; selecting pacing calls `map_canvas.set_pacing()`; tapping legend opens the existing `network_reference` modal — none of these three behaviours change, only their entry point.
- [ ] The old inline chip row (`_chip_row`/`_scroll` in `map_controls.gd`) is removed; `MapCanvas`'s draw area reclaims that screen space (map gets more visible height on a phone).
- [ ] Drawer closes after a selection (or stays open — implementer's call, note which in the report) and is dismissible (tap outside / back gesture / explicit close).
- [ ] `filter_mode`/`pacing_mode` remain UI-local: not written to `GameState.state`, not persisted across restarts — same as today.
- [ ] Tests cover: selecting each filter mode from the new drawer entry point still drives `MapStyle`'s pure re-styling functions correctly (regression on `tests/test_map_controls.gd` if it exists, or equivalent), and pacing toggle default/behaviour is unchanged.
- [ ] Report lists exactly what a human should check on-device (drawer open/close gesture feel, tap targets for each list row, that closing the drawer doesn't lose the current filter selection, map canvas now has more vertical room).
