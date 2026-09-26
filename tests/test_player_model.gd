extends "res://tests/test_base.gd"


func run() -> void:
	run_case("set_model_writes_a_discovered_variant", func():
		GameState.reset()
		var key: String = GameData.TERRITORIAL_VARIANTS[0]
		assert_true(PlayerModel.set_model(key), "a discovered variant is accepted")
		assert_eq(GameState.state["player"]["model"], key, "player.model holds the chosen variant")
	)

	run_case("set_model_refuses_an_unknown_key", func():
		GameState.reset()
		var before: String = GameState.state["player"]["model"]
		assert_true(not PlayerModel.set_model("territorial999"), "an undiscovered key is refused")
		assert_true(not PlayerModel.set_model("mugger"), "a non-variant template key is refused")
		assert_true(not PlayerModel.set_model(""), "an empty key is refused")
		assert_eq(GameState.state["player"]["model"], before, "a refused key leaves player.model untouched")
	)

	run_case("debug_start_keeps_the_chosen_model_through_its_reset", func():
		var key: String = GameData.TERRITORIAL_VARIANTS[0]
		DebugStart.apply(key)
		assert_eq(GameState.state["player"]["model"], key, "the picked model survives DebugStart's reset")
	)
