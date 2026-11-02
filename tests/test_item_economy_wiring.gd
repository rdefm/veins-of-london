extends "res://tests/test_base.gd"

# The 26 roster-only items (docs/brainstorm.md, Stutter, Invisibility) in the
# economy: market entries, faction crafts/consumes, barometer hooks, a seller
# and master-source entry per recipe, and a Lab procedure crafted rank 1 to 5.

const JAMES_ORES := ["time", "life"]


func _roster() -> Array:
	return GameData.RECIPES.keys().filter(func(k): return GameData.RECIPES[k].get("bagWhenHeld", false))


func _crafter_of(recipe_key: String) -> Array:
	var ids := []
	for faction_id in GameData.FACTIONS:
		if GameData.FACTIONS[faction_id].get("crafts", []).has(recipe_key):
			ids.append(faction_id)
	return ids


func _fresh() -> void:
	GameState.reset()
	GameData.LAB["bonus"]["chance"] = 0.0
	GameData.RECIPE_KNOWLEDGE["insight"]["base"] = 0.0
	GameData.RECIPE_KNOWLEDGE["insight"]["perSkill"] = 0.0
	var player: Dictionary = GameState.state["player"]
	player["cash"] = 10000000
	for ore_type in GameData.ORE_TYPES:
		player["orichalchum"][ore_type] = 500


# Sets every known step on its shown target (begin_run already tapped the jars).
func _perform_known(recipe_key: String) -> void:
	var g := Lab.gauge("distilling")
	for step in Lab.known_procedure(recipe_key):
		var target := float(step["target"])
		match step["apparatus"]:
			"grinding":
				Lab.perform_grind([target, target, target])
			"distilling":
				var taps := []
				for i in int(g["drips"]):
					taps.append(i * float(g["beatMsec"]) + target / 100.0 * float(g["fallMsec"]))
				Lab.perform_distil(taps)
			_:
				Lab.perform_step(step["apparatus"], target)


func run() -> void:
	var saved_bonus: float = GameData.LAB["bonus"]["chance"]
	var saved_insight: Dictionary = GameData.RECIPE_KNOWLEDGE["insight"].duplicate()
	var saved_success: float = GameData.RECIPES["bloom"]["baseSuccess"]

	run_case("every_roster_item_trades_on_the_market", func():
		assert_eq(_roster().size(), 26, "26 roster items")
		for key in _roster():
			var entry: Dictionary = GameData.MARKET["goods"]["consumable"].get(key, {})
			assert_true(int(entry.get("normalStock", 0)) > 0, "%s stock" % key)
			assert_true(int(entry.get("civilianDemand", 0)) > 0, "%s demand" % key)
	)

	run_case("every_roster_item_but_keystone_has_a_faction_crafter_with_a_target", func():
		for key in _roster():
			if key == "keystone":
				continue
			var crafters := _crafter_of(key)
			assert_true(not crafters.is_empty(), "%s has a crafting faction" % key)
			for faction_id in crafters:
				var split: Dictionary = GameData.FACTIONS[faction_id]["craftTargets"].get(key, {})
				assert_true(int(split.get("sellQuota", 0)) > 0, "%s/%s sellQuota" % [faction_id, key])
		assert_true(_crafter_of("stutter").has("firm") and _crafter_of("invisibility").has("firm"), "Firm crafts Stutter and Invisibility")
		for faction_id in GameData.FACTIONS:
			for key in GameData.FACTIONS[faction_id].get("consumes", {}):
				assert_true(GameData.RECIPES.has(key), "%s consumes a real recipe %s" % [faction_id, key])
	)

	run_case("faction_sim_crafts_a_new_item", func():
		GameState.reset()
		var faction: Dictionary = GameData.FACTIONS["collective"]
		var skill: int = faction["craftSkill"]
		var costs: Dictionary = Crafting.calc_cost("bloom", skill)
		for ore_type in costs:
			GameState.state["factions"]["collective"]["holdings"]["ore"][ore_type] = int(costs[ore_type]) * 1000
		GameData.RECIPES["bloom"]["baseSuccess"] = 1.0
		FactionSim.craft()
		assert_true(FactionSim.item_held("collective", "bloom") > 0, "Collective filed Bloom")
	)

	run_case("barometer_hooks_name_roster_items", func():
		var states: Dictionary = GameData.BAROMETER_STATES
		assert_true(states["economic"]["crisis"]["effects"]["itemDemand"].has("stiffUpperLip"), "crisis raises Stiff Upper Lip")
		var boom: Dictionary = states["economic"]["boom"]["effects"]["itemDemand"]
		assert_true(boom.has("nostalgia") and boom.has("introduction"), "boom raises Nostalgia and Introduction")
	)

	run_case("every_roster_recipe_has_a_seller_and_master_entry", func():
		for key in _roster():
			var ores: Array = GameData.RECIPES[key]["ingredients"].keys()
			var expected := "james" if ores.all(func(o): return JAMES_ORES.has(o)) else "wren"
			assert_eq(RecipeKnowledge.seller_of(key), expected, "%s seller" % key)
			assert_true(GameData.RECIPE_KNOWLEDGE["masterSources"].has(key), "%s master entry" % key)
	)

	run_case("every_roster_recipe_buys_base_hint1_hint2_in_order", func():
		_fresh()
		GameState.state["flags"]["jamesRecipesUnlocked"] = true
		GameState.state["flags"]["wrenRecipesUnlocked"] = true
		GameState.state["contacts"]["james"]["relation"] = 100
		GameState.state["factions"]["guild"]["relation"] = 100
		GameState.state["factionStances"]["player"]["guild"]["stance"] = FactionAI.PARTNER
		for key in _roster():
			for rung in ["base", "hint1", "hint2"]:
				var bought := RecipeKnowledge.buy(key, rung)
				assert_true(bought["ok"], "%s %s: %s" % [key, rung, bought.get("reason", "")])
			assert_eq(RecipeKnowledge.rank_ceiling(key), 4, "%s ceiling 4 before the master rung" % key)
	)

	run_case("every_roster_item_crafts_at_rank_one_and_reaches_rank_five", func():
		for key in _roster():
			_fresh()
			Lab.grant_recipe(key)
			assert_true(Lab.begin_run(key)["ok"], "%s begins" % key)
			var low := Lab.finish_run()
			assert_eq(low["rank"], 1, "%s rank 1 with no steps" % key)
			assert_eq(Crafting.inventory_qty(key), 1, "%s filed" % key)
			Lab.grant_steps(key, Lab.rung_steps(key, "hint1"), "exact")
			Lab.grant_steps(key, Lab.rung_steps(key, "hint2"), "exact")
			Lab.grant_steps(key, Lab.rung_steps(key, "master"), "exact")
			assert_true(Lab.begin_run(key)["ok"], "%s begins again" % key)
			_perform_known(key)
			var top := Lab.finish_run()
			assert_eq(top["rank"], 5, "%s rank 5 (score %d)" % [key, top.get("score", -1)])
	)

	GameData.LAB["bonus"]["chance"] = saved_bonus
	GameData.RECIPE_KNOWLEDGE["insight"] = saved_insight
	GameData.RECIPES["bloom"]["baseSuccess"] = saved_success
