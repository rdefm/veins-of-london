# 06 — HQ merge

**What to build:** the HQ tab per D4 — workbench (= the crafting screen; visually upgrades when workshop/library/lab rooms are built), gym placeholder (training arrives M2), rooms, security, stored ore, tier upgrade, assigned contacts. Merges and replaces the old M0 property + crafting screens.

**Blocked by:** 03 (needs the nav shell to exist).

**Status:** COMPLETED

- [x] All M0 property-screen functionality (rooms, security, stored ore, tier upgrade) present under HQ
- [x] All M0 crafting-screen functionality (recipes, devices) present under HQ as the "workbench"
- [x] Workbench visual state reflects installed workshop/library/lab rooms
- [x] Assigned-contact UI (lab/veinStation room assignment) present and functional
- [x] M0 property and crafting screens deleted; no remaining nav path to them
- [ ] Human visual QA: install a room, assign a contact, craft an item, all from HQ
- [x] `godot --headless --check-only --script` clean on all touched files

## Implementation notes

- `scenes/screens/hq.gd` (new) merges the old `property.gd` + `crafting.gd` content into one screen, registered as `SCREEN_SCRIPTS["hq"]` in `scenes/Main.gd`. `property.gd`/`crafting.gd` deleted; dangling references fixed (`scenes/screens/world.gd`'s "Manage property" button, `data/events/james_meeting.json`'s post-tutorial `set_screen`).
- New UI, previously nonexistent anywhere in the codebase: contact-assignment controls for the `lab`/`veinStation` rooms (`Contacts.assign_to_room` had no caller before this).
- **Scope decision (confirmed with human):** `home.storedOre` had no deposit/withdraw mechanic anywhere — it was write-only (raid-loss code) and never populated by the player, so HQ had nothing real to show. Rather than build a new deposit/withdraw system (out of scope) or show a dict that's always empty, `home.storedOre` was merged into `player.orichalchum` — carried ore is now what a home raid risks/loses (`systems/home.gd`, `systems/combat.gd`'s home-raid-loss code). This is a real mechanics change beyond the ticket's literal scope; `docs/REFERENCE.md` §2/§3.3/§3.8 updated to match, plus `tests/test_home.gd`, `tests/test_combat.gd`, `tests/test_gamestate.gd`.
- PROSE-REVIEW: new flavour text in `hq.gd` — workbench tiered description (`_workbench_flavor_text`) and the gym-placeholder card text.
