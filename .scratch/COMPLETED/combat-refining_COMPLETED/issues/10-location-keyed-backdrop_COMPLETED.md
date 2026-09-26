# 10 — Location-keyed edge-to-edge backdrop

**What to build:** The fight's backdrop changes with where the fight happens. When combat starts, the system records a `locationKey` on the combat state per ticket 01 (district of the raided/defended vein; the player's current district for street muggings; the fixed home key for home raids). The stage resolves its backdrop plate by location first, then falls back to the context plate, then to the existing palette fallback colour — all from the visuals data file, no paths in code. The plate renders edge-to-edge behind the full-width stage from ticket 02. Ships with at least one real plate wired for one district so the lookup is demonstrable; the remaining plates are human-supplied art added by data only.

**Blocked by:** 01 — Canonical contract amendments; 02 — Two-region layout.

**Relevant files:**
- `systems/combat.gd` — `_start_combat`, `start_mugging`, `start_street_mugging`, `start_archie_deal_mugging`, `start_home_raid_combat`, `start_raid`, `start_defend_vein`, `exit_combat` (reset shape)
- `systems/sites.gd` — vein → district lookup (`find_faction_vein` and player-vein equivalents)
- `systems/travel.gd` / `GameState.state["world"]` — player's current district field
- `scenes/components/combat_stage.gd` — `_sync_backdrop`, `_backdrop_texture` stretch/anchoring to full width
- `data/combat_visuals.json` — `backdrops` re-keyed with a location tier above the context tier
- `data/districts.json` — district ids (read only)
- `assets/combat/` — backdrop plate(s)
- `autoload/GameState.gd` — save/load shape if combat schema needs a migration default
- `tests/test_combat.gd` — `locationKey` set correctly per start path
- `tests/test_combat_screen.gd` — "stage_backdrop_shows_the_palette_fallback_fill…", "stage_backdrop_follows_context_across_fights", "…archie_deal_mugging_reuses_muggings_fallback", "…unrecognised_context…"
- `docs/REFERENCE.md` — §2 combat schema `locationKey`; §3.7 backdrop lookup order (as amended by 01)
- `docs/combat-animation-vision.md` — §2.1 Backdrops

**Status:** done

- [x] Every `start_*` path sets `locationKey`; raid/defend use the vein's district, mugging uses the player's district, home raid uses the fixed key
- [x] Lookup order location → context → palette colour verified by three headless cases (plate for location; no location plate but context plate; neither)
- [x] Backdrop texture rect spans the full stage width and height with no inset or border
- [x] Same context in two different districts shows two different plates when both are configured
- [x] Unknown `locationKey` degrades to the context/palette path, never a crash
- [x] Save → load round-trips `locationKey`; older saves without it load with a safe default
- [x] `scripts/check_all.sh` and `scripts/run_tests.sh` pass; CODEMAP rows for `combat.gd`, `combat_stage.gd`, `combat_visuals.json` updated
- [x] Report lists which districts still need plates (human art)

**Notes:** Per human, the supplied plate (`assets/combat/backdrops/street.png`) ships as the generic street *context* plate for mugging/event_mugging/archie_deal_mugging, not a district plate; `locationBackdrops` ships empty and the location tier is proven by tests with stand-in textures. Location plates keyed by `locationKey` only (no timeOfDay yet). Stage border removed per human (vision §9 amended).
