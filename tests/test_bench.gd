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
		GameState.state["player"]["orichalchum"]["fate"] = 100
		GameState.state["player"]["orichalchum"]["physics"] = 100
		# fate+physics has no authored effect at any approach (calc-discovery
		# ticket 10's cell assignment) -- deliberately barren, unlike
		# life+time which now holds real content on several approaches.
		var result := Bench.probe(["fate", "physics"], "heat")
		assert_true(result["ok"])
		assert_eq(result["outcome"], "inert", "an empty cell always resolves to inert")
		assert_eq(Bench.cell_state(["fate", "physics"], "heat"), "inert")
		assert_eq(GameState.state["player"]["craftingXP"], 6, "inert still awards XP_INERT")
	)

	run_case("probing_an_inert_cell_is_blocked_and_the_cell_never_leaves_inert", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["fate"] = 100
		GameState.state["player"]["orichalchum"]["physics"] = 100
		Bench.probe(["fate", "physics"], "heat")
		assert_eq(Bench.cell_state(["fate", "physics"], "heat"), "inert")

		var ore_before: int = GameState.state["player"]["orichalchum"]["fate"]
		var result := Bench.probe(["fate", "physics"], "heat")
		assert_true(not result["ok"], "a probe against an inert cell must refuse")
		assert_eq(Bench.cell_state(["fate", "physics"], "heat"), "inert", "inert is permanent — no probe can move it out")
		assert_eq(GameState.state["player"]["orichalchum"]["fate"], ore_before, "a blocked probe must not deduct ore")
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
		assert_eq(GameState.state["player"]["craftingXP"], 50, "success awards XP_FOUND")
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
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "hot", "misses": 3, "tier": 1, "progress": 0 }
		var after := Bench.discovery_chance(["life", "time"], "heat", 1)
		assert_almost_eq(after - base, 3 * 0.12, 0.0001, "pity should add +0.12 per prior miss, uncapped count")
	)

	run_case("discovery_chance_caps_at_0_90", func():
		GameState.reset()
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "hot", "misses": 50, "tier": 1, "progress": 0 }
		var chance := Bench.discovery_chance(["life", "time"], "heat", 5)
		assert_almost_eq(chance, 0.90, 0.0001, "chance should clamp at the 0.90 cap")
	)

	run_case("census_reveals_total_effect_count_including_unlearned_approaches_on_first_probe", func():
		GameState.reset()
		GameData.RECIPES["_testBenchHeat"] = { "discovery": { "types": ["fate", "physics"], "approach": "heat" } }
		GameData.APPROACHES["_testGated"] = { "name": "Gated", "symbol": "?", "source": { "type": "room", "id": "lab" } }
		GameData.RECIPES["_testBenchDistilling"] = { "discovery": { "types": ["physics", "fate"], "approach": "_testGated" } }
		GameState.state["player"]["orichalchum"]["fate"] = 100
		GameState.state["player"]["orichalchum"]["physics"] = 100

		assert_true(not Bench.is_surveyed(["fate", "physics"]), "sanity: unsurveyed before any probe")
		assert_true(not Approaches.is_known("_testGated"), "sanity: the gated approach is not learned by default")

		Bench.probe(["fate", "physics"], "heat")

		assert_true(Bench.is_surveyed(["fate", "physics"]), "the pairing's first probe should survey it")
		assert_eq(Bench.get_surveyed_count(["fate", "physics"]), 2, "census counts both effects, including the one behind an unlearned approach")

		GameData.RECIPES.erase("_testBenchHeat")
		GameData.RECIPES.erase("_testBenchDistilling")
		GameData.APPROACHES.erase("_testGated")
	)

	run_case("census_survey_is_written_once_and_does_not_change_on_later_probes", func():
		GameState.reset()
		GameData.RECIPES["_testBenchHeat"] = { "discovery": { "types": ["fate", "physics"], "approach": "heat" } }
		GameState.state["player"]["orichalchum"]["fate"] = 100
		GameState.state["player"]["orichalchum"]["physics"] = 100

		Bench.probe(["fate", "physics"], "heat")
		assert_eq(Bench.get_surveyed_count(["fate", "physics"]), 1)

		GameData.RECIPES["_testBenchGrinding"] = { "discovery": { "types": ["fate", "physics"], "approach": "grinding" } }
		Bench.probe(["fate", "physics"], "grinding")
		assert_eq(Bench.get_surveyed_count(["fate", "physics"]), 1, "the survey count is fixed permanently at the first probe, not recomputed")

		GameData.RECIPES.erase("_testBenchHeat")
		GameData.RECIPES.erase("_testBenchGrinding")
	)

	run_case("census_of_a_barren_set_surveys_to_zero", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["fate"] = 100
		GameState.state["player"]["orichalchum"]["physics"] = 100
		Bench.probe(["fate", "physics"], "heat")
		assert_eq(Bench.get_surveyed_count(["fate", "physics"]), 0, "a barren set surveys flatly to zero")
	)

	run_case("found_count_in_set_counts_only_cells_actually_found", func():
		GameState.reset()
		GameData.RECIPES["_testBenchHeat"] = { "discovery": { "types": ["fate", "physics"], "approach": "heat" } }
		GameData.RECIPES["_testBenchGrinding"] = { "discovery": { "types": ["fate", "physics"], "approach": "grinding" } }
		assert_eq(Bench.found_count_in_set(["fate", "physics"]), 0, "nothing found yet")

		GameState.state["player"]["bench"]["cells"]["fate+physics|heat"] = { "state": "found", "misses": 0, "tier": 1, "progress": 0 }
		GameState.state["player"]["bench"]["cells"]["fate+physics|grinding"] = { "state": "hot", "misses": 1, "tier": 1, "progress": 0 }
		assert_eq(Bench.found_count_in_set(["fate", "physics"]), 1, "only the found cell counts, not a hot one")

		GameData.RECIPES.erase("_testBenchHeat")
		GameData.RECIPES.erase("_testBenchGrinding")
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
		GameData.APPROACHES["_testGated"] = { "name": "Gated", "symbol": "?", "source": { "type": "room", "id": "lab" } }
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		var result := Bench.probe(["time"], "_testGated")
		assert_true(not result["ok"], "a room-gated approach is not known without the room")
		assert_eq(Bench.cell_state(["time"], "_testGated"), "untried")
		GameData.APPROACHES.erase("_testGated")
	)

	run_case("probe_costs_no_time_block", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		Bench.probe(["life", "time"], "heat")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 0, "an experiment costs no time block")
		assert_eq(GameState.state["world"]["timeBlock"], 0)
	)

	run_case("probe_allowed_when_time_exhausted", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		assert_true(TimeSystem.is_time_exhausted())
		assert_true(Bench.probe(["life", "time"], "heat")["ok"], "spent day doesn't block the bench")
		assert_eq(GameState.state["world"]["day"], 1, "day doesn't roll over")
	)

	run_case("experiment_is_blocked_on_an_inert_cell", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["fate"] = 100
		GameState.state["player"]["orichalchum"]["physics"] = 100
		# No recipe assigned to this cell -- probing resolves it inert.
		Bench.probe(["fate", "physics"], "heat")
		assert_eq(Bench.cell_state(["fate", "physics"], "heat"), "inert")

		var ore_before: int = GameState.state["player"]["orichalchum"]["fate"]
		var result := Bench.experiment(["fate", "physics"], "heat")
		assert_true(not result["ok"], "experiment on an inert cell must refuse")
		assert_eq(GameState.state["player"]["orichalchum"]["fate"], ore_before, "a blocked experiment must not deduct ore")
	)

	run_case("experiment_is_blocked_on_a_never_found_untried_cell", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		assert_eq(Bench.cell_state(["life", "time"], "heat"), "untried")
		var result := Bench.experiment(["life", "time"], "heat")
		assert_true(not result["ok"], "experiment on an untried cell must refuse")
	)

	run_case("experiment_is_blocked_on_a_hot_cell", func():
		GameData.RECIPES["_testBenchEffect"] = { "discovery": { "types": ["life", "time"], "approach": "heat" } }
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		GameState.state["player"]["craftingSkill"] = 1
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "hot", "misses": 1, "tier": 1, "progress": 0 }
		var result := Bench.experiment(["life", "time"], "heat")
		assert_true(not result["ok"], "experiment on a hot (not-yet-found) cell must refuse")
		GameData.RECIPES.erase("_testBenchEffect")
	)

	run_case("experiment_is_blocked_on_an_unlearned_approach", func():
		GameData.APPROACHES["_testGated"] = { "name": "Gated", "symbol": "?", "source": { "type": "room", "id": "lab" } }
		GameData.RECIPES["_testBenchEffect"] = { "discovery": { "types": ["time"], "approach": "_testGated" } }
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["bench"]["cells"]["time|_testGated"] = { "state": "found", "misses": 0, "tier": 1, "progress": 0 }
		var result := Bench.experiment(["time"], "_testGated")
		assert_true(not result["ok"], "a room-gated approach is not known without the room")
		assert_eq(Bench.get_cell(["time"], "_testGated")["progress"], 0, "a blocked experiment must not add progress")
		GameData.RECIPES.erase("_testBenchEffect")
		GameData.APPROACHES.erase("_testGated")
	)

	run_case("experiment_cost_rises_by_tier", func():
		GameState.reset()
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "tier": 1, "progress": 0 }
		var tier1_cost := Bench.experiment_cost(["life", "time"], "heat")
		assert_eq(tier1_cost["time"], 6, "tier 1: 3 * (1 + 1)")

		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "tier": 3, "progress": 0 }
		var tier3_cost := Bench.experiment_cost(["life", "time"], "heat")
		assert_eq(tier3_cost["time"], 12, "tier 3: 3 * (3 + 1), cost keeps rising with tier")
	)

	run_case("experiment_chance_falls_by_tier_but_never_hits_zero", func():
		GameState.reset()
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "tier": 1, "progress": 0 }
		var tier1_chance := Bench.experiment_chance(["life", "time"], "heat", 1)
		assert_almost_eq(tier1_chance, 0.55, 0.0001, "tier 1 has no penalty yet")

		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "tier": 100, "progress": 0 }
		var deep_tier_chance := Bench.experiment_chance(["life", "time"], "heat", 1)
		assert_almost_eq(deep_tier_chance, 0.08, 0.0001, "odds floor at 8%, never zero, however deep the tier")
	)

	run_case("experiment_is_blocked_at_the_top_tier", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "tier": 5, "progress": 0 }
		var ore_before: int = GameState.state["player"]["orichalchum"]["time"]
		var result := Bench.experiment(["life", "time"], "heat")
		assert_true(not result["ok"], "tier 5 is the cap -- nothing to experiment toward")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], ore_before, "a capped cell deducts no ore")
		assert_eq(Bench.get_cell(["life", "time"], "heat")["tier"], 5, "tier stays at the cap")
	)

	run_case("experiment_success_adds_progress_and_awards_xp_without_changing_tier", func():
		var seed := -1
		for candidate in range(500):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["orichalchum"]["life"] = 100
			GameState.state["player"]["craftingSkill"] = 5
			GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "tier": 1, "progress": 0 }
			Rng.set_seed(candidate)
			var result := Bench.experiment(["life", "time"], "heat")
			if result.get("outcome") == "progress":
				seed = candidate
				break
		assert_true(seed != -1, "should find a success roll within 500 tries")
		assert_eq(Bench.get_cell(["life", "time"], "heat")["progress"], Bench.PROGRESS_PER_SUCCESS, "a success fills the bar by one step")
		assert_eq(Bench.get_cell(["life", "time"], "heat")["tier"], 1, "a partial bar leaves the tier alone")
		assert_eq(GameState.state["player"]["craftingXP"], 30, "success awards XP_EXPERIMENT")
	)

	run_case("experiment_filling_the_bar_advances_the_tier_and_resets_progress", func():
		var seed := -1
		for candidate in range(500):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["orichalchum"]["life"] = 100
			GameState.state["player"]["craftingSkill"] = 5
			GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "tier": 2, "progress": Bench.PROGRESS_TO_TIER - Bench.PROGRESS_PER_SUCCESS }
			Rng.set_seed(candidate)
			var result := Bench.experiment(["life", "time"], "heat")
			if result.get("outcome") == "tier_up":
				seed = candidate
				break
		assert_true(seed != -1, "should find a success roll within 500 tries")
		assert_eq(Bench.get_cell(["life", "time"], "heat")["tier"], 3, "a full bar advances the tier")
		assert_eq(Bench.get_cell(["life", "time"], "heat")["progress"], 0, "progress resets on tier-up")
	)

	run_case("experiment_failure_leaves_tier_progress_and_found_state_unchanged", func():
		var seed := -1
		for candidate in range(500):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["orichalchum"]["life"] = 100
			GameState.state["player"]["craftingSkill"] = 1
			GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "tier": 3, "progress": 2 }
			Rng.set_seed(candidate)
			var result := Bench.experiment(["life", "time"], "heat")
			if result.get("outcome") == "no_progress":
				seed = candidate
				break
		assert_true(seed != -1, "should find a failure roll within 500 tries")
		var cell := Bench.get_cell(["life", "time"], "heat")
		assert_eq(cell["state"], "found", "a failed experiment never regresses a found cell")
		assert_eq(cell["tier"], 3, "experiments never lower the tier")
		assert_eq(cell["progress"], 2, "a failed experiment adds no progress and removes none")
	)

	run_case("item_tier_reads_the_found_cell_and_defaults_to_one", func():
		GameState.reset()
		GameData.RECIPES["_testBenchEffect"] = { "discovery": { "types": ["life", "time"], "approach": "heat" } }
		GameData.RECIPES["_testNoCell"] = {}
		assert_eq(Bench.item_tier("_testBenchEffect"), 1, "an unwritten cell reads the default tier")
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "tier": 4, "progress": 0 }
		assert_eq(Bench.item_tier("_testBenchEffect"), 4, "item tier is the cell tier")
		assert_eq(Bench.item_tier("_testNoCell"), 1, "a recipe with no Lab cell sits at tier 1")
		GameData.RECIPES.erase("_testBenchEffect")
		GameData.RECIPES.erase("_testNoCell")
	)

	run_case("experiment_ore_is_always_deducted_regardless_of_outcome", func():
		GameData.RECIPES["_testBenchEffect"] = { "discovery": { "types": ["life", "time"], "approach": "heat" } }
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "tier": 1, "progress": 0 }
		Rng.set_seed(1)
		Bench.experiment(["life", "time"], "heat")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 94, "6 ore deducted at tier 1 regardless of hit/miss")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 94, "6 ore deducted at tier 1 regardless of hit/miss")
		GameData.RECIPES.erase("_testBenchEffect")
	)

	run_case("experiment_costs_no_time_block_and_works_when_time_exhausted", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "tier": 1, "progress": 0 }
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		assert_true(Bench.experiment(["life", "time"], "heat")["ok"], "a spent day does not block experimenting")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 3, "an experiment costs no time block")
		assert_eq(GameState.state["world"]["day"], 1, "day does not roll over")
	)

	run_case("experiment_blocked_without_enough_ore_deducts_nothing", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 1
		GameState.state["player"]["orichalchum"]["life"] = 100
		GameState.state["player"]["bench"]["cells"]["life+time|heat"] = { "state": "found", "misses": 0, "tier": 1, "progress": 0 }
		var result := Bench.experiment(["life", "time"], "heat")
		assert_true(not result["ok"], "insufficient ore on any one type should refuse the whole experiment")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 1, "no deduction when blocked")
		assert_eq(Bench.get_cell(["life", "time"], "heat")["progress"], 0, "a blocked experiment must not add progress")
	)

	# ── ticket 08: app close/reopen mid-flow (spec story 48) ─────────────
	#
	# probe()/experiment() mutate GameState synchronously and exactly once, at
	# the moment they're called -- every caller (originally lab.gd's now-
	# deleted confirm screen, hq-diorama ticket 07's hq_lab_bench.gd today)
	# only ever navigates afterward, never re-calls Bench for the same
	# attempt. So "resume correctly" reduces to: a save/load round trip
	# after a probe must not itself alter player.bench in any way. Slot 93
	# -- tests/test_gamestate.gd uses 92, tests/test_savemanager.gd uses 91.
	const RESUME_TEST_SLOT := 93

	run_case("resuming_after_a_save_load_round_trip_mid_flow_does_not_double_charge_ore_or_duplicate_a_note", func():
		GameData.RECIPES["_testBenchEffect"] = { "discovery": { "types": ["life", "time"], "approach": "heat" } }
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		Rng.set_seed(1)

		Bench.probe(["life", "time"], "heat")
		var ore_after_probe: int = GameState.state["player"]["orichalchum"]["time"]
		var notes_after_probe: int = GameState.state["player"]["bench"]["notes"]["life+time"].size()
		var cell_after_probe: Dictionary = Bench.get_cell(["life", "time"], "heat")

		var save_result := SaveManager.save_to_slot(RESUME_TEST_SLOT)
		assert_true(save_result["ok"])

		# Simulate the app actually having closed: reset in-memory state
		# (a fresh boot would start from new_game_state()) before loading
		# back, same as SaveManager.load_from_slot would meet on a real
		# cold start.
		GameState.reset()
		var load_result := SaveManager.load_from_slot(RESUME_TEST_SLOT)
		assert_true(load_result["ok"])

		assert_eq(GameState.state["player"]["orichalchum"]["time"], ore_after_probe, "resuming must not deduct ore a second time")
		assert_eq(GameState.state["player"]["bench"]["notes"]["life+time"].size(), notes_after_probe, "resuming must not duplicate the note entry")
		assert_eq(Bench.get_cell(["life", "time"], "heat"), cell_after_probe, "resuming must not lose or alter the cell's resolved state")

		SaveManager.delete_slot(RESUME_TEST_SLOT)
		GameData.RECIPES.erase("_testBenchEffect")
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

	# ── ticket 09: bench notes' listing source ───────────────────────────

	run_case("touched_type_sets_lists_only_pairings_with_a_note_sorted_by_key", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		GameState.state["player"]["orichalchum"]["fate"] = 100
		Bench.probe(["life", "time"], "heat")
		Bench.probe(["fate"], "heat")

		assert_eq(Bench.touched_type_sets(), [["fate"], ["life", "time"]], "only touched pairings appear, sorted by key")
	)

	run_case("touched_type_sets_is_empty_for_a_fresh_game", func():
		GameState.reset()
		assert_eq(Bench.touched_type_sets(), [], "nothing touched yet on a fresh game")
	)

	run_case("touched_type_sets_surfaces_a_pairing_whose_cell_was_written_without_a_note", func():
		GameState.reset()
		GameState.state["player"]["bench"]["cells"]["fate|heat"] = { "state": "found", "misses": 0, "tier": 1, "progress": 0 }
		assert_eq(Bench.touched_type_sets(), [["fate"]], "a direct cell write (e.g. a future NPC grant, ticket 11) must surface here even without a note entry")
	)

	run_case("notes_for_returns_the_stored_entries_for_a_touched_pairing_and_empty_for_an_untouched_one", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 100
		GameState.state["player"]["orichalchum"]["life"] = 100
		Bench.probe(["life", "time"], "heat")

		assert_eq(Bench.notes_for(["life", "time"]).size(), 1)
		assert_eq(Bench.notes_for(["time", "life"]).size(), 1, "input order does not matter, same as every other Bench lookup")
		assert_eq(Bench.notes_for(["physics"]), [], "an untouched pairing returns an empty array")
	)

	# ── ticket 10: content-integrity checks on the real catalogue ────────

	run_case("every_authored_discovery_cell_resolves_to_a_valid_types_and_approach_combination", func():
		for recipe_key in GameData.RECIPES:
			var discovery: Dictionary = GameData.RECIPES[recipe_key].get("discovery", {})
			if discovery.is_empty():
				continue
			var types: Array = discovery["types"]
			assert_true(types.size() == 1 or types.size() == 2, "%s: discovery.types must be a single type or a pair, got %d" % [recipe_key, types.size()])
			for t in types:
				assert_true(GameData.ORE_TYPES.has(t), "%s: discovery type '%s' is not a known ore type" % [recipe_key, t])
			if types.size() == 2:
				assert_true(types[0] != types[1], "%s: a pair cannot repeat the same type twice" % recipe_key)
			assert_true(GameData.APPROACHES.has(discovery["approach"]), "%s: discovery approach '%s' is not a known approach" % [recipe_key, discovery["approach"]])
	)

	run_case("no_two_authored_recipes_collide_on_the_same_cell", func():
		# M3 §2.1: a cell holds at most one effect. Every recipe's discovery
		# cell key must be unique across the whole catalogue.
		var seen: Dictionary = {}
		for recipe_key in GameData.RECIPES:
			var discovery: Dictionary = GameData.RECIPES[recipe_key].get("discovery", {})
			if discovery.is_empty():
				continue
			var key := Bench.cell_key(discovery["types"], discovery["approach"])
			assert_true(not seen.has(key), "cell '%s' is claimed by both '%s' and '%s'" % [key, seen.get(key, ""), recipe_key])
			seen[key] = recipe_key
	)

	# ── ticket 11: Bench.grant_effect() + collision contract ────────────

	run_case("grant_effect_on_a_fresh_cell_marks_it_found_free_of_ore_and_time_and_returns_granted", func():
		GameData.RECIPES["_testBenchGrant"] = { "discovery": { "types": ["life", "time"], "approach": "heat" } }
		GameState.reset()
		var ore_before: int = GameState.state["player"]["orichalchum"].get("time", 0)
		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()

		var result := Bench.grant_effect("_testBenchGrant")

		assert_eq(result, Bench.GrantResult.GRANTED, "an unfound effect is granted")
		assert_eq(Bench.cell_state(["life", "time"], "heat"), "found", "the cell is marked found")
		assert_eq(GameState.state["player"]["orichalchum"].get("time", 0), ore_before, "grant_effect never deducts ore")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before, "grant_effect never advances a time block")
		assert_eq(GameState.state["player"]["craftingXP"], Bench.XP_FOUND, "granting awards XP_FOUND, exactly like an experiment success")
		GameData.RECIPES.erase("_testBenchGrant")
	)

	run_case("grant_effect_surveys_the_pairing_on_first_touch_same_as_a_probe_would", func():
		# fate+physics has no authored effect at any approach in the real
		# catalogue (calc-discovery ticket 10) -- deliberately barren, so a
		# single test recipe here gives a clean census count of 1 to check.
		GameData.RECIPES["_testBenchGrant"] = { "discovery": { "types": ["fate", "physics"], "approach": "heat" } }
		GameState.reset()
		assert_true(not Bench.is_surveyed(["fate", "physics"]), "sanity: unsurveyed before any touch")

		Bench.grant_effect("_testBenchGrant")

		assert_true(Bench.is_surveyed(["fate", "physics"]), "granting surveys the pairing, same as probe() does")
		assert_eq(Bench.get_surveyed_count(["fate", "physics"]), 1, "census count is locked in from the real catalogue")
		GameData.RECIPES.erase("_testBenchGrant")
	)

	run_case("grant_effect_on_an_already_found_cell_mutates_nothing_and_returns_already_known", func():
		GameData.RECIPES["_testBenchGrant"] = { "discovery": { "types": ["fate", "physics"], "approach": "heat" } }
		GameState.reset()
		GameState.state["player"]["bench"]["cells"]["fate+physics|heat"] = { "state": "found", "misses": 0, "tier": 1, "progress": 0 }
		var ore_before: int = GameState.state["player"]["orichalchum"].get("fate", 0)
		var xp_before: int = GameState.state["player"]["craftingXP"]
		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()

		var result := Bench.grant_effect("_testBenchGrant")

		assert_eq(result, Bench.GrantResult.ALREADY_KNOWN, "an already-found effect reports the collision instead of silently granting nothing")
		assert_eq(Bench.cell_state(["fate", "physics"], "heat"), "found", "the cell's state is untouched")
		assert_eq(GameState.state["player"]["orichalchum"].get("fate", 0), ore_before, "no ore is deducted on collision")
		assert_eq(GameState.state["player"]["craftingXP"], xp_before, "no XP is awarded on collision -- that fallback belongs to the calling content")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before, "no time block is spent on collision")
		GameData.RECIPES.erase("_testBenchGrant")
	)

	run_case("grant_effect_on_an_already_found_cell_the_player_discovered_themselves_still_returns_already_known", func():
		GameData.RECIPES["_testBenchEffect"] = { "discovery": { "types": ["life", "time"], "approach": "heat" } }
		var seed := -1
		for candidate in range(500):
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 100
			GameState.state["player"]["orichalchum"]["life"] = 100
			GameState.state["player"]["craftingSkill"] = 5
			Rng.set_seed(candidate)
			var probe_result := Bench.probe(["life", "time"], "heat")
			if probe_result.get("outcome") == "found":
				seed = candidate
				break
		assert_true(seed != -1, "should find a discovery-success roll within 500 tries")

		var ore_before: int = GameState.state["player"]["orichalchum"]["time"]
		var blocks_before: int = GameState.state["world"]["timeBlocksDone"].size()
		var result := Bench.grant_effect("_testBenchEffect")

		assert_eq(result, Bench.GrantResult.ALREADY_KNOWN, "self-discovering it first still collides the same way as a prior grant")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], ore_before, "no ore deducted on collision")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), blocks_before, "no time block is spent on collision")
		GameData.RECIPES.erase("_testBenchEffect")
	)

	run_case("the_three_tutorial_recipes_start_found_on_a_fresh_players_bench", func():
		GameState.reset()
		for recipe_key in ["timePearl", "enhancementPowder", "rewind"]:
			var discovery: Dictionary = GameData.RECIPES[recipe_key]["discovery"]
			assert_eq(Bench.cell_state(discovery["types"], discovery["approach"]), "found", "%s should start found via its taughtBy tutorial grant" % recipe_key)
		assert_true(Bench.found_recipe_keys().has("timePearl"))
		assert_true(Bench.found_recipe_keys().has("enhancementPowder"))
		assert_true(Bench.found_recipe_keys().has("rewind"))
	)
