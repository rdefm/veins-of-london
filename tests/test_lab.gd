extends "res://tests/test_base.gd"

const TEST_SLOT := 87
const SeedSearch := preload("res://tests/support/seed_search.gd")
const Fixtures := preload("res://tests/support/fixtures.gd")

var _real_bonus_chance: float
var _real_insight: Dictionary

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
		assert_eq(procedure.size(), 4, "every ideal step shown")
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

	_real_bonus_chance = GameData.LAB["bonus"]["chance"]
	_real_insight = GameData.RECIPE_KNOWLEDGE["insight"].duplicate()
	_register_run_cases()
	_register_learning_cases()
	_register_insight_cases()
	_register_batch_rewind_cases()
	GameData.LAB["bonus"]["chance"] = _real_bonus_chance
	_set_insight_chance(_real_insight["base"], _real_insight["perSkill"])


# A fresh game knowing recipe_key, crafting skill 0, with this unstashed
# calc, and no re-run bonus or insight unless a case sets their chance back.
func _bench(recipe_key: String, calc: Dictionary) -> Dictionary:
	_fresh()
	GameData.LAB["bonus"]["chance"] = 0.0
	_set_insight_chance(0.0, 0.0)
	var player: Dictionary = GameState.state["player"]
	player["craftingSkill"] = 0
	for ore_type in calc:
		player["orichalchum"][ore_type] = calc[ore_type]
	Lab.grant_recipe(recipe_key)
	return player


func _set_insight_chance(base: float, per_skill: float) -> void:
	GameData.RECIPE_KNOWLEDGE["insight"]["base"] = base
	GameData.RECIPE_KNOWLEDGE["insight"]["perSkill"] = per_skill


func _calc(ore_type: String) -> int:
	return int(GameState.state["player"]["orichalchum"].get(ore_type, 0))


# timePearl ideal: compress (time) 82 w28, grind 50 w14, heat 25 w40,
# compress 30 w18; band ±6 at skill 0; base calc time 5.
func _perfect_time_pearl() -> void:
	Lab.add_ore("timePearl", "time")
	Lab.perform_step("compression", 82.0)
	Lab.perform_grind([50.0, 50.0, 50.0])
	Lab.perform_step("heat", 25.0)
	Lab.perform_step("compression", 30.0)


