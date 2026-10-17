# 11 — Reinforcements and player-KO continuation

**What to build:** Fights with more than three per side work under the new rules. When an active enemy or ally is KO'd, the next `enemyQueue`/`allyQueue` entry joins at the round boundary. An entering enemy rolls a fresh plan; an entering ally plans from the fogged view. Reserve sprites and `+N` still show on the stage.

After a player KO (once Failsafe and guard-kit rewind fail), the player's actions leave the timeline and the fight continues while allies remain. It is lost only when no friendly is standing.

**Blocked by:** 05

**Relevant files:** `systems/combat.gd` (`_admit_reinforcement`, `_substitute_turn_entries`, `_undo_enemy_substitution`, `_player_ko`, `_lose_if_no_friendlies`, `_settle_player_ko_hp`); `scenes/components/combat_stage.gd`; `scenes/components/turn_order_strip.gd`; `tests/test_combat.gd`; REFERENCE §3.7b

**Status:** ready-for-agent

- [ ] A reinforcement enters at the round boundary with a committed plan
- [ ] Rewind across an entry undoes it
- [ ] Player KO with allies standing continues; with none it's a loss
