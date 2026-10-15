# 03 — Archetypes, groups, levels, crits

**What to build:** Enough enemy variety and level scaling to test the curve. The designer picks each enemy's archetype (Mugger, Bruiser, Turtle), 1–3 enemies, and the enemies' combat level. A level-3+ fighter gets a third action that lands after everyone's second. Crits add spikes. An action aimed at an enemy already KO'd this round moves to the next living one. Spec: `.scratch/combat-revamp/spec.md` (User stories 3, 4, 10, 25, 31, 32, 38–44; Implementation Decisions: Damage, Crit chance, Actions per round, Enemy plans, KO and outcome).

**Blocked by:** 01 — Tracer: replace old prototype with Guard/Strike 1v1

**Relevant files:** `systems/combat_prototype.gd`, `scenes/screens/combat_prototype.gd`, `data/combat_prototype.json`, `autoload/GameData.gd` (validation; `COMBAT_SPEED_BY_LEVEL`, `COMBAT_ATTACK_BONUS_BY_LEVEL`, HP curve), `tests/test_combat_prototype.gd`.

**Status:** ready-for-agent

- [ ] Bruiser (strike-heavy) and Turtle (guard-heavy, occasional strikes) archetypes with bases and weighted plan patterns in data; Mugger stays mixed
- [ ] Enemies, player (and later allies) use the same level curves for actions/speed/attack/HP/crit on top of an archetype base
- [ ] Actions-per-round curve drives plan length; the 3rd action index orders after all 2nd actions
- [ ] Crit: per-level chance from the curve, doubles the final figure; a crit on Guarded = 2× chip (doesn't pierce guard)
- [ ] An enemy-targeted action at a target KO'd earlier in the round retargets the next living enemy (index order)
- [ ] Tests: level-3 player has 3 actions, 3rd after all 2nd; seeded forced crit → double, on Guarded → double chip; retarget after early kill; multi-enemy fight resolves in timeline order
- [ ] Screen setup: per-enemy archetype + count 1–3 + enemy level selector; timeline handles 3 enemies and 3-action plans
- [ ] Check/lint clean; suite passes; new prose flagged `PROSE-REVIEW:`
