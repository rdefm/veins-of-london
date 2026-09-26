# 03 — Territorial scrappers roll a variant

**What to build:** Whenever a Territorial Scrapper enters combat, from any entry point (raids, defend-vein, debug combat, or anything else that spawns one), it is randomly given one of the discovered territorial variants and uses that variant's sprites for the whole fight. The old single `territorial_scrapper` sprite set is gone.

Decisions (agreed with the human):
- **Rolled once per combat instance**, when the enemy is spawned, and stored on the enemy's entry in combat state (e.g. `variant: "territorial2"`, a plain string). Saves, snapshots, and Rewind therefore keep it; nothing re-rolls when the screen re-renders.
- **The player's own variant is never used.** Exclude whatever `player.model` currently is from the pool.
- **Spread before repeating:** within one fight, give out distinct variants until the pool is used up, and only then allow repeats (e.g. 2 variants available and 3 scrappers gives both variants, plus one repeat). Other enemy types in the same fight don't affect this.
- Use the project RNG (`Rng`) so rolls stay deterministic under the existing seeding.
- **Empty pool** (defensive; can't happen with 3 variants): fall back to the `default` stand-in template. Don't crash.
- Stats, name, and the rest of the Territorial Scrapper stat block are unchanged. This is visuals only.

**Blocked by:** 02 — Build territorial variant sprite sets from the folders.

**Relevant files:**
- `systems/combat.gd` — `generate_raid_enemy`, `_spawn_guard_instance`, and any other path that spawns `territorialScrapper` (check `start_raid`, `start_defend_vein`, `start_debug_combat`)
- `autoload/Rng.gd`
- `scenes/components/combat_stage.gd` — `enemy_template_key()` returns the enemy's stored variant for scrappers
- `data/combat_visuals.json` — delete `templates.territorialScrapper`
- `assets/combat/territorial_scrapper/` — delete the folder
- `data/enemies.json` — `raidGuards.territorialScrapper` (read only; the stat block stays as is)
- `tests/test_combat.gd` (or the existing combat system test file), `tests/test_combat_screen.gd`
- `docs/REFERENCE.md` §2 STATE SCHEMA (combat enemy entry gains `variant`), §3.7a Squad combat
- `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Every spawned Territorial Scrapper has a `variant` field naming a discovered variant; no other enemy type gets one.
- [ ] A scrapper's variant never equals `player.model` (tested across many seeds).
- [ ] With N scrappers and P variants available, the fight holds min(N, P) distinct variants (tested).
- [ ] The combat stage draws each scrapper with its stored variant's sprites, including the ko-from-hurt pose.
- [ ] `territorial_scrapper/` and `templates.territorialScrapper` are gone, and no references remain.
- [ ] The variant survives save/load and Rewind (a test round-trips the state).
- [ ] REFERENCE.md §2 documents the enemy `variant` field.
- [ ] The syntax check is clean, all tests pass, and CODEMAP is updated.

**Human on-device check:** start a raid against 2–3 scrappers and confirm they mostly look different from each other and never look like your own character.
