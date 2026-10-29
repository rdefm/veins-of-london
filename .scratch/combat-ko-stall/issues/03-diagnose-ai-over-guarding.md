# 03 — Diagnose combat AI over-guarding

**What to build:** Diagnosis only, with no behaviour change. In normal fights (not just after a player KO), the allies (e.g. Archie) and the enemies guard almost every action, so fights drag on and can stall entirely. Find out why, and measure it.

- Build a seeded headless sim that runs representative fights (mugging with an Archie ally; at least one other archetype mix). It reports the share of each move per side, and the rounds-to-outcome.
- Trace the decision paths:
  - Ally side: `_ally_action` guards whenever an enemy's read plan targets the ally. It only strikes when it sees Open, and otherwise falls back to Guard unless the `allyChipStrikeChance` roll passes.
  - Enemy side: the archetype pattern weights and moves, and the auto-guard reply logic.
- Check whether an ally-vs-enemy matchup can deadlock (both sides guard forever, so no damage is ever dealt).
- Write findings to `.scratch/combat-ko-stall/ai-guard-diagnosis.md`: the root causes, the numbers, and 1-3 fix options with trade-offs. Any option that changes a number or pattern names the REFERENCE.md lines it would touch.

Do not change code, data or REFERENCE behaviour. The sim harness may be committed as a test helper or a script.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/combat_rounds.gd` (`ALLY_AI_MOVES` ~132, `_pick_pattern()` ~699, `_plan_from()` ~653, `_plan_allies()` ~917, `_ally_action()` ~1115, `_ally_sees_open()`, auto-guard reply ~1440, `_autoguards()` ~2347)
- `data/combat_rounds.json` (`allyChipStrikeChance`, `archetypes[*].patterns`)
- `tests/test_combat_rounds.gd`
- REFERENCE.md §3.7b (Moves, ally AI, enemy patterns)

**Status:** ready-for-agent

- [ ] Seeded sim reports per-side move share and rounds-to-outcome for at least 2 fight setups
- [ ] Root cause(s) for the over-guarding identified, with evidence
- [ ] Deadlock possibility confirmed or ruled out
- [ ] Diagnosis doc lists fix options; the human picks one before ticket 04 starts
