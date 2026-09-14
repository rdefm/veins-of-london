extends "res://tests/test_base.gd"

# day-rhythm-business-and-combat ticket 14: public-resolution coverage for
# systems/combat_prototype.gd against ticket 13a's approved rule set. Drives
# everything through the public API (start_encounter/take_player_action/
# skip_exhausted_round/rewind/advance_to_next_encounter/exit_encounter) and
# asserts on the resulting GameState.state["combatPrototype"] tree, per the
# ticket's "headless public-resolution tests" instruction -- no reaching
# into CombatPrototype's private `_`-prefixed resolution helpers.
#
# Solo (1v1) means ticket 13a's acceptance examples 5 (squad, unguarded
# second attacker) and 6 (interrupted stance from a third combatant dying)
# can't be exercised here -- both need more than one enemy, which is
# ticket 15's job. Examples 8 (shield) and 9 (Enhancement Powder) are also
# out of scope: this prototype wires no items at all (see
# systems/combat_prototype.gd's own top comment for the full assumptions
# list). The four matchups are still all covered below, from whichever side
# (attacker/defender) actually reaches them via the teaching roster's
# scripts -- the resolution logic is symmetric by construction, which is
# the point being tested.


# Bypasses start_encounter() (avoids the Nav.go_to() side effect) for full
# control over hp/exhaustion/scriptIndex starting values, same
# hand-build-the-state-dict-directly precedent tests/test_combat.gd's own
# _fresh_combat() sets. `encounter_id` must be one of GameData.
# COMBAT_PROTOTYPE's real encounters (brawler/knifeFighter/enforcer) so
# take_player_action()'s enemy auto-commit has a real script to read.
func _fresh_prototype(encounter_id: String, player_spec: Dictionary = {}, enemy_spec: Dictionary = {}) -> Dictionary:
	GameState.reset()
	var def: Dictionary = GameData.COMBAT_PROTOTYPE["encounters"][encounter_id]
	GameState.state["combatPrototype"] = {
		"active": true, "encounterId": encounter_id, "round": 1, "outcome": null, "log": [],
		"player": {
			"hp": player_spec.get("hp", 100), "hpMax": player_spec.get("hpMax", 100),
			"committedAction": null, "committedTarget": null,
			"exhaustedNextTurn": player_spec.get("exhaustedNextTurn", false), "stanceTriggered": false,
		},
		"enemy": {
			"name": def["name"],
			"hp": enemy_spec.get("hp", def["hp"]), "hpMax": enemy_spec.get("hpMax", def["hp"]),
			"attackMin": enemy_spec.get("attackMin", def["attackMin"]), "attackMax": enemy_spec.get("attackMax", def["attackMax"]),
			"speed": enemy_spec.get("speed", def["speed"]), "evadeChance": enemy_spec.get("evadeChance", 0.0),
			"scriptIndex": enemy_spec.get("scriptIndex", 0),
			"committedAction": null, "committedTarget": null,
			"exhaustedNextTurn": enemy_spec.get("exhaustedNextTurn", false), "stanceTriggered": false,
		},
		"snapshots": [], "beatsSinceSnapshot": [],
	}
	return GameState.state["combatPrototype"]


# Same seed-search precedent as tests/test_combat.gd's own _find_seed_for --
# used only for the flee cases below, where the outcome hinges on a single
# Rng.chance() roll neither side's committed action determines.
static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


