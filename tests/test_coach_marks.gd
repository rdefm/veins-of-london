extends "res://tests/test_scripted_fight.gd"

# Coach marks (R§3.7b Coach marks): a fight's `coach` block gives per-round
# lesson lines and an allowed move / item set; other actions are blocked.


func _coached() -> Dictionary:
	var script := _script()
	script["coach"] = {
		"lessons": { "1": "Read the intent. Guard the Strike." },
		"allowed": { "1": ["guard"] },
	}
	return script


func run() -> void:
	run_case("allowed_set_blocks_other_moves_that_round", func():
		var combat := _start(_coached())
		assert_eq(CombatRounds.coach_lesson(combat), "Read the intent. Guard the Strike.")
		assert_eq(CombatRounds.move_block_reason(combat, "guard"), "", "allowed")
		assert_eq(CombatRounds.move_block_reason(combat, "strike", 2), GameData.COMBAT_ROUNDS["coach"]["notNow"])
		assert_eq(CombatRounds.move_block_reason(combat, "legIt"), GameData.COMBAT_ROUNDS["coach"]["notNow"])
		assert_true(not Combat.choose_move("strike", 2)["ok"], "pick refused")
		assert_true(Combat.choose_move("guard")["ok"], "allowed pick plays")
	)

	run_case("rounds_without_a_limit_are_open", func():
		var combat := _start(_coached())
		combat["round"] = 2
		assert_eq(CombatRounds.coach_allowed(combat), [])
		assert_eq(CombatRounds.coach_lesson(combat), "")
		assert_eq(CombatRounds.move_block_reason(combat, "strike", 2), "")
	)

	run_case("ordinary_fights_have_no_coach", func():
		var combat := _start(_script())
		assert_eq(combat["coach"], null)
		assert_true(not CombatRounds.coach_active(combat))
		assert_eq(CombatRounds.move_block_reason(combat, "strike", 2), "")
	)

	run_case("coach_survives_save_and_load", func():
		_start(_coached())
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		var combat: Dictionary = GameState.state["combat"]
		assert_eq(CombatRounds.coach_allowed(combat), ["guard"])
		assert_eq(CombatRounds.move_block_reason(combat, "strike", 2), GameData.COMBAT_ROUNDS["coach"]["notNow"])
	)

	run_case("hints_come_from_data_and_validate", func():
		assert_true(CombatRounds.coach_hint("guard") != "")
		var errors: Array[String] = []
		var script := _script()
		script["coach"] = { "lessons": { "1": "" }, "allowed": { "1": ["nope"] } }
		GameData._validate_effect_list([{ "op": "start_scripted_fight", "script": script }], "t", errors)
		assert_eq(errors.size(), 2)
		GameData.EVENTS.erase(EVENT_ID)
	)
