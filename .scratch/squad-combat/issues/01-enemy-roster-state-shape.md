# 01 — Enemy roster state shape (`combat.enemies` array + `focusedEnemyIndex`)

**What to build:** Replace the single-enemy combat state with a roster shape, with no behavior change yet for existing single-enemy fights — this is the plumbing every later ticket in this spec hangs off.

`combat.enemy: Dictionary` becomes `combat.enemies: Array` (0–3 entries, each keeping today's shape — `name, hp, hpMax, attackMin, attackMax, weapon, ability, evadeChance` — plus new `speed:int` (unused until ticket 02, default any placeholder value) and `koed:bool`). `combat.veinId` moves up to sit directly on the `combat` dict (one vein per fight regardless of guard count) instead of living on the enemy entry. `combat.focusedEnemyIndex:int` (default 0) is added and auto-clamps to the next living enemy if the focused one dies mid-round. The fight's win condition changes from "the one enemy's hp hits zero" to "every entry in `combat.enemies` is `koed`."

All existing single-target combat actions (Attack, Blast, Time Pearl, Shield, Black Hole, Prophet's Breath, Wormhole, every Complication cast) continue to work exactly as today, just reading/writing through `combat.enemies[focusedEnemyIndex]` instead of `combat.enemy` — every fight in this ticket still only ever has exactly one entry in the array, since roster generation (N distinct entries) isn't built until ticket 04. The rewind snapshot mechanism (`push_combat_snapshot`/`_restore_from_snapshot`) is updated to snapshot the `enemies` array and `focusedEnemyIndex` in place of the old single `enemy` field. The one UI read site (`scenes/screens/combat.gd`'s enemy card) reads the focused entry instead.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `combat.enemies` is an Array; every existing combat-start path (`start_mugging`, `start_archie_deal_mugging`, `start_street_mugging`, `start_home_raid_combat`, `start_raid`, `start_defend_vein`) populates it with exactly one entry, each entry carrying `koed:bool` (false at start) and a `speed:int` field
- [ ] `combat.veinId` lives on the top-level `combat` dict, not on the enemy entry; every read/write site is updated
- [ ] `combat.focusedEnemyIndex` defaults to 0 at combat start and auto-clamps to the next living (non-koed) enemy if the currently-focused entry's hp reaches zero mid-round
- [ ] Win condition is "every entry in `combat.enemies` is `koed`" — for a 1-entry roster this is behaviorally identical to today's single-enemy-hp-zero check
- [ ] `player_attack()`, `use_blast()`, `use_black_hole()`, `cast_complication()`, `enemy_attack()`, `disarm_enemy()`, `is_ability_locked()`, `get_enemy_attack_range()` all resolve against `combat.enemies[focusedEnemyIndex]` (or, for `enemy_attack()`/AI, the acting enemy's own entry) instead of `combat.enemy`
- [ ] `push_combat_snapshot()`/`_restore_from_snapshot()` snapshot/restore `enemies` (the focused entry's hp, per existing single-enemy rewind scope) and `focusedEnemyIndex` in place of the old single `enemy` field
- [ ] `scenes/screens/combat.gd`'s enemy display reads `combat["enemies"][combat["focusedEnemyIndex"]]`
- [ ] All existing `tests/test_combat.gd` cases pass unmodified in behavior (updated only for the field-name/shape change), demonstrating this is a pure reshape with no combat-outcome regression
- [ ] New test: a fresh combat starts with `enemies.size() == 1`, `focusedEnemyIndex == 0`, `enemies[0]["koed"] == false`; killing that entry sets `koed = true` and the outcome resolves via the new "all koed" check
