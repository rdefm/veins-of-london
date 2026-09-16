# 02 — Direction A: stealth-check + raid resolution ops (event-card engine)

**What to build:** The reusable mechanism Direction A's raid event cards will be built from, added to the district event-card engine (`systems/events.gd`) alongside its existing effect-op vocabulary (`set_flag`, `chance`, `start_home_raid_combat`, `relation`, etc.):

- A `stealth_check` effect op: rolls success/caught from `stealthSkill` (ticket 01), the target vein's security tier (`raidResist`, `data/vein_security.json`, same field `factions.gd`'s rivalry-odds code already reads via `GameData.VEIN_SECURITY[...]["raidResist"]`), the vein's value (ore type/level), and any consumables spent in the event (existing items like `enhancementPowder`, plus room for new stealth-specific consumables — exact items/effects are a later content decision per the PRD, this op just needs to accept a consumable-bonus input). Exact formula/weighting is this ticket's call — document it in code, same convention as `roll_rivalry_odds()`'s documented-but-open weighting (Chunk 6 ticket 03).
- A way for an event card to branch into the existing `Combat.start_raid(vein_id, vein_level, guards, template)` on "caught" (already built per the PRD's "Why," previously reachable only via debug) — winning combat proceeds same as clean stealth; losing combat fails the raid, using combat's existing loss handling (no new raid-specific punishment).
- Claim/loot resolution ops: **claim** converts the target `factionVein` to player ownership (same field/shape Chunk 1's claim code already writes — `oreType`/`level`/`security` carry over) and always applies a severe relation hit against the owning faction; **loot** grants a smaller one-time ore/cash payoff (or vein security/charge damage) and leaves faction ownership untouched, applying only a moderate relation hit, and only if the player was actually caught during the attempt (a clean stealth-and-loot leaves relation untouched).
- Since `state.factions[id].relation` (player↔faction) currently has no generic adjuster — it's hand-mutated in `debug_start.gd`, and the existing `"relation"` event op (`Contacts.award_relation`) is contact-only, not faction-only — add `Factions.adjust_player_relation(faction_id, delta)`, mirroring `Contacts.award_relation`'s shape, and use it for both the severe/moderate hits above.

This ticket has no UI and is not yet wired to any real event card or entry point — that's ticket 03. It's verified by tests exercising the ops directly.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] `stealth_check` op: pure function taking stealthSkill, target vein (security tier + oreType/level), and a consumable-bonus input, returning success/caught; weighting formula documented in code
- [ ] Stealth check awards stealth XP on resolution (win or lose), mirroring how `Cultivating.award_xp`/crafting XP awards work
- [ ] Event-card path exists to branch into `Combat.start_raid()` when caught, and to route combat win back into the claim/loot choice, combat loss into raid failure (existing combat-loss handling, no new punishment)
- [ ] Claim resolution: target `factionVein` becomes player-owned (`oreType`/`level`/`security` carried over, matching Chunk 1's ownership-change shape); always applies a severe relation hit
- [ ] Loot resolution: one-time ore/cash payoff (or security/charge damage) to the still-faction-owned vein; applies a moderate relation hit only if the player was caught during the attempt, none if clean
- [ ] New `Factions.adjust_player_relation(faction_id, delta)` helper added and used by both relation hits above; existing contact-only `"relation"` op and faction-to-faction `adjust_relation(a, b)` (Chunk 6) untouched
- [ ] Tests cover: stealth check success/caught distributions respond to stealthSkill and raidResist in the right direction; claim always hits relation severely regardless of caught/clean; loot hits relation only when caught; loot never transfers ownership; claim always transfers ownership
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes
