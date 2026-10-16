extends "res://tests/test_base.gd"

const SeedSearch := preload("res://tests/support/seed_search.gd")

# systems/bench_prototype.gd's shared core (.scratch/lab-revamp/spec.md
# §Shared core rules), driven through the public API.

func _fresh() -> Dictionary:
	GameState.reset()
	return GameState.state["benchPrototype"]


func _data() -> Dictionary:
	return GameData.BENCH_PROTOTYPE


func _run(recipe_id: String, score: int) -> Dictionary:
	BenchPrototype.begin_run(recipe_id)
	return BenchPrototype.finish_run(score)


# Performs one apparatus step dead on value, with the raw input its gauge
# reports.
func _perform_at(apparatus: String, value: float) -> Dictionary:
	match apparatus:
		"grinding":
			var readings := []
			for i in int(_data()["gauges"]["grinding"]["strokes"]):
				readings.append(value)
			return BenchPrototype.perform_grind(readings)
		"distilling":
			return BenchPrototype.perform_distil(_distil_taps(value))
	return BenchPrototype.perform_step(apparatus, value)


# Plays steps as [ore type or "", apparatus, value]: a jar tap first when
# an ore is named, then the step dead on value. Returns the last result.
func _play(recipe_id: String, steps: Array) -> Dictionary:
	var result := {}
	for step in steps:
		if step[0] != "":
			BenchPrototype.add_ore(recipe_id, step[0])
		result = _perform_at(step[1], step[2])
	return result


# A recipe's ideal procedure as _play() steps, its ore tapped in first.
func _ideal_steps(recipe_id: String) -> Array:
	return BenchPrototype.procedure_def(recipe_id)["ideal"].map(func(s): return [s.get("ore", ""), s["apparatus"], float(s["target"])])


# One tap per drip, each as the drip passes value.
func _distil_taps(value: float) -> Array:
	var g: Dictionary = _data()["gauges"]["distilling"]
	var taps := []
	for i in int(g["drips"]):
		taps.append(i * float(g["beatMsec"]) + value / 100.0 * float(g["fallMsec"]))
	return taps


# Everything in GameState.state except the prototype's own tree.
func _outside_state() -> Dictionary:
	var copy: Dictionary = GameState.deep_copy(GameState.state)
	copy.erase("benchPrototype")
	return copy