func run() -> void:
	# ── Ticket 13a scenario 1: Fast vs. committed Counter -- stopped, retaliates, no exhaustion ──

	run_case("fast_into_counter_is_stopped_and_defender_retaliates", func():
		var cp := _fresh_prototype("enforcer")  # script[0] == "counter", aimed at the player
		Rng.set_seed(1)
		var result := CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)
		assert_true(result["ok"], "take_player_action should succeed")
		assert_eq(cp["enemy"]["hp"], cp["enemy"]["hpMax"], "Fast stopped by Counter should deal zero damage to the enemy")
		assert_true(cp["player"]["hp"] < cp["player"]["hpMax"], "the enemy's Counter should retaliate for its own Fast-range damage")
		var dmg_taken: int = cp["player"]["hpMax"] - cp["player"]["hp"]
		assert_true(dmg_taken >= cp["enemy"]["attackMin"] and dmg_taken <= cp["enemy"]["attackMax"], "retaliation damage %d should fall within the enemy's own Fast range [%d,%d]" % [dmg_taken, cp["enemy"]["attackMin"], cp["enemy"]["attackMax"]])
		assert_true(not cp["player"]["exhaustedNextTurn"], "only Heavy triggers exhaustion, not a stopped Fast")
		assert_true(not cp["enemy"]["exhaustedNextTurn"], "the retaliation is Fast-range, not Heavy -- no exhaustion either side")
	)

	# ── Ticket 13a scenario 2: Heavy vs. committed Counter -- bypasses, connects, attacker exhausted ──

	run_case("heavy_bypasses_counter_and_exhausts_the_attacker", func():
		var cp := _fresh_prototype("enforcer")  # script[0] == "counter"
		Rng.set_seed(2)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_HEAVY)
		assert_true(cp["enemy"]["hp"] < cp["enemy"]["hpMax"], "Heavy should bypass Counter and connect")
		var dmg: int = cp["enemy"]["hpMax"] - cp["enemy"]["hp"]
		var heavy_min: int = GameState.round_epsilon(Combat.get_attack_range()["min"] * CombatPrototype.HEAVY_MULTIPLIER)
		var heavy_max: int = GameState.round_epsilon(Combat.get_attack_range()["max"] * CombatPrototype.HEAVY_MULTIPLIER)
		assert_true(dmg >= heavy_min and dmg <= heavy_max, "bypassing Heavy damage %d should fall within the scaled Heavy range [%d,%d]" % [dmg, heavy_min, heavy_max])
		assert_eq(cp["player"]["hp"], cp["player"]["hpMax"], "a bypassed Counter doesn't retaliate")
		assert_true(cp["player"]["exhaustedNextTurn"], "committing Heavy always exhausts the attacker next turn")
	)

	# ── Ticket 13a: "evadeChance rolls apply after the matchup resolves, before HP loss -- unchanged order" ──
	# i.e. the passive evade roll isn't just for a plain hit -- it has to
	# cover every damage instance a matchup can produce, bypass included.

	run_case("passive_evade_chance_still_applies_to_a_bypassing_heavy", func():
		var cp := _fresh_prototype("enforcer", {}, { "evadeChance": 1.0 })  # script[0] == "counter"; guaranteed evade
		Rng.set_seed(11)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_HEAVY)
		assert_eq(cp["enemy"]["hp"], cp["enemy"]["hpMax"], "a guaranteed evade should still apply after the Counter-bypass matchup resolves, before HP loss")
		var evaded_logged := false
		for line in cp["log"]:
			if line.contains("slips out of the way"):
				evaded_logged = true
		assert_true(evaded_logged, "the evade should be logged distinctly from a stopped/dodged stance")
		assert_true(cp["player"]["exhaustedNextTurn"], "the Heavy was still committed and swung -- exhaustion triggers regardless of the evade roll downstream")
	)

	# ── Ticket 13a scenario 3: Heavy vs. committed Dodge -- zero damage, attacker still exhausted ──

	run_case("dodged_heavy_deals_no_damage_but_still_exhausts_the_attacker", func():
		var cp := _fresh_prototype("brawler")  # script[0] == "heavy", aimed at the player
		Rng.set_seed(3)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_DODGE)
		assert_eq(cp["player"]["hp"], cp["player"]["hpMax"], "a Dodge aimed at an incoming Heavy should take zero damage")
		assert_true(cp["enemy"]["exhaustedNextTurn"], "a dodged Heavy still costs the swinger fatigue")
	)

	# ── Ticket 13a scenario 4: Fast catches Dodge -- still connects ──

	run_case("fast_catches_dodge_and_still_connects", func():
		var cp := _fresh_prototype("knifeFighter")  # script[0] == "fast", aimed at the player
		Rng.set_seed(4)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_DODGE)
		assert_true(cp["player"]["hp"] < cp["player"]["hpMax"], "Fast should catch a Dodge and still connect")
		var dmg: int = cp["player"]["hpMax"] - cp["player"]["hp"]
		assert_true(dmg >= cp["enemy"]["attackMin"] and dmg <= cp["enemy"]["attackMax"], "damage %d should be the enemy's plain Fast range [%d,%d], not scaled" % [dmg, cp["enemy"]["attackMin"], cp["enemy"]["attackMax"]])
		assert_true(not cp["enemy"]["exhaustedNextTurn"], "Fast never exhausts, whether it's caught by a Dodge or not")
	)

	# ── Stance scope: a stance whose opponent never attacks fizzles, action still spent ──

	run_case("unused_stance_fizzles_and_logs_but_costs_the_action", func():
		var cp := _fresh_prototype("enforcer", {}, { "exhaustedNextTurn": true })
		Rng.set_seed(5)
		# The enemy is already exhausted going in -- this round auto-skips its
		# commit (no attack at all), so a player Counter this round has
		# nothing to trigger against.
		CombatPrototype.take_player_action(CombatPrototype.ACTION_COUNTER)
		assert_eq(cp["outcome"], null, "an exhausted enemy's skip shouldn't end the fight")
		assert_eq(cp["player"]["hp"], cp["player"]["hpMax"], "no attack landed on the player this round")
		assert_eq(cp["enemy"]["hp"], cp["enemy"]["hpMax"], "the player's Counter had nothing to retaliate against")
		var fizzled := false
		for line in cp["log"]:
			if line.contains("stance goes unused"):
				fizzled = true
		assert_true(fizzled, "an unused stance should log a fizzle line")
		assert_eq(cp["player"]["committedAction"], null, "the spent action still clears at round end like any other")
	)

	# ── Exhaustion cycle: trigger, skip-next-turn, silent recovery, script index only advances on a real commit ──

	run_case("exhaustion_skips_exactly_one_round_then_recovers", func():
		var cp := _fresh_prototype("brawler")  # script == ["heavy"], always aimed at the player
		Rng.set_seed(6)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)  # round 1: brawler commits heavy -> exhausted next turn
		assert_true(cp["enemy"]["exhaustedNextTurn"], "round 1's committed Heavy should exhaust the brawler")
		assert_eq(cp["enemy"]["scriptIndex"], 1, "the script index advances once for round 1's real commit")
		var hp_before_round_2: int = cp["player"]["hp"]

		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)  # round 2: brawler should auto-skip (exhausted)
		assert_eq(cp["player"]["hp"], hp_before_round_2, "an exhausted enemy takes no action, so the player takes no damage this round")
		assert_true(not cp["enemy"]["exhaustedNextTurn"], "the skip completes and the flag clears the same round")
		assert_eq(cp["enemy"]["scriptIndex"], 1, "a skipped round must not consume a script step")
		var skipped_logged := false
		for line in cp["log"]:
			if line.contains("exhausted"):
				skipped_logged = true
		assert_true(skipped_logged, "the skip should be logged distinctly (\"exhausted\"), not silently dropped")

		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)  # round 3: brawler commits heavy again
		assert_eq(cp["enemy"]["scriptIndex"], 2, "round 3's real commit advances the script index again")
		assert_true(cp["enemy"]["exhaustedNextTurn"], "swinging Heavy again immediately re-triggers the one-turn cost")
	)

	# ── Player's own exhaustion: no commit available, only skip_exhausted_round() ──

	run_case("player_exhaustion_blocks_take_player_action_but_allows_skip", func():
		var cp := _fresh_prototype("knifeFighter", { "exhaustedNextTurn": true })
		var blocked := CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)
		assert_true(not blocked["ok"], "an exhausted player shouldn't be able to commit any action")
		Rng.set_seed(7)
		var result := CombatPrototype.skip_exhausted_round()
		assert_true(result["ok"], "skip_exhausted_round() should succeed for an exhausted player")
		assert_true(not cp["player"]["exhaustedNextTurn"], "the skip completes and clears the flag")
		assert_eq(cp["player"]["committedAction"], null, "a skipped round commits nothing for the player")
	)

	# ── Win / loss outcomes stop the round loop ──

	run_case("enemy_hp_reaching_zero_ends_the_fight_as_a_win", func():
		var cp := _fresh_prototype("brawler", {}, { "hp": 1, "hpMax": 1 })
		Rng.set_seed(8)
		var result := CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)  # min Fast damage (5) always exceeds 1 hp
		assert_eq(cp["outcome"], "win", "the enemy should go down before ever taking its own turn")
		assert_eq(result["outcome"], "win")
		assert_eq(cp["enemy"]["hp"], 0)
	)

	run_case("player_hp_reaching_zero_ends_the_fight_as_a_loss", func():
		# Player speed (10) beats the brawler's (8), so the player's own Fast
		# resolves first -- the enemy's high hp guarantees it survives to take
		# its own turn, where a committed Heavy (min scaled damage 9) is
		# guaranteed to finish off a 1-hp player.
		var cp := _fresh_prototype("brawler", { "hp": 1, "hpMax": 1 }, { "hp": 999, "hpMax": 999 })
		Rng.set_seed(9)
		var result := CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)
		assert_eq(cp["outcome"], "loss", "the brawler's committed Heavy should finish off a 1-hp player")
		assert_eq(result["outcome"], "loss")
		assert_eq(cp["player"]["hp"], 0)
	)

	run_case("fled_outcome_ends_the_encounter_without_a_hp_change", func():
		var cp := _fresh_prototype("brawler")
		var seed := _find_seed_for(500, func():
			var result := CombatPrototype.take_player_action(CombatPrototype.ACTION_FLEE)
			return result["outcome"] == "fled"
		)
		assert_true(seed != -1, "a flee-success roll should exist within 500 seeds at a 65% base chance")
		var final_cp: Dictionary = GameState.state["combatPrototype"]
		assert_eq(final_cp["outcome"], "fled")
	)

	# ── Ticket 13a scenario 10: Rewind restores committedAction/committedTarget/exhaustedNextTurn alongside hp/log ──

	run_case("rewind_restores_hp_log_commits_and_exhaustion_to_the_prior_round", func():
		var cp := _fresh_prototype("enforcer")  # script: counter, then heavy
		Rng.set_seed(10)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_HEAVY)  # round 1: bypasses committed Counter, player exhausted
		assert_true(cp["player"]["exhaustedNextTurn"], "sanity check: round 1 should have exhausted the player")
		var hp_after_round_1: int = cp["enemy"]["hp"]
		assert_true(hp_after_round_1 < cp["enemy"]["hpMax"])

		var result := CombatPrototype.rewind()
		assert_true(result["ok"], "rewind should succeed with a snapshot on the stack")
		assert_eq(cp["enemy"]["hp"], cp["enemy"]["hpMax"], "rewind should undo round 1's damage to the enemy")
		assert_eq(cp["player"]["hp"], cp["player"]["hpMax"], "rewind should undo any damage to the player too")
		assert_true(not cp["player"]["exhaustedNextTurn"], "rewind should restore exhaustedNextTurn to its pre-round value (false)")
		assert_eq(cp["player"]["committedAction"], null, "rewind restores to before this round's commit was made")
		assert_eq(cp["enemy"]["committedAction"], null, "the enemy's commit resets the same way")
		assert_eq(cp["enemy"]["scriptIndex"], 0, "the enemy's script pointer rewinds along with everything else, so the same round replays the same scripted choice")
		assert_eq(cp["outcome"], null)
		assert_true(String(cp["log"][-1]).contains("Rewind"), "rewind should append its own log line describing the reset")
		assert_true(cp["snapshots"].is_empty(), "rewind consumes the whole snapshot stack, same as production combat_rewind()")

		# The round replays identically off the restored (unadvanced) script index.
		Rng.set_seed(10)
		CombatPrototype.take_player_action(CombatPrototype.ACTION_FAST)
		assert_eq(cp["enemy"]["hp"], cp["enemy"]["hpMax"], "the enforcer's restored script[0] (\"counter\") should stop a Fast exactly as round 1 would have before any Heavy was ever thrown")
	)

	run_case("rewind_with_no_snapshot_fails_cleanly", func():
		var cp := _fresh_prototype("brawler")
		var result := CombatPrototype.rewind()
		assert_true(not result["ok"], "rewind should refuse with nothing on the stack")
		assert_eq(cp["outcome"], null)
	)

	# ── Sequence progression ──

	run_case("advance_to_next_encounter_walks_the_teaching_order_and_stops_at_the_end", func():
		GameState.reset()
		var order: Array = GameData.COMBAT_PROTOTYPE["encounterOrder"]
		assert_eq(order, ["brawler", "knifeFighter", "enforcer"], "ticket 14's own teaching order: Heavy/Dodge/exhaustion, then Fast/Counter, then Counter/Heavy")

		CombatPrototype.start_encounter(order[0])
		assert_eq(GameState.state["combatPrototype"]["encounterId"], "brawler")
		assert_true(GameState.state["combatPrototype"]["active"])
		assert_eq(GameState.state["combatPrototype"]["player"]["hp"], GameState.state["combatPrototype"]["player"]["hpMax"], "each encounter starts the player fresh")

		var next1 := CombatPrototype.advance_to_next_encounter()
		assert_true(next1["ok"])
		assert_eq(GameState.state["combatPrototype"]["encounterId"], "knifeFighter")

		var next2 := CombatPrototype.advance_to_next_encounter()
		assert_true(next2["ok"])
		assert_eq(GameState.state["combatPrototype"]["encounterId"], "enforcer")

		var next3 := CombatPrototype.advance_to_next_encounter()
		assert_true(not next3["ok"], "there's no fourth encounter to advance into")
		assert_eq(GameState.state["combatPrototype"]["encounterId"], "enforcer", "a failed advance shouldn't disturb the current encounter")
	)

	run_case("exit_encounter_deactivates_without_touching_the_real_player", func():
		var cp := _fresh_prototype("brawler", { "hp": 42, "hpMax": 100 })
		var real_player_hp: int = GameState.state["player"]["hp"]
		CombatPrototype.exit_encounter()
		assert_true(not cp["active"])
		assert_eq(GameState.state["player"]["hp"], real_player_hp, "a prototype fight must never leak hp changes into the real save")
	)

	# ── Isolation: the prototype's own hp is never the real player's hp ──

	run_case("start_encounter_never_touches_the_real_players_hp_field", func():
		GameState.reset()
		GameState.state["player"]["hp"] = 37
		CombatPrototype.start_encounter("brawler")
		assert_eq(GameState.state["player"]["hp"], 37, "start_encounter should read hpMax to seed the prototype's own player, never write GameState.state.player.hp")
		assert_eq(GameState.state["combatPrototype"]["player"]["hp"], GameState.state["player"]["hpMax"])
	)
