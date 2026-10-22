# 01 — Stun rework: per-level Guard-through + Lv3 2-action stun

**Visual spec:** `.scratch/move-book/move-book.html` (live copy: https://claude.ai/artifact/FPL7F27VL6oHT5DTsSYgFR). See its "Decisions" section and the Stun row of "What every card says". Implement the numbers exactly as there; if this ticket and the mock disagree, stop and ask.

**What to build:** Stun's move levels change for every combatant (player, allies, enemies):
- **Per-level stat:** chance for a Stun to work on a Guarded target, by the stunner's Stun level: Lv1 0%, Lv2 10%, Lv3 20%, Lv4 30%, Lv5 40%. Replaces the flat 80% from Lv3. Below the roll a Guarded target still shrugs it off (fizzle).
- **Lv3 unlock:** a landed Stun takes the target's next **2** actions instead of 1 (both open-target and through-Guard stuns).
- **Lv5 unlock:** unchanged — a landed Stun holds the target Open for its next 2 actions.
- All numbers in data.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `data/combat_rounds.json` (`moveLevelEffects.stun`, its `_moveLevelEffectsComment`, `moves.stun.params.actions`)
- `systems/combat_rounds.gd` (`_stun`, `level_effects`, `move_level`)
- `autoload/GameData.gd` (validation of `moveLevelEffects`)
- `tests/test_combat_rounds.gd`
- `scripts/sim_combat_balance.gd`
- REFERENCE §3.7b Moves, Removal, Move levels (the move-level effects table)

**Status:** ready-for-agent

- [ ] Guard-through chance is a per-level array 0/.10/.20/.30/.40; seeded tests at Lv1 (never), Lv2 and Lv5
- [ ] Stun at Lv3+ removes 2 actions, Lv1–2 removes 1 (tests, open and through-Guard)
- [ ] Lv5 Open hold still works alongside the 2-action stun (test)
- [ ] REFERENCE §3.7b table and data comment updated
- [ ] Balance sim re-run, result noted in the commit
