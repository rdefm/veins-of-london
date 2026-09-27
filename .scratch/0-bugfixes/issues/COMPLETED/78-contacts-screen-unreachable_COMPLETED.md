# 78 — Restore reachability to the `contacts` screen (Archie/James)

**What to build:** The `contacts` screen (`scenes/screens/contacts.gd`) is where Archie's and James's contact cards live, gating their bespoke SMS threads (`sms_archie`/`sms_archie_2`) and James's job offers. It has no live entry point anywhere in the game — `nav_bar.gd`'s dock is Phone/Map/HQ only, and `PhoneApps.apps()` (the phone home grid) has no `contacts` entry. The only two places in the codebase that navigate to `"contacts"` are `archie_motion.json` and `james_motion.json`'s own `on_complete` blocks — i.e. it only points back to itself, a dead end. This is a regression from the ticket-11 dock restructure (Phone/Map/HQ collapse) and ticket-07 phone home grid, which replaced the old card-list navigation without carrying forward a way back into `contacts`. It affects a plain New Game exactly as much as debug start; tests don't catch it because `tests/test_playthrough.gd` drives events via `Events.start_event()` directly, bypassing UI navigation entirely. Fix: add a tile to the phone app grid (`PhoneApps.apps()`), same `AppTile` pattern as Messages/Notes/Factions, that opens `contacts`.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] New entry in `PhoneApps.apps()` (e.g. id `"contacts"`) routing to the `contacts` screen — unlocked from game start (`metArchie` is set true immediately post-intro, before the grid is ever shown).
- [ ] `PhoneScreen._on_app_tile_pressed()` special-cases this tile the same way it already special-cases `"vfl"`: `Nav.go_to("contacts")` directly, since `contacts` is a standalone `SCREEN_SCRIPTS` entry, not a `phoneNav.app` — it doesn't fit the `PhoneNav.open_app()` path the other tiles use.
- [ ] New test covers the tile's presence in the grid and that pressing it calls `Nav.go_to("contacts")`.
- [ ] Existing `tests/test_phone_apps.gd` / `tests/test_phone_home_grid.gd` still pass.
- [ ] Manual check noted for the human: fresh debug start, tap the new tile, confirm Archie's card renders and his SMS thread opens; confirm James's card renders (once `contacts.james.unlocked` is true) and his SMS/job flow opens. Repeat on a plain New Game after the Archie/James meeting events fire.
