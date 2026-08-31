extends "res://tests/test_base.gd"

# collective-ore-stock T01: Factions.restock_ore()/maybe_restock_ore() (the
# Collective's shared, independently-scarce ore stock the buy lane -- ticket
# 02 -- will draw against), the unlock-moment pre-roll wired into events.gd's
# set_flag op, and the daily_tick wiring test in tests/test_time_system.gd.


func run() -> void:
	# ── restock_ore: all 5 ore types together, in range, replacing not adding ──

	run_case("restock_ore_rolls_every_canonical_ore_type_within_the_intended_range", func():
		GameState.reset()
		Rng.set_seed(1)
		Factions.restock_ore("collective")
		var stock: Dictionary = GameState.state["factions"]["collective"]["oreStock"]
		assert_eq(stock.size(), GameData.CANONICAL_ORE_TYPES.size(), "all 5 canonical ore types should reroll together in the same event")
		for ore_type in GameData.CANONICAL_ORE_TYPES:
			assert_true(stock.has(ore_type), "missing ore type %s" % ore_type)
			var qty: int = stock[ore_type]
			assert_true(qty >= Factions.ORE_STOCK_QTY_MIN and qty <= Factions.ORE_STOCK_QTY_MAX,
				"rolled qty %d for %s outside the intended %d-%d range" % [qty, ore_type, Factions.ORE_STOCK_QTY_MIN, Factions.ORE_STOCK_QTY_MAX])
	)

	run_case("restock_ore_replaces_remaining_stock_rather_than_adding_to_it", func():
		GameState.reset()
		var stock: Dictionary = GameState.state["factions"]["collective"]["oreStock"]
		for ore_type in GameData.CANONICAL_ORE_TYPES:
			stock[ore_type] = 9999

		Rng.set_seed(1)
		Factions.restock_ore("collective")
		for ore_type in GameData.CANONICAL_ORE_TYPES:
			assert_true(stock[ore_type] <= Factions.ORE_STOCK_QTY_MAX, "restock should replace old stock, not add the fresh roll on top of it")
	)

	run_case("restock_ore_produces_varied_quantities_across_seeds_not_a_fixed_value", func():
		var seen_values: Dictionary = {}
		for seed in range(50):
			GameState.reset()
			Rng.set_seed(seed)
			Factions.restock_ore("collective")
			var stock: Dictionary = GameState.state["factions"]["collective"]["oreStock"]
			seen_values[stock["time"]] = true
		assert_true(seen_values.size() > 1, "50 seeds should turn up more than one distinct rolled quantity")
	)

	# ── unlock-moment pre-roll: events.gd's set_flag op ─────────────────────

	run_case("collectiveLaneUnlocked_first_becoming_true_rolls_the_initial_stock", func():
		GameState.reset()
		assert_eq(GameState.state["factions"]["collective"]["oreStock"], {}, "fresh game should start with no stock rolled yet")

		Rng.set_seed(1)
		Events.apply_effects([{ "op": "set_flag", "flag": "collectiveLaneUnlocked", "value": true }])

		var stock: Dictionary = GameState.state["factions"]["collective"]["oreStock"]
		assert_eq(stock.size(), GameData.CANONICAL_ORE_TYPES.size(), "unlocking the lane should roll all 5 ore types immediately")
		for ore_type in GameData.CANONICAL_ORE_TYPES:
			var qty: int = stock[ore_type]
			assert_true(qty >= Factions.ORE_STOCK_QTY_MIN and qty <= Factions.ORE_STOCK_QTY_MAX, "day one must never be an empty shelf")
	)

	run_case("collectiveLaneUnlocked_pre_roll_fires_exactly_once_not_on_every_redundant_set_flag", func():
		GameState.reset()
		Rng.set_seed(1)
		Events.apply_effects([{ "op": "set_flag", "flag": "collectiveLaneUnlocked", "value": true }])
		var stock_after_first: Dictionary = GameState.state["factions"]["collective"]["oreStock"].duplicate()

		# A redundant set_flag true (the flag is already true) must not
		# re-roll -- the pre-roll is keyed on the false->true transition,
		# not on every set_flag call carrying value true.
		Rng.set_seed(2)  # a different seed would produce different values if it re-rolled
		Events.apply_effects([{ "op": "set_flag", "flag": "collectiveLaneUnlocked", "value": true }])
		var stock_after_second: Dictionary = GameState.state["factions"]["collective"]["oreStock"]
		assert_eq(stock_after_second, stock_after_first, "an already-true flag being set true again must not re-roll the stock")
	)

	run_case("set_flag_for_an_unrelated_flag_never_touches_ore_stock", func():
		GameState.reset()
		assert_eq(GameState.state["factions"]["collective"]["oreStock"], {})
		Events.apply_effects([{ "op": "set_flag", "flag": "colA1DesMet", "value": true }])
		assert_eq(GameState.state["factions"]["collective"]["oreStock"], {}, "an unrelated flag flip must not roll the Collective's stock")
	)

	# ── restocking is silent ─────────────────────────────────────────────

	run_case("restock_ore_never_pushes_a_notification", func():
		GameState.reset()
		Rng.set_seed(1)
		Factions.restock_ore("collective")
		assert_true(GameState.state["notifications"].is_empty(), "restocking must be silent -- no Notify.push of any kind")

		GameState.state["notifications"].clear()
		Events.apply_effects([{ "op": "set_flag", "flag": "collectiveLaneUnlocked", "value": true }])
		assert_true(GameState.state["notifications"].is_empty(), "the unlock-moment pre-roll must also be silent")
	)

	# ── maybe_restock_ore: unpredictable daily chance, not a fixed interval ──

	run_case("maybe_restock_ore_sometimes_fires_across_many_seeds", func():
		var hit := false
		for seed in range(200):
			GameState.reset()
			Rng.set_seed(seed)
			Factions.maybe_restock_ore()
			if not GameState.state["factions"]["collective"]["oreStock"].is_empty():
				hit = true
				break
		assert_true(hit, "the daily restock chance should fire at least once within 200 seeds")
	)

	run_case("maybe_restock_ore_does_not_always_fire", func():
		var missed := false
		for seed in range(200):
			GameState.reset()
			Rng.set_seed(seed)
			Factions.maybe_restock_ore()
			if GameState.state["factions"]["collective"]["oreStock"].is_empty():
				missed = true
				break
		assert_true(missed, "a ~25-35% daily chance should also NOT fire at least once within 200 seeds")
	)

	run_case("maybe_restock_ore_fire_rate_lands_roughly_in_the_25_to_35_percent_band", func():
		var trials := 4000
		var hits := 0
		for seed in range(trials):
			GameState.reset()
			Rng.set_seed(seed)
			Factions.maybe_restock_ore()
			if not GameState.state["factions"]["collective"]["oreStock"].is_empty():
				hits += 1
		var rate: float = float(hits) / float(trials)
		assert_true(rate > 0.20 and rate < 0.40, "restock fire rate %.3f should land roughly in the 25-35%% band across %d trials" % [rate, trials])
	)

	run_case("maybe_restock_ore_rerolls_all_5_ore_types_together_when_it_fires", func():
		var found_a_fire := false
		for seed in range(200):
			GameState.reset()
			Rng.set_seed(seed)
			Factions.maybe_restock_ore()
			var stock: Dictionary = GameState.state["factions"]["collective"]["oreStock"]
			if not stock.is_empty():
				found_a_fire = true
				assert_eq(stock.size(), GameData.CANONICAL_ORE_TYPES.size(), "a fired restock event should reroll all 5 ore types together")
				break
		assert_true(found_a_fire, "sanity: should be able to find a firing seed within 200 tries")
	)

	# ── daily_tick wiring (mirrors tests/test_time_system.gd's own style) ──

	run_case("daily_tick_reaches_the_collective_restock_step", func():
		var hit := false
		for seed in range(200):
			GameState.reset()
			Rng.set_seed(seed)
			TimeSystem.daily_tick()
			if not GameState.state["factions"]["collective"]["oreStock"].is_empty():
				hit = true
				break
		assert_true(hit, "daily_tick should reach step 5j (Factions.maybe_restock_ore) within 200 tries")
	)

	# ── stock is independent of relation ────────────────────────────────

	run_case("relation_never_affects_rolled_stock_quantities", func():
		var low_relation_values: Array = []
		var high_relation_values: Array = []
		for seed in range(30):
			GameState.reset()
			GameState.state["factions"]["collective"]["relation"] = -1000
			Rng.set_seed(seed)
			Factions.restock_ore("collective")
			low_relation_values.append(GameState.state["factions"]["collective"]["oreStock"]["time"])

			GameState.reset()
			GameState.state["factions"]["collective"]["relation"] = 1000
			Rng.set_seed(seed)
			Factions.restock_ore("collective")
			high_relation_values.append(GameState.state["factions"]["collective"]["oreStock"]["time"])
		assert_eq(low_relation_values, high_relation_values, "the same seed should roll identical stock regardless of Collective relation")
	)
