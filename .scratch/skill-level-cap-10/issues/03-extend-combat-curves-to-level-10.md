# 03 — Extend combat's level-indexed curves to level 10

**What to build:** Every Combat Skill level-indexed curve has exactly 6 entries (index 0–5). With the level-10 cap from ticket 01, extend each to 11 entries (index 0–10), placeholder/extrapolated values for levels 6–10 continuing each curve's existing growth pattern, flagged **TBD, needs a human balance pass**:

- `data/enemies.json`: `combatAttackBonusByLevel`, `combatSpeedByLevel`, `combatHpBonusByLevel`.
- The live combat data table (REFERENCE §3.7b, Open/Guarded round combat): `actionsPerRound`, `critChance`, and the fog curve `fog.unreadChance` (keep it ≥ 0 at every level; it already falls to .07 at level 5).

Also extend whatever caps the level at 5 in combat (the data's `levelMax`, Debug/sim level pickers, the enemy- and ally-level tables in §3.7b if they clamp) to 10, and update REFERENCE §3.7b's curve table.

**Blocked by:** 01 — Extend XP curves for all four skills to level 10 (players must be able to reach combat skill 6–10 for this to matter); combat-port 13 (the live combat data table must be in its permanent home).

**Status:** ready-for-agent

- [ ] Attack, speed, HP, actions-per-round, crit and fog `unreadChance` curves each have 11 entries (index 0–10), levels 6–10 flagged TBD/placeholder in a comment.
- [ ] Fighting at Combat Skill 6–10 applies the extended attack bonus, speed, HP, actions per round, crit chance and fog chance, verified by a test.
- [ ] No index-out-of-range or crash at any Combat Skill level 1–10, for player, ally or enemy.
