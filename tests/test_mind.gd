extends "res://tests/test_base.gd"


func run() -> void:
	run_case("study_awards_ten_xp_and_spends_a_block_without_library", func():
		GameState.reset()
		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()
		var result := Mind.study()
		assert_true(result["ok"], "Study should succeed")
		assert_eq(GameState.state["player"]["mindXP"], 10, "10 Mind XP without a Library")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before + 1, "one block spent")
	)

	run_case("study_awards_thirty_xp_with_library", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("library")
		Mind.study()
		assert_eq(GameState.state["player"]["mindXP"], 30, "30 Mind XP with a Library")
	)

	run_case("study_refused_when_time_exhausted", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = GameData.TIME_BLOCKS.duplicate()
		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()
		var result := Mind.study()
		assert_true(not result["ok"], "refused")
		assert_eq(GameState.state["player"]["mindXP"], 0, "no XP")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before, "no block spent")
	)
