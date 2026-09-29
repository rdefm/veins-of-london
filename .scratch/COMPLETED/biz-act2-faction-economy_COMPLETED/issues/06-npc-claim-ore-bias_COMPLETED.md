# 06 — NPC claim ore bias

**What to build:** The daily NPC claim roll favours factions whose primary and secondary ores match the site's ore type, so each faction's identity shows on the map. District presence still matters; the weighting (placeholder) lives in JSON.

Spec: §Module layout (Factions), user story 9.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/sites.gd` (`roll_npc_claims`), `systems/factions.gd` (`pick_claimant`, `RIVAL_ENCROACH_CHANCE`)
- `data/factions.json` (`primaryOre`, `secondaryOre`, bias weights)
- Tests: `tests/test_factions.gd`, sites claim tests
- REFERENCE.md §1.8; `docs/M1-LONDON.md` D2

**Status:** ready-for-agent

- [ ] Over a seeded run, claims skew toward each faction's primary and secondary ores
- [ ] Weights in JSON
- [ ] REFERENCE.md updated
