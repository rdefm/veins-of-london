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
				assert_eq(s["hintLevels"][recipe_id], "off", "%s.%s hints start off" % [slice_id, recipe_id])
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
		BenchPrototype.set_hint_level(P, "timePearl", "vague")
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

	run_case("hint_levels_are_per_slice_per_recipe", func():
		var root := _fresh()
		assert_true(BenchPrototype.set_hint_level(P, "healingBurst", "exact")["ok"])
		assert_true(not BenchPrototype.set_hint_level(P, "healingBurst", "loud")["ok"], "unknown level refused")
		assert_eq(root["slices"][P]["hintLevels"]["healingBurst"], "exact")
		assert_eq(root["slices"][C]["hintLevels"]["healingBurst"], "off")
	)

	run_case("no_prototype_action_touches_state_outside_bench_prototype", func():
		_fresh()
		var before := _outside_state()
		Rng.set_seed(3)
		BenchPrototype.set_skill_override(9)
		BenchPrototype.set_bonus_type("calcRefund")
		for slice_id in BenchPrototype.SLICES:
			BenchPrototype.set_active_slice(slice_id)
			BenchPrototype.set_hint_level(slice_id, "timePearl", "exact")
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
		var band := BenchPrototype.known_band("healingSalve", { "target": 50 })
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

	run_case("base_procedure_executed_perfectly_caps_at_rank_2_to_3", func():
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
