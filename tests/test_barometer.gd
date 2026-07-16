extends "res://tests/test_base.gd"


func run() -> void:
	run_case("ensure_progress_inits_active_at_100_others_at_0", func():
		GameState.reset()
		Barometer.ensure_progress()
		var progress: Dictionary = GameState.state["barometer"]["progress"]
		assert_eq(progress["economic"]["stable"], 100, "active state starts at 100")
		assert_eq(progress["economic"]["boom"], 0, "non-active state starts at 0")
		assert_eq(progress["social"]["stable"], 100, "social active state starts at 100")
		assert_eq(progress["political"]["stable"], 100, "political active state starts at 100")
	)

	run_case("ensure_progress_does_not_clobber_existing_values", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["economic"]["boom"] = 42
		Barometer.ensure_progress()
		assert_eq(GameState.state["barometer"]["progress"]["economic"]["boom"], 42, "second call should not reset an existing value")
	)

	run_case("drift_is_deterministic_given_the_same_seed", func():
		GameState.reset()
		Barometer.ensure_progress()
		var baseline: Dictionary = GameState.deep_copy(GameState.state["barometer"]["progress"])

		Rng.set_seed(555)
		Barometer._apply_organic_drift()
		var first_result: Dictionary = GameState.deep_copy(GameState.state["barometer"]["progress"])

		GameState.state["barometer"]["progress"] = GameState.deep_copy(baseline)
		Rng.set_seed(555)
		Barometer._apply_organic_drift()
		var second_result: Dictionary = GameState.deep_copy(GameState.state["barometer"]["progress"])

		assert_eq(first_result, second_result, "same seed should drift identically")
	)

	run_case("state_force_fed_to_100_flips_active_and_zeroes_old", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["economic"]["boom"] = 100
		Barometer._resolve_section("economic")

		assert_eq(GameState.state["barometer"]["economic"], "boom", "boom should become the active state")
		assert_eq(GameState.state["barometer"]["progress"]["economic"]["boom"], 100, "new active sits at 100")
		assert_eq(GameState.state["barometer"]["progress"]["economic"]["stable"], 0, "old active drops to 0")
	)

	run_case("resolution_pushes_a_shift_notification", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["social"]["unrest"] = 100
		Barometer._resolve_section("social")
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"].begins_with("Social shift: Social Unrest."):
				found = true
		assert_true(found, "should push a '<Section> shift: <Label>. <description>' notification")
	)

	run_case("manual_push_costs_2000_adds_20_progress_and_sets_cooldown", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["player"]["cash"] = 5000
		var result := Barometer.manual_push("economic", "boom")

		assert_true(result["ok"], "push should succeed with enough cash and no cooldown")
		assert_eq(GameState.state["player"]["cash"], 3000, "push costs £2000")
		assert_eq(GameState.state["barometer"]["progress"]["economic"]["boom"], 20, "push adds +20 progress")
	)

	run_case("manual_push_respects_cooldown", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["player"]["cash"] = 10000
		Barometer.manual_push("economic", "boom")
		var cash_after_first: int = GameState.state["player"]["cash"]
		var result := Barometer.manual_push("economic", "boom")

		assert_true(not result["ok"], "second push same day should be blocked by cooldown")
		assert_eq(GameState.state["player"]["cash"], cash_after_first, "blocked push should not spend cash")
	)

	run_case("manual_push_requires_enough_cash", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["player"]["cash"] = 100
		var result := Barometer.manual_push("economic", "boom")
		assert_true(not result["ok"], "push should fail without £2000")
	)

	run_case("manual_pull_subtracts_20_and_does_not_resolve", func():
		GameState.reset()
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["economic"]["boom"] = 50
		GameState.state["player"]["cash"] = 5000
		Barometer.manual_pull("economic", "boom")
		assert_eq(GameState.state["barometer"]["progress"]["economic"]["boom"], 30, "pull subtracts 20")
		assert_eq(GameState.state["barometer"]["economic"], "stable", "pull alone never resolves a new active state")
	)

	run_case("effective_ore_price_fate_under_crisis", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "crisis"
		var price := Barometer.get_effective_ore_price("fate", 90)
		assert_eq(price, 104, "round(90 * (1 - 0.35 + 0.5)) = 104")
	)

	run_case("effective_mug_chance_is_clamped_0_to_0_8", func():
		GameState.reset()
		GameState.state["barometer"]["economic"] = "crisis"  # +0.12 mugChance
		var chance := Barometer.get_effective_mug_chance(0.20)
		assert_almost_eq(chance, 0.32, 0.0001, "0.20 base + 0.12 crisis mugChance")
	)
