# 119 — Phone home-grid tiles overlap and obscure each other

**What to build:** Discovered during human visual QA (screenshot-12-09-2026.PNG):
the Phone tab's home grid (`phone.gd` `_build_home()`, `AppTile`) renders
with multiple tiles overlapping rather than laid out in a clean grid:

- "Factions" and "The Ticker" tiles overlap each other.
- A "Notes" label is visible peeking out from underneath the "Factions"
  tile, implying the Notes tile is stacked behind it rather than
  positioned in its own grid cell.
- "Profile" overlaps "Notifications".
- The "Reynard's" tile's full-tile coloured background (orange/red) and
  the "Harrow's" tile's full-tile coloured background (green) each bleed
  across and cover parts of neighbouring tiles ("VfL", "Contacts",
  "Debug") instead of staying contained to their own cell.

This reads as a layout/positioning bug in the home grid (wrong
container type, hardcoded/absolute positions instead of grid-flow, or a
z-order issue with two tiles occupying the same cell), not a colour or
theme issue — diagnose the actual cause before fixing.

**Blocked by:** None.

**Status:** ready-for-agent

- [ ] Root cause identified: why do these tiles occupy overlapping screen
      space instead of each sitting in its own grid cell.
- [ ] Every app tile on the Phone home grid (Notes, Factions, The Ticker,
      Profile, Notifications, Reynard's, Contacts, VfL, Debug, and any
      others) renders in its own non-overlapping cell, at normal phone
      width.
- [ ] No tile's background colour/art bleeds outside its own cell into a
      neighbour's.
- [ ] Add a test (likely in `tests/test_phone_screen.gd` or
      `tests/test_app_tile.gd`) that catches two home-grid tiles occupying
      overlapping rects, so this doesn't regress silently again.
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean
      on every touched file; `scripts/run_tests.sh` passes.

Human visual QA note: on-device, open the Phone tab's home grid and confirm
every tile is fully visible, non-overlapping, and legible at normal phone
width.
