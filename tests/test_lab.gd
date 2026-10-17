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
		Events.apply_effects(GameData.EVENTS["james_meeting"]["on_complete"].filter(func(e): return e["op"] == "grant_recipe"))
		assert_true(Lab.is_known("timePearl"), "timePearl known")
		assert_eq(Lab.known_recipes(), ["timePearl"], "only timePearl")
		assert_true(GameState.state["objectives"]["tut_crafting_unlocked"]["complete"], "knowing timePearl completes the checkpoint")
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