func _register_run_cases() -> void:
	run_case("only_the_run_recipes_own_jars_spend_real_calc", func():
		_bench("timePearl", { "time": 12, "life": 10 })
		Lab.grant_recipe("healingSalve")
		assert_true(not Lab.add_ore("timePearl", "life")["ok"], "life jar refused for timePearl")
		assert_eq(_calc("life"), 10, "no life spent")
		assert_eq(Lab.active_run(), null, "a refused tap opens no run")
		assert_true(Lab.add_ore("timePearl", "time")["ok"], "time jar taps")
		assert_eq(_calc("time"), 7, "per-tap amount spent from real calc")
		Lab.add_ore("timePearl", "time")
		assert_eq(_calc("time"), 2, "each tap spends again")
		assert_eq(Lab.active_run()["calcSpent"], { "time": 10 }, "run tallies spend")
		assert_true(not Lab.add_ore("healingSalve", "life")["ok"], "another recipe's jar refused mid-run")
		assert_eq(_calc("life"), 10, "still no life spent")
		assert_true(not Lab.add_ore("timePearl", "time")["ok"], "short of calc refused")
		assert_eq(_calc("time"), 2, "nothing spent when short")
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
			assert_eq(_calc("time"), 5, "base calc 5 at skill %d" % skill)
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
		assert_eq(_calc("time"), 5, "calc stays spent")
	)

	run_case("score_weights_order_and_extra_step_penalty", func():
		var cases := [
			# base procedure as written: compress 70 is 12 off (2× band, 0) + heat 40.
			[[["compression", 70.0], ["heat", 25.0]], 40, 2],
			# compress in band: 28 + 40.
			[[["compression", 79.0], ["heat", 25.0]], 68, 3],
			# plus an unmatched distil: -5.
			[[["compression", 79.0], ["heat", 25.0], ["distilling", 0.0]], 63, 3],
			# heat first eats ideal step 2, so the later grind is extra.
			[[["heat", 25.0], ["grinding", 50.0]], 35, 1],
			# compress 9 off: accuracy 0.5 -> 14, plus grind 14 and heat 40.
			[[["compression", 91.0], ["grinding", 50.0], ["heat", 25.0]], 68, 3],
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
		assert_eq(_calc("time"), 5, "calc lost")
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
		assert_eq(_calc("time"), 5, "calc lost")
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

	run_case("bench_effects_outlast_runs_until_the_clock_moves", func():
		_bench("timePearl", { "time": 20 })
		Crafting.inventory_add(ActiveEffects.LADY, 1, 1)
		Crafting.inventory_add(ActiveEffects.PROPHETS_BREATH, 1, 1)
		Lab.add_ore("timePearl", "time")
		Lab.use_effect(ActiveEffects.LADY)
		Lab.use_effect(ActiveEffects.PROPHETS_BREATH)
		assert_eq(Lab.finish_run()["ladyBonus"], 10, "Lady used mid-run counts")
		assert_true(ActiveEffects.lady_active() and ActiveEffects.prophets_breath_active(), "both still running after Finish")
		Lab.add_ore("timePearl", "time")
		Lab.abandon_run()
		Lab.add_ore("timePearl", "time")
		assert_eq(Lab.finish_run()["ladyBonus"], 10, "Lady still adds on a later run")
		assert_eq(Lab.known_procedure("timePearl")[1]["knowledge"], "revealed", "Breath still reveals")
		var lady: Dictionary = ActiveEffects.find(ActiveEffects.LADY)
		for i in ActiveEffects.blocks_left(lady):
			TimeSystem.advance_time_block()
		assert_true(not ActiveEffects.lady_active() and not ActiveEffects.prophets_breath_active(), "both expire once the clock passes them")
	)

	run_case("pending_step_is_the_next_known_step_on_that_apparatus", func():
		_bench("timePearl", { "time": 10 })
		assert_eq(Lab.pending_step("compression"), {}, "no run: nothing pending")
		Lab.begin_run("timePearl")
		var steps := Lab.known_procedure("timePearl")
		assert_eq(Lab.pending_step("compression"), steps[0], "the base press")
		assert_eq(Lab.pending_step("grinding"), {}, "no known grind")
		Lab.perform_step("compression", 70.0)
		assert_eq(Lab.pending_step("compression"), {}, "the only known press is done")
		assert_eq(Lab.pending_step("heat"), steps[1], "the heat is next")
	)

	run_case("prophets_breath_from_the_bench_reveals_true_bands", func():
		_bench("timePearl", {})
		Crafting.inventory_add(ActiveEffects.PROPHETS_BREATH, 1, 1)
		assert_true(Lab.use_effect(ActiveEffects.PROPHETS_BREATH)["ok"], "Breath started")
		var compress: Dictionary = Lab.known_procedure("timePearl")[0]
		assert_eq([compress["knowledge"], compress["target"]], ["revealed", 82.0], "true target shown")
		assert_eq(Lab.step_region("timePearl", compress), { "low": 76.0, "high": 88.0, "vague": false }, "true band")
	)


func _clue_marks(clues: Array) -> Array:
	return clues.map(func(c): return [c["clue"], c["direction"]])


func _register_learning_cases() -> void:
	run_case("each_step_gets_one_of_four_clues", func():
		_bench("timePearl", { "time": 10 })
		Lab.add_ore("timePearl", "time")
		Lab.perform_step("compression", 70.0)
		Lab.perform_grind([50.0, 50.0, 50.0])
		Lab.perform_step("heat", 25.0)
		Lab.perform_distil([])
		var clues: Array = Lab.finish_run()["clues"]
		assert_eq(_clue_marks(clues), [["near", "higher"], ["changed", null], ["hit", null], ["none", null]], "near, changed, hit, none")
		assert_eq(clues.map(func(c): return c["ideal"]), [0, 1, 2, -1], "matched ideal steps")
		_bench("timePearl", { "time": 10 })
		Lab.add_ore("timePearl", "time")
		Lab.perform_step("compression", 90.0)
		assert_eq(_clue_marks(Lab.finish_run()["clues"]), [["near", "lower"]], "over the band reads lower")
	)

	run_case("off_book_step_that_shifts_the_book_is_not_a_change", func():
		# healingBurst hides distil (ideal 2); performed first it skips ideal
		# 0-1, so the base compress then matches nothing.
		_bench("healingBurst", { "life": 10, "time": 10 })
		Lab.add_ore("healingBurst", "life")
		Lab.add_ore("healingBurst", "time")
		Lab.perform_distil([500.0, 1900.0, 3300.0, 4700.0])
		Lab.perform_step("compression", 60.0)
		Lab.perform_step("heat", 35.0)
		var clues: Array = Lab.finish_run()["clues"]
		assert_eq(_clue_marks(clues), [["hit", null], ["none", null], ["hit", null]], "distil scored, not a change")
		assert_eq(Lab.step_specificity("healingBurst", 2), "", "nothing learned")
	)

	run_case("off_book_match_learns_vague_like_a_granted_step", func():
		_bench("timePearl", {})
		Lab.grant_steps("timePearl", [1], "vague")
		var granted: Dictionary = GameState.deep_copy(GameState.state["lab"]["known"])
		_bench("timePearl", { "time": 10 })
		Lab.add_ore("timePearl", "time")
		Lab.perform_step("compression", 70.0)
		Lab.perform_grind([20.0, 20.0, 20.0])
		var result := Lab.finish_run()
		assert_eq(result["clues"][1]["learned"], "vague", "clue marks the lesson")
		assert_eq(GameState.state["lab"]["known"], granted, "same knowledge as a vague grant")
		assert_eq(Lab.known_procedure("timePearl")[1]["knowledge"], "vague", "book shows it vague")
	)

	run_case("three_in_band_hits_make_a_vague_step_exact", func():
		_bench("timePearl", { "time": 20 })
		Lab.grant_steps("timePearl", [1], "vague")
		var entry: Dictionary = GameState.state["lab"]["known"]["timePearl"]
		for n in [1, 2, 3]:
			Lab.add_ore("timePearl", "time")
			Lab.perform_step("compression", 70.0)
			Lab.perform_grind([50.0, 50.0, 50.0])
			var clue: Dictionary = Lab.finish_run()["clues"][1]
			assert_eq([clue["clue"], clue["hits"]], ["hit", n], "hit %d counted" % n)
			if n < 3:
				assert_eq(entry["vagueHits"], { "1": n }, "vagueHits after %d" % n)
				assert_true(not clue.has("learned"), "not yet exact")
		assert_eq(entry["steps"], { "1": "exact" }, "now exact")
		assert_eq(entry["vagueHits"], {}, "hits cleared")
		Lab.add_ore("timePearl", "time")
		Lab.perform_step("compression", 70.0)
		Lab.perform_grind([10.0, 10.0, 10.0])
		Lab.finish_run()
		assert_eq(entry["steps"], { "1": "exact" }, "exact never drops")
	)

	run_case("bonus_rolls_only_at_or_above_best_rank", func():
		_bench("timePearl", { "time": 15 })
		GameData.LAB["bonus"]["chance"] = 1.0
		GameState.state["lab"]["bestRanks"]["timePearl"] = 5
		Lab.add_ore("timePearl", "time")
		assert_eq(Lab.finish_run()["bonus"], null, "rank 1 under best 5: no roll")
		_perfect_time_pearl()
		assert_true(Lab.finish_run()["bonus"] != null, "rank 5 at best 5 rolls")
		GameData.LAB["bonus"]["chance"] = 0.0
		_perfect_time_pearl()
		assert_eq(Lab.finish_run()["bonus"], null, "chance from data")
	)

	run_case("all_three_bonus_types_reachable_with_seeded_rng", func():
		var xp_reward := int(GameData.RECIPES["timePearl"]["xpReward"])
		var xp_gained := [0]
		var perfect_run_with_bonus := func(bonus_type: String) -> bool:
			var player := _bench("timePearl", { "time": 10 })
			GameData.LAB["bonus"]["chance"] = _real_bonus_chance
			var xp_before := int(player["craftingXP"])
			_perfect_time_pearl()
			var result := Lab.finish_run()
			xp_gained[0] = int(player["craftingXP"]) - xp_before
			return result["bonus"] == bonus_type
		assert_true(SeedSearch.find_seed_for(200, perfect_run_with_bonus.bind("extraItem")) >= 0, "extraItem reachable")
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], { "5": 2 }, "two items at the run's rank")
		assert_eq(GameState.state["player"]["craftedCounts"]["timePearl"], 2, "both counted")
		assert_eq(xp_gained[0], xp_reward, "XP unchanged")
		assert_true(SeedSearch.find_seed_for(200, perfect_run_with_bonus.bind("calcRefund")) >= 0, "calcRefund reachable")
		assert_eq(_calc("time"), 7, "2 of 5 calc (half, floored) back in real calc")
		assert_eq(Crafting.inventory_qty("timePearl"), 1, "one item")
		assert_true(SeedSearch.find_seed_for(200, perfect_run_with_bonus.bind("xp")) >= 0, "xp reachable")
		assert_eq(xp_gained[0], roundi(xp_reward * 1.5), "XP x1.5 on the run")
	)

	run_case("really_bad_runs_sometimes_get_a_flavour_line", func():
		var lines: Array = GameData.LAB["badRun"]["lines"]
		var seed := SeedSearch.find_seed_for(200, func():
			_bench("timePearl", { "time": 10 })
			Lab.add_ore("timePearl", "time")
			var flavour = Lab.finish_run()["flavour"]
			return flavour != null and lines.has(flavour))
		assert_true(seed >= 0, "a score-0 run can draw a line")
		var silent := SeedSearch.find_seed_for(200, func():
			_bench("timePearl", { "time": 10 })
			Lab.add_ore("timePearl", "time")
			return Lab.finish_run()["flavour"] == null)
		assert_true(silent >= 0, "but not always")
		for i in 20:
			_bench("timePearl", { "time": 10 })
			_perfect_time_pearl()
			assert_eq(Lab.finish_run()["flavour"], null, "a good run never gets one")
	)


