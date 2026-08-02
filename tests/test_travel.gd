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

	# ── can_afford() ──────────────────────────────────────────────

	run_case("can_afford_true_with_a_full_day_for_a_different_district", func():
		GameState.reset()
		assert_true(Travel.can_afford("camden", 1), "3 blocks available, needs 1 travel + 1 action")
	)

	run_case("can_afford_false_with_only_1_block_left_for_a_different_district", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1]
		assert_true(not Travel.can_afford("camden", 1), "1 block remaining, needs 2 (travel + action)")
	)

	run_case("can_afford_zero_action_cost_only_needs_the_travel_block", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1]
		assert_true(Travel.can_afford("camden", 0), "1 block remaining is enough for travel alone")
	)

	# ── travel_to() ───────────────────────────────────────────────

	run_case("travel_to_a_different_district_spends_exactly_one_block", func():
		GameState.reset()
		var result := Travel.travel_to("camden")
		assert_true(result["ok"], "should succeed with blocks available")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "currentDistrict updates")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1, "travel alone costs exactly 1 block")
	)

	run_case("travel_to_the_current_district_refuses_as_a_no_op", func():
		GameState.reset()
		var result := Travel.travel_to("shoreditch")
		assert_true(not result["ok"], "travelling to where you already are should refuse, not silently succeed")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "no block spent")
	)

	run_case("travel_to_blocked_when_no_blocks_remain", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var result := Travel.travel_to("camden")
		assert_true(not result["ok"], "should refuse with 0 blocks remaining")
		assert_eq(GameState.state["world"]["currentDistrict"], "shoreditch", "currentDistrict unchanged when blocked")
	)
