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
