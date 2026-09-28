extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")


func _set_day(day: int) -> void:
	GameState.state["world"]["day"] = day


# Returns the ore the matching attempt spent.
func _craft_until(recipe_key: String, want_success: bool) -> Dictionary:
	for seed in range(200):
		GameState.state["player"]["orichalchum"] = { "time": 50, "life": 50, "physics": 50, "fate": 50, "emotion": 50 }
		var costs := Crafting.calc_cost(recipe_key, GameState.state["player"]["craftingSkill"])
		Rng.set_seed(seed)
		if Crafting.attempt_craft(recipe_key)["success"] == want_success:
			return costs
		GameState.state["shares"] = Shares.new_state()
	assert_true(false, "no seed gave success=%s" % want_success)
	return {}


func run() -> void:
	# ── pure reads ─────────────────────────────────────────────────────

	run_case("empty_buckets_read_zero_for_every_producer", func():
		GameState.reset()
		assert_eq(Shares.ore_share("player", "time"), 0.0)
		assert_eq(Shares.crafting_share("firm", "life", 1), 0.0)
		var table := Shares.overview("ore")
		assert_eq(table.keys(), ["player", "collective", "firm", "guild", "network", "conclave", "independents"], "player, five factions, independents")
		assert_eq(table["independents"]["fate"], 0.0)
		assert_eq(Shares.deliveries(), {})
	)

	run_case("a_single_producer_owns_the_whole_type", func():
		GameState.reset()
		Shares.record_ore("firm", "physics", 12)
		assert_eq(Shares.ore_share("firm", "physics"), 1.0)
		assert_eq(Shares.ore_share("player", "physics"), 0.0)
		assert_eq(Shares.ore_share("firm", "time"), 0.0, "other types untouched")
	)

	run_case("shares_split_by_volume_across_producers", func():
		GameState.reset()
		Shares.record_ore("player", "time", 10)
		Shares.record_ore("guild", "time", 30)
		assert_eq(Shares.ore_share("player", "time"), 0.25)
		var table := Shares.overview("ore")
		assert_eq(table["guild"]["time"], 0.75)
	)

	run_case("mixed_recipe_craft_counts_toward_each_type_by_weight", func():
		GameState.reset()
		Shares.record_craft("player", { "time": 6, "life": 6 })
		Shares.record_craft("guild", { "time": 18 })
		assert_eq(Shares.crafting_share("player", "time"), 0.25, "6 of 24 time")
		assert_eq(Shares.crafting_share("player", "life"), 1.0, "all 6 life")
		assert_eq(Shares.ore_share("player", "time"), 0.0, "crafting never credits ore share")
	)

	run_case("window_edges_split_current_and_prior_week", func():
		GameState.reset()
		for day in [1, 7, 8, 14]:
			_set_day(day)
			Shares.record_ore("player", "time", day)
		_set_day(14)
		var current := Shares.window_totals("ore", 0)
		var prior := Shares.window_totals("ore", 1)
		assert_eq(current["player"]["time"], 22, "days 8..14")
		assert_eq(prior["player"]["time"], 8, "days 1..7")
		_set_day(15)
		Shares.roll_buckets()
		assert_eq(GameState.state["shares"]["days"].map(func(b): return b["day"]), [7, 8, 14], "day 1 falls out of 14 days kept")
		assert_eq(Shares.window_totals("ore", 1)["player"]["time"], 15, "prior week is now days 2..8")
	)

	run_case("deliveries_total_per_buyer_faction", func():
		GameState.reset()
		Shares.record_delivery("firm", 8)
		Shares.record_delivery("firm", 4)
		Shares.record_delivery("guild", 3)
		assert_eq(Shares.deliveries(), { "firm": 12, "guild": 3 })
		assert_eq(Shares.ore_share("player", "time"), 0.0, "deliveries credit no ore share")
	)

	run_case("supplier_share_reads_split_and_intake", func():
		GameState.reset()
		assert_eq(Shares.delivery_split("firm"), 0.0, "nothing delivered")
		assert_eq(Shares.intake_share("firm"), 0.0, "no intake")
		Shares.record_delivery("firm", 6)
		Shares.record_delivery("guild", 2)
		assert_eq(Shares.delivery_split("firm"), 0.75, "A: where my output goes")
		assert_eq(Shares.delivery_split("network"), 0.0)
		assert_eq(Shares.intake_share("firm"), 1.0, "B: no London buys yet")
		GameState.state["shares"]["days"][0]["londonBuys"] = { "firm": 18 }
		assert_eq(Shares.london_buys(), { "firm": 18 })
		assert_eq(Shares.intake_share("firm"), 0.25, "B: 6 of 24 intake")
		assert_eq(Shares.intake_share("guild"), 1.0)
	)

	run_case("ore_equivalent_counts_calc_1_to_1_and_items_by_ingredient_weight", func():
		assert_eq(Shares.ore_equivalent("ore", "time", 5), 5)
		var weight := 0
		for ore_type in GameData.RECIPES["healingBurst"]["ingredients"]:
			weight += int(GameData.RECIPES["healingBurst"]["ingredients"][ore_type])
		assert_eq(Shares.ore_equivalent("consumable", "healingBurst", 2), 2 * weight)
	)

	# ── player crediting ───────────────────────────────────────────────

	run_case("player_prune_credits_player_ore_share", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [Fixtures.player_vein("v1", "s1", "shoreditch", "life", 90, "fair")]
		var result := Cultivating.prune("v1", GameData.VEIN_GROWTH["pruneHardDepth"])
		assert_true(result["amount"] > 0)
		assert_eq(Shares.window_totals("ore")["player"]["life"], result["amount"])
	)

	run_case("successful_craft_credits_crafting_share_by_ingredient_weight", func():
		GameState.reset()
		var costs := _craft_until("failsafe", true)
		var totals := Shares.window_totals("craft")
		assert_eq(totals["player"], costs, "time and life each by their ingredient weight")
	)

	run_case("failed_craft_credits_nothing", func():
		GameState.reset()
		_craft_until("failsafe", false)
		assert_eq(Shares.window_totals("craft"), {})
	)

	# ── rollover + save ────────────────────────────────────────────────

	run_case("after_14_days_current_and_prior_week_both_report", func():
		var saved_share: float = GameData.MARKET["independentsShare"]
		var saved_ore_share: float = GameData.MARKET["independentsOreShare"]
		GameData.MARKET["independentsShare"] = 0.0
		GameData.MARKET["independentsOreShare"] = 0.0
		GameState.reset()
		for i in range(14):
			if i > 0:
				GameState.state["world"]["day"] += 1
				TimeSystem.daily_tick()
			Shares.record_ore("player", "time", 5)
			Shares.record_ore("firm", "time", 15)
		GameData.MARKET["independentsShare"] = saved_share
		GameData.MARKET["independentsOreShare"] = saved_ore_share
		assert_eq(GameState.state["world"]["day"], 14)
		assert_eq(Shares.window_totals("ore", 0)["player"]["time"], 35, "days 8..14")
		assert_eq(Shares.window_totals("ore", 1)["player"]["time"], 35, "days 1..7 all kept")
		assert_eq(Shares.ore_share("player", "time", 0), 0.25)
		assert_eq(Shares.ore_share("player", "time", 1), 0.25)
	)

	# ── Independents slice ─────────────────────────────────────────────

	run_case("independents_share_zero_removes_the_slice_and_the_row", func():
		var saved_share: float = GameData.MARKET["independentsShare"]
		var saved_ore_share: float = GameData.MARKET["independentsOreShare"]
		GameData.MARKET["independentsShare"] = 0.0
		GameData.MARKET["independentsOreShare"] = 0.0
		GameState.reset()
		GameState.state["world"]["day"] += 1
		TimeSystem.daily_tick()
		var ore_table := Shares.overview("ore")
		var craft_totals := Shares.window_totals("craft")
		var ore_totals := Shares.window_totals("ore")
		GameState.reset()
		Market.daily_reprice()
		var unsupplied: int = GameState.state["market"]["goods"]["ore"]["time"]["stock"]
		GameData.MARKET["independentsShare"] = saved_share
		GameData.MARKET["independentsOreShare"] = saved_ore_share
		GameState.reset()
		Market.daily_reprice()
		var supplied: int = GameState.state["market"]["goods"]["ore"]["time"]["stock"]
		assert_true(not ore_table.has("independents"), "no Independents row at share 0")
		assert_true(not ore_totals.has("independents"), "no Independents ore credited")
		assert_true(not craft_totals.has("independents"), "no Independents craft credited")
		assert_true(unsupplied < supplied, "no slice, less London stock (%d vs %d)" % [unsupplied, supplied])
	)

	run_case("independents_slice_credits_shares_and_all_producers_sum_to_one", func():
		GameState.reset()
		Rng.set_seed(7)
		Shares.record_ore("firm", "physics", 40)
		Shares.record_ore("player", "time", 12)
		Shares.record_craft("guild", { "time": 6, "life": 3 })
		GameState.state["world"]["day"] += 1
		TimeSystem.daily_tick()
		for tally in ["ore", "craft"]:
			var table := Shares.overview(tally)
			assert_true(table.has("independents"), "%s table has an Independents row" % tally)
			for ore_type in GameData.CANONICAL_ORE_TYPES:
				var total := 0.0
				for producer in table:
					total += float(table[producer][ore_type])
				assert_true(absf(total - 1.0) < 0.000001, "%s %s shares sum to 100%%, got %f" % [tally, ore_type, total])
				assert_true(float(table["independents"][ore_type]) > 0.0, "Independents hold some %s %s" % [tally, ore_type])
	)

	run_case("buckets_survive_save_and_load_as_ints", func():
		GameState.reset()
		Shares.record_ore("player", "time", 5)
		Shares.record_craft("guild", { "life": 4 })
		Shares.record_delivery("firm", 3)
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		var bucket: Dictionary = GameState.state["shares"]["days"][0]
		assert_eq(typeof(bucket["day"]), TYPE_INT)
		assert_eq(typeof(bucket["ore"]["player"]["time"]), TYPE_INT)
		assert_eq(Shares.crafting_share("guild", "life"), 1.0)
		assert_eq(Shares.deliveries(), { "firm": 3 })
	)

	run_case("an_old_save_backfills_empty_buckets", func():
		GameState.reset()
		var save: Dictionary = GameState.state.duplicate(true)
		save.erase("shares")
		assert_true(SaveManager._load_save_dict(save)["ok"])
		assert_eq(GameState.state["shares"], { "days": [] })
		assert_eq(Shares.ore_share("player", "time"), 0.0)
	)
