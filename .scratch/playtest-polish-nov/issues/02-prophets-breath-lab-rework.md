# 02 — Prophet's Breath Lab rework: scaled clues

**What to build:** In the Lab, Prophet's Breath no longer reveals the entire (lvl 5) procedure. It shows true bands for the steps of the recipe tier the player is currently reaching, plus clue(s) on extra step(s) toward the next tier (max +1 tier effect). Higher item level = more accurate bands and more than one extra-step clue. Combat sight behaviour (fog) is unchanged.

**Blocked by:** None — can start immediately (touches same Lab area as 01; do in either order).

**Relevant files:** `systems/lab.gd` (`known_procedure` / `_book` ~L165-200, step specificity), `systems/active_effects.gd` (`prophets_breath_active`, effect level), `data/constants.json` + recipe procedure data (`procedure_def`), `docs/REFERENCE.md` §3.5 (Lab; Prophet's Breath row ~L80, Scoring ~L792), Lab UI showing knowledge "revealed", Lab tests.

**Status:** ready-for-agent

- [ ] Level-scaling table (band accuracy, number of next-tier clues) in data and REFERENCE
- [ ] A lvl 1 Prophet's Breath no longer lets the player craft to lvl 5
- [ ] Clues use existing hint/knowledge vocabulary; no reveal beyond next tier
- [ ] Combat/fog use of Prophet's Breath untouched
- [ ] Tests per level; boundary: at next-tier cap nothing extra revealed
