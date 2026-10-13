# 03 — Live control drives claims and pressure

**What to build:** Strong factions consolidate where they rule. The NPC claim roll's `presence` weight now applies to the district's live controller instead of the heritage `factionPresence`. Pressure's `homeVeins` term uses live controlled districts. Heritage presence only seeds starting turf and stockpile home districts.

**Blocked by:** 01 — Turf core

**Relevant files:** `systems/factions.gd` (claim weight ~line 64), `systems/faction_ai.gd` (`home_vein_share`, ~line 306), `systems/faction_sim.gd` (~line 792, stockpile home districts stay on heritage), `systems/sites.gd` (`roll_npc_claims`), `tests/test_factions.gd`, `tests/test_faction_ai.gd`. REFERENCE.md §1.8, faction pressure weights.

**Status:** ready-for-agent

- [ ] Claim weighting gives the `presence` bonus to the live controller; the heritage-only weight is gone
- [ ] `homeVeins` reads live control
- [ ] Stockpile home districts still come from heritage presence
- [ ] Tests cover a district whose controller differs from its heritage presence
- [ ] REFERENCE §1.8 amended
