# 13 — Faction vein guard repel

**What to build:** Guards on a vein defend it the same way whoever owns it. Decisions are in spec.md §Faction guard upkeep and extra guards → "Comments — faction vein guard repel".
- **Rivalry.** When a faction's rivalry attempt would succeed against a guarded rival vein, the defender's guards get a repel roll. A repel fails the attempt, and the outcome records that it was repelled. It's silent, like the rest of rivalry: no Notify, Ticker or map event.
- **Player veins.** The missed-defend repel on a player's vein counts every guard (the Hired Guard tier guard plus extras), not extras only. A `guarded` vein with no extras now gets one guard's repel chance.
- **Player raids.** When the player is caught raiding a faction vein, they fight one enemy per guard on that vein: minimum 1, at most the combat squad cap of 3. The raid event asks for "the vein's guards" instead of a fixed count. A literal count in event data still works.

Repel odds use the existing shared `guardRepel` constants. Kit burns don't change: every rivalry attempt still burns both kits. The repel roll uses the shared Rng stream and consumes a roll only when the odds succeed and the vein has 1+ guards.

`factionRivalry` is currently false, so rivalry repel stays dormant in play. Rivalry tests turn the flag on.

**Blocked by:** None — can start immediately (09 — Factions hire extra guards is done).

**Relevant files:**
- `systems/factions.gd` (`roll_rivalry_odds`, `resolve_rivalry_outcome`, `apply_rivalry_resolution`)
- `systems/raiding.gd` (`guard_repel_chance`, `_guards_repel_defend_raid`, `_expire_pending_defend_raids`)
- `systems/cultivating.gd` (`vein_guard_count`)
- `systems/events.gd` (`_start_raid_combat`)
- `systems/combat.gd` (`generate_raid_enemy`, `start_raid`, `SQUAD_MAX`)
- `data/events/vein_raid.json` (`start_raid_combat` guards)
- `data/constants.json` (`guardRepel`, `factionRivalry`)
- `tests/test_factions.gd`, `tests/test_raiding.gd`, `tests/test_events.gd`, `tests/test_combat.gd`
- REFERENCE.md §1.6 `data/vein_security.json`, §1.8 `data/factions.json` (Rivalry, Faction guard hiring), §3.12 Vein raiding (Faction extra guards, Raid kit burns)

**Status:** ready-for-agent

- [ ] A rivalry attempt whose odds succeed against a vein with 1+ guards (tier or extra) can be repelled. The vein stays with the defender, no relation penalty or map event is applied, and the outcome is marked repelled.
- [ ] A rivalry attempt against a vein with 0 guards never rolls repel, so the Rng stream isn't advanced by it.
- [ ] A rivalry attempt whose odds fail never rolls repel.
- [ ] Repel chance for a faction vein = the shared guard repel chance applied to tier guard + extras.
- [ ] Rivalry kit burns are unchanged for repelled attempts: both sides still burn.
- [ ] A player vein at `guarded` with 0 extras gets a repel roll on a missed defend. Repel chance counts tier guard + extras.
- [ ] A caught player raid on a faction vein spawns one enemy per vein guard: 0 guards → 1, 2 → 2, 4 → 3 (clamped).
- [ ] `vein_raid.json` uses the vein-guards form. An integer `guards` in any event still spawns that many.
- [ ] No new player-facing prose.
- [ ] Seeded rivalry/raid tests re-pinned where the extra roll shifts the stream.
- [ ] REFERENCE.md §1.6, §1.8 and §3.12 updated to describe faction vein repel, all-guard counting on player veins, and guard-sized raid squads.
- [ ] CODEMAP.md rows updated if a file's responsibility changed.
- [ ] Syntax check clean on touched files. `scripts/run_tests.sh` passes.
