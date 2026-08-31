# 03 — Extend combat's level-indexed curves to level 10

**What to build:** Combat Skill's two additive, level-indexed effect curves in `data/enemies.json` — `combatAttackBonusByLevel` and `combatSpeedByLevel` — currently have exactly 6 entries (index 0–5). With the level-10 cap from ticket 01, extend both from 6 to 11 entries (index 0–10), placeholder/extrapolated values for levels 6–10 continuing each curve's existing growth pattern, flagged **TBD, needs a human balance pass** (REFERENCE.md already notes these curves are "draft, need balance sign-off" even at their current 1–5 range).

**Blocked by:** 01 — Extend XP curves for all four skills to level 10 (players must be able to reach combat skill 6–10 for this to matter).

**Status:** ready-for-agent

- [ ] `combatAttackBonusByLevel` and `combatSpeedByLevel` each have 11 entries (index 0–10), with levels 6–10 flagged TBD/placeholder in a comment.
- [ ] Fighting at combat skill levels 6–10 applies the extended attack bonus and turn-order speed correctly, verified by a test.
- [ ] No index-out-of-range or crash at any combat skill level 1–10.
