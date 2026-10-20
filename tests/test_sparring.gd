extends "res://tests/test_base.gd"

# The calc gym's Spar (Sparring): flag-gated, one time block, free sessions
# then a £ fee, scaled partners, a free house-rules Rewind, Combat XP split
# by result, and hp / loadout units restored afterwards.


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

	run_case("hp_and_loadout_units_come_back_as_they_were", func():
		_fresh()
		var player: Dictionary = GameState.state["player"]
		player["hp"] = 17
		player["loadout"]["slots"][0] = { "recipe": "timePearl", "tier": 1 }
		Sparring.spar("hard")
		player["hp"] = 1
		player["loadout"]["slots"][0] = null
		GameState.state["combat"]["outcome"] = "loss"
		Combat.exit_combat()
		assert_eq(player["hp"], 17, "hp restored")
		assert_eq(Loadout.slot(0)["recipe"], "timePearl", "unit restored")
	)
