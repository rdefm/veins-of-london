extends "res://tests/test_base.gd"


static func _find_seed_for(max_tries: int, fn: Callable) -> int:
	for seed in range(max_tries):
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		Rng.set_seed(seed)
		if fn.call():
			return seed
		GameState.state = snapshot
	return -1


func _fresh_combat(context: String = Combat.CONTEXT_MUGGING) -> void:
	GameState.reset()
	GameState.state["combat"] = {
		"active": true, "context": context, "veinId": null,
		"enemy": { "name": "Test Enemy", "hp": 100, "hpMax": 100, "attackMin": 5, "attackMax": 5, "veinId": null, "isMugging": context == Combat.CONTEXT_MUGGING, "weapon": null, "ability": null, "evadeChance": 0.0 },
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

	run_case("home_raid_loss_halves_carried_ore", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"] = { "time": 10, "physics": 7, "life": 20 }
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_HOME_RAID, "veinId": null,
			"enemy": { "name": "The raider", "hp": 0, "hpMax": 35, "attackMin": 6, "attackMax": 14, "veinId": null, "isMugging": false },
			"log": [], "outcome": "loss", "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "homeRaidWon", "snapshots": [],
		}
		var result := Combat.exit_combat()

		assert_eq(result["nextScreen"], "event", "home_raid should route to the generic event screen")
		assert_eq(GameState.state["currentScreen"], "event", "exit_combat should navigate directly for home_raid, same as it already does for raid/other")
		assert_eq(GameState.state["event"]["eventId"], "home_raid_debrief_loss", "a loss should chain into the loss debrief event")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 5, "floor(10*0.5) = 5 lost, 5 remain")
		assert_eq(GameState.state["player"]["orichalchum"]["physics"], 4, "floor(7*0.5) = 3 lost, 4 remain")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 10, "floor(20*0.5) = 10 lost, 10 remain")
		assert_eq(GameState.state["flags"]["homeRaidWon"], false, "loss should set homeRaidWon false")
		assert_eq(GameState.state["flags"]["homeRaidEventSeen"], true, "loss should still mark the event seen")
	)

	run_case("home_raid_win_does_not_halve_ore", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"] = { "time": 10 }
		GameState.state["combat"] = {
			"active": true, "context": Combat.CONTEXT_HOME_RAID, "veinId": null,
			"enemy": { "name": "The raider", "hp": 0, "hpMax": 35, "attackMin": 6, "attackMax": 14, "veinId": null, "isMugging": false },
			"log": [], "outcome": "win", "frozenTurns": 0, "motionTurns": 0, "motionPower": 0,
			"evadeTurns": 0, "evadeChance": 0.0, "onWin": "homeRaidWon", "snapshots": [],
		}
		Combat.exit_combat()
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 10, "a win should not halve carried ore")
		assert_eq(GameState.state["event"]["eventId"], "home_raid_debrief_win", "a win should chain into the win debrief event")
	)

	run_case("exit_combat_mugging_win_does_not_change_screen", func():
		GameState.reset()
		GameState.state["currentScreen"] = "combat"
		GameState.state["combat"]["active"] = true
		GameState.state["combat"]["context"] = Combat.CONTEXT_MUGGING
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "combat", "mugging-win exit should leave the screen alone (sale_result modal handles it)")
	)

	run_case("exit_combat_raid_win_routes_to_inventory_else_home", func():
		GameState.reset()
		GameState.state["combat"]["context"] = Combat.CONTEXT_RAID
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "inventory", "a raid win should route to inventory")

		GameState.reset()
		GameState.state["combat"]["context"] = Combat.CONTEXT_MUGGING
		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "home", "anything else should route home")
	)

	# ── vein-raiding ticket 02: event_raid exit routing ─────────────────

	run_case("exit_combat_event_raid_win_resumes_the_still_active_event", func():
		GameState.reset()
		Events.start_event("intro")
		GameState.state["combat"]["context"] = Combat.CONTEXT_EVENT_RAID
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "event", "a win should resume the event screen")
		assert_true(GameState.state["event"] != null, "the event should still be active, unresolved cardIndex intact, for its next authored card")
	)

	run_case("exit_combat_event_raid_loss_ends_the_event_and_goes_home", func():
		GameState.reset()
		Events.start_event("intro")
		GameState.state["combat"]["context"] = Combat.CONTEXT_EVENT_RAID
		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(GameState.state["currentScreen"], "home", "a loss should route home, same as a losing plain raid")
		assert_eq(GameState.state["event"], null, "the failed raid's event should be cleared, not left dangling")
	)

	# ── vein-raiding ticket 07: defend_vein combat ──────────────────────

	run_case("start_defend_vein_starts_combat_with_the_defend_vein_context", func():
		GameState.reset()
		Combat.start_defend_vein("v1", 2)
		assert_true(GameState.state["combat"]["active"], "defend combat should start")
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_DEFEND_VEIN)
		assert_eq(GameState.state["combat"]["veinId"], "v1")
		assert_eq(GameState.state["currentScreen"], "combat")
	)

	run_case("exit_combat_defend_vein_win_leaves_the_vein_alone_and_routes_home", func():
		GameState.reset()
		var vein := { "id": "pv_test", "oreType": "time", "level": 1, "levelLabel": "Trace", "devBar": 0, "charged": false, "chargeBlocks": 0, "security": "none", "alarmUpgrades": ["alarm"], "location": "Test St, nowhere", "claimedOnDay": 0, "district": "shoreditch", "siteId": "s_player", "hospitability": { "tier": "fair", "bonuses": [] } }
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [{ "id": "s_player", "district": "shoreditch", "tier": "fair", "oreType": "time", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false }]
		GameState.state["world"]["activeDefendRaid"] = { "attackerId": "collective", "veinId": "pv_test", "siteId": "s_player", "success": true }
		GameState.state["combat"]["context"] = Combat.CONTEXT_DEFEND_VEIN
		GameState.state["combat"]["outcome"] = "win"

		Combat.exit_combat()

		assert_eq(GameState.state["currentScreen"], "home", "should route home either way")
		assert_eq(GameState.state["player"]["veins"].size(), 1, "a defend win leaves the vein with the player")
		assert_eq(GameState.state["world"]["sites"][0]["factionVein"], null, "the site should stay player-claimed, not flip to faction-owned")
		assert_eq(GameState.state["world"]["activeDefendRaid"], null, "activeDefendRaid should be cleared either way")
		assert_eq(GameState.state["notifications"].size(), 0, "a win requires no separate notification, per the PRD")
	)

	run_case("exit_combat_defend_vein_loss_transfers_the_vein_exactly_like_the_no_alarm_path", func():
		GameState.reset()
		var vein := { "id": "pv_test", "oreType": "physics", "level": 3, "levelLabel": "Vein", "devBar": 0, "charged": false, "chargeBlocks": 0, "security": "warded", "alarmUpgrades": ["alarm"], "location": "Test St, nowhere", "claimedOnDay": 0, "district": "shoreditch", "siteId": "s_player", "hospitability": { "tier": "fair", "bonuses": [] } }
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [{ "id": "s_player", "district": "shoreditch", "tier": "fair", "oreType": "physics", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false }]
		GameState.state["world"]["activeDefendRaid"] = { "attackerId": "firm", "veinId": "pv_test", "siteId": "s_player", "success": true }
		GameState.state["combat"]["context"] = Combat.CONTEXT_DEFEND_VEIN
		GameState.state["combat"]["outcome"] = "loss"

		Combat.exit_combat()

		assert_eq(GameState.state["currentScreen"], "home")
		assert_eq(GameState.state["player"]["veins"].size(), 0, "the vein leaves player.veins on a defend loss")
		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_true(site["factionVein"] != null, "ownership transfers to the attacking faction, same as the no-alarm path")
		assert_eq(site["factionVein"]["factionId"], "firm")
		assert_eq(site["factionVein"]["oreType"], "physics", "oreType carries over")
		assert_eq(site["factionVein"]["level"], 3, "level carries over")
		assert_eq(site["factionVein"]["security"], "warded", "security carries over")
		assert_eq(GameState.state["world"]["activeDefendRaid"], null, "activeDefendRaid should be cleared")
		assert_eq(GameState.state["notifications"].size(), 1, "a loss should still notify, same as the off-screen path")
	)

	run_case("onWin_muggingWon_pays_pendingSaleCut", func():
		_fresh_combat(Combat.CONTEXT_MUGGING)
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

	# ── hygiene-03: canonical context constants/validation ──────────────

	run_case("every_start_helper_stores_its_canonical_context_constant", func():
		GameState.reset()
		Combat.start_mugging()
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_MUGGING)

		GameState.reset()
		Combat.start_street_mugging()
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_EVENT_MUGGING)

		GameState.reset()
		Combat.start_home_raid_combat()
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_HOME_RAID)

		GameState.reset()
		Combat.start_raid("v1", 1)
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_RAID, "start_raid's default context")

		GameState.reset()
		Combat.start_raid("v1", 1, 1, "", Combat.CONTEXT_EVENT_RAID)
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_EVENT_RAID)

		GameState.reset()
		Combat.start_defend_vein("v1", 2)
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_DEFEND_VEIN)
	)

	run_case("is_canonical_context_accepts_every_named_constant", func():
		for context in Combat.CANONICAL_CONTEXTS:
			assert_true(Combat.is_canonical_context(context), "%s should be canonical" % context)
	)

	run_case("is_canonical_context_rejects_a_typo_or_empty_string", func():
		assert_true(not Combat.is_canonical_context("raidd"), "a typo'd context should not validate")
		assert_true(not Combat.is_canonical_context(""), "an empty context should not validate")
	)

	run_case("start_combat_with_an_unrecognized_context_still_starts_but_stores_it_verbatim", func():
		GameState.reset()
		Combat.start_raid("v1", 1, 1, "", "raidd")
		assert_true(GameState.state["combat"]["active"], "combat should still start -- this ticket is call-site/validation hygiene, not new blocking behaviour")
		assert_eq(GameState.state["combat"]["context"], "raidd", "the bad context is stored verbatim; _start_combat() push_errors loudly instead of silently defaulting it")
	)

	# ── calc-effect-wiring-01: enemy combat capabilities ─────────────────

	run_case("player_attack_zero_evade_chance_always_hits", func():
		_fresh_combat()
		GameState.state["combat"]["enemy"]["evadeChance"] = 0.0
		var hp_before: int = GameState.state["combat"]["enemy"]["hp"]
		Rng.set_seed(1)
		Combat.player_attack()
		assert_true(GameState.state["combat"]["enemy"]["hp"] < hp_before, "0% evade should never dodge -- damage always lands")
		var dodged := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("dodges"):
				dodged = true
		assert_true(not dodged, "no dodge log line at 0% evade")
	)

	run_case("player_attack_guaranteed_evade_chance_always_misses", func():
		_fresh_combat()
		GameState.state["combat"]["enemy"]["evadeChance"] = 1.0
		var hp_before: int = GameState.state["combat"]["enemy"]["hp"]
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["combat"]["enemy"]["hp"], hp_before, "100% evade should always dodge -- no damage lands")
		var dodged := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("dodges") and line.contains("no damage"):
				dodged = true
		assert_true(dodged, "should log the dodge line")
	)

	run_case("player_attack_nonzero_evade_chance_can_go_either_way_across_seeds", func():
		var hit_seed := _find_seed_for(200, func():
			_fresh_combat()
			GameState.state["combat"]["enemy"]["evadeChance"] = 0.5
			var hp_before: int = GameState.state["combat"]["enemy"]["hp"]
			Combat.player_attack()
			return GameState.state["combat"]["enemy"]["hp"] < hp_before
		)
		assert_true(hit_seed != -1, "should find a landed-hit roll within 200 tries at 50% evade")

		var miss_seed := _find_seed_for(200, func():
			_fresh_combat()
			GameState.state["combat"]["enemy"]["evadeChance"] = 0.5
			var hp_before: int = GameState.state["combat"]["enemy"]["hp"]
			Combat.player_attack()
			return GameState.state["combat"]["enemy"]["hp"] == hp_before
		)
		assert_true(miss_seed != -1, "should find a dodged-miss roll within 200 tries at 50% evade")
	)

	run_case("disarm_enemy_strips_weapon_bonus_and_locks_ability", func():
		_fresh_combat()
		var enemy: Dictionary = GameState.state["combat"]["enemy"]
		enemy["weapon"] = { "min": 3, "max": 6 }
		enemy["ability"] = { "id": "test_ability", "lockedTurns": 0 }

		Combat.disarm_enemy(enemy, 2)

		assert_eq(enemy["weapon"], null, "weapon bonus should be stripped")
		assert_eq(enemy["ability"]["lockedTurns"], 2, "ability should be locked for the given number of turns")
		assert_true(Combat.is_ability_locked(enemy), "is_ability_locked should report true while lockedTurns > 0")
	)

	run_case("disarm_enemy_weapon_strip_removes_the_attack_bonus_from_enemy_damage", func():
		_fresh_combat()
		var enemy: Dictionary = GameState.state["combat"]["enemy"]
		enemy["attackMin"] = 5
		enemy["attackMax"] = 5
		enemy["weapon"] = { "min": 20, "max": 20 }
		var before := Combat.get_enemy_attack_range(enemy)
		assert_eq(before["min"], 25, "weapon bonus should apply before disarm")

		Combat.disarm_enemy(enemy, 1)

		var after := Combat.get_enemy_attack_range(enemy)
		assert_eq(after["min"], 5, "weapon bonus should be gone after disarm")
		assert_eq(after["max"], 5, "weapon bonus should be gone after disarm")
	)

	run_case("disarmed_ability_lock_expires_after_n_player_turns_and_logs_it", func():
		_fresh_combat()
		var enemy: Dictionary = GameState.state["combat"]["enemy"]
		enemy["ability"] = { "id": "test_ability", "lockedTurns": 0 }
		Combat.disarm_enemy(enemy, 2)
		assert_true(Combat.is_ability_locked(enemy), "should start locked")

		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(enemy["ability"]["lockedTurns"], 1, "one player turn should tick the lock down by 1")
		assert_true(Combat.is_ability_locked(enemy), "still locked with 1 turn left")

		Combat.player_attack()
		assert_eq(enemy["ability"]["lockedTurns"], 0, "second player turn should exhaust the lock")
		assert_true(not Combat.is_ability_locked(enemy), "no longer locked once lockedTurns hits 0")
		var found := false
		for line in GameState.state["combat"]["log"]:
			if line.contains("back online"):
				found = true
		assert_true(found, "expiry should log the ability-restored line")
	)

	run_case("disarm_enemy_with_no_ability_is_a_no_op_for_the_ability_field", func():
		_fresh_combat()
		var enemy: Dictionary = GameState.state["combat"]["enemy"]
		assert_eq(enemy["ability"], null, "sanity: fixture enemy has no ability")
		Combat.disarm_enemy(enemy, 3)
		assert_eq(enemy["ability"], null, "disarm should not fabricate an ability where none existed")
		assert_true(not Combat.is_ability_locked(enemy), "no ability -> never locked")
	)

	run_case("existing_raid_guard_templates_default_to_zero_evade_chance", func():
		GameState.reset()
		for key in GameData.ENEMY_RAID_GUARDS.keys():
			var enemy := Combat.generate_raid_enemy("v1", 1, 1, key)
			assert_eq(enemy["evadeChance"], 0.0, "%s should default to 0%% evade (existing template, preserves current combat math)" % key)
			assert_eq(enemy["weapon"], null, "%s should have no weapon by default" % key)
			assert_eq(enemy["ability"], null, "%s should have no ability by default" % key)
	)

	run_case("home_raid_raider_template_defaults_to_zero_evade_chance", func():
		GameState.reset()
		Combat.start_home_raid_combat()
		assert_eq(GameState.state["combat"]["enemy"]["evadeChance"], 0.0, "homeRaidRaider should default to 0% evade")
	)

	run_case("procedural_mugger_defaults_to_zero_evade_chance", func():
		for seed in range(10):
			Rng.set_seed(seed)
			var enemy := Combat.generate_mugger()
			assert_eq(enemy["evadeChance"], 0.0, "procedurally generated muggers should default to 0% evade")
			assert_eq(enemy["weapon"], null, "muggers should have no weapon by default")
			assert_eq(enemy["ability"], null, "muggers should have no ability by default")
	)

	run_case("raid_enemy_template_without_an_explicit_evadeChance_defaults_to_20_percent", func():
		# Exercises Combat's capability-assembly helper directly against a
		# template dict, rather than mutating the shared GameData.ENEMY_RAID_GUARDS
		# singleton (which would leak on an assertion failure mid-case).
		var template := { "name": "New Guard", "hpBase": 20, "attackMin": 3, "attackMax": 8 }
		var capabilities := Combat._enemy_capabilities_from_template(template)
		assert_almost_eq(capabilities["evadeChance"], 0.2, 0.0001, "a newly-authored template that omits evadeChance should default to 20%")
	)

	# ── calc-effect-wiring-02: combat-pattern consumables ────────────────

	run_case("use_blast_deals_immediate_damage_and_grants_a_flee_boost", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blast"] = 2
		GameState.state["player"]["craftingSkill"] = 1
		var hp_before: int = GameState.state["combat"]["enemy"]["hp"]
		var result := Combat.use_blast()
		assert_true(result["ok"], "should succeed with a blast in hand")
		# blast effectPower at skill 1 = 6
		assert_eq(GameState.state["combat"]["enemy"]["hp"], hp_before - 6, "should deal effectPower damage immediately")
		assert_eq(GameState.state["player"]["inventory"]["blast"], 1, "one blast consumed")
		assert_eq(GameState.state["combat"]["blastFleeBoost"], true, "should grant a one-use flee boost")
	)

	run_case("use_blast_fails_with_none_in_inventory", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blast"] = 0
		var result := Combat.use_blast()
		assert_true(not result["ok"], "should fail with no blast")
	)

	run_case("use_blast_can_defeat_the_enemy_outright", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blast"] = 1
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["combat"]["enemy"]["hp"] = 3
		Combat.use_blast()
		assert_eq(GameState.state["combat"]["outcome"], "win", "lethal blast damage should win the fight")
	)

	run_case("blast_flee_boost_raises_flee_chance_to_90_percent_and_clears_after_one_attempt", func():
		var boosted_flee_seed := _find_seed_for(50, func():
			_fresh_combat()
			GameState.state["combat"]["blastFleeBoost"] = true
			var result := Combat.flee()
			return result.get("outcome", "") == "fled"
		)
		assert_true(boosted_flee_seed != -1, "a 90% boosted flee chance should fled within 50 tries")

		_fresh_combat()
		GameState.state["combat"]["blastFleeBoost"] = true
		Rng.set_seed(boosted_flee_seed)
		Combat.flee()
		assert_eq(GameState.state["combat"]["blastFleeBoost"], false, "the boost should clear after the one attempt regardless of outcome")
	)

	run_case("blast_flee_boost_clears_even_on_a_failed_flee_attempt", func():
		var failed_flee_seed := _find_seed_for(200, func():
			_fresh_combat()
			GameState.state["combat"]["blastFleeBoost"] = true
			var result := Combat.flee()
			return result.get("outcome", "") != "fled"
		)
		assert_true(failed_flee_seed != -1, "should find a failed boosted-flee roll within 200 tries")

		_fresh_combat()
		GameState.state["combat"]["blastFleeBoost"] = true
		Rng.set_seed(failed_flee_seed)
		Combat.flee()
		assert_eq(GameState.state["combat"]["blastFleeBoost"], false, "the boost should still clear on a failed attempt")
	)

	run_case("blast_can_disarm_the_enemy_on_its_small_chance", func():
		var disarm_seed := _find_seed_for(500, func():
			_fresh_combat()
			GameState.state["player"]["inventory"]["blast"] = 1
			var enemy: Dictionary = GameState.state["combat"]["enemy"]
			enemy["weapon"] = { "min": 3, "max": 6 }
			enemy["ability"] = { "id": "test_ability", "lockedTurns": 0 }
			Combat.use_blast()
			return Combat.is_ability_locked(enemy)
		)
		assert_true(disarm_seed != -1, "blast's 15% disarm chance should land within 500 tries")

		_fresh_combat()
		GameState.state["player"]["inventory"]["blast"] = 1
		var enemy: Dictionary = GameState.state["combat"]["enemy"]
		enemy["weapon"] = { "min": 3, "max": 6 }
		enemy["ability"] = { "id": "test_ability", "lockedTurns": 0 }
		Rng.set_seed(disarm_seed)
		Combat.use_blast()
		assert_eq(enemy["weapon"], null, "a landed disarm should also strip the weapon bonus")
	)

	run_case("use_shield_sets_shieldPool_from_effect_power", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["shield"] = 2
		GameState.state["player"]["craftingSkill"] = 1
		var result := Combat.use_shield()
		assert_true(result["ok"], "should succeed with a shield in hand")
		# shield effectPower at skill 1 = 4
		assert_eq(GameState.state["player"]["shieldPool"], 4, "shieldPool should be set from effectPower")
		assert_eq(GameState.state["player"]["inventory"]["shield"], 1, "one shield consumed")
	)

	run_case("use_shield_blocked_while_a_pool_is_still_active", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["shield"] = 2
		GameState.state["player"]["shieldPool"] = 3
		var result := Combat.use_shield()
		assert_true(not result["ok"], "a second shield should be blocked while one is active")
		assert_eq(GameState.state["player"]["inventory"]["shield"], 2, "no shield consumed when blocked")
		assert_eq(GameState.state["player"]["shieldPool"], 3, "existing pool untouched")
	)

	run_case("use_shield_fails_with_none_in_inventory", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["shield"] = 0
		var result := Combat.use_shield()
		assert_true(not result["ok"], "should fail with no shield")
	)

	run_case("shield_absorbs_damage_1_to_1_when_damage_does_not_exceed_the_pool", func():
		_fresh_combat()
		GameState.state["player"]["shieldPool"] = 20
		GameState.state["player"]["hp"] = 100
		GameState.state["combat"]["enemy"]["attackMin"] = 10
		GameState.state["combat"]["enemy"]["attackMax"] = 10
		Rng.set_seed(1)
		Combat.enemy_attack()
		assert_eq(GameState.state["player"]["hp"], 100, "10 dmg <= 20 pool -> player takes 0")
		assert_eq(GameState.state["player"]["shieldPool"], 10, "pool should drain by the full damage amount")
	)

	run_case("shield_overflow_drains_the_pool_and_passes_the_remainder_through", func():
		_fresh_combat()
		GameState.state["player"]["shieldPool"] = 5
		GameState.state["player"]["hp"] = 100
		GameState.state["combat"]["enemy"]["attackMin"] = 12
		GameState.state["combat"]["enemy"]["attackMax"] = 12
		Rng.set_seed(1)
		Combat.enemy_attack()
		assert_eq(GameState.state["player"]["hp"], 93, "12 dmg - 5 pool = 7 damage taken")
		assert_eq(GameState.state["player"]["shieldPool"], 0, "pool should be fully drained")
	)

	run_case("use_black_hole_deals_immediate_damage_and_adds_to_frozenTurns", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blackHole"] = 2
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["combat"]["frozenTurns"] = 1
		var hp_before: int = GameState.state["combat"]["enemy"]["hp"]
		var result := Combat.use_black_hole()
		assert_true(result["ok"], "should succeed with a black hole in hand")
		# blackHole effectPower at skill 1 = 8 -> freeze = 1 + floor(8/8) = 2
		assert_eq(GameState.state["combat"]["enemy"]["hp"], hp_before - 8, "should deal effectPower damage immediately")
		assert_eq(GameState.state["combat"]["frozenTurns"], 3, "should add to the existing frozenTurns, not replace it (1 prior + 2 new)")
		assert_eq(GameState.state["player"]["inventory"]["blackHole"], 1, "one black hole consumed")
	)

	run_case("use_black_hole_fails_with_none_in_inventory", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blackHole"] = 0
		var result := Combat.use_black_hole()
		assert_true(not result["ok"], "should fail with no black hole")
	)

	run_case("use_black_hole_can_defeat_the_enemy_outright", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["blackHole"] = 1
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["combat"]["enemy"]["hp"] = 3
		Combat.use_black_hole()
		assert_eq(GameState.state["combat"]["outcome"], "win", "lethal black hole damage should win the fight")
	)

	# ── calc-effect-wiring-03: reactive and escape consumables ───────────

	run_case("use_prophets_breath_sets_evadeTurns_from_effect_power_and_50_percent_chance", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["prophetsBreath"] = 2
		GameState.state["player"]["craftingSkill"] = 1
		var result := Combat.use_prophets_breath()
		assert_true(result["ok"], "should succeed with prophet's breath in hand")
		# prophetsBreath effectPower ([0,1,1,2,2,3]) at skill 1 = 1
		assert_eq(GameState.state["combat"]["evadeTurns"], 1, "evadeTurns should be set from effectPower")
		assert_almost_eq(GameState.state["combat"]["evadeChance"], 0.50, 0.0001, "evadeChance should be 50%, same as Rewind's grant")
		assert_eq(GameState.state["player"]["inventory"]["prophetsBreath"], 1, "one prophet's breath consumed")
	)

	run_case("use_prophets_breath_fails_with_none_in_inventory", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["prophetsBreath"] = 0
		var result := Combat.use_prophets_breath()
		assert_true(not result["ok"], "should fail with no prophet's breath")
	)

	run_case("use_prophets_breath_overwrites_an_existing_evade_grant_rather_than_stacking", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["prophetsBreath"] = 1
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["combat"]["evadeTurns"] = 5
		GameState.state["combat"]["evadeChance"] = 0.9
		Combat.use_prophets_breath()
		# prophetsBreath effectPower ([0,1,1,2,2,3]) at skill 1 = 1
		assert_eq(GameState.state["combat"]["evadeTurns"], 1, "should overwrite, not add to, an existing evade grant")
		assert_almost_eq(GameState.state["combat"]["evadeChance"], 0.50, 0.0001, "should overwrite evadeChance too")
	)

	run_case("use_wormhole_flee_guarantees_the_outcome_and_consumes_one", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["wormhole"] = 1
		var result := Combat.use_wormhole()
		assert_true(result["ok"], "should succeed with a wormhole in hand")
		assert_eq(GameState.state["combat"]["outcome"], "fled", "wormhole should guarantee a flee outright")
		assert_eq(GameState.state["player"]["inventory"]["wormhole"], 0, "one wormhole consumed")
	)

	run_case("use_wormhole_flee_never_gives_the_enemy_a_free_attack", func():
		# use_wormhole() bypasses flee()'s roll (and its free-attack-on-fail
		# consequence) entirely -- no Rng call at all, so this holds
		# unconditionally rather than needing a seed search.
		_fresh_combat()
		GameState.state["player"]["inventory"]["wormhole"] = 1
		GameState.state["combat"]["enemy"]["attackMin"] = 50
		GameState.state["combat"]["enemy"]["attackMax"] = 50
		var hp_before: int = GameState.state["player"]["hp"]
		Combat.use_wormhole()
		assert_eq(GameState.state["player"]["hp"], hp_before, "wormhole flee must never let the enemy get a parting shot in")
	)

	run_case("use_wormhole_fails_with_none_in_inventory", func():
		_fresh_combat()
		GameState.state["player"]["inventory"]["wormhole"] = 0
		var result := Combat.use_wormhole()
		assert_true(not result["ok"], "should fail with no wormhole")
	)

	run_case("failsafe_auto_triggers_before_the_loss_outcome_when_hp_would_hit_0", func():
		_fresh_combat()
		var combat: Dictionary = GameState.state["combat"]
		GameState.state["player"]["hp"] = 100
		GameState.state["player"]["hpMax"] = 100
		GameState.state["player"]["inventory"]["failsafe"] = 1
		combat["enemy"]["attackMin"] = 500
		combat["enemy"]["attackMax"] = 500
		Snapshots.push("combat", combat["snapshots"], { "playerHp": 90, "enemyHp": 80, "log": ["turn 1"], "frozenTurns": 0, "motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0 })

		Rng.set_seed(1)
		Combat.enemy_attack()

		assert_eq(GameState.state["player"]["inventory"]["failsafe"], 0, "the failsafe should be auto-consumed")
		assert_eq(GameState.state["player"]["hp"], 90, "should restore the snapshot's playerHp, not the 30%-hpMax revive")
		assert_eq(combat["outcome"], null, "the loss outcome must never resolve when failsafe catches it")
		assert_eq(combat["snapshots"], [], "the snapshot stack should be cleared, same as a manual rewind")
		var found := false
		for line in combat["log"]:
			if line.contains("Failsafe fires"):
				found = true
		assert_true(found, "should log the failsafe auto-trigger line")
	)

	run_case("failsafe_does_not_trigger_with_no_snapshot_to_restore_to", func():
		_fresh_combat()
		var combat: Dictionary = GameState.state["combat"]
		GameState.state["player"]["hp"] = 100
		GameState.state["player"]["hpMax"] = 100
		GameState.state["player"]["inventory"]["failsafe"] = 1
		combat["enemy"]["attackMin"] = 500
		combat["enemy"]["attackMax"] = 500

		Rng.set_seed(1)
		Combat.enemy_attack()

		assert_eq(GameState.state["player"]["inventory"]["failsafe"], 1, "failsafe should not be spent with nothing to restore to")
		assert_eq(combat["outcome"], "loss", "the loss should resolve normally")
		assert_eq(GameState.state["player"]["hp"], 30, "should revive at 30% hpMax, the normal loss path")
	)

	run_case("failsafe_is_tried_before_a_manually_held_rewind_consumable_or_device", func():
		# Both a rewind consumable and failsafe are in stock -- failsafe
		# should fire (its own inventory count drops), leaving the rewind
		# consumable untouched, since failsafe is checked automatically
		# before the player ever gets a chance to manually spend Rewind.
		_fresh_combat()
		var combat: Dictionary = GameState.state["combat"]
		GameState.state["player"]["hp"] = 100
		GameState.state["player"]["hpMax"] = 100
		GameState.state["player"]["inventory"]["failsafe"] = 1
		GameState.state["player"]["inventory"]["rewind"] = 1
		combat["enemy"]["attackMin"] = 500
		combat["enemy"]["attackMax"] = 500
		Snapshots.push("combat", combat["snapshots"], { "playerHp": 90, "enemyHp": 80, "log": ["turn 1"], "frozenTurns": 0, "motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0 })

		Rng.set_seed(1)
		Combat.enemy_attack()

		assert_eq(GameState.state["player"]["inventory"]["failsafe"], 0, "failsafe should be spent")
		assert_eq(GameState.state["player"]["inventory"]["rewind"], 1, "the rewind consumable should be left untouched")
	)

	run_case("failsafe_auto_triggers_inside_an_event_raid_context_too", func():
		# vein-raiding's event-embedded-raid case (event_raid context) uses
		# the same enemy_attack() path -- failsafe must not be context-gated.
		_fresh_combat(Combat.CONTEXT_EVENT_RAID)
		var combat: Dictionary = GameState.state["combat"]
		GameState.state["player"]["hp"] = 100
		GameState.state["player"]["hpMax"] = 100
		GameState.state["player"]["inventory"]["failsafe"] = 1
		combat["enemy"]["attackMin"] = 500
		combat["enemy"]["attackMax"] = 500
		Snapshots.push("combat", combat["snapshots"], { "playerHp": 90, "enemyHp": 80, "log": ["turn 1"], "frozenTurns": 0, "motionTurns": 0, "motionPower": 0, "evadeTurns": 0, "evadeChance": 0.0 })

		Rng.set_seed(1)
		Combat.enemy_attack()

		assert_eq(combat["outcome"], null, "failsafe should catch the loss inside an event_raid context too")
		assert_eq(GameState.state["player"]["inventory"]["failsafe"], 0, "the failsafe should be auto-consumed")
	)
