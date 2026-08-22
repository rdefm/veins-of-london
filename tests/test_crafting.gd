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
		assert_eq(Crafting.inventory_qty("timePearl"), 1, "successful craft grants +1 item")
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
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "failed craft grants no item")
		assert_eq(GameState.state["player"]["craftingXP"], 6, "failure grants floor(20/3) = 6 xp")
	)

	run_case("award_crafting_xp_never_pushes_a_notification", func():
		GameState.reset()
		Crafting.award_crafting_xp(1000)  # force a level-up
		assert_true(GameState.state["player"]["craftingSkill"] > 1, "sanity: xp should have levelled the skill")
		assert_eq(GameState.state["notifications"], [], "crafting xp/level-up never notifies, unlike cultivating")
	)

	# ── calc-discovery ticket 10: refine tier wired into effect_power() ───

	run_case("effect_power_at_refine_tier_zero_matches_the_plain_skill_indexed_value", func():
		GameState.reset()
		GameData.RECIPES["_testRefinable"] = {
			"name": "Test Refinable", "symbol": "?",
			"ingredients": { "fate": 1 },
			"discovery": { "types": ["fate", "physics"], "approach": "heat" },
			"baseSuccess": 1.0,
			"effectPower": [0, 5, 6, 7, 8, 9],
			"refineStep": { "field": "effectPower", "add": 3 },
			"xpReward": 10, "eventUsable": false, "description": "",
		}
		assert_eq(Crafting.effect_power("_testRefinable", 3), 7, "tier 0 (unrefined, absent cell) reads the plain skill-indexed value (effectPower[3] = 7) -- regression check against the pre-Lab behaviour")
		GameData.RECIPES.erase("_testRefinable")
	)

	run_case("effect_power_at_refine_tier_gt_zero_adds_the_refine_bonus_on_top_of_the_skill_indexed_value", func():
		GameState.reset()
		GameData.RECIPES["_testRefinable"] = {
			"name": "Test Refinable", "symbol": "?",
			"ingredients": { "fate": 1 },
			"discovery": { "types": ["fate", "physics"], "approach": "heat" },
			"baseSuccess": 1.0,
			"effectPower": [0, 5, 6, 7, 8, 9],
			"refineStep": { "field": "effectPower", "add": 3 },
			"xpReward": 10, "eventUsable": false, "description": "",
		}
		GameState.state["player"]["bench"]["cells"]["fate+physics|heat"] = { "state": "found", "misses": 0, "refine": 2 }
		assert_eq(Crafting.effect_power("_testRefinable", 3), 7 + 3 * 2, "tier 2 stacks refineStep.add * tier on top of the skill-indexed base (effectPower[3] = 7), not a replacement of it")
		GameData.RECIPES.erase("_testRefinable")
	)

	# ── bugfixes ticket 57: batch craft +/- qty and attempt_craft_batch ───

	run_case("get_craft_qty_defaults_to_one_and_adjust_craft_qty_increments", func():
		GameState.reset()
		assert_eq(Crafting.get_craft_qty("timePearl"), 1, "an unselected recipe defaults to a batch of 1")
		Crafting.adjust_craft_qty("timePearl", 1)
		Crafting.adjust_craft_qty("timePearl", 1)
		assert_eq(Crafting.get_craft_qty("timePearl"), 3, "each + tap increments by 1")
	)

	run_case("adjust_craft_qty_clamps_between_one_and_max_batch_qty", func():
		GameState.reset()
		Crafting.adjust_craft_qty("timePearl", -5)
		assert_eq(Crafting.get_craft_qty("timePearl"), 1, "a batch of zero (or fewer) makes no sense -- floor of 1")
		Crafting.adjust_craft_qty("timePearl", 1000)
		assert_eq(Crafting.get_craft_qty("timePearl"), Crafting.MAX_BATCH_QTY, "quantity is capped, not unbounded")
	)

	run_case("attempt_craft_batch_rolls_each_attempt_independently_not_a_pooled_chance", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["craftingSkill"] = 1
		Rng.set_seed(1)
		var result := Crafting.attempt_craft_batch("timePearl", 5)
		assert_eq(result["requested"], 5, "requested reflects what was asked")
		assert_eq(result["completed"], 5, "100 calc affords 5 attempts at 5 calc each")
		assert_eq(result["attempts"].size(), 5, "one reported entry per attempt")

		var successes := 0
		for attempt in result["attempts"]:
			if attempt["success"]:
				successes += 1
		assert_eq(result["successes"], successes, "reported success count matches the per-attempt breakdown")
		assert_eq(Crafting.inventory_qty("timePearl"), successes, "inventory grew by exactly the successful attempts -- proves each was rolled on its own, not one pooled chance for the whole batch")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 100 - 5 * 5, "ingredient deducted once per attempt, 5 attempts x 5 calc")
	)

	run_case("attempt_craft_batch_stops_early_when_ingredients_run_out_partway_through", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 17  # enough for 3 crafts at 5 calc each, short of a 4th
		GameState.state["player"]["craftingSkill"] = 1
		Rng.set_seed(2)
		var result := Crafting.attempt_craft_batch("timePearl", 5)
		assert_eq(result["ok"], true, "a partial batch is still a successful call, not an error")
		assert_eq(result["requested"], 5, "still reports what was originally requested")
		assert_eq(result["completed"], 3, "stops after the 3rd attempt, unable to afford a 4th")
		assert_eq(result["attempts"].size(), 3, "only the attempts that actually ran are reported")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 2, "3 x 5 calc deducted, 2 left over -- not enough for another attempt")
	)

	run_case("attempt_craft_batch_opens_a_batch_result_modal_with_the_full_breakdown", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["craftingSkill"] = 1
		Rng.set_seed(3)
		Crafting.attempt_craft_batch("timePearl", 2)
		assert_eq(GameState.state["modal"]["type"], "craft_batch_result", "batch overwrites the last attempt's single-result modal with its own breakdown")
		assert_eq(GameState.state["modal"]["data"]["attempts"].size(), 2, "modal data carries every attempt, not just an aggregate")
	)

	run_case("attempt_craft_at_a_refined_tier_grants_the_refined_potency_not_the_base_value", func():
		GameData.RECIPES["_testRefinable"] = {
			"name": "Test Refinable", "symbol": "?",
			"ingredients": { "fate": 1 },
			"discovery": { "types": ["fate", "physics"], "approach": "heat" },
			"baseSuccess": 0.90,
			"effectPower": [0, 5, 6, 7, 8, 9],
			"refineStep": { "field": "effectPower", "add": 3 },
			"xpReward": 10, "eventUsable": false, "description": "",
		}
		var seed := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["fate"] = 100
			GameState.state["player"]["craftingSkill"] = 3
			GameState.state["player"]["bench"]["cells"]["fate+physics|heat"] = { "state": "found", "misses": 0, "refine": 2 }
			Rng.set_seed(candidate)
			var result := Crafting.attempt_craft("_testRefinable")
			if result.get("success", false):
				seed = candidate
				assert_eq(result["power"], 13, "7 (skill 3 base, effectPower[3]) + 3*2 (refine tier 2 bonus) = 13")
				break
		assert_true(seed != -1, "should find a successful craft roll within 200 tries")
		GameData.RECIPES.erase("_testRefinable")
	)

	# ── ticket 64: tier-bucketed inventory ───────────────────────────────

	run_case("crafting_at_different_skill_levels_files_into_different_tier_buckets", func():
		var seed_lo := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["craftingSkill"] = 1
			Rng.set_seed(candidate)
			if Crafting.attempt_craft("timePearl").get("success", false):
				seed_lo = candidate
				break
		assert_true(seed_lo != -1, "should find a successful skill-1 craft within 200 tries")
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], { "1": 1 }, "a skill-1 craft files into the tier-1 bucket")

		var seed_hi := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["craftingSkill"] = 5
			Rng.set_seed(candidate)
			if Crafting.attempt_craft("timePearl").get("success", false):
				seed_hi = candidate
				break
		assert_true(seed_hi != -1, "should find a successful skill-5 craft within 200 tries")
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], { "5": 1 }, "a skill-5 craft files into a separate tier-5 bucket, distinct from tier 1")

		# Craft one of each in the same game -- proves they stack in separate
		# buckets rather than one overwriting or merging with the other.
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["craftingSkill"] = 1
		Rng.set_seed(seed_lo)
		Crafting.attempt_craft("timePearl")
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["craftingSkill"] = 5
		Rng.set_seed(seed_hi)
		Crafting.attempt_craft("timePearl")
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], { "1": 1, "5": 1 }, "distinct tiers accumulate in separate buckets, not merged")
		assert_eq(Crafting.inventory_qty("timePearl"), 2, "inventory_qty sums across every tier bucket")
	)

	run_case("quality_tier_at_a_refined_tier_reports_the_refine_tier_not_the_skill", func():
		GameState.reset()
		GameData.RECIPES["_testRefinable"] = {
			"name": "Test Refinable", "symbol": "?",
			"ingredients": { "fate": 1 },
			"discovery": { "types": ["fate", "physics"], "approach": "heat" },
			"baseSuccess": 1.0,
			"effectPower": [0, 5, 6, 7, 8, 9],
			"refineStep": { "field": "effectPower", "add": 3 },
			"xpReward": 10, "eventUsable": false, "description": "",
		}
		assert_eq(Crafting.quality_tier("_testRefinable", 3), 3, "tier 0 (unrefined) reports the skill index, same as effect_power()'s own fallback")
		GameState.state["player"]["bench"]["cells"]["fate+physics|heat"] = { "state": "found", "misses": 0, "refine": 2 }
		assert_eq(Crafting.quality_tier("_testRefinable", 3), 2, "refined past tier 0 reports the Bench refine tier instead of the skill index")
		GameData.RECIPES.erase("_testRefinable")
	)
