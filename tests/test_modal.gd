extends "res://tests/test_base.gd"


func run() -> void:
	run_case("open_and_close_modal", func():
		GameState.reset()
		Modal.open("seed_result", { "success": true })
		assert_eq(GameState.state["modal"]["type"], "seed_result", "modal type set")
		assert_eq(GameState.state["modal"]["data"], { "success": true }, "modal data set")

		Modal.close()
		assert_eq(GameState.state["modal"], null, "modal cleared")
	)

	run_case("open_defaults_data_to_empty_dict", func():
		GameState.reset()
		Modal.open("confirm")
		assert_eq(GameState.state["modal"]["data"], {}, "data defaults to an empty dict")
	)
