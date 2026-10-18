# 02 — Turtle aggression + ally attack AI

**What to build:** Turtles attack sometimes, and allies (Archie, James, guards) stop guarding every turn against them. Turtle and turtleV2 patterns become guard-strike-guard (weight 5), guard-guard-strike (3), strike-guard-guard (2); the guard×3 pattern is dropped. Ally AI: Strike an enemy who'll be Open; else run the Feint → Strike combo on a Guarded enemy (now works, since Feint makes the next Guard fail); else chip-Strike a Guarded enemy with chance `allyChipStrikeChance` (0.30, in data); else Guard.

**Blocked by:** 01 — Merge Lure into Feint

**Relevant files:**
- `data/combat_rounds.json` (archetypes.turtle / turtleV2 patterns, new `allyChipStrikeChance`)
- `systems/combat_rounds.gd` (Ally AI section: `_plan_allies`, `_ally_action`)
- `tests/test_combat_rounds.gd`
- `scripts/sim_combat_balance.gd`
- REFERENCE §3.7b Round, Archetypes, Table 5

**Status:** ready-for-agent

- [ ] Turtle patterns as above; no all-guard pattern
- [ ] Seeded test: vs a lone turtle over N rounds, allies plan Strikes (full or chip) and Feints, not only Guards
- [ ] Seeded test: an ally Feint followed by its own (or a later ally's) Strike in the same round on that target
- [ ] Chip-Strike chance read from data, validated at boot
- [ ] Ally still Guards where a read enemy Strike targets it (existing rule kept, unless overridden by an item rule)
- [ ] REFERENCE updated; sim re-run, result noted in the commit
