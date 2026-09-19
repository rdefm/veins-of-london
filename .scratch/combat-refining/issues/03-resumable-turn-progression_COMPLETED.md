# 03 — Resumable turn progression (pause at every player decision point)

**What to build:** Combat stops at every player decision point instead of resolving a whole sorted round per Attack press. Pressing Attack, Leg it, using an item or casting a Complication resolves the player's current occurrence and then advances automatic turns only until the next player occurrence (crossing a round boundary if needed) — so enemies faster than the player act before the player's first command of a round, and a Motion-boosted extra turn is a separate pause the player commands. The turn cursor is persisted in the combat state per ticket 01's contract, snapshots are pushed at each decision point, and Rewind restores a coherent decision point. Damage, XP, rewards, flee odds, item effects and enemy targeting rules are unchanged. The combat screen still plays the returned beats and simply stops at the pause; the existing strip keeps working (dedup and all) until ticket 04.

Existing progression tests that asserted "one call resolves the whole round" are updated only where the new contract makes them obsolete.

**Blocked by:** 01 — Canonical contract amendments.

**Relevant files:**
- `systems/combat.gd` — `player_attack`, `build_turn_queue`, `_resolve_player_turn`, `_ally_turn`, `_enemy_turn`, `flee`, `use_time_pearl`/`use_enhancement_powder`/`use_blast`/`use_shield`/`use_black_hole`/`use_prophets_breath`/`use_wormhole`, `cast_complication`, `push_combat_snapshot`, `_restore_from_snapshot`, `combat_rewind`, `_start_combat`, `exit_combat`
- `systems/consumables.gd` — `use_healing_burst` (in-combat branch)
- `systems/dial.gd` — `combat_turn_tick` call site timing
- `scenes/screens/combat.gd` — `_play_round`, `_on_attack_pressed`, `_on_run_pressed`, `_on_dial_triggered`
- `scenes/components/bag_drawer.gd` — `_add_combat_use_buttons`, `_play_result_beats`
- `tests/test_combat.gd` — round-resolution, snapshot, rewind, motion cases
- `tests/test_combat_screen.gd` — "stage_slot_node_identity_survives_a_real_turn…", "a_real_kill_mid_fight_re_sorts…"
- `docs/REFERENCE.md` — §3.7a Turn order bullet, §3.9 Combat rewind (as amended by 01)

**Status:** completed

- [x] Fixture where an enemy outspeeds the player: first Attack press yields beats with the enemy's turn before the player's hit
- [x] Fixture with Motion active: each player occurrence is its own call; the second occurrence does not resolve until the player acts again
- [x] After a player action, automatic turns resolve only up to the next player occurrence; state shows the cursor parked there
- [x] Snapshot count grows by one per player decision point; Rewind restores the oldest and the cursor points at a valid player occurrence
- [x] Per-turn XP, damage ranges, flee odds and item effects produce the same values as before for the same RNG seed
- [x] Item use / Complication cast from the Bag drawer or Dial follows the same advance-to-next-decision-point rule
- [x] Round-boundary decrements (`motionTurns`, `frozenTurns`, ability lock) fire once per round, at the boundary defined in 01 — with one refinement: `motionTurns` only decrements when the ending round's queue actually carried a Motion-inserted slot, not whenever it's merely >0 (see REFERENCE.md §3.7a's round-boundary bullet)
- [x] `scripts/check_all.sh` and `scripts/run_tests.sh` pass; CODEMAP row for `systems/combat.gd` updated