func run() -> void:
	run_case("new_state_seeds_from_data_and_is_pure", func():
		var root := _fresh()
		assert_eq(root["pool"], _data()["poolSeed"], "pool seeds from data")
		for recipe_id in _data()["roster"]:
			assert_eq(root["bestRanks"][recipe_id], 0, "%s starts unranked" % recipe_id)
			for hint in BenchPrototype.hints(recipe_id):
				assert_eq(root["hintLevels"][recipe_id][hint["id"]], "off", "%s.%s starts off" % [recipe_id, hint["id"]])
			assert_eq(root["hintLevels"][recipe_id].size(), BenchPrototype.hints(recipe_id).size(), "%s: one level per hint" % recipe_id)
		var parsed = JSON.parse_string(JSON.stringify(root))
		assert_true(parsed is Dictionary, "benchPrototype survives a JSON round-trip (pure data)")
		root["pool"]["life"] = 1
		assert_eq(_data()["poolSeed"]["life"], 40, "seeding doesn't alias GameData")
	)

	run_case("score_maps_to_rank_per_thresholds", func():
		_fresh()
		var cases := { 0: 1, 39: 1, 40: 2, 59: 2, 60: 3, 74: 3, 75: 4, 89: 4, 90: 5, 100: 5 }
		for score in cases.keys():
			assert_eq(BenchPrototype.rank_for_score(score), cases[score], "score %d" % score)
	)

	run_case("run_spends_base_calc_logs_item_and_sets_best_rank", func():
		var root := _fresh()
		Rng.set_seed(1)
		var result := _run("healingSalve", 62)
		assert_true(result["ok"], "run finishes")
		var s: Dictionary = root
		assert_eq(s["bestRanks"]["healingSalve"], 3, "score 62 sets rank 3")
		var entry: Dictionary = s["ledger"][0]
		assert_eq(entry["kind"], "run")
		assert_eq(entry["score"], 62)
		assert_eq(entry["rank"], 3)
		assert_true(entry.has("durationMsec") and entry["durationMsec"] >= 0, "duration logged")
		assert_true(entry.has("bonus"), "bonus field logged")
		var refunded: int = 0 if entry["bonus"] != "calcRefund" else 1
		assert_eq(s["pool"]["life"], 40 - 3 + refunded, "base calc spent")
	)

	run_case("best_rank_only_rises", func():
		var root := _fresh()
		_run("timePearl", 80)
		_run("timePearl", 10)
		assert_eq(root["bestRanks"]["timePearl"], 4, "a worse run doesn't lower best rank")
		_run("timePearl", 95)
		assert_eq(root["bestRanks"]["timePearl"], 5, "a better run raises it")
	)

	run_case("begin_refuses_without_calc_or_while_run_open", func():
		var root := _fresh()
		root["pool"]["time"] = 2
		assert_true(not BenchPrototype.begin_run("timePearl")["ok"], "can't afford 3 time")
		assert_true(BenchPrototype.begin_run("healingSalve")["ok"])
		assert_true(not BenchPrototype.begin_run("healingSalve")["ok"], "one run at a time")
	)

	run_case("finish_with_zero_steps_scores_zero_and_keeps_calc_spent", func():
		var root := _fresh()
		Rng.set_seed(2)
		BenchPrototype.begin_run("healingBurst")
		var result := BenchPrototype.finish_procedure_run()
		assert_true(result["ok"], "Finish closes a run with no steps")
		assert_eq(result["entry"]["score"], 0, "no steps scores 0")
		assert_eq(result["entry"]["rank"], 1)
		assert_eq(result["entry"]["steps"], [])
		assert_eq(root["pool"], { "life": 38, "time": 38 }, "calc stays spent (default bonus refunds nothing)")
		assert_eq(root["activeRun"], null)
		assert_true(not BenchPrototype.finish_procedure_run()["ok"], "nothing left to finish")
	)

	run_case("bonus_never_rolls_below_best_rank", func():
		var root := _fresh()
		root["bestRanks"]["healingSalve"] = 4
		for i in range(30):
			Rng.set_seed(i)
			var entry: Dictionary = _run("healingSalve", 50)["entry"]
			assert_eq(entry["bonus"], null, "rank 2 < best 4 never rolls a bonus (seed %d)" % i)
			BenchPrototype.refill_pool()
	)

	run_case("bonus_extra_item_adds_an_item", func():
		var root := _fresh()
		BenchPrototype.set_bonus_type("extraItem")
		var seed := SeedSearch.find_seed_for(200, func(): return _run("healingSalve", 50)["entry"]["bonus"] != null)
		assert_true(seed != -1, "a 30% bonus should land within 200 seeds")
		var entry: Dictionary = root["ledger"][-1]
		assert_eq(entry["bonus"], "extraItem")
		assert_eq(entry["items"], 2, "+1 item")
		assert_eq(entry["xp"], _data()["baseXp"], "XP unscaled")
	)

	run_case("bonus_calc_refund_returns_half_the_calc", func():
		var root := _fresh()
		BenchPrototype.set_bonus_type("calcRefund")
		var seed := SeedSearch.find_seed_for(200, func(): return _run("healingBurst", 50)["entry"]["bonus"] != null)
		assert_true(seed != -1, "a bonus should land within 200 seeds")
		assert_eq(root["pool"], { "life": 39, "time": 39 }, "2 spent, floor(2 × 0.5) = 1 back per type")
		assert_eq(root["ledger"][-1]["items"], 1)
	)

	run_case("bonus_xp_scales_xp_display_only", func():
		var root := _fresh()
		BenchPrototype.set_bonus_type("xp")
		var xp_before: int = GameState.state["player"]["craftingXP"]
		var seed := SeedSearch.find_seed_for(200, func(): return _run("timePearl", 50)["entry"]["bonus"] != null)
		assert_true(seed != -1, "a bonus should land within 200 seeds")
		assert_eq(root["ledger"][-1]["xp"], roundi(_data()["baseXp"] * 1.5), "XP ×1.5")
		assert_eq(GameState.state["player"]["craftingXP"], xp_before, "real crafting XP untouched")
	)

	run_case("bonus_rate_is_roughly_thirty_percent", func():
		var root := _fresh()
		Rng.set_seed(42)
		var hits := 0
		for i in range(400):
			if _run("healingSalve", 95)["entry"]["bonus"] != null:
				hits += 1
			BenchPrototype.refill_pool()
			root["ledger"].clear()
		assert_true(hits > 80 and hits < 160, "~120 of 400 should roll a bonus, got %d" % hits)
	)

	run_case("flavour_only_below_threshold_about_one_in_three", func():
		var root := _fresh()
		Rng.set_seed(7)
		var hits := 0
		for i in range(300):
			var entry: Dictionary = _run("healingSalve", 14)["entry"]
			if entry["flavour"] != null:
				hits += 1
				assert_true(_data()["badRun"]["lines"].has(entry["flavour"]), "flavour comes from data")
			var high: Dictionary = _run("healingSalve", 15)["entry"]
			assert_eq(high["flavour"], null, "score 15 never shows flavour")
			BenchPrototype.refill_pool()
			root["ledger"].clear()
		assert_true(hits > 60 and hits < 140, "~100 of 300 should show flavour, got %d" % hits)
	)

	run_case("batch_spends_base_calc_per_item_and_logs_n_at_best_rank", func():
		var root := _fresh()
		assert_true(not BenchPrototype.batch("healingSalve", 5)["ok"], "no batch before a rank exists")
		_run("healingSalve", 76)
		var s: Dictionary = root
		var pool_before: int = s["pool"]["life"]
		var result := BenchPrototype.batch("healingSalve", 5)
		assert_true(result["ok"])
		assert_eq(s["pool"]["life"], pool_before - 15, "5 × 3 life")
		var entry: Dictionary = s["ledger"][-1]
		assert_eq(entry["kind"], "batch")
		assert_eq(entry["items"], 5)
		assert_eq(entry["rank"], 4, "batch runs at best rank")
		assert_eq(entry["xp"], _data()["baseXp"] * 5, "XP ×1.0")
		assert_eq(entry["bonus"], null, "batch never rolls a bonus")
		assert_true(not BenchPrototype.batch("healingSalve", 10)["ok"], "can't afford 30 more life")
	)

	run_case("refill_restores_the_pool", func():
		var root := _fresh()
		_run("healingBurst", 50)
		BenchPrototype.refill_pool()
		assert_eq(root["pool"], _data()["poolSeed"])
	)

	run_case("rewind_restores_state_exactly", func():
		var root := _fresh()
		_run("healingSalve", 45)
		BenchPrototype.set_hint_level("timePearl", "grindBetween", "vague")
		var before: Dictionary = GameState.deep_copy(root)
		before.erase("snapshots")
		_run("healingSalve", 95)
		BenchPrototype.batch("healingSalve", 5)
		BenchPrototype.rewind()
		BenchPrototype.rewind()
		var after: Dictionary = GameState.deep_copy(root)
		after.erase("snapshots")
		assert_eq(after, before, "two rewinds undo the batch then the run")
	)

	run_case("known_recipes_start_from_data_in_roster_order", func():
		var root := _fresh()
		assert_eq(_data()["knownAtStart"], ["healingSalve"], "healingSalve known at start")
		assert_eq(BenchPrototype.known_recipes(), ["healingSalve"])
		assert_true(BenchPrototype.is_known("healingSalve"))
		assert_true(not BenchPrototype.is_known("timePearl"))
		root["known"].append("x")
		assert_eq(_data()["knownAtStart"], ["healingSalve"], "seeding doesn't alias GameData")
	)

	run_case("set_known_toggles_and_the_list_follows_roster_order", func():
		_fresh()
		assert_true(BenchPrototype.set_known("healingBurst", true)["ok"])
		assert_true(BenchPrototype.set_known("timePearl", true)["ok"])
		assert_eq(BenchPrototype.known_recipes(), ["healingSalve", "timePearl", "healingBurst"], "roster order, not toggle order")
		BenchPrototype.set_known("timePearl", true)
		assert_eq(BenchPrototype.known_recipes().size(), 3, "re-marking known doesn't duplicate")
		assert_true(BenchPrototype.set_known("healingSalve", false)["ok"])
		assert_eq(BenchPrototype.known_recipes(), ["timePearl", "healingBurst"])
		assert_true(not BenchPrototype.set_known("bogus", true)["ok"], "unknown recipe refused")
		assert_true(not BenchPrototype.known_recipes().has("bogus"))
	)

	run_case("max_batch_is_what_the_pool_affords", func():
		var root := _fresh()
		assert_eq(BenchPrototype.max_batch("healingSalve"), 13, "40 life / 3")
		assert_eq(BenchPrototype.max_batch("healingBurst"), 20, "40 life / 2, 40 time / 2")
		root["pool"]["time"] = 1
		assert_eq(BenchPrototype.max_batch("healingBurst"), 0, "short on time")
	)

	run_case("an_old_shape_save_restarts_the_prototype_fresh", func():
		GameState.reset()
		var raw = JSON.parse_string(JSON.stringify(GameState.state))
		raw["benchPrototype"] = { "activeSlice": "procedure", "slices": {} }
		assert_true(SaveManager._load_save_dict(raw)["ok"], "save loads")
		assert_eq(GameState.state["benchPrototype"]["known"], ["healingSalve"], "fresh state")
	)

	run_case("rewind_leaves_debug_settings_alone", func():
		var root := _fresh()
		BenchPrototype.begin_run("timePearl")
		BenchPrototype.set_skill_override(7)
		BenchPrototype.set_bonus_type("xp")
		BenchPrototype.rewind()
		assert_eq(root["skillOverride"], 7)
		assert_eq(root["bonusType"], "xp")
	)

	run_case("rewind_mid_run_refunds_and_closes_the_run", func():
		var root := _fresh()
		BenchPrototype.begin_run("timePearl")
		assert_true(BenchPrototype.rewind()["ok"])
		assert_eq(root["activeRun"], null)
		assert_eq(root["pool"], _data()["poolSeed"])
		assert_true(not BenchPrototype.rewind()["ok"], "nothing left to rewind")
	)

	run_case("skill_defaults_to_real_crafting_skill_and_override_is_sandboxed", func():
		_fresh()
		GameState.state["player"]["craftingSkill"] = 4
		assert_eq(BenchPrototype.effective_skill(), 4, "defaults to real skill")
		BenchPrototype.set_skill_override(15)
		assert_eq(BenchPrototype.effective_skill(), 10, "override clamps to 10")
		assert_almost_eq(BenchPrototype.skill_multiplier(), 1.8, 0.0001, "1 + 0.08 × 10")
		BenchPrototype.set_skill_override(0)
		assert_eq(BenchPrototype.effective_skill(), 0)
		assert_eq(GameState.state["player"]["craftingSkill"], 4, "real skill untouched")
		BenchPrototype.clear_skill_override()
		assert_eq(BenchPrototype.effective_skill(), 4)
	)

	run_case("hint_levels_are_per_recipe_per_hint", func():
		var root := _fresh()
		assert_true(BenchPrototype.set_hint_level("healingBurst", "heatLower", "exact")["ok"])
		assert_true(not BenchPrototype.set_hint_level("healingBurst", "heatLower", "loud")["ok"], "unknown level refused")
		assert_true(not BenchPrototype.set_hint_level("healingBurst", "heatHigher", "exact")["ok"], "another recipe's hint refused")
		assert_eq(root["hintLevels"]["healingBurst"], { "distilBetween": "off", "heatLower": "exact" })
	)

	run_case("every_authored_hint_has_vague_and_exact_forms", func():
		_fresh()
		var ids := []
		for recipe_id in _data()["roster"]:
			var hints := BenchPrototype.hints(recipe_id)
			assert_eq(hints.size(), 2, "%s: both table improvements authored" % recipe_id)
			for hint in hints:
				ids.append(hint["id"])
				for level in ["vague", "exact"]:
					assert_true(not str(hint[level]["note"]).is_empty(), "%s.%s has a note" % [hint["id"], level])
		assert_eq(ids, ["heatHigher", "distilFinish", "compressLonger", "grindBetween", "distilBetween", "heatLower"])
	)

	run_case("hints_reshape_the_known_procedure", func():
		_fresh()
		var salve := BenchPrototype.known_procedure("healingSalve")
		assert_eq(salve.map(func(s): return s["knowledge"]), ["base", "base"], "no hints: base only, distil hidden")
		assert_eq(salve[1]["target"], 50.0)
		BenchPrototype.set_hint_level("healingSalve", "heatHigher", "exact")
		BenchPrototype.set_hint_level("healingSalve", "distilFinish", "vague")
		salve = BenchPrototype.known_procedure("healingSalve")
		assert_eq(salve.map(func(s): return s["apparatus"]), ["grinding", "heat", "distilling"], "distil appended")
		assert_eq(salve[1]["target"], 62.0, "exact hint corrects the heat target")
		assert_eq(salve[1]["knowledge"], "exact")
		assert_eq(salve[0]["calc"], { "life": 3 }, "base calc stays on its step")
		assert_eq(salve[2]["knowledge"], "vague")
		assert_true(not salve[2].has("calc"), "inserted step costs nothing")
		assert_eq(salve[2]["note"], BenchPrototype.hint_def("healingSalve", "distilFinish")["vague"]["note"], "vague note shown")
		BenchPrototype.set_hint_level("timePearl", "grindBetween", "exact")
		assert_eq(BenchPrototype.known_procedure("timePearl").map(func(s): return s["apparatus"]), ["compression", "grinding", "heat"], "grind inserted between")
		BenchPrototype.set_hint_level("healingBurst", "distilBetween", "vague")
		assert_eq(BenchPrototype.known_procedure("healingBurst").map(func(s): return s["apparatus"]), ["grinding", "compression", "distilling", "heat"], "distil inserted before heat")
		BenchPrototype.set_hint_level("healingSalve", "distilFinish", "off")
		assert_eq(BenchPrototype.known_procedure("healingSalve").size(), 2, "off hides the step again")
	)

	run_case("vague_region_always_contains_the_true_band", func():
		_fresh()
		for skill in range(0, 11):
			BenchPrototype.set_skill_override(skill)
			for recipe_id in _data()["roster"]:
				var ideal: Array = BenchPrototype.procedure_def(recipe_id)["ideal"]
				var half := BenchPrototype.band_half_width(recipe_id)
				for hint in BenchPrototype.hints(recipe_id):
					var target := float(ideal[int(hint["step"])]["target"])
					for level in ["vague", "exact"]:
						BenchPrototype.set_hint_level(recipe_id, hint["id"], level)
						var step: Dictionary = BenchPrototype.known_procedure(recipe_id).filter(func(s): return s.get("hintId") == hint["id"])[0]
						var region := BenchPrototype.step_region(recipe_id, step)
						var low := maxf(0.0, target - half)
						var high := minf(100.0, target + half)
						var label := "%s.%s %s at skill %d" % [recipe_id, hint["id"], level, skill]
						if level == "exact":
							assert_true(is_equal_approx(region["low"], low) and is_equal_approx(region["high"], high) and not region["vague"], label + ": true band")
						else:
							assert_true(region["low"] <= low and region["high"] >= high and region["vague"], label + ": region contains band")
							assert_true(region["high"] - region["low"] > high - low, label + ": region is wider")
	)

	run_case("all_hints_exact_and_a_perfect_run_reaches_rank_5", func():
		var root := _fresh()
		BenchPrototype.set_skill_override(0)
		for recipe_id in _data()["roster"]:
			for hint in BenchPrototype.hints(recipe_id):
				BenchPrototype.set_hint_level(recipe_id, hint["id"], "exact")
			_play(recipe_id, _ideal_steps(recipe_id))
			var result := BenchPrototype.finish_procedure_run()
			assert_eq(result["entry"]["score"], 100, "%s: perfect with every hint" % recipe_id)
			assert_eq(root["bestRanks"][recipe_id], 5, "%s reaches rank 5" % recipe_id)
	)

	run_case("no_prototype_action_touches_state_outside_bench_prototype", func():
		_fresh()
		var before := _outside_state()
		Rng.set_seed(3)
		BenchPrototype.set_skill_override(9)
		BenchPrototype.set_bonus_type("calcRefund")
		BenchPrototype.set_hint_level("timePearl", "compressLonger", "exact")
		_run("healingSalve", 92)
		_run("healingBurst", 5)
		BenchPrototype.batch("healingSalve", 5)
		_play("timePearl", [["time", "compression", 99.0]])
		_play("healingSalve", [["life", "grinding", 50.0], ["", "heat", 62.0]])
		BenchPrototype.finish_procedure_run()
		BenchPrototype.rewind()
		BenchPrototype.refill_pool()
		assert_eq(_outside_state(), before, "real inventory, XP, craftingSkill and bench state unchanged")
	)

	run_case("save_round_trip_preserves_bench_prototype_exactly", func():
		var root := _fresh()
		Rng.set_seed(5)
		BenchPrototype.set_skill_override(6)
		_run("healingSalve", 77)
		BenchPrototype.set_hint_level("healingSalve", "distilFinish", "vague")
		_play("healingSalve", [["life", "grinding", 50.0], ["", "heat", 62.0], ["", "distilling", 50.0]])
		BenchPrototype.finish_procedure_run()
		assert_true(root["notebook"]["healingSalve"][2].has("hits"), "a clue with hits to round-trip")
		BenchPrototype.batch("healingSalve", 5)
		BenchPrototype.begin_run("timePearl")
		var expected: Dictionary = GameState.deep_copy(root)
		var raw = JSON.parse_string(JSON.stringify(GameState.state))
		assert_true(SaveManager._load_save_dict(raw)["ok"], "save loads")
		assert_eq(GameState.state["benchPrototype"], expected, "ints restored, nothing lost")
	)

	run_case("validator_flags_roster_id_missing_its_recipe", func():
		_fresh()
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["bench_prototype"]["recipes"].erase("timePearl")
		var found := false
		for e in GameData.validate_tables(corrupted):
			if e.contains("bench_prototype") and e.contains("timePearl"):
				found = true
		assert_true(found, "a roster id with no recipes entry should be flagged")
	)

	run_case("step_accuracy_is_flat_in_band_then_falls_to_zero_at_twice_the_band", func():
		_fresh()
		assert_eq(BenchPrototype.step_accuracy(54.0, 50.0, 4.0), 1.0, "band edge counts as inside")
		assert_eq(BenchPrototype.step_accuracy(44.0, 50.0, 4.0), 0.5, "halfway to 2× scores 0.5")
		assert_eq(BenchPrototype.step_accuracy(58.0, 50.0, 4.0), 0.0, "2× the band scores 0")
		assert_eq(BenchPrototype.step_accuracy(90.0, 50.0, 4.0), 0.0, "never negative")
	)

	run_case("band_half_width_widens_with_skill", func():
		_fresh()
		BenchPrototype.set_skill_override(0)
		assert_eq(BenchPrototype.band_half_width("healingSalve"), 8.0, "skill 0 = base tolerance")
		BenchPrototype.set_skill_override(10)
		assert_true(is_equal_approx(BenchPrototype.band_half_width("healingSalve"), 14.4), "skill 10 = base × 1.8")
		var band := BenchPrototype.step_region("healingSalve", { "target": 50 })
		assert_true(is_equal_approx(band["low"], 35.6) and is_equal_approx(band["high"], 64.4), "known band is target ± half-width")
	)

	run_case("score_sums_weighted_accuracy_missing_scores_zero_extras_cost_five", func():
		_fresh()
		BenchPrototype.set_skill_override(0)
		var perfect := []
		for step in BenchPrototype.procedure_def("healingSalve")["ideal"]:
			var ores: Array = [step["ore"]] if step.has("ore") else []
			perfect.append({ "apparatus": step["apparatus"], "ores": ores, "value": step["target"] })
		assert_eq(BenchPrototype.score_procedure("healingSalve", perfect)["score"], 100, "perfect ideal scores 100")
		var missing := perfect.slice(0, 2)
		assert_eq(BenchPrototype.score_procedure("healingSalve", missing)["score"], 70, "missing distil (weight 30) scores 0")
		var extra := perfect.duplicate()
		extra.insert(1, { "apparatus": "compression", "value": 50.0 })
		extra.append({ "apparatus": "heat", "value": 50.0 })
		var scored := BenchPrototype.score_procedure("healingSalve", extra)
		assert_eq(scored["score"], 90, "two extra steps cost 5 each")
		assert_eq(scored["accuracies"][1], null, "extra step has no accuracy")
		var off := [{ "apparatus": "grinding", "ores": ["life"], "value": 50.0 }, { "apparatus": "heat", "value": 50.0 }]
		assert_eq(BenchPrototype.score_procedure("healingSalve", off)["score"], 50, "skill 0: heat 12 off a ±8 band = half accuracy")
		BenchPrototype.set_skill_override(10)
		assert_eq(BenchPrototype.score_procedure("healingSalve", off)["score"], 70, "skill 10: the wider band takes it in")
		assert_eq(BenchPrototype.score_procedure("healingSalve", [{ "apparatus": "compression", "value": 0.0 }])["score"], 0, "score clamps at 0")
	)

	run_case("base_only_procedure_executed_perfectly_caps_at_rank_2_to_3", func():
		_fresh()
		for skill in [0, 10]:
			BenchPrototype.set_skill_override(skill)
			for recipe_id in _data()["roster"]:
				var performed := []
				for step in BenchPrototype.known_procedure(recipe_id):
					performed.append({ "apparatus": step["apparatus"], "ores": step.get("calc", {}).keys(), "value": step["target"] })
				var rank := BenchPrototype.rank_for_score(BenchPrototype.score_procedure(recipe_id, performed)["score"])
				assert_true(rank >= 2 and rank <= 3, "%s at skill %d reaches rank %d" % [recipe_id, skill, rank])
	)

	run_case("jar_tap_spends_the_fixed_amount_and_the_first_opens_the_run", func():
		var root := _fresh()
		var s: Dictionary = root
		assert_true(not BenchPrototype.add_ore("healingSalve", "time")["ok"], "an off-recipe jar is inert")
		assert_eq(s["activeRun"], null, "an inert jar opens no run")
		assert_eq(s["snapshots"].size(), 0, "nor snapshots")
		assert_true(BenchPrototype.add_ore("healingSalve", "life")["ok"])
		assert_eq(s["pool"]["life"], 37, "one tap spends the recipe's 3 life")
		assert_eq(s["snapshots"].size(), 1, "the first tap snapshots")
		assert_eq(s["activeRun"]["recipeId"], "healingSalve", "and opens the run")
		BenchPrototype.add_ore("healingSalve", "life")
		assert_eq(s["pool"]["life"], 34, "each tap spends it again")
		assert_eq(s["activeRun"]["calcSpent"], { "life": 6 })
		assert_eq(s["snapshots"].size(), 1, "only the first tap snapshots")
		assert_true(not BenchPrototype.add_ore("healingBurst", "life")["ok"], "another recipe's jar waits for Finish")
		s["pool"]["life"] = 2
		assert_true(not BenchPrototype.add_ore("healingSalve", "life")["ok"], "can't tap what the pool can't pay")
		assert_eq(BenchPrototype.jar_amount("healingBurst", "time"), 2)
		assert_eq(BenchPrototype.jar_amount("healingBurst", "fate"), 0)
	)

	run_case("apparatus_waits_for_a_jar_then_records_the_ores_added_since_the_last_step", func():
		var root := _fresh()
		assert_true(not BenchPrototype.check_apparatus()["ok"], "no apparatus before a jar")
		assert_true(not BenchPrototype.perform_step("heat", 50.0)["ok"])
		assert_true(not BenchPrototype.perform_grind([50.0])["ok"])
		assert_true(not BenchPrototype.perform_distil([])["ok"])
		assert_eq(root["activeRun"], null, "a refused step opens nothing")
		assert_true(not BenchPrototype.perform_step("grinding", 50.0)["ok"], "grind isn't a hold apparatus")
		_play("healingBurst", [["life", "grinding", 50.0]])
		BenchPrototype.add_ore("healingBurst", "time")
		BenchPrototype.add_ore("healingBurst", "time")
		_perform_at("compression", 60.0)
		_perform_at("heat", 35.0)
		var performed: Array = root["activeRun"]["performed"]
		assert_eq(performed.map(func(p): return p["ores"]), [["life"], ["time"], []], "each step keeps the ores tapped since the last")
		assert_eq(performed[0], { "apparatus": "grinding", "ores": ["life"], "readings": [50.0, 50.0, 50.0] })
		assert_eq(performed[1], { "apparatus": "compression", "ores": ["time"], "value": 60.0 })
	)

	run_case("ore_aware_matching_needs_the_ore_in_the_mixture", func():
		_fresh()
		var ideal: Array = BenchPrototype.procedure_def("healingBurst")["ideal"]
		assert_eq(BenchPrototype.match_ideal(ideal, [{ "apparatus": "grinding", "ores": ["time"] }]), [-1], "right apparatus, wrong ore: no match")
		assert_eq(BenchPrototype.match_ideal(ideal, [{ "apparatus": "grinding", "ores": [] }]), [-1], "right apparatus, no ore: no match")
		assert_eq(BenchPrototype.match_ideal(ideal, [{ "apparatus": "grinding", "ores": ["life"] }]), [0])
		var earlier := [{ "apparatus": "grinding", "ores": ["life", "time"] }, { "apparatus": "compression", "ores": [] }]
		assert_eq(BenchPrototype.match_ideal(ideal, earlier), [0, 1], "an ore added earlier is still in the mixture")
		assert_eq(BenchPrototype.match_ideal(ideal, [{ "apparatus": "distilling", "ores": [] }]), [2], "a step with no ore matches on apparatus")
		BenchPrototype.set_skill_override(0)
		_play("healingBurst", [["time", "grinding", 50.0], ["life", "compression", 60.0]])
		var entry: Dictionary = BenchPrototype.finish_procedure_run()["entry"]
		assert_eq(entry["steps"].map(func(p): return p["accuracy"]), [null, 1.0], "the time-only grind is an extra step")
		assert_eq(entry["score"], 15, "compress 20 − one extra 5")
	)

	run_case("steps_run_in_any_order_and_repeat", func():
		_fresh()
		BenchPrototype.set_skill_override(0)
		var result := _play("healingSalve", [["life", "grinding", 50.0], ["", "grinding", 50.0], ["", "heat", 62.0], ["", "heat", 62.0]])
		assert_true(result["ok"], "a repeat performs")
		var entry: Dictionary = BenchPrototype.finish_procedure_run()["entry"]
		assert_eq(entry["steps"].size(), 4, "every performed step is recorded")
		assert_eq(entry["score"], 60, "grind 30 + heat 40 − two repeats at 5")
		_play("healingSalve", [["life", "heat", 62.0], ["", "grinding", 50.0]])
		entry = BenchPrototype.finish_procedure_run()["entry"]
		assert_eq(entry["steps"].map(func(p): return p["accuracy"]), [1.0, null], "heat before grind: the grind comes too late")
		assert_eq(entry["score"], 35, "heat 40 − one extra 5")
	)

	run_case("finish_scores_grind_then_heat_through_the_core", func():
		var root := _fresh()
		var before := _outside_state()
		Rng.set_seed(1)
		BenchPrototype.set_skill_override(0)
		var s: Dictionary = root
		_play("healingSalve", [["life", "grinding", 50.0], ["", "heat", 62.0]])
		assert_true(s["activeRun"] != null, "no step finishes the run on its own")
		var result := BenchPrototype.finish_procedure_run()
		assert_eq(result["entry"]["score"], 70, "grind 30 + heat 40, distil missing")
		assert_eq(result["entry"]["rank"], 3)
		assert_true(result["newBest"], "first rank is a new best")
		assert_eq(s["bestRanks"]["healingSalve"], 3, "best rank set via the core")
		assert_eq(s["ledger"].size(), 1, "ledger logs the run")
		assert_eq(result["entry"]["steps"][0], { "apparatus": "grinding", "ores": ["life"], "readings": [50.0, 50.0, 50.0], "accuracy": 1.0 }, "ledger keeps the grind strokes")
		assert_eq(result["entry"]["steps"][1], { "apparatus": "heat", "ores": [], "value": 62.0, "accuracy": 1.0 }, "ledger keeps per-step results")
		assert_eq(s["activeRun"], null, "run closed")
		_play("healingSalve", [["life", "grinding", 50.0], ["", "heat", 62.0]])
		assert_true(not BenchPrototype.finish_procedure_run()["newBest"], "the same rank again isn't a new best")
		assert_eq(_outside_state(), before, "real state untouched")
	)

	run_case("grind_scores_mean_stroke_accuracy_short_strokes_miss", func():
		_fresh()
		BenchPrototype.set_skill_override(0)
		# healingSalve ±8 band on target 50: 62 is half accuracy, 70 is none.
		var acc := func(readings: Array) -> float:
			return BenchPrototype.performed_accuracy({ "readings": readings }, 50.0, 8.0)
		assert_true(is_equal_approx(acc.call([50.0, 62.0, 70.0]), 0.5), "mean of 1, 0.5, 0")
		assert_true(is_equal_approx(acc.call([38.0, 62.0, 50.0]), 2.0 / 3.0), "errors either side don't cancel")
		BenchPrototype.add_ore("healingSalve", "life")
		BenchPrototype.perform_grind([50.0, 999.0, 50.0, 50.0, 50.0])
		BenchPrototype.perform_grind([50.0])
		var performed: Array = GameState.state["benchPrototype"]["activeRun"]["performed"]
		assert_eq(performed[0]["readings"], [50.0, 100.0, 50.0], "clamped, extras past the stroke count ignored")
		assert_eq(performed[1]["readings"], [50.0, null, null], "missing strokes read as misses")
		assert_true(is_equal_approx(acc.call(performed[1]["readings"]), 1.0 / 3.0), "a miss scores 0")
	)

	run_case("compress_past_crack_line_ends_run_and_loses_calc", func():
		var root := _fresh()
		var s: Dictionary = root
		var crack_at := float(_data()["gauges"]["compression"]["crackAt"])
		var safe := _play("timePearl", [["time", "compression", crack_at - 0.5]])
		assert_true(safe["ok"] and not safe.get("cracked", false), "just under the line holds")
		assert_true(not BenchPrototype.perform_step("heat", crack_at).get("cracked", false), "only compression cracks")
		BenchPrototype.finish_procedure_run()
		BenchPrototype.rewind()
		var cracked := _play("timePearl", [["time", "compression", crack_at]])
		assert_true(cracked["ok"] and cracked["cracked"], "the crack line ends the run")
		assert_eq(cracked["entry"]["kind"], "cracked")
		assert_eq(cracked["entry"]["items"], 0, "no item")
		assert_eq(s["pool"]["time"], 37, "the tapped calc is lost")
		assert_eq(s["activeRun"], null, "run closed")
		assert_eq(s["bestRanks"]["timePearl"], 0, "no rank from a crack")
		assert_true(not BenchPrototype.perform_step("heat", 25.0)["ok"], "no step after a crack")
		BenchPrototype.rewind()
		assert_eq(root["pool"], _data()["poolSeed"], "rewind restores the calc")
	)

	run_case("distil_works_the_mixture_and_a_stray_tap_spoils_it", func():
		_fresh()
		BenchPrototype.set_skill_override(0)
		_play("healingSalve", [["life", "grinding", 50.0], ["", "heat", 62.0], ["", "distilling", 50.0]])
		assert_eq(BenchPrototype.finish_procedure_run()["entry"]["score"], 100, "full ideal performed dead on")
		var spoiled_taps := _distil_taps(50.0)
		spoiled_taps.append(-10.0)
		_play("healingSalve", [["life", "grinding", 50.0], ["", "heat", 62.0]])
		BenchPrototype.perform_distil(spoiled_taps)
		assert_eq(BenchPrototype.finish_procedure_run()["entry"]["score"], 70, "a stray tap zeroes the distil's 30")
	)

	run_case("distil_taps_read_drip_positions_stray_tap_spoils", func():
		_fresh()
		var g: Dictionary = _data()["gauges"]["distilling"]
		var beat := float(g["beatMsec"])
		var fall := float(g["fallMsec"])
		var clean := BenchPrototype.distil_readings(_distil_taps(50.0))
		assert_eq(clean, { "readings": [50.0, 50.0, 50.0, 50.0], "stray": false }, "one mid-fall tap per drip")
		var missed := BenchPrototype.distil_readings([fall * 0.25, 2 * beat + fall * 0.5])
		assert_eq(missed, { "readings": [25.0, null, 50.0, null], "stray": false }, "untapped drips read null")
		for stray_tap in [-10.0, fall + 50.0, 4 * beat]:
			assert_true(BenchPrototype.distil_readings([stray_tap])["stray"], "tap at %d is stray" % stray_tap)
		assert_true(BenchPrototype.distil_readings([100.0, 200.0])["stray"], "a second tap on one drip is stray")
		assert_eq(BenchPrototype.performed_accuracy({ "readings": [50.0, 50.0, 50.0, 50.0], "stray": true }, 50.0, 8.0), 0.0, "stray spoils the step")
		assert_true(is_equal_approx(BenchPrototype.performed_accuracy(missed, 50.0, 8.0), 0.25), "one drip in band of four")
	)

	run_case("every_recipe_plays_its_known_procedure_end_to_end", func():
		_fresh()
		for recipe_id in _data()["roster"]:
			var steps := []
			for step in BenchPrototype.known_procedure(recipe_id):
				var calc: Dictionary = step.get("calc", {})
				steps.append([calc.keys()[0] if not calc.is_empty() else "", step["apparatus"], float(step["target"])])
			assert_true(_play(recipe_id, steps)["ok"], "%s performs" % recipe_id)
			var result := BenchPrototype.finish_procedure_run()
			assert_true(result["ok"] and result["entry"]["kind"] == "run", "%s finishes" % recipe_id)
			assert_eq(result["entry"]["steps"].size(), steps.size(), "%s: one result per step" % recipe_id)
			assert_true(not result["entry"]["steps"].map(func(p): return p["accuracy"]).has(null), "%s: no extras" % recipe_id)
	)

	run_case("rewind_restores_to_before_the_first_jar_tap", func():
		var root := _fresh()
		BenchPrototype.set_skill_override(0)
		var before: Dictionary = GameState.deep_copy(root)
		_play("healingBurst", [["life", "grinding", 50.0], ["time", "compression", 60.0]])
		assert_eq(root["pool"], { "life": 38, "time": 38 }, "calc spent jar by jar")
		assert_eq(root["activeRun"]["calcSpent"], { "life": 2, "time": 2 })
		BenchPrototype.finish_procedure_run()
		assert_true(BenchPrototype.rewind()["ok"])
		var after: Dictionary = GameState.deep_copy(root)
		assert_eq(after, before, "pool, ledger, ranks and run back to before the first tap")
		_play("healingBurst", [["life", "grinding", 50.0]])
		BenchPrototype.rewind()
		assert_eq(root["activeRun"], null, "rewind mid-run closes it")
		assert_eq(root["pool"], _data()["poolSeed"], "and refunds it")
	)

	run_case("save_round_trip_preserves_open_run", func():
		var root := _fresh()
		_play("healingBurst", [["life", "grinding", 50.0]])
		BenchPrototype.add_ore("healingBurst", "time")
		var expected: Dictionary = GameState.deep_copy(root)
		var raw = JSON.parse_string(JSON.stringify(GameState.state))
		assert_true(SaveManager._load_save_dict(raw)["ok"], "save loads")
		assert_eq(GameState.state["benchPrototype"], expected, "open run, its steps and added ores survive a save")
	)

	run_case("an_old_plan_editor_save_restarts_the_prototype_fresh", func():
		GameState.reset()
		var raw = JSON.parse_string(JSON.stringify(GameState.state))
		raw["benchPrototype"]["plans"] = {}
		raw["benchPrototype"]["activeRun"] = { "recipeId": "healingSalve", "startedMsec": 0, "calcSpent": {}, "procedure": [], "performed": [] }
		assert_true(SaveManager._load_save_dict(raw)["ok"], "save loads")
		assert_eq(GameState.state["benchPrototype"]["activeRun"], null, "fresh state")
		assert_true(not GameState.state["benchPrototype"].has("plans"))
	)

	run_case("validator_flags_an_ideal_ore_outside_base_calc", func():
		_fresh()
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["bench_prototype"]["recipes"]["healingSalve"]["procedure"]["ideal"][0]["ore"] = "time"
		var found := false
		for e in GameData.validate_tables(corrupted):
			if e.contains("healingSalve.procedure.ideal") and e.contains("'time'"):
				found = true
		assert_true(found, "an ideal ore the recipe doesn't use is flagged")
	)

	run_case("validator_flags_bad_procedure_weights_and_calc", func():
		_fresh()
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		var procedure: Dictionary = corrupted["bench_prototype"]["recipes"]["healingSalve"]["procedure"]
		procedure["ideal"][0]["weight"] = 10
		procedure["base"][0]["calc"] = { "life": 1 }
		var errors := GameData.validate_tables(corrupted)
		var weights := false
		var calc := false
		for e in errors:
			if e.contains("healingSalve.procedure.ideal") and e.contains("weights"):
				weights = true
			if e.contains("healingSalve.procedure.base") and e.contains("baseCalc"):
				calc = true
		assert_true(weights, "weights not summing to 100 flagged")
		assert_true(calc, "base calc not matching baseCalc flagged")
		corrupted["bench_prototype"]["gauges"].erase("distilling")
		var gauges := false
		for e in GameData.validate_tables(corrupted):
			if e.contains("no gauges entry for apparatus 'distilling'"):
				gauges = true
		assert_true(gauges, "an apparatus with no gauge flagged")
	)

	run_case("notebook_clues_cover_hit_near_none_and_changed", func():
		_fresh()
		BenchPrototype.set_skill_override(0)
		var performed := [
			{ "apparatus": "grinding", "ores": ["life"], "readings": [50.0, 52.0, 48.0] },
			{ "apparatus": "heat", "ores": [], "value": 40.0 },
			BenchPrototype.distil_readings(_distil_taps(50.0)).merged({ "apparatus": "distilling", "ores": [] }),
			{ "apparatus": "compression", "ores": [], "value": 50.0 },
		]
		var clues := BenchPrototype.notebook_clues("healingSalve", performed)
		assert_eq(clues.map(func(c): return c["clue"]), ["hit", "near", "changed", "none"])
		assert_eq(clues[1]["direction"], "higher", "heat 40 under the ideal 62")
		assert_eq(clues[3]["ideal"], -1, "an extra step matches nothing")
		performed[1] = { "apparatus": "heat", "ores": [], "value": 80.0 }
		assert_eq(BenchPrototype.notebook_clues("healingSalve", performed)[1]["direction"], "lower")
		performed[0] = { "apparatus": "grinding", "ores": ["life"], "readings": [50.0, 50.0, null] }
		var missed: Dictionary = BenchPrototype.notebook_clues("healingSalve", performed)[0]
		assert_eq([missed["clue"], missed["direction"]], ["near", null], "a missed stroke: right amount, no direction")
		BenchPrototype.set_hint_level("healingSalve", "distilFinish", "vague")
		assert_eq(BenchPrototype.notebook_clues("healingSalve", performed)[2]["clue"], "hit", "a known step isn't a discovery")
	)

	run_case("notebook_changed_needs_the_hidden_step_in_position", func():
		_fresh()
		BenchPrototype.set_skill_override(0)
		var distil := BenchPrototype.distil_readings(_distil_taps(50.0)).merged({ "apparatus": "distilling", "ores": [] })
		var performed := [distil, { "apparatus": "grinding", "ores": ["life"], "readings": [50.0, 50.0, 50.0] }, { "apparatus": "heat", "ores": [], "value": 62.0 }]
		assert_true(BenchPrototype.notebook_clues("healingSalve", performed)[0]["clue"] != "changed", "a distil first displaces the grind and heat")
		var pearl := [
			{ "apparatus": "compression", "ores": ["time"], "value": 82.0 },
			{ "apparatus": "grinding", "ores": [], "readings": [50.0, 50.0, 50.0] },
			{ "apparatus": "heat", "ores": [], "value": 25.0 },
		]
		assert_eq(BenchPrototype.notebook_clues("timePearl", pearl).map(func(c): return c["clue"]), ["hit", "changed", "hit"], "grind between press and heat")
	)

	run_case("wrong_ore_never_yields_a_hit_or_something_changed", func():
		_fresh()
		BenchPrototype.set_skill_override(0)
		var grind := [{ "apparatus": "grinding", "ores": ["time"], "readings": [50.0, 50.0, 50.0] }]
		assert_eq(BenchPrototype.notebook_clues("healingBurst", grind)[0]["clue"], "none", "grind needs life in the mixture")
		var root := _fresh()
		_play("healingBurst", [["life", "compression", 60.0]])
		var entry: Dictionary = BenchPrototype.finish_procedure_run()["entry"]
		assert_eq(entry["clues"][0]["clue"], "none", "compress needs time, played through Finish")
		assert_eq(root["hintLevels"]["healingBurst"].values(), ["off", "off"], "nothing learned")
	)

	run_case("finish_off_book_step_grants_a_vague_hint_on_the_book", func():
		var root := _fresh()
		BenchPrototype.set_skill_override(0)
		_play("healingSalve", [["life", "grinding", 50.0], ["", "heat", 62.0], ["", "distilling", 50.0]])
		var entry: Dictionary = BenchPrototype.finish_procedure_run()["entry"]
		assert_eq(entry["clues"].map(func(c): return c["clue"]), ["hit", "hit", "changed"])
		assert_eq(entry["clues"][2].get("learned"), "vague", "something changed · new vague hint")
		assert_eq(root["notebook"]["healingSalve"], entry["clues"], "notebook keeps the last run's clues")
		assert_eq(BenchPrototype.hint_level("healingSalve", "distilFinish"), "vague")
		var book := BenchPrototype.known_procedure("healingSalve")
		assert_eq([book[2]["apparatus"], book[2]["knowledge"]], ["distilling", "vague"], "the book shows the learned step faded")
		assert_true(BenchPrototype.step_region("healingSalve", book[2])["vague"], "vague region")
	)

	run_case("three_hits_on_a_vague_step_upgrade_it_to_exact", func():
		var root := _fresh()
		BenchPrototype.set_skill_override(0)
		BenchPrototype.set_hint_level("healingSalve", "distilFinish", "vague")
		var needed := int(_data()["vagueToExactHits"])
		var last := {}
		for run in needed:
			_play("healingSalve", [["life", "grinding", 50.0], ["", "heat", 62.0], ["", "distilling", 50.0]])
			last = BenchPrototype.finish_procedure_run()["entry"]["clues"][2]
			if run < needed - 1:
				assert_eq([last["clue"], last["hits"], last.has("learned")], ["hit", run + 1, false], "n/3 toward exact")
		assert_eq(last.get("learned"), "exact", "now exact")
		assert_eq(BenchPrototype.hint_level("healingSalve", "distilFinish"), "exact")
		assert_eq(BenchPrototype.known_procedure("healingSalve")[2]["knowledge"], "exact")
		_play("healingSalve", [["life", "grinding", 50.0], ["", "heat", 62.0], ["", "distilling", 50.0]])
		assert_true(not BenchPrototype.finish_procedure_run()["entry"]["clues"][2].has("hits"), "an exact step stops counting")
		assert_eq(root["vagueHits"]["healingSalve"]["distilFinish"], needed)
	)

	run_case("a_near_miss_on_a_vague_step_does_not_count", func():
		var root := _fresh()
		BenchPrototype.set_skill_override(0)
		BenchPrototype.set_hint_level("healingSalve", "heatHigher", "vague")
		_play("healingSalve", [["life", "grinding", 50.0], ["", "heat", 50.0]])
		var clue: Dictionary = BenchPrototype.finish_procedure_run()["entry"]["clues"][1]
		assert_eq([clue["clue"], clue.has("hits")], ["near", false])
		assert_true(not root["vagueHits"].has("healingSalve"), "no hit recorded")
	)

	run_case("debug_hint_toggle_drops_vague_hits", func():
		var root := _fresh()
		root["vagueHits"]["healingSalve"] = { "distilFinish": 2 }
		BenchPrototype.set_hint_level("healingSalve", "distilFinish", "vague")
		assert_true(not root["vagueHits"]["healingSalve"].has("distilFinish"), "hit count reset")
	)

	run_case("use_effect_spends_real_inventory_and_starts_the_effect", func():
		_fresh()
		Crafting.inventory_add(ActiveEffects.PROPHETS_BREATH, 2, 2)
		var before := Crafting.inventory_qty(ActiveEffects.PROPHETS_BREATH)
		assert_true(BenchPrototype.use_effect(ActiveEffects.PROPHETS_BREATH)["ok"], "used")
		assert_eq(Crafting.inventory_qty(ActiveEffects.PROPHETS_BREATH), before - 1, "one spent from the real bag")
		assert_true(ActiveEffects.prophets_breath_active(), "effect running")
		Crafting.inventory_add("timePearl", 1, 1)
		var pearls := Crafting.inventory_qty("timePearl")
		assert_true(not BenchPrototype.use_effect("timePearl")["ok"], "only Breath and Lady")
		assert_eq(Crafting.inventory_qty("timePearl"), pearls, "untouched")
	)

	run_case("prophets_breath_reveals_true_bands_on_every_step", func():
		var root := _fresh()
		BenchPrototype.set_skill_override(0)
		BenchPrototype.set_hint_level("healingSalve", "distilFinish", "vague")
		Crafting.inventory_add(ActiveEffects.PROPHETS_BREATH, 1, 1)
		BenchPrototype.use_effect(ActiveEffects.PROPHETS_BREATH)
		var book := BenchPrototype.known_procedure("healingSalve")
		var ideal: Array = BenchPrototype.procedure_def("healingSalve")["ideal"]
		assert_eq(book.map(func(s): return s["apparatus"]), ideal.map(func(s): return s["apparatus"]), "every ideal step shown")
		var half := BenchPrototype.band_half_width("healingSalve")
		for i in ideal.size():
			assert_eq(book[i]["knowledge"], "revealed", "step %d revealed" % i)
			assert_true(not book[i].has("note"), "no hint note")
			var region := BenchPrototype.step_region("healingSalve", book[i])
			var target := float(ideal[i]["target"])
			assert_eq([region["low"], region["high"], region["vague"]], [maxf(0.0, target - half), minf(100.0, target + half), false], "true band %d" % i)
		assert_eq(root["hintLevels"]["healingSalve"].values(), ["off", "vague"], "hint levels untouched")
		BenchPrototype.set_hint_level("healingSalve", "heatHigher", "exact")
		book = BenchPrototype.known_procedure("healingSalve")
		assert_eq([book[1]["knowledge"], book[1].has("note")], ["exact", true], "an exact step keeps its note")
	)

	run_case("lady_adds_level_times_ten_to_the_score_clamped", func():
		var root := _fresh()
		var plain: Dictionary = _run("healingSalve", 60)["entry"]
		assert_eq([plain["score"], plain.has("ladyBonus")], [60, false], "no Lady, no bonus")
		Crafting.inventory_add(ActiveEffects.LADY, 3, 1)
		BenchPrototype.use_effect(ActiveEffects.LADY)
		var entry: Dictionary = _run("healingSalve", 60)["entry"]
		assert_eq([entry["rawScore"], entry["ladyBonus"], entry["score"]], [60, 30, 90], "lvl 3 = +30")
		assert_eq(entry["rank"], BenchPrototype.rank_for_score(90), "rank from the lifted score")
		assert_eq(_run("healingSalve", 85)["entry"]["score"], 100, "clamped at 100")
		assert_eq(root["bestRanks"]["healingSalve"], BenchPrototype.rank_for_score(100))
	)
