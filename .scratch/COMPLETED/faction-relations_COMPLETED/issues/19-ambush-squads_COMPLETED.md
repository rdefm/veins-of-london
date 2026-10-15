# 19 — Ambush squads

**What to build:** Hostile factions field their own enemy squads. `factionSquads = { factionId: [{ weight, enemies: [...] }] }` in the enemies data builds on the existing squad combat. `Turf.ambush_chance(district)` comes from the controller's (and foothold factions') relation with the player: zero at or above a relation line, rising with hostility, scaled by control vs foothold (TBD). When the player spends a block acting in a district (tend, prune, prospect, seed…), the chance is rolled. On a hit, an authored ambush intro event fires, and a new event action starts a faction-ambush combat with that faction's squad. Outcomes feed grudges and relation like other fights; warmonger is fed only when the player initiates (wired in 20).

**Blocked by:** 01 — Turf core; 17 — Grudges

**Relevant files:** `data/enemies.json`, `autoload/GameData.gd`, `systems/turf.gd`, `systems/sites.gd` (district action hook ~line 262, before `DistrictDeck.maybe_trigger`), `systems/district_deck.gd`, `systems/cultivating.gd`, `systems/combat.gd`, `systems/combat_prep.gd`, `systems/events.gd` (new action), placeholder intro event in `data/events/`, tests: `test_combat`, `test_combat_prep`, `test_turf`, new ambush test. REFERENCE.md §3.7a, new Ambush §.

**Status:** ready-for-agent

- [ ] `factionSquads` defined for all five factions using existing enemy art/templates
- [ ] `ambush_chance` is zero in friendly/own turf and rises with hostility; foothold scaled
- [ ] The roll runs from the shared district-action hook with seeded `Rng` and doesn't disturb the deck's roll order
- [ ] A hit queues the intro event; its action starts combat with the faction squad
- [ ] A win or loss updates relation and grudge
- [ ] Placeholder card `PROSE-REVIEW`
