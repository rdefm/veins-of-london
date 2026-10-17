extends "res://tests/test_base.gd"

# systems/recipe_knowledge.gd (.scratch/recipe-acquisition/spec.md § New
# RecipeKnowledge system module, § Further Notes): rung states, rank
# ceilings, grant_rung, the grant_recipe_rung op and the collision fallback.

const JAMES_RECIPES := ["timePearl", "enhancementPowder", "rewind", "healingSalve", "prophetsBreath", "healingBurst", "failsafe", "rejuvenation"]


func _fresh() -> void:
	GameState.reset()


func _know_all(recipe_keys: Array) -> void:
	for recipe_key in recipe_keys:
		Lab.grant_recipe(recipe_key)


func _collision() -> Dictionary:
	return GameData.RECIPE_KNOWLEDGE["collision"]


func run() -> void:
	run_case("ceiling_rises_one_rank_per_rung", func():
		_fresh()
		assert_eq(RecipeKnowledge.rank_ceiling("timePearl"), 0, "unknown recipe")
		var expected := { "base": 2, "hint1": 3, "hint2": 4, "master": 5 }
		for rung in RecipeKnowledge.rungs():
			RecipeKnowledge.grant_rung("timePearl", rung, "vague")
			assert_eq(RecipeKnowledge.rank_ceiling("timePearl"), expected[rung], "ceiling after %s" % rung)
	)

	run_case("ceiling_stops_at_a_gap", func():
		_fresh()
		RecipeKnowledge.grant_rung("timePearl", "master")
		assert_eq(RecipeKnowledge.rank_ceiling("timePearl"), 2, "master without hints stays at base")
		RecipeKnowledge.grant_rung("timePearl", "hint1")
		assert_eq(RecipeKnowledge.rank_ceiling("timePearl"), 3, "hint2 still missing")
	)

	run_case("rung_owned_when_every_step_vague_exact_when_every_step_exact", func():
		_fresh()
		Lab.grant_recipe("pandemonium")
		assert_eq(RecipeKnowledge.rung_state("pandemonium", "base"), "exact", "base held")
		var steps := Lab.rung_steps("pandemonium", "master")
		assert_eq(steps.size(), 2, "two master steps")
		Lab.grant_steps("pandemonium", [steps[0]], "exact")
		assert_eq(RecipeKnowledge.rung_state("pandemonium", "master"), "unknown", "one step of two is not owned")
		Lab.grant_steps("pandemonium", [steps[1]], "vague")
		assert_eq(RecipeKnowledge.rung_state("pandemonium", "master"), "vague", "all at least vague")
		Lab.grant_steps("pandemonium", [steps[1]], "exact")
		assert_eq(RecipeKnowledge.rung_state("pandemonium", "master"), "exact", "all exact")
	)

	run_case("grant_upgrades_in_place_and_never_downgrades", func():
		_fresh()
		Lab.grant_recipe("timePearl")
		var r := RecipeKnowledge.grant_rung("timePearl", "hint1", "vague")
		assert_eq(r["path"], "granted", "first grant")
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint1"), "vague", "vague")
		assert_eq(RecipeKnowledge.grant_rung("timePearl", "hint1", "vague")["path"], "none", "same specificity teaches nothing")
		assert_eq(RecipeKnowledge.grant_rung("timePearl", "hint1")["path"], "granted", "exact upgrades")
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint1"), "exact", "exact")
		assert_eq(RecipeKnowledge.grant_rung("timePearl", "hint1", "vague")["path"], "none", "lower specificity is a no-op")
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint1"), "exact", "still exact")
		assert_eq(RecipeKnowledge.grant_rung("timePearl", "base")["path"], "none", "known recipe at base")
	)

	run_case("hint_on_unknown_recipe_grants_the_recipe_too", func():
		_fresh()
		var r := RecipeKnowledge.grant_rung("shield", "hint2")
		assert_eq(r["path"], "granted", "granted")
		assert_true(Lab.is_known("shield"), "recipe known")
		assert_eq(RecipeKnowledge.rung_state("shield", "hint2"), "exact", "hint2 held")
		assert_eq(RecipeKnowledge.rung_state("shield", "hint1"), "unknown", "hint1 not")
	)

	run_case("grant_refuses_bad_input", func():
		_fresh()
		assert_true(not RecipeKnowledge.grant_rung("nope", "base")["ok"], "unknown recipe")
		assert_true(not RecipeKnowledge.grant_rung("timePearl", "hint9")["ok"], "unknown rung")
		assert_true(not RecipeKnowledge.grant_rung("timePearl", "hint1", "fuzzy")["ok"], "unknown specificity")
		assert_true(not Lab.is_known("timePearl"), "nothing granted")
	)

	run_case("event_op_defaults_to_exact", func():
		_fresh()
		Events.apply_effects([
			{ "op": "grant_recipe_rung", "recipe": "blast", "rung": "base" },
			{ "op": "grant_recipe_rung", "recipe": "blast", "rung": "hint1" },
			{ "op": "grant_recipe_rung", "recipe": "blast", "rung": "hint2", "specificity": "vague" },
		])
		assert_eq(RecipeKnowledge.rung_state("blast", "hint1"), "exact", "default exact")
		assert_eq(RecipeKnowledge.rung_state("blast", "hint2"), "vague", "explicit vague")
		assert_eq(RecipeKnowledge.rank_ceiling("blast"), 4, "ceiling 4")
	)

	run_case("content_lint_accepts_the_op", func():
		var errors: Array[String] = []
		GameData._validate_effect_list([{ "op": "grant_recipe_rung", "recipe": "blast", "rung": "master", "specificity": "vague", "source": "wren" }], "t", errors)
		assert_eq(errors, [] as Array[String], "valid op")
		GameData._validate_effect_list([{ "op": "grant_recipe_rung", "recipe": "blast", "rung": "hint9" }], "t", errors)
		assert_eq(errors.size(), 1, "bad rung flagged")
		assert_eq(GameData.validate_tables(GameData.snapshot()), [] as Array[String], "shipped data validates")
	)

	run_case("collision_redirects_base_to_another_recipe_of_the_source", func():
		_fresh()
		Lab.grant_recipe("timePearl")
		var r := RecipeKnowledge.grant_rung("timePearl", "base", "exact", "james")
		assert_eq(r["path"], "redirected", "redirected")
		assert_eq(r["recipe"], "enhancementPowder", "next James recipe in data order")
		assert_true(Lab.is_known("enhancementPowder"), "taught")
	)

	run_case("collision_redirects_a_hint_only_to_a_known_recipe_missing_it", func():
		_fresh()
		_know_all(["timePearl", "rewind", "blast"])
		RecipeKnowledge.grant_rung("timePearl", "hint1")
		var r := RecipeKnowledge.grant_rung("timePearl", "hint1", "exact", "james")
		assert_eq(r["path"], "redirected", "redirected")
		assert_eq(r["recipe"], "rewind", "skips unknown enhancementPowder, picks known rewind")
		assert_eq(RecipeKnowledge.rung_state("rewind", "hint1"), "exact", "rewind hint1 taught")
		assert_true(not Lab.is_known("enhancementPowder"), "unknown recipe untouched")
	)

	run_case("guild_source_draws_on_wrens_recipes", func():
		_fresh()
		Lab.grant_recipe("blast")
		var r := RecipeKnowledge.grant_rung("blast", "base", "exact", "guild")
		assert_eq(r["path"], "redirected", "redirected")
		assert_eq(r["recipe"], "shield", "next Wren recipe")
		assert_eq(RecipeKnowledge.seller_of("wormhole"), "wren", "mixed ores go to Wren")
		assert_eq(RecipeKnowledge.seller_of("failsafe"), "james", "time+life goes to James")
	)

	run_case("collision_pool_includes_master_source_recipes", func():
		_fresh()
		var entry: Dictionary = GameData.RECIPE_KNOWLEDGE["masterSources"]["blast"]
		entry["source"] = "james"
		_know_all(JAMES_RECIPES)
		var r := RecipeKnowledge.grant_rung("timePearl", "base", "exact", "james")
		entry["source"] = null
		assert_eq(r["path"], "redirected", "redirected")
		assert_eq(r["recipe"], "blast", "James is blast's master source")
	)

	run_case("collision_consoles_with_xp_relation_and_line_for_a_contact", func():
		_fresh()
		_know_all(JAMES_RECIPES)
		var xp_before := int(GameState.state["player"]["craftingXP"])
		var rel_before := int(GameState.state["contacts"]["james"]["relation"])
		var r := RecipeKnowledge.grant_rung("timePearl", "base", "exact", "james")
		assert_eq(r["path"], "consolation", "nothing left to teach")
		assert_eq(r["line"], _collision()["lines"]["james"], "James's line")
		assert_true(int(GameState.state["player"]["craftingXP"]) > xp_before, "crafting XP awarded")
		assert_eq(int(GameState.state["contacts"]["james"]["relation"]), rel_before + int(_collision()["relation"]), "relation bump")
	)

	run_case("collision_consoles_a_faction_with_its_alias_line", func():
		_fresh()
		_know_all(GameData.RECIPES.keys().filter(func(k): return RecipeKnowledge.seller_of(k) == "wren"))
		var rel_before := int(GameState.state["factions"]["guild"]["relation"])
		var r := RecipeKnowledge.grant_rung("blast", "base", "exact", "guild")
		assert_eq(r["path"], "consolation", "consolation")
		assert_eq(r["line"], _collision()["lines"]["wren"], "falls back to Wren's line")
		assert_eq(int(GameState.state["factions"]["guild"]["relation"]), rel_before + int(_collision()["relation"]), "faction bump")
	)

	run_case("collision_consolation_line_reaches_notifications_via_op", func():
		_fresh()
		_know_all(JAMES_RECIPES)
		Events.apply_effects([{ "op": "grant_recipe_rung", "recipe": "timePearl", "rung": "base", "source": "james" }])
		var texts: Array = GameState.state["notifications"].map(func(n): return n["text"])
		assert_true(texts.has(_collision()["lines"]["james"]), "line pushed")
	)

	run_case("unsourced_collision_changes_nothing", func():
		_fresh()
		_know_all(JAMES_RECIPES)
		var xp_before := int(GameState.state["player"]["craftingXP"])
		assert_eq(RecipeKnowledge.grant_rung("timePearl", "base")["path"], "none", "none")
		assert_eq(int(GameState.state["player"]["craftingXP"]), xp_before, "no XP")
	)

	run_case("master_source_table_covers_every_recipe", func():
		var masters: Dictionary = GameData.RECIPE_KNOWLEDGE["masterSources"]
		for recipe_key in GameData.RECIPES.keys():
			assert_true(masters.has(recipe_key), "%s has an entry" % recipe_key)
		assert_eq(RecipeKnowledge.master_source("timePearl"), { "source": null, "pointer": "???" }, "null pointer reads ???")
		var entry: Dictionary = masters["timePearl"]
		entry["source"] = "james"
		entry["pointer"] = "Ask about the Dial."
		var looked := RecipeKnowledge.master_source("timePearl")
		entry["source"] = null
		entry["pointer"] = null
		assert_eq(looked, { "source": "james", "pointer": "Ask about the Dial." }, "set entry returned")
	)
