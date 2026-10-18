# 18 — Enemy `evadeChance` in round fights

**What to build:** (Originally scoped as dropping `evadeChance`; the human chose to implement it instead.) Round fights roll the target's `evadeChance` before every Strike (player, ally or fury enemy): a hit misses outright (`evade` beat, no damage, a Lure still springs). No evade while the target is Exposed or has actions to lose (stunned, Time Pearl, Black Hole). Be a Lady cuts it by `evadeCutPerTier` 0.05 × the attacker's Be a Lady tier (slot tier, or the carry-in effect's level), floored at 0. Stun, Feint and items never miss. Baseline 20% (`Combat.DEFAULT_EVADE_CHANCE`) for every template that omits it (all current ones) and the procedural mugger.

**Relevant files:** `systems/combat_rounds.gd` (`evade_chance()`, `_strike()`, `ITEM_LADY`, `carry_in()`); `systems/combat.gd` (`_round_enemy_combatant()`); `systems/active_effects.gd` (`lady_level()`); `data/combat_rounds.json`; `scenes/screens/combat_rounds.gd` (`beat_cues`); `docs/REFERENCE.md` §1.10, §3.7b Evade.

**Status:** done

- [x] Strikes roll evade; exceptions + Be a Lady cut tested in `tests/test_combat_rounds.gd`
- [x] REFERENCE §1.10 and §3.7b describe it
- [x] Full suite and `scripts/check_all.sh` clean
