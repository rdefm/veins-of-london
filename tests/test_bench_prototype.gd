extends "res://tests/test_base.gd"

const SeedSearch := preload("res://tests/support/seed_search.gd")

# systems/bench_prototype.gd's shared core (.scratch/lab-revamp/spec.md
# §Shared core rules), driven through the public API on both slices.

const P := BenchPrototype.SLICE_PROCEDURE
const C := BenchPrototype.SLICE_CHART


func _fresh() -> Dictionary:
	GameState.reset()
	return GameState.state["benchPrototype"]


func _data() -> Dictionary:
	return GameData.BENCH_PROTOTYPE


func _run(slice_id: String, recipe_id: String, score: int) -> Dictionary:
	BenchPrototype.begin_run(slice_id, recipe_id)
	return BenchPrototype.finish_run(slice_id, score)


# Everything in GameState.state except the prototype's own tree.
# Performs the open procedure run's current step dead on value, with the
# raw input each gauge reports.
func _perform_at(value: float) -> Dictionary:
	var apparatus: String = BenchPrototype.current_step()["apparatus"]
	match apparatus:
		"grinding":
			var readings := []
			for i in int(_data()["gauges"]["grinding"]["strokes"]):
				readings.append(value)
			return BenchPrototype.perform_grind(readings)
		"distilling":
			return BenchPrototype.perform_distil(_distil_taps(value))
	return BenchPrototype.perform_step(value)


# One tap per drip, each as the drip passes value.
func _distil_taps(value: float) -> Array:
	var g: Dictionary = _data()["gauges"]["distilling"]
	var taps := []
	for i in int(g["drips"]):
		taps.append(i * float(g["beatMsec"]) + value / 100.0 * float(g["fallMsec"]))
	return taps


func _outside_state() -> Dictionary:
	var copy: Dictionary = GameState.deep_copy(GameState.state)
	copy.erase("benchPrototype")
	return copy


