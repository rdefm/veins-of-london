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

	run_case("calc_cost_scales_with_skill_constant_not_tier", func():
		var before := Crafting.calc_cost("timePearl", 3)
		var saved: float = GameData.CRAFT_COST_PER_SKILL
		GameData.CRAFT_COST_PER_SKILL = 1.5
		var after := Crafting.calc_cost("timePearl", 3)
		GameData.CRAFT_COST_PER_SKILL = saved
		assert_eq(before["time"], 3, "5 - 2*0.8 = 3.4 -> 3")
		assert_eq(after["time"], 2, "5 - 2*1.5 = 2")
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

	run_case("attempt_craft_costs_no_time_and_works_when_time_exhausted", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		assert_true(Crafting.attempt_craft("timePearl")["ok"], "spent day doesn't block crafting")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 3, "crafting costs no time block")
		assert_eq(GameState.state["world"]["day"], 1)
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
		assert_eq(result["reason"], Crafting.craft_block_reason("timePearl"), "attempt_craft refuses with the same reason the Craft button shows")
	)

	run_case("craft_block_reason_is_empty_when_affordable", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		assert_eq(Crafting.craft_block_reason("timePearl"), "")
		GameState.state["player"]["orichalchum"]["time"] = 0
		assert_eq(Crafting.craft_block_reason("timePearl"), "Not enough calc.")
	)

	# ── dial-device ticket 02: seated-Movement attunement bonus ─────────

	run_case("attempt_craft_gets_a_matching_seated_movements_attunement_bonus", func():
		var flipped := false
		for seed in range(500):
			GameState.reset()
			GameState.state["player"]["craftingSkill"] = 1
			GameState.state["player"]["orichalchum"]["time"] = 1000
			Rng.set_seed(seed)
			var without := Crafting.attempt_craft("timePearl")

			GameState.reset()
			GameState.state["player"]["craftingSkill"] = 1
			GameState.state["player"]["orichalchum"]["time"] = 1000
			GameState.state["player"]["dial"] = { "level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 0, "rechargeRate": 0, "capacityMax": 0, "movement": { "archetype": "impact", "oreType": "time", "tier": 5 }, "loadedComplications": [], "haftId": "collective_brolly" }
			Rng.set_seed(seed)
			var with_attunement := Crafting.attempt_craft("timePearl")

			if not without["success"] and with_attunement["success"]:
				flipped = true
				break
		assert_true(flipped, "a matching-ore-type attunement bonus should flip at least one borderline roll from fail to success within 500 seeds")
	)

	run_case("attempt_craft_attunement_matches_a_multi_ingredient_recipes_second_ore_type_too", func():
		# healingBurst spends both time and life (data/recipes.json) -- a
		# Movement attuned to "life" (not the first ingredient key) must
		# still get matched, proving recipe_ore_types() checks every
		# ingredient, not just one.
		var flipped := false
		for seed in range(500):
			GameState.reset()
			GameState.state["player"]["craftingSkill"] = 1
			GameState.state["player"]["orichalchum"]["time"] = 1000
			GameState.state["player"]["orichalchum"]["life"] = 1000
			Rng.set_seed(seed)
			var without := Crafting.attempt_craft("healingBurst")

			GameState.reset()
			GameState.state["player"]["craftingSkill"] = 1
			GameState.state["player"]["orichalchum"]["time"] = 1000
			GameState.state["player"]["orichalchum"]["life"] = 1000
			GameState.state["player"]["dial"] = { "level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 0, "rechargeRate": 0, "capacityMax": 0, "movement": { "archetype": "impact", "oreType": "life", "tier": 5 }, "loadedComplications": [], "haftId": "collective_brolly" }
			Rng.set_seed(seed)
			var with_attunement := Crafting.attempt_craft("healingBurst")

			if not without["success"] and with_attunement["success"]:
				flipped = true
				break
		assert_true(flipped, "attunement to a recipe's second ingredient ore type should still flip at least one borderline roll within 500 seeds")
	)

	run_case("attempt_craft_mismatched_attunement_never_changes_the_outcome", func():
		for seed in range(100):
			GameState.reset()
			GameState.state["player"]["craftingSkill"] = 1
			GameState.state["player"]["orichalchum"]["time"] = 1000
			Rng.set_seed(seed)
			var without := Crafting.attempt_craft("timePearl")

			GameState.reset()
			GameState.state["player"]["craftingSkill"] = 1
			GameState.state["player"]["orichalchum"]["time"] = 1000
			GameState.state["player"]["dial"] = { "level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 0, "rechargeRate": 0, "capacityMax": 0, "movement": { "archetype": "impact", "oreType": "physics", "tier": 5 }, "loadedComplications": [], "haftId": "collective_brolly" }
			Rng.set_seed(seed)
			var mismatched := Crafting.attempt_craft("timePearl")

			assert_eq(mismatched["success"], without["success"], "seed %d: a mismatched-ore-type Movement must not change the outcome" % seed)
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

	run_case("attempt_craft_success_increments_craftedCounts_failure_does_not", func():
		var success_seed := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["craftingSkill"] = 5
			Rng.set_seed(candidate)
			if Crafting.attempt_craft("timePearl").get("success", false):
				success_seed = candidate
				break
		assert_true(success_seed != -1, "should find a successful craft roll within 200 tries")
		assert_eq(GameState.state["player"]["craftedCounts"]["timePearl"], 1, "a successful craft increments craftedCounts")

		Rng.set_seed(success_seed)
		Crafting.attempt_craft("timePearl")
		assert_eq(GameState.state["player"]["craftedCounts"]["timePearl"], 2, "repeated successes accumulate")

		var failure_seed := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["craftingSkill"] = 1
			Rng.set_seed(candidate)
			if not Crafting.attempt_craft("timePearl").get("success", true):
				failure_seed = candidate
				break
		assert_true(failure_seed != -1, "should find a failed craft roll within 200 tries")
		assert_eq(GameState.state["player"]["craftedCounts"].get("timePearl", 0), 0, "a failed craft must not increment craftedCounts")
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

	# ── item tier drives effect_power() ───

	run_case("effect_power_indexes_effectPower_by_item_tier", func():
		GameState.reset()
		GameData.RECIPES["_testRefinable"] = {
			"name": "Test Refinable", "symbol": "?",
			"ingredients": { "fate": 1 },
			"discovery": { "types": ["fate", "physics"], "approach": "heat" },
			"baseSuccess": 1.0,
			"effectPower": [0, 5, 6, 7, 8, 9],
			"xpReward": 10, "eventUsable": false, "description": "",
		}
		assert_eq(Crafting.effect_power("_testRefinable", 3), 7, "tier 3 reads effectPower[3]")
		assert_eq(Crafting.effect_power("_testRefinable", 99), 9, "a tier past the table clamps to the top entry")
		GameData.RECIPES.erase("_testRefinable")
	)

	# ── bugfixes ticket 57: batch craft +/- qty and attempt_craft_batch ───

	run_case("max_craftable_qty_is_held_calc_over_cost_rounded_down", func():
		GameState.reset()
		GameState.state["player"]["craftingSkill"] = 1
		var cost: int = Crafting.calc_cost("timePearl", 1)["time"]
		GameState.state["player"]["orichalchum"]["time"] = cost * 3 + cost - 1
		assert_eq(Crafting.max_craftable_qty("timePearl"), 3, "a partial batch's worth of calc doesn't count")
	)

	run_case("max_craftable_qty_is_zero_when_one_craft_is_unaffordable", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 0
		assert_eq(Crafting.max_craftable_qty("timePearl"), 0)
	)

	run_case("max_craftable_qty_ignores_stashed_calc", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 0
		GameState.state["player"]["stash"]["orichalchum"]["time"] = 100
		assert_eq(Crafting.max_craftable_qty("timePearl"), 0, "stashed calc isn't on the bench")
	)

	run_case("max_craftable_qty_is_set_by_the_scarcest_ingredient", func():
		GameState.reset()
		GameState.state["player"]["craftingSkill"] = 1
		GameData.RECIPES["_testTwoOre"] = {
			"name": "Test", "symbol": "", "ingredients": { "fate": 2, "life": 3 },
			"baseSuccess": 1.0, "effectPower": [0, 1, 1, 1, 1, 1],
			"xpReward": 0, "eventUsable": false, "description": "",
		}
		GameState.state["player"]["orichalchum"]["fate"] = 20
		GameState.state["player"]["orichalchum"]["life"] = 7
		assert_eq(Crafting.max_craftable_qty("_testTwoOre"), 2, "life's 7/3 limits below fate's 20/2")
		GameState.state["player"]["orichalchum"]["life"] = 0
		assert_eq(Crafting.max_craftable_qty("_testTwoOre"), 0, "one missing ingredient zeroes the batch")
		GameData.RECIPES.erase("_testTwoOre")
	)

	run_case("get_craft_qty_defaults_to_one", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		assert_eq(Crafting.get_craft_qty("timePearl"), 1, "an unselected recipe defaults to a batch of 1")
	)

	run_case("set_craft_qty_clamps_between_one_and_max_craftable", func():
		GameState.reset()
		GameState.state["player"]["craftingSkill"] = 1
		var cost: int = Crafting.calc_cost("timePearl", 1)["time"]
		GameState.state["player"]["orichalchum"]["time"] = cost * 4
		Crafting.set_craft_qty("timePearl", 3)
		assert_eq(Crafting.get_craft_qty("timePearl"), 3)
		Crafting.set_craft_qty("timePearl", -5)
		assert_eq(Crafting.get_craft_qty("timePearl"), 1, "floor of 1")
		Crafting.set_craft_qty("timePearl", 1000)
		assert_eq(Crafting.get_craft_qty("timePearl"), 4, "capped at what the calc covers")
	)

	run_case("get_craft_qty_reclamps_after_calc_is_spent", func():
		GameState.reset()
		GameState.state["player"]["craftingSkill"] = 1
		var cost: int = Crafting.calc_cost("timePearl", 1)["time"]
		GameState.state["player"]["orichalchum"]["time"] = cost * 4
		Crafting.set_craft_qty("timePearl", 4)
		GameState.state["player"]["orichalchum"]["time"] = cost * 2
		assert_eq(Crafting.get_craft_qty("timePearl"), 2, "a stale pick never exceeds today's max")
		GameState.state["player"]["orichalchum"]["time"] = 0
		assert_eq(Crafting.get_craft_qty("timePearl"), 1, "nothing craftable still reads 1, never 0")
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

	run_case("attempt_craft_grants_the_cell_tier_potency_not_the_crafting_skill_potency", func():
		GameData.RECIPES["_testRefinable"] = {
			"name": "Test Refinable", "symbol": "?",
			"ingredients": { "fate": 1 },
			"discovery": { "types": ["fate", "physics"], "approach": "heat" },
			"baseSuccess": 0.90,
			"effectPower": [0, 5, 6, 7, 8, 9],
			"xpReward": 10, "eventUsable": false, "description": "",
		}
		var seed := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["fate"] = 100
			GameState.state["player"]["craftingSkill"] = 5
			GameState.state["player"]["bench"]["cells"]["fate+physics|heat"] = { "state": "found", "misses": 0, "tier": 2, "progress": 0 }
			Rng.set_seed(candidate)
			var result := Crafting.attempt_craft("_testRefinable")
			if result.get("success", false):
				seed = candidate
				assert_eq(result["power"], 6, "tier 2 -> effectPower[2], regardless of skill 5")
				assert_eq(GameState.state["player"]["inventory"]["_testRefinable"], { "2": 1 }, "the unit files under the item tier")
				break
		assert_true(seed != -1, "should find a successful craft roll within 200 tries")
		GameData.RECIPES.erase("_testRefinable")
	)

	# ── ticket 64: tier-bucketed inventory ───────────────────────────────

	run_case("crafting_at_different_item_tiers_files_into_different_tier_buckets", func():
		var seed_lo := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["bench"]["cells"]["time|compression"] = { "state": "found", "misses": 0, "tier": 1, "progress": 0 }
			Rng.set_seed(candidate)
			if Crafting.attempt_craft("timePearl").get("success", false):
				seed_lo = candidate
				break
		assert_true(seed_lo != -1, "should find a successful tier-1 craft within 200 tries")
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], { "1": 1 }, "a tier-1 craft files into the tier-1 bucket")

		var seed_hi := -1
		for candidate in range(200):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["bench"]["cells"]["time|compression"] = { "state": "found", "misses": 0, "tier": 5, "progress": 0 }
			Rng.set_seed(candidate)
			if Crafting.attempt_craft("timePearl").get("success", false):
				seed_hi = candidate
				break
		assert_true(seed_hi != -1, "should find a successful tier-5 craft within 200 tries")
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], { "5": 1 }, "a tier-5 craft files into a separate tier-5 bucket, distinct from tier 1")

		# Craft one of each in the same game -- proves they stack in separate
		# buckets rather than one overwriting or merging with the other.
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["bench"]["cells"]["time|compression"] = { "state": "found", "misses": 0, "tier": 1, "progress": 0 }
		Rng.set_seed(seed_lo)
		Crafting.attempt_craft("timePearl")
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["bench"]["cells"]["time|compression"] = { "state": "found", "misses": 0, "tier": 5, "progress": 0 }
		Rng.set_seed(seed_hi)
		Crafting.attempt_craft("timePearl")
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], { "1": 1, "5": 1 }, "distinct tiers accumulate in separate buckets, not merged")
		assert_eq(Crafting.inventory_qty("timePearl"), 2, "inventory_qty sums across every tier bucket")
	)

	run_case("quality_tier_reports_the_cell_tier_not_the_skill", func():
		GameState.reset()
		GameData.RECIPES["_testRefinable"] = {
			"name": "Test Refinable", "symbol": "?",
			"ingredients": { "fate": 1 },
			"discovery": { "types": ["fate", "physics"], "approach": "heat" },
			"baseSuccess": 1.0,
			"effectPower": [0, 5, 6, 7, 8, 9],
			"xpReward": 10, "eventUsable": false, "description": "",
		}
		GameState.state["player"]["craftingSkill"] = 4
		assert_eq(Crafting.quality_tier("_testRefinable"), 1, "a fresh cell is tier 1 whatever the skill")
		GameState.state["player"]["bench"]["cells"]["fate+physics|heat"] = { "state": "found", "misses": 0, "tier": 3, "progress": 0 }
		assert_eq(Crafting.quality_tier("_testRefinable"), 3, "reports the cell tier")
		GameData.RECIPES.erase("_testRefinable")
	)

	run_case("effect_power_table_per_item_tier_1_to_5", func():
		var expected := {
			"timePearl": [1, 2, 3, 4, 5],
			"enhancementPowder": [1, 1, 2, 2, 3],
			"rewind": [2, 2, 2, 2, 2],
			"healingSalve": [2, 3, 4, 5, 6],
			"blast": [4, 6, 8, 10, 12],
			"shield": [3, 4, 5, 6, 8],
			"blackHole": [6, 8, 10, 13, 16],
			"prophetsBreath": [1, 1, 1, 2, 2],
			"beALady": [1, 1, 1, 2, 2],
			"pansPrank": [2, 2, 3, 4, 5],
			"healingBurst": [6, 8, 10, 12, 15],
			"failsafe": [1, 1, 2, 2, 2],
			"rejuvenation": [0, 0, 0, 0, 0],
			"wormhole": [1, 1, 1, 1, 1],
		}
		for key in expected:
			for tier in range(1, 6):
				assert_eq(Crafting.effect_power(key, tier), expected[key][tier - 1], "%s tier %d" % [key, tier])
		assert_eq(expected.size(), GameData.RECIPES.size(), "every recipe has a tier table asserted")
	)
