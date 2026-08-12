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
		var costs := Crafting.calc_cost("timePearl", 10)
		assert_eq(costs["time"], 1, "calcCost should never go below 1")
	)

	run_case("calc_cost_at_skill_1_matches_base", func():
		var costs := Crafting.calc_cost("timePearl", 1)
		assert_eq(costs["time"], 5, "at skill 1, (skill-1)*0.8 = 0, so cost = baseCalcCost")
	)

	run_case("calc_cost_returns_a_dict_keyed_by_each_ingredient", func():
		# A synthetic multi-ingredient recipe, proving calc_cost computes
		# each ingredient's cost independently rather than assuming one key.
		GameData.RECIPES["_testMultiIngredient"] = {
			"name": "Test Multi",
			"symbol": "?",
			"ingredients": { "time": 5, "life": 6 },
			"baseSuccess": 0.40,
			"effectPower": [0, 1, 1, 2, 2, 3],
			"xpReward": 20,
			"eventUsable": false,
			"description": "",
		}
		var costs := Crafting.calc_cost("_testMultiIngredient", 3)
		assert_eq(costs["time"], 3, "time: max(1, round(5 - 2*0.8)) = max(1, round(3.4)) = 3")
		assert_eq(costs["life"], 4, "life: max(1, round(6 - 2*0.8)) = max(1, round(4.4)) = 4")
		GameData.RECIPES.erase("_testMultiIngredient")
	)

	run_case("attempt_craft_deducts_ingredient_regardless_of_outcome", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["craftingSkill"] = 1
		Crafting.attempt_craft("timePearl")
		# calc_cost at skill 1 = baseCalcCost = 5
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 95, "5 calc deducted regardless of success/fail")
	)

	run_case("attempt_craft_multi_ingredient_deducts_all_and_blocks_if_any_insufficient", func():
		GameData.RECIPES["_testMultiIngredient"] = {
			"name": "Test Multi",
			"symbol": "?",
			"ingredients": { "time": 5, "life": 6 },
			"baseSuccess": 0.40,
			"effectPower": [0, 1, 1, 2, 2, 3],
			"xpReward": 20,
			"eventUsable": false,
			"description": "",
		}

		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 2  # short of the 6 needed
		var blocked := Crafting.attempt_craft("_testMultiIngredient")
		assert_true(not blocked["ok"], "should refuse when any one ingredient is short")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 100, "no deduction of any ingredient when blocked")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 2, "no deduction of any ingredient when blocked")

		GameState.state["player"]["orichalchum"]["life"] = 100
		GameState.state["player"]["craftingSkill"] = 1
		Crafting.attempt_craft("_testMultiIngredient")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 95, "time deducted (baseCalcCost 5 at skill 1)")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 94, "life deducted (baseCalcCost 6 at skill 1)")

		GameData.RECIPES.erase("_testMultiIngredient")
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
		assert_eq(GameState.state["modal"]["type"], "craft_result", "attempt_craft should open the craft_result modal")
		assert_eq(GameState.state["modal"]["data"]["success"], true, "modal data reflects the outcome")
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
