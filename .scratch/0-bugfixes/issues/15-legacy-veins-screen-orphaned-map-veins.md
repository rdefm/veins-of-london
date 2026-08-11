# 15 — Legacy "Seed a new vein" screen creates veins invisible on the map

**What to build:** `scenes/screens/veins.gd` is still registered in `scenes/Main.gd` (screen id `"veins"`) and still exposes a "Seed a new vein" card calling the old M0 free-floating `Cultivating.seed(oreType)` (`systems/cultivating.gd`) — but `docs/M1-LONDON.md` §D4 already said this screen was deleted as part of the M1 nav restructure, and its own §D2 says `attempt_seed(siteId)` (`systems/sites.gd`) "replaces free-floating seeding." It was apparently never actually removed.

A vein created via `Cultivating.seed()` has only a `district` field and no `siteId` — it bypasses the site/prospecting pipeline entirely. The Network Map's rendering is built from `state.world.sites`, so a vein with no backing site never gets a stop or a connection line drawn for it: this is the exact bug hit seeding a vein in King's Cross (invisible stop, no line to nearby veins), which "fixed itself" only once other sites were later discovered normally in that district.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `scenes/screens/veins.gd` deleted, along with its `"veins"` registration in `scenes/Main.gd`.
- [ ] `systems/cultivating.gd`'s `seed()` function deleted.
- [ ] `tests/test_cultivating.gd` and `tests/test_veins_screen.gd` (or their `Cultivating.seed()`-specific coverage) removed/updated accordingly; call-sites in `tests/test_playthrough.gd` updated to seed via `Sites.attempt_seed()` instead.
- [ ] All vein creation in the game now exclusively goes through `Sites.attempt_seed(site_id)`, which always creates a matching site+vein pair.
- [ ] Full test suite passes after removal.
