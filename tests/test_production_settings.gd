extends "res://tests/test_base.gd"

const SALVE := "healingSalve"


func run() -> void:
	run_case("new_game_holds_master_defaults_and_no_overrides", func():
		GameState.reset()
		var production: Dictionary = GameState.state["production"]
		assert_eq(production["overrides"], {})
		assert_eq(production["master"], {
			"production": 0,
			"keep": 0,
			"sellAbove": GameData.PRODUCTION_TARGET_MAX,
			"mood": GameData.MARKET["autoSell"]["defaultMood"],
			"coverContracts": true,
		})
		assert_eq(ProductionSettings.resolve(SALVE), production["master"])
	)

	run_case("editing_any_field_copies_the_whole_master_into_an_override", func():
		GameState.reset()
		ProductionSettings.set_master_field("keep", 4)
		ProductionSettings.set_master_field("mood", "aggressive")
		assert_true(not ProductionSettings.has_override(SALVE))
		Rooms.set_lab_cover_contracts(SALVE, false)
		assert_true(ProductionSettings.has_override(SALVE))
		var setting_set := ProductionSettings.resolve(SALVE)
		assert_eq(setting_set["keep"], 4, "other fields copied from master")
		assert_eq(setting_set["mood"], "aggressive")
		assert_eq(setting_set["coverContracts"], false, "the edit applied")
		assert_true(not is_same(ProductionSettings.master(), setting_set), "override is a copy")
		assert_eq(ProductionSettings.master()["coverContracts"], true, "master untouched")
	)

	run_case("master_edits_reach_only_non_overridden_recipes", func():
		GameState.reset()
		Rooms.set_lab_threshold(SALVE, 7)
		ProductionSettings.set_master_field("production", 3)
		assert_eq(Rooms.lab_target(SALVE), 7, "override keeps its own copy")
		assert_eq(Rooms.lab_target("timePearl"), 3, "followers pick up the master")
	)

	run_case("revert_drops_the_override_and_follows_master_again", func():
		GameState.reset()
		Rooms.set_lab_threshold(SALVE, 7)
		ProductionSettings.revert(SALVE)
		assert_true(not ProductionSettings.has_override(SALVE))
		assert_eq(Rooms.lab_target(SALVE), 0)
		ProductionSettings.revert(SALVE)
		assert_true(not ProductionSettings.has_override(SALVE), "reverting nothing is harmless")
	)

	run_case("v14_save_resets_to_master_defaults_and_drops_old_fields", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save.erase("production")
		save["meta"]["saveVersion"] = 14
		save["labThresholds"] = { SALVE: 9 }
		save["labCoverContracts"] = { SALVE: true }
		save["autoSell"] = { SALVE: { "sellAbove": 3, "mood": "aggressive" } }
		assert_true(SaveManager.import_string(JSON.stringify(save))["ok"])
		assert_eq(GameState.state["production"], ProductionSettings.default_state())
		assert_true(not GameState.state.has("labThresholds") and not GameState.state.has("labCoverContracts") and not GameState.state.has("autoSell"))
		assert_eq(GameState.state["meta"]["saveVersion"], SaveManager.SAVE_VERSION)
	)

	run_case("overrides_survive_a_save_round_trip", func():
		GameState.reset()
		Rooms.set_lab_threshold(SALVE, 7)
		var exported: String = SaveManager.export_string()
		ProductionSettings.revert(SALVE)
		assert_true(SaveManager.import_string(exported)["ok"])
		assert_eq(Rooms.lab_target(SALVE), 7)
		assert_eq(typeof(ProductionSettings.resolve(SALVE)["keep"]), TYPE_INT)
	)
