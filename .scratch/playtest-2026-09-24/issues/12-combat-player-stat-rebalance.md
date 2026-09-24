# 12 — Combat: rebalance player stats

**What to build:** A level-1 player with no items fighting a weak enemy (e.g. Territorial Scrapper) faces a real risk, not a guaranteed win. Tune player base combat stats (and level scaling if needed) so fights stay challenging without items across progression. Use a headless sim to pick numbers: target 60–80% win rate, player usually ending under 40% HP. Enemies untouched unless the sim shows the target is unreachable otherwise — ask first.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/constants.json`, `data/enemies.json`, `systems/combat.gd`, `systems/progression.gd`, `systems/combat_prototype.gd` (possible sim harness); REFERENCE §3.7, §3.7a.

**Status:** ready-for-agent

- [ ] Sim + before/after results (win rate, end HP) noted under `## Comments`
- [ ] Level-1 itemless vs weak enemy lands in the target band
- [ ] Spot-check higher levels vs matched enemies stay challenging
- [ ] REFERENCE numbers updated to match data
