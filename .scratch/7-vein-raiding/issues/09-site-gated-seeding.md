# 09 — Site-gated seeding: retire free-standing vein creation

**What to build:** Seeding a new vein is only ever reachable by selecting an unseeded site (the existing `Sites.attempt_seed()` flow) — remove the Veins screen's standalone "Cultivate" action, `Cultivating.seed()`'s only current UI entry point, so a player can no longer create a vein with no site behind it. Also retire the district event-card engine's siteless `grant_vein` effect op (`systems/events.gd`), which creates the exact same kind of site-less vein but from event content instead of a UI button — it's unused by any current event JSON today (only its sibling `grant_vein_with_site`, which already creates a proper site alongside the vein, is used, by the home-raid debrief tutorial events), so removing it costs nothing now but closes off a second path back into the same gap for any future event card. `Cultivating.seed()`'s own function/formula may stay in the codebase unreferenced, or be deleted — implementer's call, no behavioural difference either way.

This ticket exists because `state.factions[id].veins` (vein-raiding ticket 06's workaround for raiding a vein with no site) and its raid-side handling only need to exist at all because free-floating veins could be created in the first place. This ticket closes that off at the source; ticket 11 then removes the now-unnecessary workaround.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] The Veins screen no longer offers a way to seed a vein without first selecting an unseeded site
- [ ] Seeding remains reachable through the existing site-selection flow (`Sites.attempt_seed()`), unchanged
- [ ] The siteless `grant_vein` event effect op is removed from `GameData`'s registered op vocabulary; its site-creating sibling `grant_vein_with_site` is untouched and remains the only vein-granting op
- [ ] Confirmed before removal: no currently-shipped event JSON references `grant_vein` (only `grant_vein_with_site` is expected to be in use, by the home-raid debrief events)
- [ ] No remaining code path can create a `state.player.veins` entry with `siteId: null` — every creation path, once this ticket lands, always produces a site-tied vein
- [ ] Tests cover: the Veins screen's seed action requires a site id (or the standalone action no longer exists); the `grant_vein` op is no longer in `GameData`'s effect-op vocabulary and errors/is rejected if referenced; `grant_vein_with_site` behaviour is unchanged
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes
