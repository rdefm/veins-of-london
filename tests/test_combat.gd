extends "res://tests/test_base.gd"


static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


func _fresh_combat(context: String = "mugging") -> void:
	GameState.reset()
	GameState.state["combat"] = {
		"active": true, "context": context, "veinId": null,
		"enemy": { "name": "Test Enemy", "hp": 100, "hpMax": 100, "attackMin": 5, "attackMax": 5, "veinId": null, "isMugging": context == "mugging" },
		"log": [], "outcome": null, "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
		"evadeTurns": 0, "evadeChance": 0.0, "onWin": "muggingWon", "snapshots": [],
	}


func run() -> void:
	run_case("mugger_generation_bands_for_count_1_to_3", func():
		var seen := { 1: false, 2: false, 3: false }
		for seed in range(300):
			Rng.set_seed(seed)
			var enemy := Combat.generate_mugger()
			var count: int = enemy["hp"] / 28
			seen[count] = true
			if count == 1:
				assert_eq(enemy["name"], "A mugger", "count 1 name")
				assert_eq(enemy["attackMin"], 4, "count 1 attackMin")
				assert_eq(enemy["attackMax"], 10, "count 1 attackMax")
			elif count == 2:
				assert_eq(enemy["name"], "2 muggers", "count 2 name")
				assert_eq(enemy["attackMin"], 6, "count 2 attackMin = 4+2*1")
				assert_eq(enemy["attackMax"], 13, "count 2 attackMax = 10+3*1")
			elif count == 3:
				assert_eq(enemy["name"], "3 muggers", "count 3 name")
				assert_eq(enemy["attackMin"], 8, "count 3 attackMin = 4+2*2")
				assert_eq(enemy["attackMax"], 16, "count 3 attackMax = 10+3*2")
			assert_eq(enemy["hpMax"], enemy["hp"], "hp starts full")
		assert_true(seen[1] and seen[2] and seen[3], "all three mugger counts should appear across 300 seeds")
	)

	run_case("freeze_skips_enemy_turn_and_decrements", func():
		_fresh_combat()
		GameState.state["combat"]["frozenTurns"] = 2
		var hp_before: int = GameState.state["player"]["hp"]
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["player"]["hp"], hp_before, "player should take no damage while the enemy is frozen")
		assert_eq(GameState.state["combat"]["frozenTurns"], 1, "frozenTurns should decrement by 1")
	)

	run_case("frozen_turns_expiring_logs_and_then_enemy_can_act_next_turn", func():
		_fresh_combat()
		GameState.state["combat"]["frozenTurns"] = 1
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["combat"]["frozenTurns"], 0, "frozenTurns hits 0")
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("coming back round"):
				found = true
		assert_true(found, "expiry should log the wear-off line")
	)

	run_case("motion_grants_2_attacks_at_power_below_3", func():
		_fresh_combat()
		GameState.state["combat"]["motionTurns"] = 1
		GameState.state["combat"]["motionPower"] = 2
		Rng.set_seed(1)
		Combat.player_attack()
		var attack_lines := 0
		for line in GameState.state["combat"]["log"]:
			if line.begins_with("You attack"):
				attack_lines += 1
		assert_eq(attack_lines, 2, "motionPower 2 should grant exactly 2 attacks")
	)

	run_case("motion_grants_3_attacks_at_power_3_or_above", func():
		_fresh_combat()
		GameState.state["combat"]["motionTurns"] = 1
		GameState.state["combat"]["motionPower"] = 3
		Rng.set_seed(1)
		Combat.player_attack()
		var attack_lines := 0
		for line in GameState.state["combat"]["log"]:
			if line.begins_with("You attack"):
				attack_lines += 1
		assert_eq(attack_lines, 3, "motionPower 3 should grant exactly 3 attacks")
	)

	run_case("flee_65_percent_with_seed", func():
		var fled_seed := _find_seed_for(200, func():
			_fresh_combat()
			var result := Combat.flee()
			return result.get("outcome", "") == "fled"
		)
		assert_true(fled_seed != -1, "should find a fled roll within 200 tries")

		var caught_seed := _find_seed_for(200, func():
			_fresh_combat()
			var hp_before: int = GameState.state["player"]["hp"]
			Combat.flee()
			return GameState.state["combat"]["outcome"] != "fled" and GameState.state["player"]["hp"] < hp_before
		)
		assert_true(caught_seed != -1, "should find a failed-flee roll (enemy gets a free hit) within 200 tries")
	)

	run_case("loss_revives_at_30_percent_hpMax", func():
		_fresh_combat()
		GameState.state["player"]["hp"] = 1
		GameState.state["player"]["hpMax"] = 100
		GameState.state["combat"]["enemy"]["attackMin"] = 50
		GameState.state["combat"]["enemy"]["attackMax"] = 50
		Rng.set_seed(1)
		Combat.enemy_attack()
		assert_eq(GameState.state["combat"]["outcome"], "loss", "hp hitting 0 should set outcome to loss")
		assert_eq(GameState.state["player"]["hp"], 30, "revives at round(100*0.3) = 30")
	)

	run_case("evade_consumes_turns_and_can_miss", func():
		_fresh_combat()
		GameState.state["combat"]["evadeTurns"] = 1
		GameState.state["combat"]["evadeChance"] = 1.0  # guaranteed miss
		var hp_before: int = GameState.state["player"]["hp"]
		Rng.set_seed(1)
		Combat.enemy_attack()
		assert_eq(GameState.state["player"]["hp"], hp_before, "a guaranteed evade should prevent all damage")
		assert_eq(GameState.state["combat"]["evadeTurns"], 0, "evadeTurns should decrement")
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("Evade fades"):
				found = true
		assert_true(found, "evade reaching 0 should log 'Evade fades.'")
	)

	run_case("evade_turns_that_do_not_miss_still_consume_a_turn", func():
		_fresh_combat()
		GameState.state["combat"]["evadeTurns"] = 2
		GameState.state["combat"]["evadeChance"] = 0.0  # never miss
		var hp_before: int = GameState.state["player"]["hp"]
		Rng.set_seed(1)
		Combat.enemy_attack()
		assert_eq(GameState.state["combat"]["evadeTurns"], 1, "evadeTurns should still decrement even on a non-miss")
		assert_true(GameState.state["player"]["hp"] < hp_before, "a 0-chance evade should not prevent the hit")
	)

	run_case("rewind_restores_oldest_snapshot_grants_evade_clears_stack", func():
		_fresh_combat()
		var combat: Dictionary = GameState.state["combat"]
		GameState.state["player"]["hp"] = 80
		combat["enemy"]["hp"] = 90
		Snapshots.push("combat", combat["snapshots"], { "playerHp": 100, "enemyHp": 100, "log": ["turn 1"], "frozenTurns": 0, "motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0 })
		Snapshots.push("combat", combat["snapshots"], { "playerHp": 90, "enemyHp": 95, "log": ["turn 1", "turn 2"], "frozenTurns": 0, "motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0 })
		GameState.state["player"]["inventory"]["rewind"] = 1

		var result := Combat.combat_rewind()

		assert_true(result["ok"], "rewind should succeed with a rewind consumable in hand")
		assert_eq(GameState.state["player"]["hp"], 100, "should restore the OLDEST snapshot's playerHp (100, not 90)")
		assert_eq(combat["enemy"]["hp"], 100, "should restore the OLDEST snapshot's enemyHp")
		assert_eq(combat["snapshots"], [], "snapshot stack should be cleared")
		assert_eq(combat["evadeTurns"], 2, "rewind grants 2 evade turns")
		assert_almost_eq(combat["evadeChance"], 0.50, 0.0001, "rewind grants 50% evade chance")
		assert_eq(combat["outcome"], null, "rewind clears any outcome")
		assert_eq(GameState.state["player"]["inventory"]["rewind"], 0, "the rewind consumable should be spent")
		var found := false
		for line in combat["log"]:
			if line.contains("Time unspools"):
				found = true
		assert_true(found, "rewind should log the unspool line")
	)

	run_case("rewind_fails_with_no_snapshots_or_no_rewind_available", func():
		_fresh_combat()
		var no_snap := Combat.combat_rewind()
		assert_true(not no_snap["ok"], "no snapshots yet -> nothing to rewind")

		Combat.push_combat_snapshot()
		var no_item := Combat.combat_rewind()
		assert_true(not no_item["ok"], "a snapshot exists but no rewind consumable/device -> blocked")
	)

	run_case("use_time_pearl_blocked_when_already_frozen", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["timePearl"] = 3
		GameState.state["combat"]["frozenTurns"] = 1
		var result := Combat.use_time_pearl()
		assert_true(not result["ok"], "should refuse when already frozen")
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], 3, "no pearl consumed when blocked")
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("Already frozen"):
				found = true
		assert_true(found, "should log the 'already frozen' line")
	)

	run_case("use_time_pearl_sets_frozenTurns_from_effect_power", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["timePearl"] = 3
		GameState.state["player"]["craftingSkill"] = 1
		Combat.use_time_pearl()
		# timePearl effectPower at skill 1 = 1
		assert_eq(GameState.state["combat"]["frozenTurns"], 1, "frozenTurns should be set from effectPower")
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], 2, "one pearl consumed")
	)

	run_case("use_enhancement_powder_sets_motionTurns_by_power_threshold", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["enhancementPowder"] = 3
		GameState.state["player"]["craftingSkill"] = 1
		Combat.use_enhancement_powder()
		# enhancementPowder effectPower at skill 1 = 1 (< 3) -> motionTurns = 1
		assert_eq(GameState.state["combat"]["motionTurns"], 1, "power < 3 should grant 1 motion turn")
	)

	run_case("home_raid_loss_halves_carried_and_stored_ore", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"] = { "time": 10, "physics": 7 }
		GameState.state["home"]["storedOre"] = { "life": 20 }
		GameState.state["combat"] = {
			"active": true, "context": "home_raid", "veinId": null,
			"enemy": { "name": "The raider", "hp": 0, "hpMax": 35, "attackMin": 6, "attackMax": 14, "veinId": null, "isMugging": false },
			"log": [], "outcome": "loss", "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "homeRaidWon", "snapshots": [],
		}
		var result := Combat.exit_combat()

		assert_eq(result["nextScreen"], "home_raid_debrief", "home_raid should route to the debrief flow")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 5, "floor(10*0.5) = 5 lost, 5 remain")
		assert_eq(GameState.state["player"]["orichalchum"]["physics"], 4, "floor(7*0.5) = 3 lost, 4 remain")
		assert_eq(GameState.state["home"]["storedOre"]["life"], 10, "floor(20*0.5) = 10 lost, 10 remain")
		assert_eq(GameState.state["flags"]["homeRaidWon"], false, "loss should set homeRaidWon false")
		assert_eq(GameState.state["flags"]["homeRaidEventSeen"], true, "loss should still mark the event seen")
	)

	run_case("home_raid_win_does_not_halve_ore", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"] = { "time": 10 }
		GameState.state["combat"] = {
			"active": true, "context": "home_raid", "veinId": null,
			"enemy": { "name": "The raider", "hp": 0, "hpMax": 35, "attackMin": 6, "attackMax": 14, "veinId": null, "isMugging": false },
			"log": [], "outcome": "win", "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "homeRaidWon", "snapshots": [],
		}
		Combat.exit_combat()
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 10, "a win should not halve carried ore")
	)

	run_case("exit_combat_mugging_win_does_not_change_screen", func():
		GameState.reset()
		GameState.state["currentScreen"] = "combat"
		GameState.state["combat"]["active"] = true
		GameState.state["combat"]["context"] = "mugging"
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "combat", "mugging-win exit should leave the screen alone (sale_result modal handles it)")
	)

	run_case("exit_combat_raid_win_routes_to_inventory_else_home", func():
		GameState.reset()
		GameState.state["combat"]["context"] = "raid"
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "inventory", "a raid win should route to inventory")

		GameState.reset()
		GameState.state["combat"]["context"] = "mugging"
		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "home", "anything else should route home")
	)

	run_case("onWin_muggingWon_pays_pendingSaleCut", func():
		_fresh_combat("mugging")
		GameState.state["combat"]["onWin"] = "muggingWon"
		GameState.state["combat"]["enemy"]["hp"] = 1
		GameState.state["player"]["cash"] = 100
		GameState.state["pendingSaleCut"] = 50
		GameState.state["combat"]["enemy"]["attackMin"] = 0
		GameState.state["combat"]["enemy"]["attackMax"] = 0
		# force a lethal hit
		GameState.state["player"]["attackMin"] = 999
		GameState.state["player"]["attackMax"] = 999
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["combat"]["outcome"], "win", "sanity: the enemy should be dead")
		assert_eq(GameState.state["player"]["cash"], 150, "muggingWon should pay out pendingSaleCut")
		assert_eq(GameState.state["pendingSaleCut"], 0, "pendingSaleCut should clear after payout")
	)

	run_case("get_attack_range_includes_equipped_weapon_bonus", func():
		GameState.reset()
		GameState.state["player"]["attackMin"] = 5
		GameState.state["player"]["attackMax"] = 12
		GameState.state["player"]["items"] = [{ "id": "item1", "type": "crowbar" }]
		GameState.state["player"]["equipment"]["weapon"] = "item1"
		var range := Combat.get_attack_range()
		# crowbar attackBonus {min:4, max:8}
		assert_eq(range["min"], 9, "5 + 4")
		assert_eq(range["max"], 20, "12 + 8")
	)

	run_case("get_attack_range_with_no_weapon_equipped", func():
		GameState.reset()
		var range := Combat.get_attack_range()
		assert_eq(range["min"], 5, "bare player attackMin")
		assert_eq(range["max"], 12, "bare player attackMax")
	)