func run() -> void:
	run_case("new_state_seeds_both_slices_from_data_and_is_pure", func():
		var root := _fresh()
		for slice_id in BenchPrototype.SLICES:
			var s: Dictionary = root["slices"][slice_id]
			assert_eq(s["pool"], _data()["poolSeed"], "%s pool seeds from data" % slice_id)
			for recipe_id in _data()["roster"]:
				assert_eq(s["bestRanks"][recipe_id], 0, "%s.%s starts unranked" % [slice_id, recipe_id])
				for hint in BenchPrototype.hints(slice_id, recipe_id):
					assert_eq(s["hintLevels"][recipe_id][hint["id"]], "off", "%s.%s.%s starts off" % [slice_id, recipe_id, hint["id"]])
				assert_eq(s["hintLevels"][recipe_id].size(), BenchPrototype.hints(slice_id, recipe_id).size(), "%s.%s: one level per hint" % [slice_id, recipe_id])
		var parsed = JSON.parse_string(JSON.stringify(root))
		assert_true(parsed is Dictionary, "benchPrototype survives a JSON round-trip (pure data)")
		root["slices"][P]["pool"]["life"] = 1
		assert_eq(root["slices"][C]["pool"]["life"], _data()["poolSeed"]["life"], "slices don't share a pool dict")
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
		var result := _run(P, "healingSalve", 62)
		assert_true(result["ok"], "run finishes")
		var s: Dictionary = root["slices"][P]
		assert_eq(s["bestRanks"]["healingSalve"], 3, "score 62 sets rank 3")
		var entry: Dictionary = s["ledger"][0]
		assert_eq(entry["kind"], "run")
		assert_eq(entry["score"], 62)
		assert_eq(entry["rank"], 3)
		assert_true(entry.has("durationMsec") and entry["durationMsec"] >= 0, "duration logged")
		assert_true(entry.has("bonus"), "bonus field logged")
		var refunded: int = 0 if entry["bonus"] != "calcRefund" else 1
		assert_eq(s["pool"]["life"], 40 - 3 + refunded, "base calc spent")
		assert_eq(root["slices"][C]["pool"]["life"], 40, "other slice untouched")
	)

	run_case("best_rank_only_rises", func():
		var root := _fresh()
		_run(P, "timePearl", 80)
		_run(P, "timePearl", 10)
		assert_eq(root["slices"][P]["bestRanks"]["timePearl"], 4, "a worse run doesn't lower best rank")
		_run(P, "timePearl", 95)
		assert_eq(root["slices"][P]["bestRanks"]["timePearl"], 5, "a better run raises it")
	)

	run_case("begin_refuses_without_calc_or_while_run_open", func():
		var root := _fresh()
		root["slices"][P]["pool"]["time"] = 2
		assert_true(not BenchPrototype.begin_run(P, "timePearl")["ok"], "can't afford 3 time")
		assert_true(BenchPrototype.begin_run(P, "healingSalve")["ok"])
		assert_true(not BenchPrototype.begin_run(P, "healingSalve")["ok"], "one run at a time")
	)

	run_case("abandon_loses_spent_calc_and_logs_no_item", func():
		var root := _fresh()
		BenchPrototype.begin_run(C, "healingBurst")
		BenchPrototype.abandon_run(C)
		var s: Dictionary = root["slices"][C]
		assert_eq(s["pool"], { "life": 38, "time": 38 }, "calc stays spent")
		assert_eq(s["ledger"][0]["items"], 0)
		assert_eq(s["bestRanks"]["healingBurst"], 0, "no rank from an abandoned run")
	)

	run_case("bonus_never_rolls_below_best_rank", func():
		var root := _fresh()
		root["slices"][P]["bestRanks"]["healingSalve"] = 4
		for i in range(30):
			Rng.set_seed(i)
			var entry: Dictionary = _run(P, "healingSalve", 50)["entry"]
			assert_eq(entry["bonus"], null, "rank 2 < best 4 never rolls a bonus (seed %d)" % i)
			BenchPrototype.refill_pool(P)
	)

	run_case("bonus_extra_item_adds_an_item", func():
		var root := _fresh()
		BenchPrototype.set_bonus_type("extraItem")
		var seed := SeedSearch.find_seed_for(200, func(): return _run(P, "healingSalve", 50)["entry"]["bonus"] != null)
		assert_true(seed != -1, "a 30% bonus should land within 200 seeds")
		var entry: Dictionary = root["slices"][P]["ledger"][-1]
		assert_eq(entry["bonus"], "extraItem")
		assert_eq(entry["items"], 2, "+1 item")
		assert_eq(entry["xp"], _data()["baseXp"], "XP unscaled")
	)

	run_case("bonus_calc_refund_returns_half_the_calc", func():
		var root := _fresh()
		BenchPrototype.set_bonus_type("calcRefund")
		var seed := SeedSearch.find_seed_for(200, func(): return _run(C, "healingBurst", 50)["entry"]["bonus"] != null)
		assert_true(seed != -1, "a bonus should land within 200 seeds")
		assert_eq(root["slices"][C]["pool"], { "life": 39, "time": 39 }, "2 spent, floor(2 × 0.5) = 1 back per type")
		assert_eq(root["slices"][C]["ledger"][-1]["items"], 1)
	)

	run_case("bonus_xp_scales_xp_display_only", func():
		var root := _fresh()
		BenchPrototype.set_bonus_type("xp")
		var xp_before: int = GameState.state["player"]["craftingXP"]
		var seed := SeedSearch.find_seed_for(200, func(): return _run(P, "timePearl", 50)["entry"]["bonus"] != null)
		assert_true(seed != -1, "a bonus should land within 200 seeds")
		assert_eq(root["slices"][P]["ledger"][-1]["xp"], roundi(_data()["baseXp"] * 1.5), "XP ×1.5")
		assert_eq(GameState.state["player"]["craftingXP"], xp_before, "real crafting XP untouched")
	)

	run_case("bonus_rate_is_roughly_thirty_percent", func():
		var root := _fresh()
		Rng.set_seed(42)
		var hits := 0
		for i in range(400):
			if _run(P, "healingSalve", 95)["entry"]["bonus"] != null:
				hits += 1
			BenchPrototype.refill_pool(P)
			root["slices"][P]["ledger"].clear()
		assert_true(hits > 80 and hits < 160, "~120 of 400 should roll a bonus, got %d" % hits)
	)

	run_case("flavour_only_below_threshold_about_one_in_three", func():
		var root := _fresh()
		Rng.set_seed(7)
		var hits := 0
		for i in range(300):
			var entry: Dictionary = _run(P, "healingSalve", 14)["entry"]
			if entry["flavour"] != null:
				hits += 1
				assert_true(_data()["badRun"]["lines"].has(entry["flavour"]), "flavour comes from data")
			var high: Dictionary = _run(P, "healingSalve", 15)["entry"]
			assert_eq(high["flavour"], null, "score 15 never shows flavour")
			BenchPrototype.refill_pool(P)
			root["slices"][P]["ledger"].clear()
		assert_true(hits > 60 and hits < 140, "~100 of 300 should show flavour, got %d" % hits)
	)

	run_case("batch_spends_base_calc_per_item_and_logs_n_at_best_rank", func():
		var root := _fresh()
		assert_true(not BenchPrototype.batch(P, "healingSalve", 5)["ok"], "no batch before a rank exists")
		_run(P, "healingSalve", 76)
		var s: Dictionary = root["slices"][P]
		var pool_before: int = s["pool"]["life"]
		var result := BenchPrototype.batch(P, "healingSalve", 5)
		assert_true(result["ok"])
		assert_eq(s["pool"]["life"], pool_before - 15, "5 × 3 life")
		var entry: Dictionary = s["ledger"][-1]
		assert_eq(entry["kind"], "batch")
		assert_eq(entry["items"], 5)
		assert_eq(entry["rank"], 4, "batch runs at best rank")
		assert_eq(entry["xp"], _data()["baseXp"] * 5, "XP ×1.0")
		assert_eq(entry["bonus"], null, "batch never rolls a bonus")
		assert_true(not BenchPrototype.batch(P, "healingSalve", 10)["ok"], "can't afford 30 more life")
	)

	run_case("refill_restores_the_pool", func():
		var root := _fresh()
		_run(C, "healingBurst", 50)
		BenchPrototype.refill_pool(C)
		assert_eq(root["slices"][C]["pool"], _data()["poolSeed"])
	)

	run_case("rewind_restores_slice_exactly", func():
		var root := _fresh()
		_run(P, "healingSalve", 45)
		BenchPrototype.set_hint_level(P, "timePearl", "grindBetween", "vague")
		var before: Dictionary = GameState.deep_copy(root["slices"][P])
		before.erase("snapshots")
		_run(P, "healingSalve", 95)
		BenchPrototype.batch(P, "healingSalve", 5)
		BenchPrototype.rewind(P)
		BenchPrototype.rewind(P)
		var after: Dictionary = GameState.deep_copy(root["slices"][P])
		after.erase("snapshots")
		assert_eq(after, before, "two rewinds undo the batch then the run")
	)

	run_case("rewind_mid_run_refunds_and_closes_the_run", func():
		var root := _fresh()
		BenchPrototype.begin_run(C, "timePearl")
		assert_true(BenchPrototype.rewind(C)["ok"])
		assert_eq(root["slices"][C]["activeRun"], null)
		assert_eq(root["slices"][C]["pool"], _data()["poolSeed"])
		assert_true(not BenchPrototype.rewind(C)["ok"], "nothing left to rewind")
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

	run_case("hint_levels_are_per_slice_per_recipe_per_hint", func():
		var root := _fresh()
		assert_true(BenchPrototype.set_hint_level(P, "healingBurst", "heatLower", "exact")["ok"])
		assert_true(not BenchPrototype.set_hint_level(P, "healingBurst", "heatLower", "loud")["ok"], "unknown level refused")
		assert_true(not BenchPrototype.set_hint_level(P, "healingBurst", "heatHigher", "exact")["ok"], "another recipe's hint refused")
		assert_true(not BenchPrototype.set_hint_level(C, "healingBurst", "heatLower", "exact")["ok"], "procedure hints aren't chart hints")
		assert_eq(root["slices"][P]["hintLevels"]["healingBurst"], { "distilBetween": "off", "heatLower": "exact" })
		assert_eq(root["slices"][C]["hintLevels"]["healingBurst"], {})
	)

	run_case("every_authored_hint_has_vague_and_exact_forms", func():
		_fresh()
		var ids := []
		for recipe_id in _data()["roster"]:
			var hints := BenchPrototype.hints(P, recipe_id)
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
		BenchPrototype.set_hint_level(P, "healingSalve", "heatHigher", "exact")
		BenchPrototype.set_hint_level(P, "healingSalve", "distilFinish", "vague")
		salve = BenchPrototype.known_procedure("healingSalve")
		assert_eq(salve.map(func(s): return s["apparatus"]), ["grinding", "heat", "distilling"], "distil appended")
		assert_eq(salve[1]["target"], 62.0, "exact hint corrects the heat target")
		assert_eq(salve[1]["knowledge"], "exact")
		assert_eq(salve[0]["calc"], { "life": 3 }, "base calc stays on its step")
		assert_eq(salve[2]["knowledge"], "vague")
		assert_true(not salve[2].has("calc"), "inserted step costs nothing")
		assert_eq(salve[2]["note"], BenchPrototype.hint_def(P, "healingSalve", "distilFinish")["vague"]["note"], "vague note shown")
		BenchPrototype.set_hint_level(P, "timePearl", "grindBetween", "exact")
		assert_eq(BenchPrototype.known_procedure("timePearl").map(func(s): return s["apparatus"]), ["compression", "grinding", "heat"], "grind inserted between")
		BenchPrototype.set_hint_level(P, "healingBurst", "distilBetween", "vague")
		assert_eq(BenchPrototype.known_procedure("healingBurst").map(func(s): return s["apparatus"]), ["grinding", "compression", "distilling", "heat"], "distil inserted before heat")
		BenchPrototype.set_hint_level(P, "healingSalve", "distilFinish", "off")
		assert_eq(BenchPrototype.known_procedure("healingSalve").size(), 2, "off hides the step again")
	)

	run_case("vague_region_always_contains_the_true_band", func():
		_fresh()
		for skill in range(0, 11):
			BenchPrototype.set_skill_override(skill)
			for recipe_id in _data()["roster"]:
				var ideal: Array = BenchPrototype.procedure_def(recipe_id)["ideal"]
				var half := BenchPrototype.band_half_width(recipe_id)
				for hint in BenchPrototype.hints(P, recipe_id):
					var target := float(ideal[int(hint["step"])]["target"])
					for level in ["vague", "exact"]:
						BenchPrototype.set_hint_level(P, recipe_id, hint["id"], level)
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
			for hint in BenchPrototype.hints(P, recipe_id):
				BenchPrototype.set_hint_level(P, recipe_id, hint["id"], "exact")
			var steps := BenchPrototype.known_procedure(recipe_id)
			assert_true(BenchPrototype.begin_procedure_run(recipe_id)["ok"], "%s opens" % recipe_id)
			var result := {}
			for step in steps:
				result = _perform_at(float(step["target"]))
			assert_eq(result["entry"]["score"], 100, "%s: perfect with every hint" % recipe_id)
			assert_eq(root["slices"][P]["bestRanks"][recipe_id], 5, "%s reaches rank 5" % recipe_id)
	)

	run_case("no_prototype_action_touches_state_outside_bench_prototype", func():
		_fresh()
		var before := _outside_state()
		Rng.set_seed(3)
		BenchPrototype.set_skill_override(9)
		BenchPrototype.set_bonus_type("calcRefund")
		for slice_id in BenchPrototype.SLICES:
			BenchPrototype.set_active_slice(slice_id)
			BenchPrototype.set_hint_level(slice_id, "timePearl", "compressLonger", "exact")
			_run(slice_id, "healingSalve", 92)
			_run(slice_id, "healingBurst", 5)
			BenchPrototype.batch(slice_id, "healingSalve", 5)
			BenchPrototype.begin_run(slice_id, "timePearl")
			BenchPrototype.abandon_run(slice_id)
			BenchPrototype.rewind(slice_id)
			BenchPrototype.refill_pool(slice_id)
		assert_eq(_outside_state(), before, "real inventory, XP, craftingSkill and bench state unchanged")
	)

	run_case("save_round_trip_preserves_bench_prototype_exactly", func():
		var root := _fresh()
		Rng.set_seed(5)
		BenchPrototype.set_skill_override(6)
		_run(P, "healingSalve", 77)
		BenchPrototype.batch(P, "healingSalve", 5)
		BenchPrototype.begin_run(C, "timePearl")
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
			perfect.append({ "apparatus": step["apparatus"], "value": step["target"] })
		assert_eq(BenchPrototype.score_procedure("healingSalve", perfect)["score"], 100, "perfect ideal scores 100")
		var missing := perfect.slice(0, 2)
		assert_eq(BenchPrototype.score_procedure("healingSalve", missing)["score"], 70, "missing distil (weight 30) scores 0")
		var extra := perfect.duplicate()
		extra.insert(1, { "apparatus": "compression", "value": 50.0 })
		extra.append({ "apparatus": "heat", "value": 50.0 })
		var scored := BenchPrototype.score_procedure("healingSalve", extra)
		assert_eq(scored["score"], 90, "two extra steps cost 5 each")
		assert_eq(scored["accuracies"][1], null, "extra step has no accuracy")
		var off := [{ "apparatus": "grinding", "value": 50.0 }, { "apparatus": "heat", "value": 50.0 }]
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
					performed.append({ "apparatus": step["apparatus"], "value": step["target"] })
				var rank := BenchPrototype.rank_for_score(BenchPrototype.score_procedure(recipe_id, performed)["score"])
				assert_true(rank >= 2 and rank <= 3, "%s at skill %d reaches rank %d" % [recipe_id, skill, rank])
	)

	run_case("procedure_run_spends_per_step_and_scores_grind_then_heat", func():
		var root := _fresh()
		var before := _outside_state()
		Rng.set_seed(1)
		BenchPrototype.set_skill_override(0)
		var s: Dictionary = root["slices"][P]
		var opened := BenchPrototype.begin_procedure_run("healingSalve")
		assert_true(opened["ok"] and not opened["done"], "run opens and waits on the grind")
		assert_eq(s["pool"]["life"], 40, "nothing spent until a step is performed")
		assert_eq(BenchPrototype.current_step()["apparatus"], "grinding", "no step auto-passes")
		assert_true(not BenchPrototype.perform_step(50.0)["ok"], "a hold reading can't perform a grind")
		assert_true(not BenchPrototype.perform_distil([])["ok"], "nor can distil taps")
		assert_true(not BenchPrototype.perform_grind([50.0, 50.0, 50.0])["done"])
		assert_eq(s["pool"]["life"], 37, "grind spent its life calc")
		assert_true(not BenchPrototype.perform_grind([50.0])["ok"], "grind is done; heat is next")
		var result := BenchPrototype.perform_step(62.0)
		assert_true(result["ok"] and result["done"], "last step finishes the run")
		assert_eq(result["entry"]["score"], 70, "grind 30 + heat 40, distil missing")
		assert_eq(result["entry"]["rank"], 3)
		assert_eq(s["bestRanks"]["healingSalve"], 3, "best rank set via the core")
		assert_eq(s["ledger"].size(), 1, "ledger logs the run")
		assert_eq(result["entry"]["steps"][0], { "apparatus": "grinding", "readings": [50.0, 50.0, 50.0], "accuracy": 1.0 }, "ledger keeps the grind strokes")
		assert_eq(result["entry"]["steps"][1], { "apparatus": "heat", "value": 62.0, "accuracy": 1.0 }, "ledger keeps per-step results")
		assert_eq(s["activeRun"], null, "run closed")
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
		BenchPrototype.begin_procedure_run("healingSalve")
		BenchPrototype.perform_grind([50.0, 999.0, 50.0, 50.0, 50.0])
		var performed: Dictionary = GameState.state["benchPrototype"]["slices"][P]["activeRun"]["performed"][0]
		assert_eq(performed["readings"], [50.0, 100.0, 50.0], "clamped, extras past the stroke count ignored")
		BenchPrototype.abandon_run(P)
		BenchPrototype.begin_procedure_run("healingSalve")
		BenchPrototype.perform_grind([50.0])
		performed = GameState.state["benchPrototype"]["slices"][P]["activeRun"]["performed"][0]
		assert_eq(performed["readings"], [50.0, null, null], "missing strokes read as misses")
		assert_true(is_equal_approx(acc.call(performed["readings"]), 1.0 / 3.0), "a miss scores 0")
	)

	run_case("compress_past_crack_line_ends_run_and_loses_calc", func():
		var root := _fresh()
		var s: Dictionary = root["slices"][P]
		var crack_at := float(_data()["gauges"]["compression"]["crackAt"])
		BenchPrototype.begin_procedure_run("timePearl")
		var safe := BenchPrototype.perform_step(crack_at - 0.5)
		assert_true(safe["ok"] and not safe.get("cracked", false), "just under the line holds")
		BenchPrototype.abandon_run(P)
		BenchPrototype.rewind(P)
		s = root["slices"][P]
		BenchPrototype.begin_procedure_run("timePearl")
		var cracked := BenchPrototype.perform_step(crack_at)
		assert_true(cracked["ok"] and cracked["done"] and cracked["cracked"], "the crack line ends the run")
		assert_eq(cracked["entry"]["kind"], "cracked")
		assert_eq(cracked["entry"]["items"], 0, "no item")
		assert_eq(s["pool"]["time"], 37, "the compress step's calc is lost")
		assert_eq(s["activeRun"], null, "run closed")
		assert_eq(s["bestRanks"]["timePearl"], 0, "no rank from a crack")
		assert_true(not BenchPrototype.perform_step(25.0)["ok"], "heat never runs")
		BenchPrototype.rewind(P)
		assert_eq(root["slices"][P]["pool"], _data()["poolSeed"], "rewind restores the calc")
		# A heat step at the same value is no crack.
		BenchPrototype.begin_procedure_run("timePearl")
		BenchPrototype.perform_step(80.0)
		assert_true(not BenchPrototype.perform_step(crack_at).get("cracked", false), "only compression cracks")
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

	run_case("distil_step_performs_in_a_run_with_the_hidden_step", func():
		var root := _fresh()
		BenchPrototype.set_skill_override(0)
		BenchPrototype.begin_procedure_run("healingSalve")
		var run: Dictionary = root["slices"][P]["activeRun"]
		run["procedure"][1]["target"] = 62.0
		run["procedure"].append({ "apparatus": "distilling", "target": 50.0 })
		_perform_at(50.0)
		_perform_at(62.0)
		var result := _perform_at(50.0)
		assert_true(result["done"], "distil closes the run")
		assert_eq(result["entry"]["score"], 100, "full ideal performed dead on")
		var spoiled_taps := _distil_taps(50.0)
		spoiled_taps.append(-10.0)
		BenchPrototype.begin_procedure_run("healingSalve")
		run = root["slices"][P]["activeRun"]
		run["procedure"][1]["target"] = 62.0
		run["procedure"].append({ "apparatus": "distilling", "target": 50.0 })
		_perform_at(50.0)
		_perform_at(62.0)
		result = BenchPrototype.perform_distil(spoiled_taps)
		assert_eq(result["entry"]["score"], 70, "a stray tap zeroes the distil's 30")
	)

	run_case("every_recipe_plays_end_to_end_with_no_auto_steps", func():
		var root := _fresh()
		for recipe_id in _data()["roster"]:
			var steps := BenchPrototype.known_procedure(recipe_id)
			BenchPrototype.begin_procedure_run(recipe_id)
			var result := {}
			for step in steps:
				assert_eq(root["slices"][P]["activeRun"]["performed"].size(), steps.find(step), "%s: waits on step %s" % [recipe_id, step["apparatus"]])
				result = _perform_at(float(step["target"]))
				assert_true(result["ok"], "%s: %s performs" % [recipe_id, step["apparatus"]])
			assert_true(result["done"] and result["entry"]["kind"] == "run", "%s finishes" % recipe_id)
			assert_eq(result["entry"]["steps"].size(), steps.size(), "%s: one result per step" % recipe_id)
	)

	run_case("abandoned_procedure_run_loses_spent_calc_and_rewind_restores_it", func():
		var root := _fresh()
		var s: Dictionary = root["slices"][P]
		BenchPrototype.begin_procedure_run("healingBurst")
		_perform_at(50.0)
		_perform_at(60.0)
		assert_eq(s["pool"], { "life": 38, "time": 38 }, "grind and compress spent step by step")
		assert_eq(s["activeRun"]["calcSpent"], { "life": 2, "time": 2 })
		BenchPrototype.abandon_run(P)
		assert_eq(s["pool"], { "life": 38, "time": 38 }, "abandon keeps the calc spent")
		assert_eq(s["ledger"][-1]["kind"], "abandoned")
		assert_true(not BenchPrototype.perform_step(50.0)["ok"], "no step to perform after abandon")
		BenchPrototype.rewind(P)
		s = root["slices"][P]
		assert_eq(s["pool"], _data()["poolSeed"], "rewind restores the calc")
		assert_true(s["ledger"].is_empty(), "rewind drops the abandoned entry")
	)

	run_case("procedure_run_refuses_when_unaffordable_or_already_open", func():
		var root := _fresh()
		root["slices"][P]["pool"]["life"] = 2
		assert_true(not BenchPrototype.begin_procedure_run("healingSalve")["ok"], "can't afford the whole procedure")
		assert_eq(root["slices"][P]["snapshots"].size(), 0, "no snapshot on refusal")
		assert_true(BenchPrototype.begin_procedure_run("timePearl")["ok"])
		assert_true(not BenchPrototype.begin_procedure_run("timePearl")["ok"], "one run at a time")
	)

	run_case("save_round_trip_preserves_open_procedure_run", func():
		var root := _fresh()
		BenchPrototype.begin_procedure_run("timePearl")
		var expected: Dictionary = GameState.deep_copy(root)
		var raw = JSON.parse_string(JSON.stringify(GameState.state))
		assert_true(SaveManager._load_save_dict(raw)["ok"], "save loads")
		assert_eq(GameState.state["benchPrototype"], expected, "open procedure run survives a save")
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

	run_case("plan_edits_insert_remove_nudge_and_feed_the_next_run", func():
		var root := _fresh()
		var s: Dictionary = root["slices"][P]
		assert_eq(BenchPrototype.planned_procedure("healingSalve"), BenchPrototype.known_procedure("healingSalve"), "unedited plan = known procedure")
		assert_true(BenchPrototype.insert_step("healingSalve", 2, "distilling")["ok"])
		assert_true(not BenchPrototype.insert_step("healingSalve", 4, "distilling")["ok"], "no slot past the end")
		assert_true(not BenchPrototype.insert_step("healingSalve", 0, "stirring")["ok"], "unknown apparatus refused")
		var plan := BenchPrototype.planned_procedure("healingSalve")
		assert_eq(plan.size(), 3)
		assert_eq(plan[2], { "apparatus": "distilling", "target": float(_data()["insertTarget"]), "knowledge": "inserted" })
		assert_true(BenchPrototype.nudge_step("healingSalve", 1, 4.0)["ok"])
		assert_eq(BenchPrototype.planned_procedure("healingSalve")[1]["target"], 54.0, "heat nudged up")
		BenchPrototype.nudge_step("healingSalve", 1, 200.0)
		assert_eq(BenchPrototype.planned_procedure("healingSalve")[1]["target"], 100.0, "nudge clamps to the gauge")
		assert_true(not BenchPrototype.remove_step("healingSalve", 0)["ok"], "a base step can't be removed")
		assert_eq(BenchPrototype.known_procedure("healingSalve").size(), 2, "editing never changes knowledge")
		BenchPrototype.begin_procedure_run("healingSalve")
		assert_eq(s["activeRun"]["procedure"].size(), 3, "the run performs the plan")
		assert_true(not BenchPrototype.insert_step("healingSalve", 0, "heat")["ok"], "no edits mid-run")
		assert_true(not BenchPrototype.nudge_step("healingSalve", 0, 2.0)["ok"], "no nudges mid-run")
		BenchPrototype.abandon_run(P)
		assert_true(BenchPrototype.remove_step("healingSalve", 2)["ok"], "an inserted step can be removed")
		assert_eq(BenchPrototype.planned_procedure("healingSalve").size(), 2)
		BenchPrototype.reset_plan("healingSalve")
		assert_eq(BenchPrototype.planned_procedure("healingSalve"), BenchPrototype.known_procedure("healingSalve"), "reset drops edits")
	)

	run_case("notebook_clues_cover_hit_near_none_and_changed", func():
		_fresh()
		BenchPrototype.set_skill_override(0)
		var procedure := [
			{ "apparatus": "grinding", "target": 50.0, "knowledge": "base" },
			{ "apparatus": "heat", "target": 50.0, "knowledge": "base" },
			{ "apparatus": "distilling", "target": 50.0, "knowledge": "inserted" },
			{ "apparatus": "compression", "target": 50.0, "knowledge": "inserted" },
		]
		var performed := [
			{ "apparatus": "grinding", "readings": [50.0, 52.0, 48.0] },
			{ "apparatus": "heat", "value": 40.0 },
			BenchPrototype.distil_readings(_distil_taps(50.0)).merged({ "apparatus": "distilling" }),
			{ "apparatus": "compression", "value": 50.0 },
		]
		var clues := BenchPrototype.notebook_clues("healingSalve", procedure, performed)
		assert_eq(clues.map(func(c): return c["clue"]), ["hit", "near", "changed", "none"])
		assert_eq(clues[1]["direction"], "higher", "heat 40 under the ideal 62")
		assert_eq(clues[3]["ideal"], -1, "an extra step matches nothing")
		performed[1] = { "apparatus": "heat", "value": 80.0 }
		assert_eq(BenchPrototype.notebook_clues("healingSalve", procedure, performed)[1]["direction"], "lower")
		performed[0] = { "apparatus": "grinding", "readings": [50.0, 50.0, null] }
		var missed: Dictionary = BenchPrototype.notebook_clues("healingSalve", procedure, performed)[0]
		assert_eq([missed["clue"], missed["direction"]], ["near", null], "a missed stroke: right amount, no direction")
		BenchPrototype.set_hint_level(P, "healingSalve", "distilFinish", "vague")
		assert_eq(BenchPrototype.notebook_clues("healingSalve", procedure, performed)[2]["clue"], "hit", "a known step isn't a discovery")
	)

	run_case("notebook_changed_needs_the_hidden_step_in_position", func():
		_fresh()
		BenchPrototype.set_skill_override(0)
		var distil := BenchPrototype.distil_readings(_distil_taps(50.0)).merged({ "apparatus": "distilling" })
		var procedure := [
			{ "apparatus": "distilling", "target": 50.0, "knowledge": "inserted" },
			{ "apparatus": "grinding", "target": 50.0, "knowledge": "base" },
			{ "apparatus": "heat", "target": 62.0, "knowledge": "base" },
		]
		var performed := [distil, { "apparatus": "grinding", "readings": [50.0, 50.0, 50.0] }, { "apparatus": "heat", "value": 62.0 }]
		var clues := BenchPrototype.notebook_clues("healingSalve", procedure, performed)
		assert_true(clues[0]["clue"] != "changed", "a distil first displaces the grind and heat")
		var heat_first := [{ "apparatus": "heat", "target": 50.0, "knowledge": "inserted" }, procedure[1], procedure[2]]
		var heat_performed := [{ "apparatus": "heat", "value": 62.0 }, performed[1], performed[2]]
		assert_true(BenchPrototype.notebook_clues("healingSalve", heat_first, heat_performed)[0]["clue"] != "changed",
			"an inserted step on a base-matched ideal step isn't a discovery")
	)

	run_case("discovery_grants_vague_then_three_hits_upgrade_to_exact_and_rewind_undoes", func():
		var root := _fresh()
		BenchPrototype.set_skill_override(0)
		BenchPrototype.insert_step("healingSalve", 2, "distilling")
		BenchPrototype.begin_procedure_run("healingSalve")
		_perform_at(50.0)
		_perform_at(62.0)
		_perform_at(50.0)
		var s: Dictionary = root["slices"][P]
		assert_eq(BenchPrototype.hint_level(P, "healingSalve", "distilFinish"), "vague", "something changed → vague")
		assert_eq(s["notebook"]["healingSalve"][2]["clue"], "changed")
		assert_eq(s["notebook"]["healingSalve"][2]["learned"], "vague")
		var plan_step: Dictionary = BenchPrototype.planned_procedure("healingSalve")[2]
		assert_eq([plan_step["knowledge"], plan_step["hintId"]], ["vague", "distilFinish"], "the inserted step became the hinted one")
		var needed := int(_data()["vagueToExactHits"])
		for run_i in needed:
			BenchPrototype.begin_procedure_run("healingSalve")
			_perform_at(50.0)
			_perform_at(62.0)
			_perform_at(50.0)
			s = root["slices"][P]
			var expected: String = "exact" if run_i == needed - 1 else "vague"
			assert_eq(BenchPrototype.hint_level(P, "healingSalve", "distilFinish"), expected, "after %d ✓ runs" % (run_i + 1))
			assert_eq(s["notebook"]["healingSalve"][2]["hits"], run_i + 1)
		assert_eq(BenchPrototype.planned_procedure("healingSalve")[2]["knowledge"], "exact", "plan shows the exact step")
		BenchPrototype.rewind(P)
		assert_eq(BenchPrototype.hint_level(P, "healingSalve", "distilFinish"), "vague", "rewind undoes the upgrade")
		assert_eq(root["slices"][P]["vagueHits"]["healingSalve"]["distilFinish"], needed - 1)
		for i in needed:
			BenchPrototype.rewind(P)
		assert_eq(BenchPrototype.hint_level(P, "healingSalve", "distilFinish"), "off", "rewind undoes the discovery")
		assert_eq(BenchPrototype.planned_procedure("healingSalve")[2]["knowledge"], "inserted", "plan back to the guess")
	)

	run_case("debug_hint_toggle_drops_plan_and_hits", func():
		var root := _fresh()
		var s: Dictionary = root["slices"][P]
		BenchPrototype.insert_step("healingSalve", 2, "distilling")
		s["vagueHits"]["healingSalve"] = { "distilFinish": 2 }
		BenchPrototype.set_hint_level(P, "healingSalve", "distilFinish", "vague")
		assert_true(not s["plans"].has("healingSalve"), "plan rebuilt from knowledge")
		assert_true(not s["vagueHits"]["healingSalve"].has("distilFinish"), "hit count reset")
	)

	run_case("save_round_trip_preserves_plans_notebook_and_hits", func():
		var root := _fresh()
		BenchPrototype.set_skill_override(0)
		BenchPrototype.insert_step("healingSalve", 2, "distilling")
		for i in 2:
			BenchPrototype.begin_procedure_run("healingSalve")
			_perform_at(50.0)
			_perform_at(62.0)
			_perform_at(50.0)
		var expected: Dictionary = GameState.deep_copy(root)
		var raw = JSON.parse_string(JSON.stringify(GameState.state))
		assert_true(SaveManager._load_save_dict(raw)["ok"], "save loads")
		assert_eq(GameState.state["benchPrototype"], expected, "plans, notebook and hits survive a save")
	)

	# ── Chart (Slice B) ──

	run_case("chart_data_covers_every_recipe_and_pour_direction", func():
		_fresh()
		for recipe_id in _data()["roster"]:
			var region: Dictionary = BenchPrototype.recipe_chart(recipe_id)
			assert_eq(region["centre"].size(), 2, "%s centre" % recipe_id)
			assert_true(float(region["bullseyeRadius"]) < float(region["radius"]), "%s bullseye inside region" % recipe_id)
		assert_eq(_data()["chart"]["directions"]["life"], [1, 0], "life pours →")
		assert_eq(_data()["chart"]["directions"]["time"], [0, 1], "time pours ↑")
	)

	run_case("chart_score_bullseye_100_edge_rank_1_outside_0", func():
		_fresh()
		BenchPrototype.set_skill_override(0)
		var region: Dictionary = BenchPrototype.recipe_chart("healingSalve")
		var centre := Vector2(region["centre"][0], region["centre"][1])
		var radius := float(region["radius"])
		var bullseye := float(region["bullseyeRadius"])
		assert_eq(BenchPrototype.chart_score("healingSalve", centre), 100, "dead centre")
		assert_eq(BenchPrototype.chart_score("healingSalve", centre + Vector2(bullseye, 0)), 100, "bullseye rim")
		var edge := BenchPrototype.chart_score("healingSalve", centre + Vector2(0, radius))
		assert_eq(edge, int(_data()["rankThresholds"][0]), "region edge is the rank-1 threshold")
		assert_eq(BenchPrototype.rank_for_score(edge), 1, "edge is rank 1")
		assert_eq(BenchPrototype.chart_score("healingSalve", centre + Vector2(radius + 0.5, 0)), 0, "outside the region")
		var midway := BenchPrototype.chart_score("healingSalve", centre + Vector2((bullseye + radius) / 2.0, 0))
		assert_eq(midway, roundi(lerpf(100.0, edge, 0.5)), "linear fall-off")
	)

	run_case("skill_widens_the_bullseye", func():
		_fresh()
		var region: Dictionary = BenchPrototype.recipe_chart("healingBurst")
		var centre := Vector2(region["centre"][0], region["centre"][1])
		var off := centre + Vector2(float(region["bullseyeRadius"]) * 1.5, 0)
		BenchPrototype.set_skill_override(0)
		assert_almost_eq(BenchPrototype.bullseye_radius("healingBurst"), float(region["bullseyeRadius"]), 0.0001, "skill 0 = base radius")
		assert_true(BenchPrototype.chart_score("healingBurst", off) < 100, "skill 0 misses the bullseye")
		BenchPrototype.set_skill_override(10)
		assert_almost_eq(BenchPrototype.bullseye_radius("healingBurst"), float(region["bullseyeRadius"]) * (1.0 + float(_data()["skillFactor"]) * 10), 0.0001, "base × (1 + skillFactor × skill)")
		assert_eq(BenchPrototype.chart_score("healingBurst", off), 100, "skill 10 hits it")
	)

	run_case("pour_slides_the_marker_and_charges_calc_per_distance", func():
		var root := _fresh()
		var s: Dictionary = root["slices"][C]
		var speed := float(_data()["chart"]["pourSpeed"])
		var units := float(_data()["chart"]["unitsPerCalc"])
		var life: int = s["pool"]["life"]
		assert_true(BenchPrototype.begin_chart_run("healingSalve")["ok"])
		assert_eq(s["pool"]["life"], life, "opening a chart run spends nothing")
		var hold := units * 1.5 / speed
		var preview := BenchPrototype.pour_preview("life", hold)
		assert_eq(s["pool"]["life"], life, "preview spends nothing")
		var poured := BenchPrototype.pour("life", hold)
		assert_true(poured["ok"])
		assert_almost_eq(poured["distance"], units * 1.5, 0.001, "hold × speed")
		assert_eq(poured["cost"], preview["cost"], "preview matches the pour")
		assert_eq(s["pool"]["life"], life - 2, "1.5 units' worth rounds up to 2 calc")
		BenchPrototype.pour("life", units * 0.5 / speed)
		assert_eq(s["pool"]["life"], life - 2, "the remainder was already paid for")
		BenchPrototype.pour("time", units / speed)
		assert_almost_eq(BenchPrototype.chart_marker().x, units * 2.0, 0.001, "life moves →")
		assert_almost_eq(BenchPrototype.chart_marker().y, units, 0.001, "time moves ↑")
		assert_eq(s["activeRun"]["path"].size(), 4, "origin plus one point per pour")
		assert_eq(s["activeRun"]["calcSpent"], { "life": 2, "time": 1 }, "run tracks its spend")
	)

	run_case("running_out_of_calc_stops_the_pour", func():
		var root := _fresh()
		var s: Dictionary = root["slices"][C]
		var units := float(_data()["chart"]["unitsPerCalc"])
		s["pool"]["life"] = 1
		BenchPrototype.begin_chart_run("healingSalve")
		var poured := BenchPrototype.pour("life", 60.0)
		assert_true(poured["stopped"], "pour stopped short")
		assert_almost_eq(poured["distance"], units, 0.001, "one calc's worth of distance")
		assert_eq(s["pool"]["life"], 0, "pool spent")
		assert_true(not BenchPrototype.pour("life", 1.0)["ok"], "dry jar won't pour")
		assert_true(BenchPrototype.pour("time", 0.1)["ok"], "other jars still pour")
	)

	run_case("bottle_in_the_bullseye_scores_100_and_feeds_the_shared_core", func():
		var root := _fresh()
		var s: Dictionary = root["slices"][C]
		BenchPrototype.set_skill_override(0)
		var life: int = s["pool"]["life"]
		var centre: Array = BenchPrototype.recipe_chart("healingSalve")["centre"]
		BenchPrototype.begin_chart_run("healingSalve")
		BenchPrototype.pour("life", float(centre[0]) / float(_data()["chart"]["pourSpeed"]))
		var bottled := BenchPrototype.bottle()
		assert_true(bottled["ok"])
		assert_eq(bottled["entry"]["score"], 100)
		assert_eq(bottled["entry"]["rank"], 5)
		assert_eq(s["bestRanks"]["healingSalve"], 5, "best rank rises")
		assert_eq(s["activeRun"], null, "bottling ends the run")
		assert_eq(s["ledger"][-1]["recipeId"], "healingSalve", "logged")
		assert_eq(s["pool"]["life"], life - int(_data()["recipes"]["healingSalve"]["baseCalc"]["life"]), "straight pour costs the base calc")
		assert_true(not BenchPrototype.pour("life", 1.0)["ok"], "no pouring after bottling")
		assert_true(BenchPrototype.rewind(C)["ok"])
		assert_eq(s["pool"]["life"], life, "rewind restores calc")
		assert_eq(s["bestRanks"]["healingSalve"], 0, "and the rank")
	)

	run_case("bottle_outside_the_region_scores_zero_and_abandon_loses_calc", func():
		var root := _fresh()
		var s: Dictionary = root["slices"][C]
		BenchPrototype.begin_chart_run("timePearl")
		BenchPrototype.pour("life", 1.0)
		assert_eq(BenchPrototype.bottle()["entry"]["score"], 0, "nowhere near the pearl")
		var life: int = s["pool"]["life"]
		BenchPrototype.begin_chart_run("timePearl")
		BenchPrototype.pour("life", 1.0)
		BenchPrototype.abandon_run(C)
		assert_true(s["pool"]["life"] < life, "abandoning keeps the spend")
		assert_eq(s["ledger"][-1]["kind"], "abandoned")
	)

	run_case("save_round_trip_preserves_open_chart_run", func():
		var root := _fresh()
		BenchPrototype.begin_chart_run("healingBurst")
		BenchPrototype.pour("life", 0.7)
		BenchPrototype.pour("time", 1.3)
		var expected: Dictionary = GameState.deep_copy(root)
		var raw = JSON.parse_string(JSON.stringify(GameState.state))
		assert_true(SaveManager._load_save_dict(raw)["ok"], "save loads")
		assert_eq(GameState.state["benchPrototype"], expected, "open chart run survives a save")
	)

	run_case("heat_rotates_the_next_pour_and_stacks", func():
		var root := _fresh()
		var s: Dictionary = root["slices"][C]
		var speed := float(_data()["chart"]["pourSpeed"])
		BenchPrototype.begin_chart_run("healingBurst")
		assert_true(BenchPrototype.apply_apparatus("heat")["ok"])
		assert_almost_eq(BenchPrototype.chart_queue()["rotateDeg"], 45.0, 0.001, "queued 45°")
		BenchPrototype.pour("life", 10.0 / speed)
		var marker := BenchPrototype.chart_marker()
		assert_almost_eq(marker.x, 10.0 * cos(PI / 4.0), 0.001, "life turned 45° anticlockwise: x")
		assert_almost_eq(marker.y, 10.0 * sin(PI / 4.0), 0.001, "and y")
		assert_eq(BenchPrototype.chart_queue(), { "rotateDeg": 0.0, "speedMul": 1.0 }, "the pour consumed the queue")
		BenchPrototype.pour("life", 10.0 / speed)
		assert_almost_eq(BenchPrototype.chart_marker().x - marker.x, 10.0, 0.001, "the next pour is straight again")
		assert_almost_eq(BenchPrototype.chart_marker().y, marker.y, 0.001, "and doesn't climb")
		BenchPrototype.apply_apparatus("heat")
		BenchPrototype.apply_apparatus("heat")
		var before := BenchPrototype.chart_marker()
		BenchPrototype.pour("life", 10.0 / speed)
		assert_almost_eq(BenchPrototype.chart_marker().x, before.x, 0.001, "heat ×2 = 90°: life pours ↑")
		assert_almost_eq(BenchPrototype.chart_marker().y - before.y, 10.0, 0.001, "a full 10 units up")
		assert_eq(s["activeRun"]["calcSpent"].keys(), ["life"], "rotated life still costs life")
	)

	run_case("grind_halves_compress_doubles_and_they_cancel", func():
		_fresh()
		var speed := float(_data()["chart"]["pourSpeed"])
		BenchPrototype.begin_chart_run("healingSalve")
		BenchPrototype.apply_apparatus("grinding")
		assert_almost_eq(BenchPrototype.pour("life", 1.0)["distance"], speed * 0.5, 0.001, "grind halves the speed")
		BenchPrototype.apply_apparatus("compression")
		assert_almost_eq(BenchPrototype.pour("life", 1.0)["distance"], speed * 2.0, 0.001, "compress doubles it")
		BenchPrototype.apply_apparatus("grinding")
		BenchPrototype.apply_apparatus("compression")
		assert_almost_eq(BenchPrototype.chart_queue()["speedMul"], 1.0, 0.0001, "grind + compress cancel")
		assert_almost_eq(BenchPrototype.pour("life", 1.0)["distance"], speed, 0.001, "so the pour is normal speed")
		BenchPrototype.apply_apparatus("grinding")
		BenchPrototype.apply_apparatus("grinding")
		var preview := BenchPrototype.pour_preview("time", 1.0)
		assert_almost_eq(preview["distance"], speed * 0.25, 0.001, "grind ×2 quarters the preview")
		assert_almost_eq(BenchPrototype.pour("time", 1.0)["distance"], preview["distance"], 0.001, "preview matches the pour")
	)

	run_case("distil_pulls_the_marker_back_now_and_keeps_the_queue", func():
		var root := _fresh()
		var s: Dictionary = root["slices"][C]
		var speed := float(_data()["chart"]["pourSpeed"])
		var pull := float(_data()["chart"]["apparatus"]["distilling"]["pullBack"])
		assert_true(not BenchPrototype.apply_apparatus("distilling")["ok"], "no run, no distil")
		BenchPrototype.begin_chart_run("healingBurst")
		BenchPrototype.pour("life", 40.0 / speed)
		BenchPrototype.pour("time", 20.0 / speed)
		var pool_before: Dictionary = s["pool"].duplicate()
		BenchPrototype.apply_apparatus("heat")
		assert_true(BenchPrototype.apply_apparatus("distilling")["ok"])
		assert_almost_eq(BenchPrototype.chart_marker().x, 40.0 * (1.0 - pull), 0.001, "x pulled toward origin")
		assert_almost_eq(BenchPrototype.chart_marker().y, 20.0 * (1.0 - pull), 0.001, "y pulled toward origin")
		assert_eq(s["activeRun"]["path"].size(), 4, "distil leaves a path point")
		assert_eq(s["pool"], pool_before, "distil costs no calc")
		assert_almost_eq(BenchPrototype.chart_queue()["rotateDeg"], 45.0, 0.001, "the queued heat waits for the pour")
		assert_true(not BenchPrototype.apply_apparatus("bogus")["ok"], "unknown apparatus rejected")
	)

	run_case("rewind_restores_marker_queue_and_calc", func():
		var root := _fresh()
		var before: Dictionary = GameState.deep_copy(root["slices"][C])
		before.erase("snapshots")
		BenchPrototype.begin_chart_run("healingBurst")
		BenchPrototype.apply_apparatus("heat")
		BenchPrototype.pour("life", 1.0)
		BenchPrototype.apply_apparatus("distilling")
		BenchPrototype.apply_apparatus("compression")
		assert_true(BenchPrototype.rewind(C)["ok"])
		var after: Dictionary = GameState.deep_copy(root["slices"][C])
		after.erase("snapshots")
		assert_eq(after, before, "rewind undoes the whole run: marker, queue and calc")
		assert_eq(BenchPrototype.chart_queue(), { "rotateDeg": 0.0, "speedMul": 1.0 }, "no queue left over")
		assert_eq(BenchPrototype.chart_marker(), Vector2.ZERO, "no marker left over")
	)

	run_case("save_round_trip_preserves_queued_transforms", func():
		var root := _fresh()
		BenchPrototype.begin_chart_run("healingBurst")
		BenchPrototype.pour("life", 0.7)
		BenchPrototype.apply_apparatus("heat")
		BenchPrototype.apply_apparatus("grinding")
		var expected: Dictionary = GameState.deep_copy(root)
		var raw = JSON.parse_string(JSON.stringify(GameState.state))
		assert_true(SaveManager._load_save_dict(raw)["ok"], "save loads")
		assert_eq(GameState.state["benchPrototype"], expected, "queued transforms survive a save")
	)

	run_case("validator_flags_missing_apparatus_transform", func():
		_fresh()
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["bench_prototype"]["chart"]["apparatus"]["distilling"]["pullBack"] = 1.5
		corrupted["bench_prototype"]["chart"]["apparatus"]["heat"].erase("rotateDeg")
		var found := { "pullBack": false, "rotateDeg": false }
		for e in GameData.validate_tables(corrupted):
			for key in found.keys():
				if e.contains("chart.apparatus") and e.contains(key):
					found[key] = true
		assert_eq(found, { "pullBack": true, "rotateDeg": true }, "bad transforms are flagged")
	)

	run_case("validator_flags_bullseye_not_inside_region", func():
		_fresh()
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["bench_prototype"]["recipes"]["timePearl"]["chart"]["bullseyeRadius"] = 99
		var found := false
		for e in GameData.validate_tables(corrupted):
			if e.contains("timePearl.chart") and e.contains("bullseyeRadius"):
				found = true
		assert_true(found, "a bullseye wider than its region should be flagged")
	)
