extends "res://tests/test_base.gd"

const TEST_SLOT := 87

# systems/lab.gd's knowledge spine (.scratch/lab-port/spec.md § State,
# § Knowledge API), driven through the public API and event ops.

func _fresh() -> Dictionary:
	GameState.reset()
	return GameState.state["lab"]


func _steps(recipe_key: String) -> Dictionary:
	return GameState.state["lab"]["known"][recipe_key]["steps"]


func _knowledge_of(procedure: Array) -> Array:
	return procedure.map(func(step): return [step["apparatus"], step["knowledge"], step["target"]])


func run() -> void:
	run_case("new_game_knows_no_recipes", func():
		var lab := _fresh()
		assert_eq(lab["known"], {}, "no recipe known")
		assert_eq(lab["bestRanks"], {}, "no ranks")
		assert_eq(lab["activeRun"], null, "no run")
		assert_eq(lab["performedOnce"], [], "nothing performed")
		assert_eq(Lab.known_recipes(), [], "book is empty")
		assert_true(not Lab.is_known("timePearl"), "timePearl unknown")
	)

	run_case("grant_recipe_adds_it_at_base", func():
		_fresh()
		assert_true(Lab.grant_recipe("timePearl")["ok"], "granted")
		assert_true(Lab.is_known("timePearl"), "known")
		assert_eq(_steps("timePearl"), {}, "no hidden steps known")
		assert_eq(_knowledge_of(Lab.known_procedure("timePearl")), [["compression", "base", 70.0], ["heat", "base", 25.0]], "base procedure only")
		assert_true(not Lab.grant_recipe("nope")["ok"], "unknown recipe refused")
	)

	run_case("known_recipes_filters_by_ingredient_ore", func():
		_fresh()
		Lab.grant_recipe("timePearl")
		Lab.grant_recipe("healingSalve")
		assert_eq(Lab.known_recipes(), ["timePearl", "healingSalve"], "recipes.json order")
		assert_eq(Lab.known_recipes("time"), ["timePearl"], "time tab")
		assert_eq(Lab.known_recipes("life"), ["healingSalve"], "life tab")
		assert_eq(Lab.known_recipes("fate"), [], "empty tab")
	)

	run_case("grant_steps_vague_then_exact_upgrades_in_place", func():
		_fresh()
		Lab.grant_recipe("timePearl")
		var vague := Lab.grant_steps("timePearl", [1], "vague")
		assert_eq(vague["granted"], [1], "step 1 granted")
		assert_eq(_knowledge_of(Lab.known_procedure("timePearl")), [["compression", "base", 70.0], ["grinding", "vague", 50.0], ["heat", "base", 25.0]], "grind inserted vague")
		var exact := Lab.grant_steps("timePearl", [1], "exact")
		assert_eq(exact["granted"], [1], "upgraded")
		assert_eq(_steps("timePearl"), { "1": "exact" }, "one entry, now exact")
	)

	run_case("grant_steps_never_downgrades", func():
		_fresh()
		Lab.grant_recipe("timePearl")
		Lab.grant_steps("timePearl", [0], "exact")
		var again := Lab.grant_steps("timePearl", [0], "vague")
		assert_eq(again["granted"], [], "nothing granted")
		assert_eq(_steps("timePearl"), { "0": "exact" }, "still exact")
		assert_eq(Lab.grant_steps("timePearl", [0], "exact")["granted"], [], "same level is a no-op")
	)

	run_case("grant_steps_skips_non_hidden_and_refuses_unknown", func():
		_fresh()
		assert_true(not Lab.grant_steps("timePearl", [0], "vague")["ok"], "recipe not known")
		Lab.grant_recipe("timePearl")
		assert_true(not Lab.grant_steps("timePearl", [0], "fuzzy")["ok"], "bad specificity")
		assert_eq(Lab.grant_steps("timePearl", [2, 9], "exact")["granted"], [], "no hint on step 2, no step 9")
		assert_eq(_steps("timePearl"), {}, "nothing changed")
	)

	run_case("step_region_exact_band_vague_region_corrected_base", func():
		_fresh()
		GameState.state["player"]["craftingSkill"] = 0
		Lab.grant_recipe("timePearl")
		Lab.grant_steps("timePearl", [0], "vague")
		var compress: Dictionary = Lab.known_procedure("timePearl")[0]
		assert_eq(compress["knowledge"], "vague", "base step corrected vaguely")
		assert_eq(compress["target"], 82.0, "true target underneath")
		# band 82±6, vague offset -8, spread 15: 53..95.
		assert_eq(Lab.step_region("timePearl", compress), { "low": 53.0, "high": 95.0, "vague": true }, "vague region")
		Lab.grant_steps("timePearl", [0], "exact")
		compress = Lab.known_procedure("timePearl")[0]
		assert_eq(Lab.step_region("timePearl", compress), { "low": 76.0, "high": 88.0, "vague": false }, "exact band")
		GameState.state["player"]["craftingSkill"] = 5
		assert_almost_eq(Lab.band_half_width("timePearl"), 6.0 * 1.4, 0.0001, "skill widens the band")
	)

	run_case("prophets_breath_reveals_unknown_steps", func():
		_fresh()
		Lab.grant_recipe("timePearl")
		Crafting.inventory_add(ActiveEffects.PROPHETS_BREATH, 1, 1)
		assert_true(ActiveEffects.use(ActiveEffects.PROPHETS_BREATH)["ok"], "Breath started")
		var procedure := Lab.known_procedure("timePearl")
		assert_eq(procedure.size(), 3, "every ideal step shown")
		assert_eq(procedure[1]["knowledge"], "revealed", "hidden grind revealed")
		assert_eq(_steps("timePearl"), {}, "knowledge untouched")
	)

	run_case("rung_steps_reads_rung_tags", func():
		_fresh()
		assert_eq(Lab.rung_steps("timePearl", "hint1"), [0], "hint1")
		assert_eq(Lab.rung_steps("timePearl", "hint2"), [1], "hint2")
	)

	run_case("event_op_grant_recipe", func():
		_fresh()
		Events.apply_effects([{ "op": "grant_recipe", "recipe": "healingSalve" }])
		assert_true(Lab.is_known("healingSalve"), "granted by event")
	)

	run_case("event_op_grant_recipe_steps_by_steps_and_by_rung", func():
		_fresh()
		Events.apply_effects([
			{ "op": "grant_recipe", "recipe": "healingBurst" },
			{ "op": "grant_recipe_steps", "recipe": "healingBurst", "steps": [3], "specificity": "vague" },
			{ "op": "grant_recipe_steps", "recipe": "healingBurst", "rung": "hint1", "specificity": "exact" },
		])
		assert_eq(_steps("healingBurst"), { "3": "vague", "2": "exact" }, "both ops granted")
	)

	run_case("james_meeting_grants_time_pearl_and_completes_the_objective", func():
		_fresh()
		GameState.state["flags"]["metJames"] = true
		Objectives.refresh()
		assert_true(not GameState.state["objectives"]["tut_crafting_unlocked"]["complete"], "not complete before the grant")
		assert_true(not GameState.state["objectives"]["tut_archie_craft_chat"]["active"], "Archie follow-up waits for the recipe")
		Events.apply_effects(GameData.EVENTS["james_meeting"]["on_complete"].filter(func(e): return e["op"] == "grant_recipe"))
		assert_true(Lab.is_known("timePearl"), "timePearl known")
		assert_eq(Lab.known_recipes(), ["timePearl"], "only timePearl")
		assert_true(GameState.state["objectives"]["tut_crafting_unlocked"]["complete"], "knowing timePearl completes the checkpoint")
		assert_true(GameState.state["objectives"]["tut_archie_craft_chat"]["active"], "knowing timePearl opens the Archie follow-up")
	)

	run_case("lab_state_round_trips_through_save", func():
		_fresh()
		Lab.grant_recipe("timePearl")
		Lab.grant_steps("timePearl", [1], "vague")
		GameState.state["lab"]["bestRanks"]["timePearl"] = 3
		var original: Dictionary = GameState.deep_copy(GameState.state["lab"])
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"], "saved")
		GameState.state["lab"] = Lab.new_state()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"], "loaded")
		assert_eq(GameState.state["lab"], original, "lab survives save/load")
		assert_eq(typeof(GameState.state["lab"]["bestRanks"]["timePearl"]), TYPE_INT, "rank stays int")
		SaveManager.delete_slot(TEST_SLOT)
	)

	_register_run_cases()