func _stock(key: String) -> Dictionary:
	return GameState.state["player"]["inventory"].get(key, {})


# A finished-able timePearl run that scores 40 raw (rank 3 with a level 2 Lady).
func _rank_three_time_pearl() -> void:
	Lab.add_ore("timePearl", "time")
	Lab.perform_step("compression", 70.0)
	Lab.perform_step("heat", 25.0)


# Insights (recipe-acquisition spec § Insight roll): rolled on a finished
# manual run only, learned through the same clue path as an unknown step.
func _register_insight_cases() -> void:
	run_case("finished_run_rolls_insight_into_the_result", func():
		_bench("timePearl", { "time": 10 })
		_set_insight_chance(1.0, 0.0)
		Lab.add_ore("timePearl", "time")
		Lab.perform_step("compression", 70.0)
		var result := Lab.finish_run()
		assert_eq([result["insight"]["rung"], result["insight"]["step"]], ["hint2", 1], "insight in the result")
		assert_eq(Lab.step_specificity("timePearl", 1), "insight", "and in knowledge")
		_set_insight_chance(0.0, 0.0)
		Lab.add_ore("timePearl", "time")
		assert_eq(Lab.finish_run()["insight"], null, "a miss reads null")
	)

	run_case("cracked_abandoned_and_batch_never_roll", func():
		_bench("timePearl", { "time": 40 })
		_perfect_time_pearl()
		Lab.finish_run()
		var before: Dictionary = GameState.deep_copy(GameState.state["lab"]["known"])
		_set_insight_chance(1.0, 0.0)
		Lab.add_ore("timePearl", "time")
		assert_true(Lab.perform_step("compression", 99.0).get("cracked", false), "cracked")
		Lab.add_ore("timePearl", "time")
		Lab.abandon_run()
		assert_true(Lab.batch("timePearl", 2)["ok"], "batch ran")
		assert_eq(GameState.state["lab"]["known"], before, "no insight")
	)

	run_case("insight_learns_vague_then_exact_through_the_clue_path", func():
		_bench("timePearl", { "time": 30 })
		Lab.grant_steps("timePearl", [1], "insight")
		Lab.add_ore("timePearl", "time")
		Lab.perform_step("compression", 70.0)
		Lab.perform_grind([20.0, 20.0, 20.0])
		var first: Dictionary = Lab.finish_run()["clues"][1]
		assert_eq([first["clue"], first["learned"]], ["changed", "vague"], "performing it makes it vague")
		assert_eq(Lab.known_procedure("timePearl")[1]["knowledge"], "vague", "book shows it vague")
		for n in [1, 2, 3]:
			Lab.add_ore("timePearl", "time")
			Lab.perform_step("compression", 70.0)
			Lab.perform_grind([50.0, 50.0, 50.0])
			var clue: Dictionary = Lab.finish_run()["clues"][1]
			assert_eq([clue["clue"], clue["hits"]], ["hit", n], "hit %d counted" % n)
		assert_eq(Lab.step_specificity("timePearl", 1), "exact", "exact after 3 hits")
	)

	run_case("pending_insight_step_shows_no_band", func():
		_bench("timePearl", { "time": 10 })
		Lab.grant_steps("timePearl", [1], "insight")
		Lab.add_ore("timePearl", "time")
		Lab.perform_step("compression", 70.0)
		var pending := Lab.pending_step("grinding")
		assert_eq(pending["knowledge"], "insight", "the insight step is next")
		assert_eq(Lab.step_region("timePearl", pending), {}, "gauge shows no band")
		Lab.abandon_run()
	)


