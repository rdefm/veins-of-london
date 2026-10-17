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

	_register_buying_cases()


func _shop(seller_id: String) -> Dictionary:
	return GameData.RECIPE_KNOWLEDGE["shops"][seller_id]


func _open_shops() -> void:
	GameState.state["flags"]["jamesRecipesUnlocked"] = true
	GameState.state["flags"]["wrenRecipesUnlocked"] = true


# No goodwill: James's relation and Wren's standing at their zeroAt.
func _no_discount() -> void:
	GameState.state["contacts"]["james"]["relation"] = int(_shop("james")["discount"]["zeroAt"])
	GameState.state["factions"]["guild"]["standing"]["wren"] = int(_shop("wren")["discount"]["zeroAt"])


func _guild_tier(tier: String) -> void:
	var friendly := int(GameData.FACTION_PERKS["friendlyAtOrAbove"])
	GameState.state["factions"]["guild"]["joined"] = false
	GameState.state["factions"]["guild"]["relation"] = 0 if tier == "none" else friendly
	GameState.state["factionStances"]["player"]["guild"]["stance"] = FactionAI.PARTNER if tier == "partner" else FactionAI.NEUTRAL


func _register_buying_cases() -> void:
	run_case("seller_of_every_recipe", func():
		var expected := {}
		for recipe_key in GameData.RECIPES.keys():
			expected[recipe_key] = "james" if JAMES_RECIPES.has(recipe_key) else "wren"
		assert_eq(expected.size(), 17, "17 recipes")
		for recipe_key in expected.keys():
			assert_eq(RecipeKnowledge.seller_of(recipe_key), expected[recipe_key], recipe_key)
	)

	run_case("gates_follow_unlock_relation_and_guild_tier", func():
		_fresh()
		_guild_tier("partner")
		GameState.state["contacts"]["james"]["relation"] = 100
		for rung in ["base", "hint1", "hint2", "master"]:
			assert_true(not RecipeKnowledge.gate_met("timePearl", rung), "James locked: %s" % rung)
			assert_true(not RecipeKnowledge.gate_met("blast", rung), "Wren locked: %s" % rung)
		_open_shops()
		var gate: Dictionary = _shop("james")["gate"]
		GameState.state["contacts"]["james"]["relation"] = 0
		assert_true(RecipeKnowledge.gate_met("timePearl", "base"), "base needs only the unlock")
		assert_true(not RecipeKnowledge.gate_met("timePearl", "hint1"), "hint1 below threshold")
		GameState.state["contacts"]["james"]["relation"] = int(gate["hint1"])
		assert_true(RecipeKnowledge.gate_met("timePearl", "hint1"), "hint1 at threshold")
		assert_true(not RecipeKnowledge.gate_met("timePearl", "hint2"), "hint2 below threshold")
		GameState.state["contacts"]["james"]["relation"] = int(gate["hint2"])
		assert_true(RecipeKnowledge.gate_met("timePearl", "hint2"), "hint2 at threshold")
		assert_true(not RecipeKnowledge.gate_met("timePearl", "master"), "master never")
		_guild_tier("none")
		assert_true(RecipeKnowledge.gate_met("blast", "base"), "Wren base")
		assert_true(not RecipeKnowledge.gate_met("blast", "hint1"), "Stranger: no hint1")
		_guild_tier("friendly")
		assert_true(RecipeKnowledge.gate_met("blast", "hint1"), "Friendly: hint1")
		assert_true(not RecipeKnowledge.gate_met("blast", "hint2"), "Friendly: no hint2")
		_guild_tier("partner")
		assert_true(RecipeKnowledge.gate_met("blast", "hint2"), "Partner: hint2")
		GameState.state["factions"]["guild"]["joined"] = true
		assert_true(RecipeKnowledge.gate_met("blast", "hint2"), "Sworn: hint2")
		assert_true(not RecipeKnowledge.gate_met("blast", "master"), "master never")
		_guild_tier("friendly")
		assert_true(not RecipeKnowledge.gate_met("blast", "hint2"), "tier drop closes hint2")
	)

	run_case("price_is_sell_times_multiplier_with_override_and_bounded_discount", func():
		_fresh()
		_no_discount()
		var mult: Dictionary = GameData.RECIPE_KNOWLEDGE["priceMultipliers"]
		var sell := int(GameData.CONSUMABLE_PRICES["timePearl"])
		assert_eq(RecipeKnowledge.price("timePearl", "base"), sell * int(mult["base"]), "base")
		assert_eq(RecipeKnowledge.price("timePearl", "hint1"), sell * int(mult["hint1"]), "hint1")
		assert_eq(RecipeKnowledge.price("timePearl", "hint2"), sell * int(mult["hint2"]), "hint2")
		var override := int(GameData.RECIPE_KNOWLEDGE["priceOverrides"]["enhancementPowder"]["base"])
		assert_eq(RecipeKnowledge.price("enhancementPowder", "base"), override, "override wins")
		var max_d := float(GameData.RECIPE_KNOWLEDGE["maxDiscount"])
		assert_almost_eq(max_d, 0.2, 0.0001, "discount capped at 20%")
		GameState.state["contacts"]["james"]["relation"] = int(_shop("james")["discount"]["fullAt"]) + 50
		assert_almost_eq(RecipeKnowledge.discount("james"), max_d, 0.0001, "full goodwill caps")
		assert_eq(RecipeKnowledge.price("timePearl", "base"), roundi(sell * int(mult["base"]) * (1.0 - max_d)), "discounted")
		GameState.state["contacts"]["james"]["relation"] = -50
		assert_almost_eq(RecipeKnowledge.discount("james"), 0.0, 0.0001, "never negative")
		var wren: Dictionary = _shop("wren")["discount"]
		GameState.state["factions"]["guild"]["standing"]["wren"] = (int(wren["zeroAt"]) + int(wren["fullAt"])) / 2
		assert_almost_eq(RecipeKnowledge.discount("wren"), max_d / 2.0, 0.0001, "Wren scales with standing")
	)

	run_case("price_ignores_market_and_gouge", func():
		_fresh()
		_no_discount()
		var before := RecipeKnowledge.price("timePearl", "hint1")
		var good: Dictionary = GameState.state["market"]["goods"]["consumable"]["timePearl"]
		good["price"] = int(good["price"]) * 3
		GameState.state["factionEscalation"]["gouges"] = [{ "factionId": "network", "targetId": "player", "priceMult": 2.0, "untilDay": 9999 }]
		assert_true(FactionAI.gouge_mult("player") > 1.0, "gouge active")
		assert_eq(RecipeKnowledge.price("timePearl", "hint1"), before, "unchanged")
	)

	run_case("buy_refuses_with_distinct_reasons", func():
		_fresh()
		_no_discount()
		_guild_tier("none")
		GameState.state["player"]["cash"] = 1000000
		var reasons := {}
		reasons["locked"] = RecipeKnowledge.buy("timePearl", "base")
		_open_shops()
		reasons["gate"] = RecipeKnowledge.buy("blast", "hint1")
		reasons["master"] = RecipeKnowledge.buy("timePearl", "master")
		GameState.state["contacts"]["james"]["relation"] = 100
		reasons["order"] = RecipeKnowledge.buy("timePearl", "hint2")
		Lab.grant_recipe("timePearl")
		reasons["exact"] = RecipeKnowledge.buy("timePearl", "base")
		GameState.state["player"]["cash"] = RecipeKnowledge.price("timePearl", "hint1") - 1
		reasons["cash"] = RecipeKnowledge.buy("timePearl", "hint1")
		var seen := {}
		for key in reasons.keys():
			assert_true(not reasons[key]["ok"], "%s refused" % key)
			seen[reasons[key]["reason"]] = true
		assert_eq(seen.size(), reasons.size(), "each reason distinct")
		assert_eq(int(GameState.state["player"]["cash"]), RecipeKnowledge.price("timePearl", "hint1") - 1, "no cash spent")
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint1"), "unknown", "nothing taught")
	)

	run_case("buy_spends_teaches_exact_logs_and_emits", func():
		_fresh()
		_no_discount()
		_open_shops()
		GameState.state["player"]["cash"] = 100000
		var emitted := [0]
		EventBus.state_changed.connect(func(): emitted[0] += 1)
		var cost := RecipeKnowledge.price("blast", "base")
		var r := RecipeKnowledge.buy("blast", "base")
		assert_true(r["ok"], "bought")
		assert_eq(int(GameState.state["player"]["cash"]), 100000 - cost, "cash spent")
		assert_true(Lab.is_known("blast"), "recipe known")
		var entry: Dictionary = GameState.state["bankLog"].back()
		assert_eq(int(entry["amount"]), -cost, "bank log")
		assert_true(str(entry["label"]).contains("Blast"), "label names the recipe")
		assert_true(emitted[0] > 0, "state_changed emitted")
		assert_eq(RecipeKnowledge.buy("blast", "base")["ok"], false, "second base refused")
	)

	run_case("ladder_rows_show_state_ceiling_and_lock_reason", func():
		_fresh()
		_no_discount()
		var ladder: Dictionary = GameData.RECIPE_KNOWLEDGE["ladder"]
		Lab.grant_recipe("timePearl")
		RecipeKnowledge.grant_rung("timePearl", "hint1", "vague")
		var rows := RecipeKnowledge.ladder_rows("timePearl")
		assert_eq(rows.map(func(r): return r["rung"]), RecipeKnowledge.rungs(), "one row per rung, in order")
		assert_eq(rows[0]["state"], "exact", "base exact")
		assert_eq(rows[0]["note"], ladder["states"]["exact"])
		assert_eq(rows[0]["ceiling"], ladder["ceiling"] % 2, "base ceiling")
		assert_eq(rows[1]["state"], "vague", "hint1 vague")
		assert_eq(rows[1]["note"], ladder["states"]["vague"])
		assert_eq(rows[2]["state"], "locked", "hint2 locked")
		var sold := str(ladder["soldBy"]) % "James"
		var gate := str(_shop("james")["gate"]["text"]) % int(_shop("james")["gate"]["hint2"])
		assert_eq(rows[2]["note"], str(ladder["join"]) % [sold, gate], "source and unmet gate")
		assert_eq(rows[3]["note"], GameData.RECIPE_KNOWLEDGE["unknownPointer"], "unassigned master reads ???")
		assert_eq(rows[2]["text"], str(ladder["row"]) % [RecipeKnowledge.rung_label("hint2"), rows[2]["ceiling"], rows[2]["note"]], "row text")
		GameState.state["contacts"]["james"]["relation"] = int(_shop("james")["gate"]["hint2"])
		assert_eq(RecipeKnowledge.ladder_rows("timePearl")[2]["note"], sold, "gate reached, shop still shut: source only")
		_open_shops()
		assert_eq(RecipeKnowledge.ladder_rows("timePearl")[2]["note"], sold, "gate met: source only")
	)

	run_case("ladder_rows_name_a_faction_tier_gate_and_a_master_pointer", func():
		_fresh()
		Lab.grant_recipe("blast")
		var ladder: Dictionary = GameData.RECIPE_KNOWLEDGE["ladder"]
		var gate := str(_shop("wren")["gate"]["text"]) % Perks.tier_label(str(_shop("wren")["gate"]["hint1"]))
		assert_eq(RecipeKnowledge.ladder_rows("blast")[1]["note"], str(ladder["join"]) % [str(ladder["soldBy"]) % "Wren", gate], "tier gate named")
		var entry: Dictionary = GameData.RECIPE_KNOWLEDGE["masterSources"]["blast"]
		entry["pointer"] = "Ask the river."
		var note: String = RecipeKnowledge.ladder_rows("blast")[3]["note"]
		entry["pointer"] = null
		assert_eq(note, "Ask the river.", "assigned pointer shows")
	)

	run_case("buying_a_vague_rung_upgrades_it_to_exact", func():
		_fresh()
		_no_discount()
		_open_shops()
		GameState.state["contacts"]["james"]["relation"] = 100
		GameState.state["player"]["cash"] = 100000
		RecipeKnowledge.grant_rung("timePearl", "hint1", "vague")
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint1"), "vague", "held vague")
		assert_true(RecipeKnowledge.buy("timePearl", "hint1")["ok"], "bought")
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint1"), "exact", "now exact")
		assert_true(RecipeKnowledge.buy("timePearl", "hint2")["ok"], "next rung in order")
	)