# A fresh game knowing recipe_key, crafting skill 0, with this unstashed calc.
func _bench(recipe_key: String, calc: Dictionary) -> Dictionary:
	_fresh()
	var player: Dictionary = GameState.state["player"]
	player["craftingSkill"] = 0
	for ore_type in calc:
		player["orichalchum"][ore_type] = calc[ore_type]
	Lab.grant_recipe(recipe_key)
	return player


func _calc(ore_type: String) -> int:
	return int(GameState.state["player"]["orichalchum"].get(ore_type, 0))


# timePearl ideal: compress (time) 82 w35, grind 50 w25, heat 25 w40; band ±6 at skill 0.
func _perfect_time_pearl() -> void:
	Lab.add_ore("timePearl", "time")
	Lab.perform_step("compression", 82.0)
	Lab.perform_grind([50.0, 50.0, 50.0])
	Lab.perform_step("heat", 25.0)


func _register_run_cases() -> void:
	run_case("only_the_run_recipes_own_jars_spend_real_calc", func():
		_bench("timePearl", { "time": 10, "life": 10 })
		Lab.grant_recipe("healingSalve")
		assert_true(not Lab.add_ore("timePearl", "life")["ok"], "life jar refused for timePearl")
		assert_eq(_calc("life"), 10, "no life spent")
		assert_eq(Lab.active_run(), null, "a refused tap opens no run")
		assert_true(Lab.add_ore("timePearl", "time")["ok"], "time jar taps")
		assert_eq(_calc("time"), 7, "per-tap amount spent from real calc")
		Lab.add_ore("timePearl", "time")
		assert_eq(_calc("time"), 4, "each tap spends again")
		assert_eq(Lab.active_run()["calcSpent"], { "time": 6 }, "run tallies spend")
		assert_true(not Lab.add_ore("healingSalve", "life")["ok"], "another recipe's jar refused mid-run")
		assert_eq(_calc("life"), 10, "still no life spent")
		Lab.add_ore("timePearl", "time")
		assert_true(not Lab.add_ore("timePearl", "time")["ok"], "short of calc refused")
		assert_eq(_calc("time"), 1, "nothing spent when short")
	)

	run_case("unknown_recipe_cannot_run", func():
		_bench("timePearl", { "life": 10 })
		assert_true(not Lab.begin_run("healingSalve")["ok"], "begin refused")
		assert_true(not Lab.add_ore("healingSalve", "life")["ok"], "tap refused")
		assert_eq(_calc("life"), 10, "nothing spent")
	)

	run_case("calc_cost_is_fixed_whatever_the_skill", func():
		for skill in [0, 5, 10]:
			var player := _bench("timePearl", { "time": 10 })
			player["craftingSkill"] = skill
			assert_true(Lab.begin_run("timePearl")["ok"], "begin at skill %d" % skill)
			assert_eq(_calc("time"), 7, "base calc 3 at skill %d" % skill)
	)

	run_case("steps_record_apparatus_reading_and_ores_in_any_order", func():
		_bench("healingBurst", { "life": 10, "time": 10 })
		assert_true(not Lab.perform_step("heat", 30.0)["ok"], "no apparatus before a jar tap")
		Lab.add_ore("healingBurst", "life")
		Lab.perform_step("heat", 30.0)
		Lab.perform_step("heat", 140.0)
		Lab.add_ore("healingBurst", "time")
		Lab.add_ore("healingBurst", "life")
		Lab.perform_grind([40.0, 60.0])
		Lab.perform_distil([500.0, 1500.0, 1450.0])
		var performed: Array = Lab.active_run()["performed"]
		assert_eq(performed[0], { "apparatus": "heat", "value": 30.0, "ores": ["life"] }, "first step carries the opening tap")
		assert_eq(performed[1], { "apparatus": "heat", "value": 100.0, "ores": [] }, "repeat allowed, value clamped")
		assert_eq(performed[2], { "apparatus": "grinding", "readings": [40.0, 60.0, null], "ores": ["time", "life"] }, "short strokes read null")
		assert_eq(performed[3]["readings"], [50.0, 10.0, null, null], "drip readings")
		assert_true(performed[3]["stray"], "second tap on a drip is stray")
		assert_true(not Lab.perform_step("grinding", 50.0)["ok"], "grind isn't a hold step")
	)

	run_case("perfect_run_files_one_item_at_rank_five", func():
		var player := _bench("timePearl", { "time": 10 })
		var xp_before := int(player["craftingXP"])
		_perfect_time_pearl()
		var result := Lab.finish_run()
		assert_eq(result["score"], 100, "perfect score")
		assert_eq(result["rank"], 5, "rank 5")
		assert_eq(player["inventory"]["timePearl"], { "5": 1 }, "one item at tier 5")
		assert_eq(GameState.state["lab"]["bestRanks"]["timePearl"], 5, "best rank set")
		assert_eq(GameState.state["lab"]["performedOnce"], ["timePearl"], "performed once")
		assert_eq(Lab.active_run(), null, "run closed")
		assert_eq(int(player["craftingXP"]) - xp_before, int(GameData.RECIPES["timePearl"]["xpReward"]), "full xpReward")
		assert_eq(_calc("time"), 7, "calc stays spent")
	)

	run_case("score_weights_order_and_extra_step_penalty", func():
		var cases := [
			# base procedure as written: compress 70 is 12 off (2× band, 0) + heat 40.
			[[["compression", 70.0], ["heat", 25.0]], 40, 2],
			# compress in band: 35 + 40.
			[[["compression", 79.0], ["heat", 25.0]], 75, 4],
			# plus an unmatched distil: -5.
			[[["compression", 79.0], ["heat", 25.0], ["distilling", 0.0]], 70, 3],
			# heat first eats ideal step 2, so the later compress is extra.
			[[["heat", 25.0], ["compression", 82.0]], 35, 1],
			# compress 9 off: accuracy 0.5 -> 17.5 rounds with the rest.
			[[["compression", 91.0], ["grinding", 50.0], ["heat", 25.0]], 83, 4],
		]
		for c in cases:
			_bench("timePearl", { "time": 10 })
			Lab.add_ore("timePearl", "time")
			for step in c[0]:
				if step[0] == "grinding":
					Lab.perform_grind([step[1], step[1], step[1]])
				elif step[0] == "distilling":
					Lab.perform_distil([])
				else:
					Lab.perform_step(step[0], step[1])
			var result := Lab.finish_run()
			assert_eq([result["score"], result["rank"]], [c[1], c[2]], "steps %s" % str(c[0]))
	)

	run_case("rank_thresholds_come_from_data", func():
		_fresh()
		var ranks := [0, 39, 40, 59, 60, 74, 75, 89, 90, 100].map(func(s): return Lab.rank_for_score(s))
		assert_eq(ranks, [1, 1, 2, 2, 3, 3, 4, 4, 5, 5], "thresholds 0/40/60/75/90")
	)

	run_case("a_finish_with_no_steps_still_yields_a_rank_one_item", func():
		var player := _bench("timePearl", { "time": 10 })
		Lab.add_ore("timePearl", "time")
		var result := Lab.finish_run()
		assert_eq([result["score"], result["rank"], result["items"]], [0, 1, 1], "no success roll")
		assert_eq(player["inventory"]["timePearl"], { "1": 1 }, "tier 1 item")
	)

	run_case("best_rank_only_rises", func():
		var player := _bench("timePearl", { "time": 10 })
		_perfect_time_pearl()
		Lab.finish_run()
		Lab.add_ore("timePearl", "time")
		var bad := Lab.finish_run()
		assert_eq(bad["rank"], 1, "bad run ranks 1")
		assert_true(not bad["newBest"], "not a new best")
		assert_eq(GameState.state["lab"]["bestRanks"]["timePearl"], 5, "best stays 5")
		assert_eq(player["inventory"]["timePearl"], { "5": 1, "1": 1 }, "item tier is the run's rank")
	)

	run_case("overshot_compress_cracks_losing_calc_and_item", func():
		var player := _bench("timePearl", { "time": 10 })
		var xp_before := int(player["craftingXP"])
		Lab.add_ore("timePearl", "time")
		assert_true(not Lab.perform_step("compression", 94.0).get("cracked", false), "94 holds")
		var result := Lab.perform_step("compression", 95.0)
		assert_true(result["cracked"], "95 cracks")
		assert_eq(result["outcome"], "cracked", "outcome")
		assert_eq(Lab.active_run(), null, "run closed")
		assert_eq(_calc("time"), 7, "calc lost")
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "no item")
		assert_eq(GameState.state["lab"]["bestRanks"], {}, "no rank")
		assert_eq(GameState.state["lab"]["performedOnce"], [], "not performed")
		assert_eq(int(player["craftingXP"]) - xp_before, floori(GameData.RECIPES["timePearl"]["xpReward"] / 3.0), "a third of the XP")
	)

	run_case("abandon_loses_calc_and_item", func():
		var player := _bench("timePearl", { "time": 10 })
		var xp_before := int(player["craftingXP"])
		assert_true(not Lab.abandon_run()["ok"], "nothing to abandon")
		Lab.add_ore("timePearl", "time")
		Lab.perform_step("heat", 25.0)
		var result := Lab.abandon_run()
		assert_eq([result["outcome"], result["items"]], ["abandoned", 0], "abandoned, no item")
		assert_eq(Lab.active_run(), null, "run closed")
		assert_eq(_calc("time"), 7, "calc lost")
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "no item")
		assert_eq(GameState.state["lab"]["performedOnce"], [], "not performed")
		assert_eq(int(player["craftingXP"]) - xp_before, floori(GameData.RECIPES["timePearl"]["xpReward"] / 3.0), "a third of the XP")
	)

	run_case("manual_run_hook_fires_once_per_run", func():
		_bench("timePearl", { "time": 20 })
		var heard := []
		var listener := func(payload: Dictionary): heard.append(payload)
		EventBus.lab_run_completed.connect(listener)
		_perfect_time_pearl()
		Lab.finish_run()
		Lab.add_ore("timePearl", "time")
		Lab.perform_step("compression", 99.0)
		Lab.add_ore("timePearl", "time")
		Lab.abandon_run()
		Lab.finish_run()
		EventBus.lab_run_completed.disconnect(listener)
		assert_eq(heard, [
			{ "recipe": "timePearl", "score": 100, "rank": 5, "outcome": "finished" },
			{ "recipe": "timePearl", "score": 0, "rank": 0, "outcome": "cracked" },
			{ "recipe": "timePearl", "score": 0, "rank": 0, "outcome": "abandoned" },
		], "one payload per run, none for a refused finish")
	)

	run_case("a_run_spends_no_time_block", func():
		_bench("timePearl", { "time": 10 })
		var world: Dictionary = GameState.state["world"]
		var before := [world["day"], world["timeBlock"]]
		_perfect_time_pearl()
		Lab.finish_run()
		assert_eq([world["day"], world["timeBlock"]], before, "clock unchanged")
	)

	run_case("tolerance_widens_with_skill_and_each_bench_bonus", func():
		var player := _bench("healingBurst", {})
		var factors: Dictionary = GameData.LAB["benchBonusFactors"]
		assert_almost_eq(Lab.band_half_width("healingBurst"), 4.0, 0.0001, "base tolerance")
		player["craftingSkill"] = 5
		var skilled := 4.0 * (1.0 + 0.08 * 5)
		assert_almost_eq(Lab.band_half_width("healingBurst"), skilled, 0.0001, "skill widens")
		GameState.state["home"]["tier"] = "townhouse"
		GameState.state["home"]["rooms"] = ["workshop"]
		var home := Home.get_workshop_bonus() * float(factors["home"])
		assert_true(home > 0.0, "workshop gives a bonus")
		assert_almost_eq(Lab.band_half_width("healingBurst"), skilled * (1.0 + home), 0.0001, "home bonus")
		GameState.state["turf"]["soho"] = { "controller": "guild", "tiers": { "guild": Turf.TIER_CONTROL }, "shares": {} }
		GameState.state["factionStances"]["player"]["guild"]["stance"] = FactionAI.PARTNER
		player["veins"] = [{ "district": "soho" }]
		var perk := Perks.craft_chance_bonus() * float(factors["perk"])
		assert_true(perk > 0.0, "guild perk gives a bonus")
		assert_almost_eq(Lab.band_half_width("healingBurst"), skilled * (1.0 + home + perk), 0.0001, "perk bonus")
		player["dial"] = { "level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 0, "rechargeRate": 0, "capacityMax": 0, "movement": { "archetype": "impact", "oreType": "fate", "tier": 5 }, "loadedComplications": [], "haftId": "collective_brolly" }
		assert_almost_eq(Lab.band_half_width("healingBurst"), skilled * (1.0 + home + perk), 0.0001, "non-ingredient attunement ignored")
		player["dial"]["movement"]["oreType"] = "time"
		var attunement := Dial.attunement_bonus("time") * float(factors["attunement"])
		assert_almost_eq(Lab.band_half_width("healingBurst"), skilled * (1.0 + home + perk + attunement), 0.0001, "second-ingredient attunement counts")
	)

	run_case("be_a_lady_adds_score_per_item_level", func():
		_bench("timePearl", { "time": 10 })
		Crafting.inventory_add(ActiveEffects.LADY, 2, 1)
		assert_true(Lab.use_effect(ActiveEffects.LADY)["ok"], "Lady started from a real item")
		assert_eq(Crafting.inventory_qty(ActiveEffects.LADY), 0, "item consumed")
		Lab.add_ore("timePearl", "time")
		Lab.perform_step("compression", 70.0)
		Lab.perform_step("heat", 25.0)
		var result := Lab.finish_run()
		assert_eq([result["rawScore"], result["ladyBonus"], result["score"], result["rank"]], [40, 20, 60, 3], "level 2 Lady adds 20")
		assert_true(not Lab.use_effect("timePearl")["ok"], "only bench effects")
	)

	run_case("prophets_breath_from_the_bench_reveals_true_bands", func():
		_bench("timePearl", {})
		Crafting.inventory_add(ActiveEffects.PROPHETS_BREATH, 1, 1)
		assert_true(Lab.use_effect(ActiveEffects.PROPHETS_BREATH)["ok"], "Breath started")
		var compress: Dictionary = Lab.known_procedure("timePearl")[0]
		assert_eq([compress["knowledge"], compress["target"]], ["revealed", 82.0], "true target shown")
		assert_eq(Lab.step_region("timePearl", compress), { "low": 76.0, "high": 88.0, "vague": false }, "true band")
	)