func _register_batch_rewind_cases() -> void:
	run_case("batch_needs_a_hand_performed_recipe", func():
		_bench("timePearl", { "time": 30 })
		assert_true(not Lab.batch("timePearl", 2)["ok"], "refused before a manual run")
		assert_eq(_calc("time"), 30, "nothing spent")
		_perfect_time_pearl()
		Lab.finish_run()
		assert_true(Lab.batch("timePearl", 2)["ok"], "allowed once performed")
	)

	run_case("batch_crafts_at_best_rank_for_base_calc_and_never_fails", func():
		var player := _bench("timePearl", { "time": 100 })
		Crafting.inventory_add(ActiveEffects.LADY, 2, 1)
		Lab.use_effect(ActiveEffects.LADY)
		_rank_three_time_pearl()
		Lab.finish_run()
		player["activeEffects"] = []
		var calc_before := _calc("time")
		var xp_before := int(player["craftingXP"])
		var crafted_before := int(player["craftedCounts"].get("timePearl", 0))
		var result := Lab.batch("timePearl", 4)
		assert_eq([result["items"], result["rank"]], [4, 3], "4 items at best rank 3")
		assert_eq(_stock("timePearl"), { "3": 5 }, "filed at tier 3 alongside the run's")
		assert_eq(calc_before - _calc("time"), 20, "base calc 5 x 4")
		assert_eq(int(player["craftingXP"]) - xp_before, int(GameData.RECIPES["timePearl"]["xpReward"]) * 4, "xpReward per item")
		assert_eq(int(player["craftedCounts"]["timePearl"]) - crafted_before, 4, "filed through Crafting")
		assert_true(not Lab.batch("timePearl", 100)["ok"], "short of calc refused")
		assert_true(not Lab.batch("timePearl", 0)["ok"], "count < 1 refused")
	)

	run_case("batch_never_fires_the_manual_run_hook", func():
		_bench("timePearl", { "time": 30 })
		_perfect_time_pearl()
		Lab.finish_run()
		var heard := []
		var listener := func(payload: Dictionary): heard.append(payload)
		EventBus.lab_run_completed.connect(listener)
		Lab.batch("timePearl", 3)
		EventBus.lab_run_completed.disconnect(listener)
		assert_eq(heard, [], "no hook for batch")
	)

	run_case("multi_variant_gated_at_best_rank_three", func():
		_bench("healingBurst", { "life": 100, "time": 100 })
		GameState.state["lab"]["performedOnce"].append("healingBurst")
		GameState.state["lab"]["bestRanks"]["healingBurst"] = 2
		assert_true(not Crafting.multi_craft_available("healingBurst"), "rank 2: no multi")
		Lab.batch("healingBurst", 1, true)
		assert_eq(_stock("healingBurst"), { "2": 1 }, "multi ignored below rank 3")
		GameState.state["lab"]["bestRanks"]["healingBurst"] = 3
		assert_true(Crafting.multi_craft_available("healingBurst"), "rank 3: multi")
		var result := Lab.batch("healingBurst", 2, true)
		assert_true(result["multi"], "multi batch")
		assert_eq(_stock(Crafting.inventory_key("healingBurst", true)), { "3": 2 }, "filed under the _multi key")
	)

	run_case("rewind_point_opens_at_the_first_jar_tap", func():
		_bench("timePearl", { "time": 10 })
		assert_true(not Lab.has_rewind_point(), "none before a run")
		Lab.add_ore("timePearl", "time")
		assert_true(Lab.has_rewind_point(), "taken at the first tap")
		assert_eq(GameState.state["lab"]["lastCraft"]["calcSpent"], { "time": 5 }, "spend noted")
	)

	run_case("rewind_refused_without_an_item_or_loaded_complication", func():
		_bench("timePearl", { "time": 10 })
		_perfect_time_pearl()
		Lab.finish_run()
		assert_true(not Lab.can_rewind(), "can't pay")
		assert_true(not Lab.rewind()["ok"], "refused")
		assert_eq(_stock("timePearl"), { "5": 1 }, "item kept")
		assert_eq(_calc("time"), 5, "calc stays spent")
	)

	run_case("rewind_consumes_exactly_one_item_or_charge", func():
		_bench("timePearl", { "time": 10 })
		Crafting.inventory_add("rewind", 1, 2)
		_perfect_time_pearl()
		Lab.finish_run()
		assert_true(Lab.rewind()["ok"], "rewound with an item")
		assert_eq(Crafting.inventory_qty("rewind"), 1, "one item spent")
		assert_true(not Lab.rewind()["ok"], "point used up")
		assert_eq(Crafting.inventory_qty("rewind"), 1, "a refused rewind spends nothing")
		var player: Dictionary = GameState.state["player"]
		Crafting.inventory_remove("rewind", 1)
		player["dial"] = Fixtures.dial_with_loaded("rewind", 1, 5)
		_perfect_time_pearl()
		Lab.finish_run()
		assert_true(Lab.rewind()["ok"], "rewound with a Dial charge")
		assert_eq(int(player["dial"]["currentCharge"]), 4, "one Dial charge spent")
	)

	run_case("rewind_restores_calc_items_effects_and_keeps_xp_and_knowledge", func():
		var player := _bench("timePearl", { "time": 10 })
		Crafting.inventory_add("rewind", 1, 1)
		Crafting.inventory_add(ActiveEffects.LADY, 2, 1)
		var lab: Dictionary = GameState.state["lab"]
		var xp_before := int(player["craftingXP"])
		_rank_three_time_pearl()
		Lab.use_effect(ActiveEffects.LADY)
		Lab.finish_run()
		var xp_after := int(player["craftingXP"])
		var known_after: Dictionary = lab["known"].duplicate(true)
		assert_true(Lab.rewind()["ok"], "rewound")
		assert_eq(_calc("time"), 10, "calc back")
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "item gone")
		assert_eq(_stock(ActiveEffects.LADY), { "2": 1 }, "Lady used mid-run comes back")
		assert_eq(player["activeEffects"], [], "effects as before the run")
		assert_eq(Lab.active_run(), null, "no run open")
		assert_true(xp_after > xp_before and int(player["craftingXP"]) == xp_after, "XP kept")
		assert_eq([lab["bestRanks"]["timePearl"], lab["performedOnce"], lab["known"]], [3, ["timePearl"], known_after], "knowledge kept")
	)

	run_case("rewind_mid_run_refunds_and_closes_it", func():
		_bench("timePearl", { "time": 10 })
		Crafting.inventory_add("rewind", 1, 1)
		Lab.add_ore("timePearl", "time")
		Lab.add_ore("timePearl", "time")
		assert_true(Lab.rewind()["ok"], "rewound mid-run")
		assert_eq(_calc("time"), 10, "both taps refunded")
		assert_eq(Lab.active_run(), null, "run closed")
	)

	run_case("rewind_undoes_a_batch_and_refuses_once_its_items_are_gone", func():
		_bench("timePearl", { "time": 30 })
		Crafting.inventory_add("rewind", 1, 2)
		_perfect_time_pearl()
		Lab.finish_run()
		Lab.batch("timePearl", 3)
		assert_true(Lab.rewind()["ok"], "batch rewound")
		assert_eq([_calc("time"), _stock("timePearl")], [25, { "5": 1 }], "batch calc back, run's item kept")
		Lab.batch("timePearl", 2)
		Crafting.inventory_remove("timePearl", 3)
		assert_true(not Lab.rewind()["ok"], "items sold or used: refused")
		assert_eq(Crafting.inventory_qty("rewind"), 1, "nothing spent")
	)

	run_case("lab_rewind_point_round_trips_through_save", func():
		_bench("timePearl", { "time": 10 })
		_perfect_time_pearl()
		Lab.finish_run()
		var before: Dictionary = GameState.deep_copy(GameState.state["lab"]["lastCraft"])
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"], "saved")
		GameState.reset()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"], "loaded")
		SaveManager.delete_slot(TEST_SLOT)
		assert_eq(GameState.state["lab"]["lastCraft"], before, "point survives with int types")
	)

	run_case("skill_override_replaces_player_skill_only_while_set", func():
		_bench("timePearl", {})
		assert_eq(GameState.state["lab"]["skillOverride"], null, "unset on a new game")
		assert_almost_eq(Lab.band_half_width("timePearl"), 6.0, 0.0001, "player's skill 0")
		Lab.set_skill_override(5)
		assert_eq(Lab.effective_skill(), 5, "override used")
		assert_almost_eq(Lab.band_half_width("timePearl"), 6.0 * 1.4, 0.0001, "override widens the band")
		Lab.set_skill_override(999)
		assert_eq(Lab.effective_skill(), int(GameData.LAB["debug"]["skillMax"]), "clamped to skillMax")
		Lab.clear_skill_override()
		GameState.state["player"]["craftingSkill"] = 2
		assert_eq(Lab.effective_skill(), 2, "unset: player's skill")
		GameState.state["lab"].erase("skillOverride")
		assert_eq(Lab.effective_skill(), 2, "key absent (older save): player's skill")
	)

	run_case("revoke_recipe_forgets_it_and_its_steps", func():
		_bench("timePearl", { "time": 10 })
		Lab.grant_recipe("timePearl")
		Lab.grant_steps("timePearl", [0], "exact")
		Lab.add_ore("timePearl", "time")
		assert_true(not Lab.revoke_recipe("timePearl")["ok"], "refused mid-run")
		Lab.abandon_run()
		assert_true(Lab.revoke_recipe("timePearl")["ok"], "revoked")
		assert_true(not Lab.is_known("timePearl"), "unknown")
		Lab.grant_recipe("timePearl")
		assert_eq(_steps("timePearl"), {}, "re-grant starts at base")
	)

	run_case("set_best_rank_sets_lowers_clamps_and_clears", func():
		_fresh()
		var best: Dictionary = GameState.state["lab"]["bestRanks"]
		Lab.set_best_rank("timePearl", 4)
		assert_eq(best["timePearl"], 4, "set")
		Lab.set_best_rank("timePearl", 2)
		assert_eq(best["timePearl"], 2, "lowered")
		Lab.set_best_rank("timePearl", 99)
		assert_eq(best["timePearl"], 5, "clamped to top rank")
		Lab.set_best_rank("timePearl", 0)
		assert_true(not best.has("timePearl"), "0 clears")
		assert_true(not Lab.set_best_rank("nope", 3)["ok"], "unknown recipe refused")
	)

	run_case("refill_calc_tops_up_every_ore_type", func():
		_fresh()
		var target := int(GameData.LAB["debug"]["refillCalc"])
		GameState.state["player"]["orichalchum"]["time"] = target + 7
		Lab.refill_calc()
		for ore_type in GameData.ORE_TYPES.keys():
			var expected := target + 7 if ore_type == "time" else target
			assert_eq(_calc(ore_type), expected, "%s topped up, never lowered" % ore_type)
	)

	run_case("skill_override_round_trips_through_save_as_int", func():
		_fresh()
		Lab.set_skill_override(4)
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"], "saved")
		GameState.reset()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"], "loaded")
		SaveManager.delete_slot(TEST_SLOT)
		assert_eq(typeof(GameState.state["lab"]["skillOverride"]), TYPE_INT, "int after load")
		assert_eq(Lab.effective_skill(), 4, "override kept")
	)

