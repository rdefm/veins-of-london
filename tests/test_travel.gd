extends "res://tests/test_base.gd"


func run() -> void:
	run_case("blocks_needed_zero_for_current_district", func():
		GameState.reset()
		assert_eq(Travel.blocks_needed("shoreditch"), 0, "no surcharge for the district you're already in")
	)

	run_case("blocks_needed_zero_for_a_different_district", func():
		GameState.reset()
		assert_eq(Travel.blocks_needed("camden"), 0, "D3: travel is free — no surcharge for a different district either")
	)

	run_case("ensure_district_same_district_spends_no_block", func():
		GameState.reset()
		var result := Travel.ensure_district("shoreditch")
		assert_true(result["ok"], "should succeed")
		assert_true(not result["travelled"], "not travelled — already there")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "ensure_district itself spends no block")
	)

	run_case("ensure_district_cross_district_updates_currentDistrict_and_spends_no_extra_block", func():
		GameState.reset()
		var result := Travel.ensure_district("camden")
		assert_true(result["ok"], "should succeed")
		assert_true(result["travelled"], "travelled — currentDistrict changed")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "no block spent by ensure_district — only the caller's own action block")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "currentDistrict updates as a side effect")
	)

	run_case("ensure_district_cross_district_succeeds_with_only_1_block_remaining", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1]  # 1 block remaining
		var result := Travel.ensure_district("camden")
		assert_true(result["ok"], "no travel surcharge — the action's own 1 block is all that's needed")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "currentDistrict updates")
	)

	run_case("ensure_district_cross_district_blocked_when_time_exhausted", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var result := Travel.ensure_district("camden")
		assert_true(not result["ok"], "no blocks left for the action itself")
		assert_eq(GameState.state["world"]["currentDistrict"], "shoreditch", "currentDistrict unchanged when blocked")
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
		assert_true(Travel.can_afford("camden", 1), "3 blocks available, needs only 1 for the action")
	)

	run_case("can_afford_true_with_only_1_block_left_for_a_different_district", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1]
		assert_true(Travel.can_afford("camden", 1), "no travel surcharge — 1 block remaining is enough")
	)

	run_case("can_afford_false_with_no_blocks_left", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		assert_true(not Travel.can_afford("camden", 1), "0 blocks remaining, action needs 1")
	)

	# ── travel_to() ───────────────────────────────────────────────

	run_case("travel_to_a_different_district_is_free", func():
		GameState.reset()
		var result := Travel.travel_to("camden")
		assert_true(result["ok"], "should succeed")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "currentDistrict updates")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "travel spends no block at all")
	)

	run_case("travel_to_the_current_district_refuses_as_a_no_op", func():
		GameState.reset()
		var result := Travel.travel_to("shoreditch")
		assert_true(not result["ok"], "travelling to where you already are should refuse, not silently succeed")
		assert_eq(GameState.state["world"]["timeBlocksDone"], [], "no block spent")
	)

	run_case("travel_to_succeeds_even_with_no_blocks_remaining", func():
		GameState.reset()
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		var result := Travel.travel_to("camden")
		assert_true(result["ok"], "travel is free — it doesn't need any of today's blocks")
		assert_eq(GameState.state["world"]["currentDistrict"], "camden", "currentDistrict updates")
	)
