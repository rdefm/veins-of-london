extends "res://tests/test_base.gd"


func run() -> void:
	run_case("craft_chance_at_skill_3_with_workshop_bonus", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "townhouse"
		GameState.state["home"]["rooms"] = ["workshop"]
		var chance := Crafting.craft_chance("timePearl", 3)
		assert_almost_eq(chance, 0.40 + 0.26 + 0.08, 0.0001, "min(0.95, 0.40+0.26+0.08)")
	)

	run_case("calc_cost_floors_at_1", func():
		# Not a normally reachable skill (max is 5), but the formula itself
		# must clamp — proves the maxi(1, ...) floor actually engages.
		var cost := Crafting.calc_cost("timePearl", 10)
		assert_eq(cost, 1, "calcCost should never go below 1")
	)

	run_case("calc_cost_at_skill_1_matches_base", func():
		var cost := Crafting.calc_cost("timePearl", 1)
		assert_eq(cost, 5, "at skill 1, (skill-1)*0.8 = 0, so cost = baseCalcCost")
	)

	run_case("attempt_craft_deducts_ingredient_regardless_of_outcome", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["craftingSkill"] = 1
		Crafting.attempt_craft("timePearl")
		# calc_cost at skill 1 = baseCalcCost = 5
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 95, "5 calc deducted regardless of success/fail")
	)

	run_case("attempt_craft_blocked_without_enough_calc_no_deduction", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 2
		var result := Crafting.attempt_craft("timePearl")
		assert_true(not result["ok"], "should refuse with insufficient calc")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 2, "no deduction when blocked")
	)

	run_case("attempt_craft_success_grants_item_and_full_xp", func():
		var seed := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["craftingSkill"] = 5  # high chance, easier to find a success
			Rng.set_seed(candidate)
			var result := Crafting.attempt_craft("timePearl")
			if result.get("success", false):
				seed = candidate
				break
		assert_true(seed != -1, "should find a successful craft roll within 200 tries")
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], 1, "successful craft grants +1 item")
		assert_eq(GameState.state["player"]["craftingXP"], 20, "success grants full xpReward (20 for timePearl)")
	)

	run_case("attempt_craft_failure_grants_partial_xp", func():
		var seed := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["craftingSkill"] = 1  # low chance, easier to find a failure
			Rng.set_seed(candidate)
			var result := Crafting.attempt_craft("timePearl")
			if not result.get("success", true):
				seed = candidate
				break
		assert_true(seed != -1, "should find a failed craft roll within 200 tries")
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], 0, "failed craft grants no item")
		assert_eq(GameState.state["player"]["craftingXP"], 6, "failure grants floor(20/3) = 6 xp")
	)

	run_case("award_crafting_xp_never_pushes_a_notification", func():
		GameState.reset()
		Crafting.award_crafting_xp(1000)  # force a level-up
		assert_true(GameState.state["player"]["craftingSkill"] > 1, "sanity: xp should have levelled the skill")
		assert_eq(GameState.state["notifications"], [], "crafting xp/level-up never notifies, unlike cultivating")
	)
