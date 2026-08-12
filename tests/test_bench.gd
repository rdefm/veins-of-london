extends "res://tests/test_base.gd"


func run() -> void:
	run_case("type_set_key_sorts_alphabetically_and_normalizes_both_orders", func():
		assert_eq(Bench.type_set_key(["life"]), "life", "single type is a bare key")
		assert_eq(Bench.type_set_key(["time", "life"]), "life+time", "sorted alphabetically, +-joined")
		assert_eq(Bench.type_set_key(["life", "time"]), "life+time", "both input orders normalize identically")
	)

	run_case("cell_key_joins_the_type_set_key_and_approach_with_a_pipe", func():
		assert_eq(Bench.cell_key(["time", "life"], "heat"), "life+time|heat")
	)

	run_case("cell_state_defaults_to_untried_for_an_absent_cell", func():
		GameState.reset()
		assert_eq(Bench.cell_state(["life", "time"], "heat"), "untried", "absent cell key means untried")
	)

	run_case("probe_on_an_empty_cell_resolves_to_inert_with_no_roll", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		# No recipe is assigned to this cell: deliberately barren.
		var result := Bench.probe(["life", "time"], "heat")
		assert_true(result["ok"])
		assert_eq(result["outcome"], "inert", "an empty cell always resolves to inert")
		assert_eq(Bench.cell_state(["life", "time"], "heat"), "inert")
		assert_eq(GameState.state["player"]["craftingXP"], 6, "inert still awards XP_INERT")
	)

	run_case("probing_an_inert_cell_is_blocked_and_the_cell_never_leaves_inert", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		Bench.probe(["life", "time"], "heat")
		assert_eq(Bench.cell_state(["life", "time"], "heat"), "inert")

		var ore_before: int = GameState.state["player"]["orichalchum"]["time"]
		var result := Bench.probe(["life", "time"], "heat")
		assert_true(not result["ok"], "a probe against an inert cell must refuse")
		assert_eq(Bench.cell_state(["life", "time"], "heat"), "inert", "inert is permanent — no probe can move it out")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], ore_before, "a blocked probe must not deduct ore")
	)

	run_case("probe_hit_on_an_occupied_cell_resolves_to_found", func():
		GameData.RECIPES["_testBenchEffect"] = { "discovery": { "types": ["life", "time"], "approach": "heat" } }
		var seed := -1
		for candidate in range(500):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["orichalchum"]["life"] = 100
			GameState.state["player"]["craftingSkill"] = 5
			Rng.set_seed(candidate)
			var result := Bench.probe(["life", "time"], "heat")
			if result.get("outcome") == "found":
				seed = candidate
				break
		assert_true(seed != -1, "should find a discovery-success roll within 500 tries")
		assert_eq(Bench.cell_state(["life", "time"], "heat"), "found")
		assert_eq(GameState.state["player"]["craftingXP"], 40, "success awards XP_FOUND")
		GameData.RECIPES.erase("_testBenchEffect")
	)

	run_case("probe_miss_on_an_occupied_cell_resolves_to_hot_and_increments_misses", func():
		GameData.RECIPES["_testBenchEffect"] = { "discovery": { "types": ["life", "time"], "approach": "heat" } }
		var seed := -1
		for candidate in range(500):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["orichalchum"]["life"] = 100
			GameState.state["player"]["craftingSkill"] = 1
			Rng.set_seed(candidate)
			var result := Bench.probe(["life", "time"], "heat")
			if result.get("outcome") == "hot":
				seed = candidate
				break
		assert_true(seed != -1, "should find a discovery-failure roll within 500 tries")
		assert_eq(Bench.cell_state(["life", "time"], "heat"), "hot")
		assert_eq(Bench.get_cell(["life", "time"], "heat")["misses"], 1)
		assert_eq(GameState.state["player"]["craftingXP"], 12, "failure awards XP_HOT")
		GameData.RECIPES.erase("_testBenchEffect")
	)

	run_case("pity_accumulates_per_miss_and_raises_the_next_roll_odds", func():
		GameState.reset()
		var base := Bench.discovery_chance(["life", "time"], "heat", 1)
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "hot", "misses": 3, "refine": 0 }
		var after := Bench.discovery_chance(["life", "time"], "heat", 1)
		assert_almost_eq(after - base, 3 * 0.12, 0.0001, "pity should add +0.12 per prior miss, uncapped count")
	)

	run_case("discovery_chance_caps_at_0_90", func():
		GameState.reset()
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "hot", "misses": 50, "refine": 0 }
		var chance := Bench.discovery_chance(["life", "time"], "heat", 5)
		assert_almost_eq(chance, 0.90, 0.0001, "chance should clamp at the 0.90 cap")
	)

	run_case("census_reveals_total_effect_count_including_unlearned_approaches_on_first_probe", func():
		GameState.reset()
		GameData.RECIPES["_testBenchHeat"] = { "discovery": { "types": ["life", "time"], "approach": "heat" } }
		GameData.RECIPES["_testBenchDistilling"] = { "discovery": { "types": ["time", "life"], "approach": "distilling" } }
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100

		assert_true(not Bench.is_surveyed(["life", "time"]), "sanity: unsurveyed before any probe")
		assert_true(not Approaches.is_known("distilling"), "sanity: distilling is not learned by default")

		Bench.probe(["life", "time"], "heat")

		assert_true(Bench.is_surveyed(["life", "time"]), "the pairing's first probe should survey it")
		assert_eq(Bench.get_surveyed_count(["life", "time"]), 2, "census counts both effects, including the one behind an unlearned approach")

		GameData.RECIPES.erase("_testBenchHeat")
		GameData.RECIPES.erase("_testBenchDistilling")
	)

	run_case("census_survey_is_written_once_and_does_not_change_on_later_probes", func():
		GameState.reset()
		GameData.RECIPES["_testBenchHeat"] = { "discovery": { "types": ["life", "time"], "approach": "heat" } }
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100

		Bench.probe(["life", "time"], "heat")
		assert_eq(Bench.get_surveyed_count(["life", "time"]), 1)

		GameData.RECIPES["_testBenchGrinding"] = { "discovery": { "types": ["life", "time"], "approach": "grinding" } }
		Bench.probe(["life", "time"], "grinding")
		assert_eq(Bench.get_surveyed_count(["life", "time"]), 1, "the survey count is fixed permanently at the first probe, not recomputed")

		GameData.RECIPES.erase("_testBenchHeat")
		GameData.RECIPES.erase("_testBenchGrinding")
	)

	run_case("census_of_a_barren_set_surveys_to_zero", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		Bench.probe(["life", "time"], "heat")
		assert_eq(Bench.get_surveyed_count(["life", "time"]), 0, "a barren set surveys flatly to zero")
	)

	run_case("ore_is_always_deducted_regardless_of_outcome", func():
		# Empty cell -> inert.
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		Bench.probe(["life", "time"], "heat")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 97, "3 ore deducted per type for an inert outcome")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 97, "3 ore deducted per type for an inert outcome")

		# Occupied cell — ore should still be down by 3 each, hit or miss.
		GameData.RECIPES["_testBenchEffect"] = { "discovery": { "types": ["life", "time"], "approach": "grinding" } }
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		Rng.set_seed(1)
		Bench.probe(["life", "time"], "grinding")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 97, "3 ore deducted regardless of hit/miss")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 97, "3 ore deducted regardless of hit/miss")
		GameData.RECIPES.erase("_testBenchEffect")
	)

	run_case("probe_blocked_without_enough_ore_deducts_nothing", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 1
		GameState.state["player"]["orichalchum"]["life"] = 100
		var result := Bench.probe(["life", "time"], "heat")
		assert_true(not result["ok"], "insufficient ore on any one type should refuse the whole probe")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 1, "no deduction when blocked")
		assert_eq(Bench.cell_state(["life", "time"], "heat"), "untried", "a blocked probe must not resolve the cell")
	)

	run_case("probe_blocked_on_an_unlearned_approach", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		var result := Bench.probe(["time"], "distilling")
		assert_true(not result["ok"], "distilling is not known by default (needs the lab room)")
		assert_eq(Bench.cell_state(["time"], "distilling"), "untried")
	)

	run_case("probe_advances_a_time_block", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 0)
		Bench.probe(["life", "time"], "heat")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 1, "an experiment costs one time block")
	)

	run_case("notes_are_capped_at_20_per_pairing_oldest_dropped", func():
		GameState.reset()
		for i in range(25):
			GameState.state["world"]["day"] = i
			Bench._append_note(["life", "time"], "heat", "hot")
		var notes: Array = GameState.state["player"]["bench"]["notes"]["life+time"]
		assert_eq(notes.size(), 20, "notes array should be capped at 20")
		assert_eq(notes[0]["day"], 5, "the oldest 5 entries (days 0-4) should have been dropped")
		assert_eq(notes[19]["day"], 24, "the most recent entry is retained")
	)
