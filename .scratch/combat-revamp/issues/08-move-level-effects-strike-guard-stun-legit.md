# 08 — Move-level effects: Strike, Guard, Stun, Leg it

**What to build:** Move levels change how moves play, for every combatant (player, allies, enemies). All numbers in data.

| Move | Per-level stat [L1..L5] | L3 unlock | L5 unlock |
|---|---|---|---|
| Strike | +0/+2/+4/+8/+12 damage | +6% crit chance | Chip vs Guarded 0.25 → 0.55 |
| Guard | Chip taken ×0.25/.20/.17/.14/.10 | 30% chance to fully block a hit | First hit each round while Guarded does 0 |
| Stun | — | 80% chance to work on a Guarded target | Stunned target also stays Open for its next 2 actions |
| Leg it | Flee chance .65/.70/.75/.80/.85 | Failed flee no longer loses remaining actions | Failed flee leaves actor Guarded, not Open |

Unlocks are cumulative (L4/L5 keep L3's). Guard's chip multiplier and Strike's L5 chip apply to the defender's Guard level and attacker's Strike level respectively — when both apply, decide the combination rule and note it in REFERENCE (ask the human if unclear). Full blocks and stuns-through-guard get transcript lines.

**Blocked by:** 07 — Move levels: progression + display

**Relevant files:**
- `systems/combat_rounds.gd` (damage, crit, chip, stun, legIt resolution)
- `data/combat_rounds.json` (`chipMultiplier`, new per-move level tables)
- `autoload/GameData.gd` (validation)
- `tests/test_combat_rounds.gd`
- `scripts/sim_combat_balance.gd`
- REFERENCE §3.7b Moves, Damage, Evade, Removal

**Status:** ready-for-agent

- [ ] Each row's per-level stat and both unlocks tested at L1, L3, L5
- [ ] Strike L5 vs Guard L5 combination rule decided, tested, documented
- [ ] Blast/Black Hole guard-ignoring damage unaffected by Guard level
- [ ] REFERENCE §3.7b updated; sim re-run, result noted in the commit
