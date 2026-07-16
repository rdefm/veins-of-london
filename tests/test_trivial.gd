extends "res://tests/test_base.gd"

# T00 acceptance: one trivial test proving the harness works end to end.


func run() -> void:
	run_case("arithmetic_sanity", func():
		assert_eq(1 + 1, 2, "one plus one should be two")
	)

	run_case("rng_seeded_repeatable", func():
		Rng.set_seed(42)
		var a := Rng.randi_range(1, 1000)
		Rng.set_seed(42)
		var b := Rng.randi_range(1, 1000)
		assert_eq(a, b, "same seed should reproduce the same draw")
	)

	run_case("rng_chance_bounds", func():
		Rng.set_seed(7)
		var always := Rng.chance(1.0)
		Rng.set_seed(7)
		var never := Rng.chance(0.0)
		assert_true(always, "chance(1.0) should always be true")
		assert_true(not never, "chance(0.0) should always be false")
	)
