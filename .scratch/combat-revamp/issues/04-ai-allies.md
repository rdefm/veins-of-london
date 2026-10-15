# 04 — AI allies

**What to build:** Squad play. The designer adds 0–2 AI allies with their own combat level. Enemies now pick an attack target from the player and living allies when they commit. Allies plan after the enemy plans are rolled, reading visible intents: they guard where they're about to be struck, strike enemies who'll be Open, and feint a Guarded enemy ahead of a teammate's Strike. Ally plans show on the timeline before the player commits, so the player can sync with them. Spec: `.scratch/combat-revamp/spec.md` (User stories 5, 11, 45, 46; Implementation Decisions: Enemy plans, Ally AI, KO and outcome).

**Blocked by:** 02 — Opening moves; 03 — Archetypes, groups, levels, crits

**Relevant files:** `systems/combat_prototype.gd`, `scenes/screens/combat_prototype.gd`, `data/combat_prototype.json` (ally base if needed), `autoload/GameData.gd`, `tests/test_combat_prototype.gd`. Existing ally reference: `guardAlly` in `data/constants.json:50`.

**Status:** ready-for-agent

- [ ] Config accepts 0–2 allies with levels; allies use the shared level curves
- [ ] Each enemy offensive action has a target chosen uniformly from the player and living allies at commit time
- [ ] Ally AI plans from the rolled enemy plans by the spec's rules; ally plans are committed in state before the player commits and roll again each round
- [ ] Allies resolve in timeline order with tie-break player > allies > enemies; a KO'd ally loses its remaining actions; loss is still the player KO'd only
- [ ] Tests: an ally guards on the index where an enemy strikes it; an ally strikes an enemy who'll be Open; an enemy strike aimed at an ally hits the ally; KO'd ally drops actions
- [ ] Screen: ally count + level selectors in setup; ally lanes/icons visible on the timeline pre-commit; enemy intent shows type only (target hidden until sight, ticket 06)
- [ ] Check/lint clean; suite passes
