extends "res://tests/test_base.gd"

# Block-end optimisations must not change outcomes: cached share reads equal
# uncached ones, and the same seed reaches the same state.


func _warm(days: int, seed_value: int) -> void:
	GameState.reset()
	Rng.set_seed(seed_value)
	Factions.seed_day_one_veins()
	for i in days:
		GameState.state["world"]["day"] += 1
		TimeSystem.daily_tick()


func run() -> void:
	run_case("cached_share_reads_equal_uncached", func():
		_warm(20, 3)
		var plain_ore := Shares.window_totals("ore")
		var plain_deliveries := Shares.deliveries()
		Shares.begin_cache()
		assert_eq(Shares.window_totals("ore"), plain_ore)
		assert_eq(Shares.window_totals("ore"), plain_ore, "second read hits the memo")
		assert_eq(Shares.deliveries(), plain_deliveries)
		Shares.end_cache()
		assert_eq(Shares.window_totals("ore"), plain_ore)
	)

	run_case("cache_is_cleared_between_scopes", func():
		GameState.reset()
		Shares.record_ore("firm", "physics", 5)
		Shares.begin_cache()
		assert_eq(Shares.ore_share("firm", "physics"), 1.0)
		Shares.end_cache()
		Shares.record_ore("guild", "physics", 5)
		Shares.begin_cache()
		assert_eq(Shares.ore_share("firm", "physics"), 0.5)
		Shares.end_cache()
	)

	run_case("pressure_snapshots_match_uncached_threat_and_drift", func():
		_warm(30, 7)
		FactionAI.apply_pressure()
		var snapshots: Dictionary = GameState.state["factionPressure"]["snapshots"]
		for observer in snapshots:
			for target in snapshots[observer]:
				var row: Dictionary = snapshots[observer][target]
				assert_eq(row["threat"], FactionAI._snap(FactionAI.threat(observer, target)), "%s>%s threat" % [observer, target])
				assert_eq(row["dependence"], FactionAI._snap(FactionAI.dependence(observer, target)), "%s>%s dependence" % [observer, target])
	)
