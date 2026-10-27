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

	run_case("award_crafting_xp_never_pushes_a_notification", func():
		GameState.reset()
		Crafting.award_crafting_xp(1000)  # force a level-up
		assert_true(GameState.state["player"]["craftingSkill"] > 1, "sanity: xp should have levelled the skill")
		for n in GameState.state["notifications"]:
			assert_true(not str(n["text"]).begins_with("Crafting"), "crafting level-up never notifies, unlike cultivating")
	)

	# ── item tier drives effect_power() ───

	run_case("effect_power_indexes_effectPower_by_item_tier", func():
		GameState.reset()
		GameData.RECIPES["_testRefinable"] = {
			"name": "Test Refinable", "symbol": "?",
			"ingredients": { "fate": 1 },
			"baseSuccess": 1.0,
			"effectPower": [0, 5, 6, 7, 8, 9],
			"xpReward": 10, "eventUsable": false, "description": "",
		}
		assert_eq(Crafting.effect_power("_testRefinable", 3), 7, "tier 3 reads effectPower[3]")
		assert_eq(Crafting.effect_power("_testRefinable", 99), 9, "a tier past the table clamps to the top entry")
		GameData.RECIPES.erase("_testRefinable")
	)

	run_case("filed_items_at_different_tiers_land_in_separate_buckets", func():
		GameState.reset()
		Crafting.file_crafted("timePearl", 1, 1, false, {}, 0)
		Crafting.file_crafted("timePearl", 5, 1, false, {}, 0)
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], { "1": 1, "5": 1 }, "distinct tiers accumulate in separate buckets, not merged")
		assert_eq(Crafting.inventory_qty("timePearl"), 2, "inventory_qty sums across every tier bucket")
	)

	run_case("lab_item_tier_is_the_best_rank_floored_at_1", func():
		GameState.reset()
		GameState.state["player"]["craftingSkill"] = 4
		assert_eq(Lab.item_tier("timePearl"), 1, "no rank yet: tier 1 whatever the skill")
		GameState.state["lab"]["bestRanks"]["timePearl"] = 3
		assert_eq(Lab.item_tier("timePearl"), 3, "reports the best rank")
	)

	run_case("effect_power_table_per_item_tier_1_to_5", func():
		var expected := {
			"timePearl": [1, 2, 3, 4, 5],
			"enhancementPowder": [1, 1, 2, 2, 3],
			"rewind": [1, 2, 3, 4, 5],
			"healingSalve": [2, 3, 4, 5, 6],
			"blast": [4, 6, 8, 10, 12],
			"shield": [3, 4, 5, 6, 8],
			"blackHole": [6, 8, 10, 13, 16],
			"prophetsBreath": [1, 1, 1, 2, 2],
			"beALady": [1, 1, 1, 2, 2],
			"panic": [2, 2, 3, 4, 5],
			"panger": [2, 2, 3, 4, 5],
			"pandemonium": [2, 2, 3, 4, 5],
			"pansRapture": [2, 2, 3, 4, 5],
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

	run_case("file_crafted_fires_every_side_effect_once_per_item", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		var flags: Dictionary = GameState.state["flags"]
		flags["colA2LedgerStarted"] = true
		flags["colA2DefendBriefed"] = true
		Objectives.refresh()
		assert_true(GameState.state["objectives"]["col_a2_nadia_supplies"]["active"], "supplies mission active")
		var contract := { "request": { "type": "blast", "qty": 3 }, "playerAssisted": false }
		GameState.state["sales"]["activeContracts"].append(contract)
		var relation_before := int(GameState.state["factions"]["collective"]["relation"])
		var xp_before := int(player["craftingXP"])

		Crafting.file_crafted("blast", 3, 2, false, { "physics": 4 }, 30)
		assert_eq(player["inventory"]["blast"], { "3": 2 }, "two items at tier 3")
		assert_eq(player["craftedCounts"]["blast"], 2, "craftedCounts per item")
		assert_eq(GameState.state["shares"]["days"][-1]["craft"][Shares.PLAYER], { "physics": 8 }, "each item's calc credited once")
		assert_eq(int(player["craftingXP"]) - xp_before, 30, "XP awarded once")
		assert_true(contract["playerAssisted"], "contract marked player-supplied")

		Crafting.file_crafted("shield", 1, 1, false, { "physics": 4 }, 0)
		Crafting.file_crafted("panic", 1, 1, true, { "emotion": 4 }, 0)
		assert_eq(player["inventory"]["panic_multi"], { "1": 1 }, "multi files under the multi key")
		assert_true(GameState.state["objectives"]["col_a2_nadia_supplies"]["complete"], "objectives refreshed")
		assert_eq(GameState.state["collective"]["a2MissionsAwarded"], ["col_a2_nadia_supplies"], "Collective mission awarded")
		assert_eq(int(GameState.state["factions"]["collective"]["relation"]) - relation_before, Collective.A2_MISSION_RELATION, "relation once")
		Crafting.file_crafted("blast", 1, 1, false, { "physics": 4 }, 0)
		assert_eq(int(GameState.state["factions"]["collective"]["relation"]) - relation_before, Collective.A2_MISSION_RELATION, "never twice")
		assert_eq(player["craftedCounts"]["blast"], 3, "counts keep rising")
	)
