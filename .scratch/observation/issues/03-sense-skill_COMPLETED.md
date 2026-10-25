# 03 — Sense skill

**Phase:** MVP

**What to build:** A new player skill, **Sense**, that levels up from XP with a level-up notify, following the shared XP curve shape (including the level-10 extension). Prospecting awards Sense XP on top of its existing cultivating XP. Observation awards it later (ticket 04).

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/progression.gd` (`award_xp`), `systems/cultivating.gd`, `systems/sites.gd` (prospecting XP), `data/stealth.json` / `data/vein_growth.json` (curve prior art — add `senseXpLevels` to data), new-game state init, existing prospecting XP tests; REFERENCE.md §2 STATE SCHEMA; CONTEXT.md.

**Status:** ready-for-agent

- [ ] `player.senseSkill` / `player.senseXP` in state, saved and loaded, defaulted for old saves
- [ ] `senseXpLevels` in data (placeholder numbers), level-10 extension respected
- [ ] Sense XP awarded via `Progression.award_xp`; level-up notifies
- [ ] Prospecting awards Sense XP alongside cultivating XP (amount in data); test alongside existing prospecting XP tests
- [ ] REFERENCE §2 and CONTEXT.md gain Sense; CODEMAP updated if files change responsibility
