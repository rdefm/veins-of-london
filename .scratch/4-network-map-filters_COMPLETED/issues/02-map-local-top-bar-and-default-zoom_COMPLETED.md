# 02 — Map-local top bar & default zoom-in

**What to build:** Replace the Map tab's in-page header (currently: back button, "The Network" heading, muted hint — `scenes/screens/map.gd`'s `_build_diagram_layer()`) with a local top bar: **hamburger icon (left) / "The Network" title (centre) / bag icon (right)**, matching the reference screenshot layout. This is chrome local to the Map screen's diagram view only — the app-wide `TopBar` (cash/day/bag, `scenes/components/top_bar.gd`) and the 5-tab `NavBar` are untouched everywhere, including Map (this ticket doesn't remove or hide either). The hamburger button doesn't need to open anything yet (ticket 03 wires it to the filter drawer) — a no-op or `Modal.open` stub is fine here, or land it together with 03 if that's simpler in practice. The bag icon calls the same `Bag.open()` the app-wide TopBar's bag button already uses. Separately, the map now opens already zoomed in a moderate amount rather than today's zoomed-to-fit default — bump `MapZoom.DEFAULT` (`systems/map_zoom.gd`, currently `0.5`) toward `MapZoom.EVENT_ZOOM` (`0.8`), landing somewhere that shows roughly 2-3 districts' worth of detail on open, not the exact value.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Map screen's diagram view shows a top bar with hamburger (left), "The Network" title (centre), bag icon (right) instead of the old back-button/heading/hint block.
- [ ] The back button's function (returning to wherever it returned to before — check M1's D4 Map-tab contract) is preserved somewhere reachable, even if its position moves.
- [ ] Bag icon opens the same bag drawer as the existing global TopBar's bag button (`Bag.open()`).
- [ ] `MapZoom.DEFAULT` raised to a moderate zoomed-in value (between the old `0.5` and `EVENT_ZOOM`'s `0.8`); `MapCanvas` opens at this zoom on first Map-tab visit.
- [ ] No change to `MapZoom.MIN`/`MAX`, pinch-zoom behaviour, or pan behaviour — only the starting zoom.
- [ ] Tests cover: `MapZoom.clamp_zoom` still behaves correctly with the new `DEFAULT` (regression check on `tests/test_map_zoom.gd`), and any new pure top-bar-state logic if applicable.
- [ ] Report lists exactly what a human should check on-device (top bar layout on a real phone width, hamburger tap target size, bag icon still opens the bag, initial zoom level feels right — not so zoomed in that districts are hard to find, not so far out it's the old view).
