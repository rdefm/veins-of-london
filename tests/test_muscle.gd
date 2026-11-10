extends "res://tests/test_base.gd"

# systems/muscle.gd: guard records, names, traits, weights and wages.

const RUN_CAP := 400


func _guard(level: int, traits: Array, nickname: String = "") -> Dictionary:
	return { "id": "gx", "name": "Dee Okafor", "nickname": nickname, "level": level, "xp": 0, "traits": traits,
		"post": "reserve", "injuredUntilDay": 0, "trainingUntilDay": 0 }


func _is_pure(node: Variant) -> bool:
	if node is Dictionary:
		for k in node:
			if not _is_pure(node[k]):
				return false
		return true
	if node is Array:
		for v in node:
			if not _is_pure(v):
				return false
		return true
	return typeof(node) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING]


func run() -> void:
	run_case("state_starts_empty_and_holds_only_primitives", func():
		GameState.reset()
		var m: Dictionary = GameState.state["muscle"]
		assert_eq(m["guards"], [])
		assert_eq(m["former"], [])
		Rng.set_seed(1)
		m["guards"].append(Muscle.create_guard(3))
		assert_true(_is_pure(m), "pure data")
		var round_trip: Variant = JSON.parse_string(JSON.stringify(m))
		assert_eq(round_trip["guards"][0]["name"], m["guards"][0]["name"])
	)

	run_case("level_table_matches_the_spec_and_comes_from_json", func():
		GameState.reset()
		var weights := [1.0, 1.25, 1.5, 1.75, 2.0]
		var wages := [500, 600, 750, 900, 1100]
		var odds := [50, 30, 15, 5, 0]
		var xp := [0, 50, 100, 200, 400]
		for i in 5:
			var row: Dictionary = Muscle.level_row(i + 1)
			assert_eq(Muscle.level_weight(i + 1), weights[i])
			assert_eq(Muscle.level_wage(i + 1), wages[i])
			assert_eq(int(row["boardOdds"]), odds[i])
			assert_eq(int(row["xpToReach"]), xp[i])
	)

	run_case("all_thirteen_traits_are_defined_with_text", func():
		assert_eq(GameData.MUSCLE_TRAITS.size(), 13)
		for id in GameData.MUSCLE_TRAITS:
			var t: Dictionary = GameData.MUSCLE_TRAITS[id]
			assert_true(not String(t["label"]).is_empty() and not String(t["effect"]).is_empty(), id)
			assert_true(["positive", "mixed", "negative"].has(t["kind"]), id)
			assert_true(t["params"] is Dictionary and not t["params"].is_empty(), id)
	)

	run_case("traits_roll_one_or_two_and_never_a_blocked_pair", func():
		GameState.reset()
		Rng.set_seed(42)
		var seconds := 0
		for i in RUN_CAP:
			var traits := Muscle.roll_traits()
			assert_true(traits.size() == 1 or traits.size() == 2, "one or two")
			if traits.size() == 2:
				seconds += 1
				assert_true(traits[0] != traits[1], "distinct")
				assert_true(not Muscle.traits_blocked(traits[0], traits[1]), "not blocked: %s" % [traits])
		assert_true(seconds > RUN_CAP * 0.15 and seconds < RUN_CAP * 0.35, "about 25%% second traits, got %d" % seconds)
		for pair in [["solid", "glassJaw"], ["quickStudy", "slowLearner"], ["watchful", "flaky"], ["quickStudy", "lazy"]]:
			assert_true(Muscle.traits_blocked(pair[0], pair[1]) and Muscle.traits_blocked(pair[1], pair[0]), "%s" % [pair])
	)

	run_case("trait_effects_stack_multiplicatively", func():
		GameState.reset()
		assert_eq(Muscle.wage(_guard(1, [])), 500)
		assert_eq(Muscle.wage(_guard(1, ["cheap", "mouthy"])), int(round(500 * 0.8 * 1.1)))
		assert_eq(Muscle.wage(_guard(3, ["cheap"])), 600)
		assert_almost_eq(Muscle.trait_mult(_guard(1, ["brawler", "hothead"]), "attackMult"), 1.5625, 0.0001)
		assert_almost_eq(Muscle.trait_mult(_guard(1, ["hothead"]), "hpMult"), 0.8, 0.0001)
	)

	run_case("repel_weight_is_level_plus_trait_modifiers", func():
		GameState.reset()
		assert_eq(Muscle.weight(_guard(2, ["watchful"])), 1.25, "fight weight ignores repel traits")
		assert_eq(Muscle.repel_weight(_guard(2, ["watchful"])), 1.5)
		assert_eq(Muscle.repel_weight(_guard(2, ["mouthy"])), 1.5)
		assert_eq(Muscle.repel_weight(_guard(2, ["flaky"])), 1.0)
		assert_eq(Muscle.repel_weight(_guard(4, ["brawler"])), 1.75)
	)

	run_case("names_are_unique_across_current_and_former_and_some_get_nicknames", func():
		GameState.reset()
		Rng.set_seed(7)
		var seen := {}
		var nicknamed := 0
		for i in RUN_CAP:
			var g := Muscle.create_guard(1)
			assert_true(not seen.has(g["name"]), "duplicate %s" % g["name"])
			seen[g["name"]] = true
			if not String(g["nickname"]).is_empty():
				nicknamed += 1
			# Alternate between current and former so both lists block repeats.
			if i % 2 == 0:
				GameState.state["muscle"]["guards"].append(g)
			else:
				GameState.state["muscle"]["former"].append(g)
		assert_true(nicknamed > RUN_CAP * 0.08 and nicknamed < RUN_CAP * 0.25, "about 15%% nicknames, got %d" % nicknamed)
	)

	run_case("short_and_full_names", func():
		assert_eq(Muscle.short_name(_guard(1, [])), "Dee O.")
		assert_eq(Muscle.full_name(_guard(1, [], "Spanner")), "Dee \"Spanner\" O.")
		assert_eq(Muscle.full_name(_guard(1, [])), "Dee O.")
	)

	run_case("name_pools_are_big_enough", func():
		assert_eq(GameData.MUSCLE_FIRST_NAMES.size(), 60)
		assert_eq(GameData.MUSCLE_SURNAMES.size(), 60)
		assert_true(GameData.MUSCLE_NICKNAMES.size() >= 20)
	)

	run_case("create_guard_clamps_level_and_starts_in_reserve_at_that_levels_xp", func():
		GameState.reset()
		Rng.set_seed(3)
		var g := Muscle.create_guard(9)
		assert_eq(g["level"], 5)
		assert_eq(g["xp"], 400)
		assert_eq(g["post"], "reserve")
		var h := Muscle.create_guard(1)
		assert_true(g["id"] != h["id"], "ids advance")
	)
