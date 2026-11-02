# 03 — Heavy Metal (AoE damage + panic bolt)

**What to build:** Heavy Metal deals X damage to every enemy. Then the lowest-HP enemy rolls a Panic-style bolt check (brainstorm §4). It's the first area-of-effect item in the round-combat table that isn't Black Hole.

**Blocked by:** 01

**Relevant files:** `systems/combat_rounds.gd`, `data/combat_rounds.json`, `data/constants.json` (loadout/guardKit), `tests/test_combat_rounds.gd`; REFERENCE §3.7b.

**Status:** ready-for-agent

- [ ] Damage applies to all live enemies; tier scales X
- [ ] Lowest-HP enemy (after the damage) gets the bolt check, using existing Panic resolution
- [ ] Tests cover single- and multi-enemy fights
