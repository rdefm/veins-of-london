extends "res://tests/test_base.gd"

# The calc gym's Spar (Sparring): flag-gated, one time block, free sessions
# then a £ fee, scaled partners, a free house-rules Rewind, Combat XP split
# by result, hp restored afterwards, and the practice rack's free T1 units.


func _fresh() -> void:
	GameState.reset()
	GameState.state["flags"]["gymUnlocked"] = true
	GameState.state["player"]["cash"] = 500


func run() -> void:
	run_case("locked_until_the_flag_and_refused_without_time_or_cash", func():
		GameState.reset()
		assert_true(not Sparring.spar("even")["ok"], "locked")
		_fresh()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		assert_eq(Sparring.spar("even")["reason"], Sparring.line("noTime"), "no time blocks")
		GameState.state["world"]["timeBlocksDone"] = []
		GameState.state["flags"]["sparSessions"] = 3
		GameState.state["player"]["cash"] = Sparring.config()["fee"] - 1
		assert_eq(Sparring.spar("even")["reason"], Sparring.line("cantPay"), "can't pay the fee")
		assert_true(not GameState.state["combat"]["active"], "no fight opened")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 0, "no block spent")
	)

	run_case("three_free_sessions_then_the_fee", func():
		_fresh()
		var fee: int = Sparring.config()["fee"]
		for i in range(3):
			assert_eq(Sparring.next_fee(), 0, "session %d is free" % (i + 1))
			assert_true(Sparring.spar("even")["ok"])
			Combat.exit_combat()
		assert_eq(GameState.state["player"]["cash"], 500, "nothing charged")
		assert_eq(Sparring.free_sessions_left(), 0)
		assert_eq(Sparring.next_fee(), fee)
		assert_true(Sparring.spar("even")["ok"])
		assert_eq(GameState.state["player"]["cash"], 500 - fee, "the fourth costs the fee")
		assert_eq(Sparring.sessions_taken(), 4)
	)

	run_case("partners_scale_off_the_players_combat_skill", func():
		_fresh()
		GameState.state["player"]["combatSkill"] = 3
		var levels: Array = []
		for id in ["easy", "even", "hard"]:
			assert_true(Sparring.spar(id)["ok"])
			levels.append(GameState.state["combat"]["combatants"][1]["level"])
			Combat.exit_combat()
		assert_eq(levels, [2, 3, 4])
		GameState.state["player"]["combatSkill"] = 1
		assert_eq(Sparring.partner_level(Sparring.partner("easy"), 1), 1, "clamped at level 1")
	)

	run_case("the_house_rewind_is_free_and_unlimited", func():
		_fresh()
		GameState.state["player"]["loadout"]["slots"][0] = { "recipe": "rewind", "tier": 1 }
		Sparring.spar("even")
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["context"], Combat.CONTEXT_SPAR)
		for i in range(3):
			assert_true(Combat.choose_move("guard")["ok"])
			assert_eq(Combat.round_rewind_block_reason(Combat.REWIND_PAY_FREE), "", "open")
			assert_true(Combat.round_rewind(Combat.REWIND_PAY_FREE)["ok"], "rewind %d" % (i + 1))
		assert_eq(Loadout.slot(0)["recipe"], "rewind", "no unit spent")
	)

	run_case("the_house_rewind_is_refused_outside_a_spar", func():
		_fresh()
		Combat.start_street_mugging()
		assert_eq(Combat.round_rewind_block_reason(Combat.REWIND_PAY_FREE), Combat.REASON_NO_HOUSE_RULES)
	)

	run_case("xp_is_a_base_plus_a_win_bonus", func():
		_fresh()
		var cfg := Sparring.config()
		assert_eq(Sparring.xp_for("loss"), cfg["xpBase"])
		assert_eq(Sparring.xp_for("fled"), cfg["xpBase"])
		assert_eq(Sparring.xp_for("win"), cfg["xpBase"] + cfg["xpWinBonus"])
		Sparring.spar("even")
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(GameState.state["player"]["combatXP"], cfg["xpBase"] + cfg["xpWinBonus"], "win XP awarded")
		Sparring.spar("even")
		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(GameState.state["player"]["combatXP"], 2 * cfg["xpBase"] + cfg["xpWinBonus"], "loss earns the base")
		assert_true(not GameState.state["combat"]["active"])
	)

	run_case("hp_comes_back_and_own_spent_units_stay_spent", func():
		_fresh()
		var player: Dictionary = GameState.state["player"]
		player["hp"] = 17
		player["loadout"]["slots"][0] = { "recipe": "timePearl", "tier": 1 }
		Sparring.spar("hard")
		player["hp"] = 1
		Loadout.consume(0)
		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(player["hp"], 17, "hp restored")
		assert_eq(Loadout.slot(0), null, "own unit spent, none in the bag to refill")
	)

	run_case("rack_only_spar_leaves_inventory_and_slots_as_they_were", func():
		_fresh()
		var player: Dictionary = GameState.state["player"]
		Crafting.inventory_add("blast", 2, 1)
		player["loadout"]["slots"][0] = { "recipe": "timePearl", "tier": 2 }
		var inv_before: Dictionary = player["inventory"].duplicate(true)
		var slots_before: Array = player["loadout"]["slots"].duplicate(true)
		assert_true(Sparring.spar("even", { 0: "shield", 1: "rewind" })["ok"])
		assert_eq(Loadout.slot(0), { "recipe": "shield", "tier": 1, "rack": true }, "rack unit in play")
		Loadout.consume(0)
		Loadout.consume(1)
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(player["inventory"], inv_before, "inventory untouched")
		assert_eq(player["loadout"]["slots"], slots_before, "slots untouched")
	)

	run_case("rack_slots_ignore_junk_and_own_slots_spend_normally", func():
		_fresh()
		var player: Dictionary = GameState.state["player"]
		player["loadout"]["slots"][1] = { "recipe": "timePearl", "tier": 1 }
		Crafting.inventory_add("timePearl", 3, 1)
		assert_true(Sparring.spar("even", { 0: "notAnItem", 7: "shield", 1: "wormhole" })["ok"])
		assert_eq(Loadout.slot(0), null, "unknown rack item ignored")
		Combat.exit_combat()
		_fresh()
		player = GameState.state["player"]
		player["loadout"]["slots"][1] = { "recipe": "timePearl", "tier": 1 }
		player["loadout"]["lastRecipe"][1] = "timePearl"
		Crafting.inventory_add("timePearl", 3, 1)
		Sparring.spar("even", { 0: "shield" })
		Loadout.consume(0)
		Loadout.consume(1)
		GameState.state["combat"]["outcome"] = "win"
		Combat.exit_combat()
		assert_eq(Loadout.slot(0), null, "rack slot back to its empty own slot")
		assert_eq(Loadout.slot(1)["tier"], 3, "own spent unit refilled from the bag as normal")
	)

	run_case("spar_prep_cycles_rack_items_and_fight_uses_them", func():
		_fresh()
		CombatPrep.request(CombatPrep.KIND_SPAR, { "partnerId": "even", "rack": {} })
		assert_true(CombatPrep.cycle_rack_slot(0))
		var rack_items := Sparring.rack_items()
		var rows := CombatPrep.participants(CombatPrep.pending())
		assert_eq(rows[0]["units"], [{ "recipe": rack_items[0], "tier": 1, "rack": true }], "listed as practice")
		for i in range(rack_items.size()):
			CombatPrep.cycle_rack_slot(0)
		assert_eq(CombatPrep.pending()["args"]["rack"].size(), 0, "cycles back to own")
		CombatPrep.cycle_rack_slot(0)
		assert_true(CombatPrep.commit()["ok"])
		assert_eq(Loadout.slot(0)["recipe"], rack_items[0])
		assert_true(Loadout.slot(0)["rack"])
	)
