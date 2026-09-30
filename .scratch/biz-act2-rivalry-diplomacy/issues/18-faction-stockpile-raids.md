# 18 — Faction stockpile raids

**What to build:** Factions raid each other's stockpiles. The stockpile-raid rung goes live in the producer, Guild (hired) and Network menus, faction vs faction, using the ticket 17 resolution. Raided stores feed the Market, a war clock and a relocation, so London's market reacts to its own conflicts. The player has no stockpile in this spec, so the rung is skipped when the target is the player.

**Blocked by:** 17 — Player stockpile raids.

**Relevant files:** `systems/faction_ai.gd`, `systems/raiding.gd`, `systems/faction_sim.gd`, `systems/intel.gd`, `systems/barometer.gd`, `tests/test_faction_ai.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` story 100, §Escalation menus. REFERENCE.md §3.12.

**Status:** ready-for-agent

- [ ] Rollover test (seeded): a Hostile faction with location-level intel on a rival raids its stockpile. Holdings move, the stockpile relocates, and war is started or extended.
- [ ] The rung is never picked against the player.
- [ ] A big stockpile raid makes a Ticker headline. REFERENCE and CODEMAP updated.
