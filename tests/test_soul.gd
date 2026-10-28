extends "res://tests/test_base.gd"


func run() -> void:
	run_case("meditate_awards_ten_xp_and_spends_a_block_without_garden", func():
		GameState.reset()
		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()
		var result := Soul.meditate()
		assert_true(result["ok"], "Meditate should succeed")
		assert_eq(GameState.state["player"]["soulXP"], 10, "10 Soul XP without a Garden")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before + 1, "one block spent")
	)

	run_case("meditate_awards_thirty_xp_with_garden", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("garden")
		Soul.meditate()
		assert_eq(GameState.state["player"]["soulXP"], 30, "30 Soul XP with a Garden")
	)

	run_case("meditate_refused_when_time_exhausted", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = GameData.TIME_BLOCKS.duplicate()
		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()
		var result := Soul.meditate()
		assert_true(not result["ok"], "refused")
		assert_eq(GameState.state["player"]["soulXP"], 0, "no XP")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before, "no block spent")
	)

	run_case("garden_refused_in_flat", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "flat"
		GameState.state["player"]["cash"] = 5000
		var result := Home.set_room_use(0, "garden")
		assert_true(not result["ok"], "refused below townhouse")
		assert_eq(GameState.state["player"]["cash"], 5000, "no cash taken")
	)

	run_case("garden_refused_without_cash", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "townhouse"
		GameState.state["player"]["cash"] = 999
		var result := Home.set_room_use(0, "garden")
		assert_true(not result["ok"], "refused without £1000")
	)

	run_case("garden_bought_in_townhouse_deducts_cost", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "townhouse"
		GameState.state["player"]["cash"] = 1500
		var result := Home.set_room_use(0, "garden")
		assert_true(result["ok"], "buy succeeds")
		assert_eq(GameState.state["player"]["cash"], 500, "£1000 deducted")
		assert_true(GameState.state["home"]["rooms"].has("garden"), "garden built")
	)
