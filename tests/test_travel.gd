extends "res://tests/test_base.gd"


func run() -> void:
	run_case("blocks_needed_zero_for_current_district", func():
		GameState.reset()
		assert_eq(Travel.blocks_needed("shoreditch"), 0, "no travel needed for the district you're already in")
	)

	run_case("blocks_needed_one_for_a_different_district", func():
		GameState.reset()
		assert_eq(Travel.blocks_needed("camden"), 1, "travel needed to reach a district you're not in")
	)

	run_case("ensure_district_same_district_spends_no_travel_block", func():
		GameState.reset()
		var result := Travel.ensure_district("shoreditch")
		assert_true(result["ok"], "should succeed")
		assert_true(not result["travelled"], "no travel consumed for the current district")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "ensure_district itself spends no block when already there")
	)

	run_case("ensure_district_cross_district_consumes_one_travel_block_and_updates_currentDistrict", func():
		GameState.reset()
		var result := Travel.ensure_district("camden")
		assert_true(result["ok"], "should succeed with 3 blocks available")
		assert_true(result["travelled"], "travel block consumed")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [0], "one block spent on travel")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "currentDistrict updates as a side effect of travel")
	)

	run_case("ensure_district_cross_district_blocked_with_only_1_block_remaining", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1]  # 1 block remaining
		var result := Travel.ensure_district("camden")
		assert_true(not result["ok"], "travel(1) + action(1) = 2 blocks needed, only 1 remains")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [0, 1], "no block consumed when blocked")
		assert_eq(GameState.state["world"]["currentDistrict"], "shoreditch", "currentDistrict unchanged when blocked")
	)

	run_case("ensure_district_cross_district_succeeds_with_exactly_2_blocks_remaining", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0]  # 2 blocks remaining
		var result := Travel.ensure_district("camden")
		assert_true(result["ok"], "exactly enough blocks for travel + action")
	)

	run_case("ensure_district_same_district_blocked_when_time_exhausted", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var result := Travel.ensure_district("shoreditch")
		assert_true(not result["ok"], "no blocks left for the action itself")
	)
