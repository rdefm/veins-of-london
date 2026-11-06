extends "res://tests/test_base.gd"

const SeedSearch := preload("res://tests/support/seed_search.gd")


func _time() -> Dictionary:
	return GameState.state["market"]["goods"]["ore"]["time"]


# Rollovers with faction London trading switched off (no sells, buys or
# Conclave arbitrage), so these cases pin Market's own maths against civilian
# demand and the Independents slice. With factions trading, prices depend on
# which faction holds which veins, which rivalry reshuffles seed to seed;
# faction trading is covered in test_faction_sim.gd, and real-London sanity
# by idle_london_stays_sane_with_factions_trading.
func _tick(days: int) -> void:
	var saved := {}
	for faction_id in GameData.FACTIONS:
		saved[faction_id] = GameData.FACTIONS[faction_id]["trading"]
		var off: Dictionary = saved[faction_id].duplicate(true)
		off["sellFraction"] = 0.0
		off["maxBuyMult"] = 0.0
		off.erase("arbBuyMult")
		GameData.FACTIONS[faction_id]["trading"] = off
	# Mechanism tests run on the original Independents slices, not the tuned ones.
	var saved_shares: Array = [GameData.MARKET["independentsShare"], GameData.MARKET["independentsOreShare"]]
	GameData.MARKET["independentsShare"] = 0.3
	GameData.MARKET["independentsOreShare"] = 0.4
	for i in range(days):
		TimeSystem.daily_tick()
	GameData.MARKET["independentsShare"] = saved_shares[0]
	GameData.MARKET["independentsOreShare"] = saved_shares[1]
	for faction_id in saved:
		GameData.FACTIONS[faction_id]["trading"] = saved[faction_id]


# Makes state_id the active state on its axis with progress pinned so the
# rollover's resolution step keeps it there.
func _set_ticker(section: String, state_id: String) -> void:
	Barometer.ensure_progress()
	var progress: Dictionary = GameState.state["barometer"]["progress"][section]
	for other in progress.keys():
		progress[other] = 0
	progress[state_id] = 100
	GameState.state["barometer"][section] = state_id


func _price(kind: String, good_type: String) -> int:
	return Market.quote(kind, good_type)


func run() -> void:
	# ── pure quote ─────────────────────────────────────────────────────

	run_case("target_price_is_base_at_normal_stock", func():
		GameState.reset()
		var normal: float = GameData.MARKET["goods"]["ore"]["time"]["normalStock"]
		assert_eq(Market.target_price("ore", "time", normal), 75, "stock exactly normal -> base")
	)

	run_case("target_price_hits_the_ceiling_at_zero_stock", func():
		GameState.reset()
		assert_eq(Market.target_price("ore", "time", 0.0), 300, "zero stock -> 4x base")
		assert_eq(Market.target_price("consumable", "timePearl", 0.0), 480, "zero stock -> 4x base for items too")
	)

	run_case("target_price_clamps_at_the_floor_under_a_glut", func():
		GameState.reset()
		assert_eq(Market.target_price("ore", "time", 1000000.0), 15, "huge stock -> 0.2x base")
	)

	run_case("above_trigger_counter_counts_then_resets", func():
		GameState.reset()
		var scarce: Array[int] = [0, 0, 0, 0, 0]
		var glut: Array[int] = [100000, 0, 0, 0, 0]
		Market._set_tier_stocks("consumable", "timePearl", scarce)
		Market.daily_reprice()
		Market.daily_reprice()
		assert_eq(Market.days_above("timePearl"), 2, "two straight days above the trigger")
		var saved: Dictionary = GameState.deep_copy(GameState.state["market"]["aboveDays"])
		assert_eq(saved, {"timePearl": 2}, "plain dict of ints, only pinned goods")
		Market._set_tier_stocks("consumable", "timePearl", glut)
		Market.daily_reprice()
		Market.daily_reprice()
		assert_eq(Market.days_above("timePearl"), 0, "a day at or below the trigger resets")
	)

	run_case("outside_craft_eligibility", func():
		GameState.reset()
		var scarce: Array[int] = [0, 0, 0, 0, 0]
		var grace: int = GameData.MARKET["outsideCraft"]["graceDays"]
		# timePearl: Guild lists it in craftTargets; Collective does not.
		assert_true(Market.is_specialist("guild", "timePearl"), "guild specialises")
		assert_true(not Market.is_specialist("collective", "timePearl"), "collective does not")
		for i in range(grace - 1):
			Market._set_tier_stocks("consumable", "timePearl", scarce)
			Market.daily_reprice()
		assert_true(not Market.outside_craft_eligible("collective", "timePearl"), "inside the grace period")
		Market._set_tier_stocks("consumable", "timePearl", scarce)
		Market.daily_reprice()
		assert_true(Market.outside_craft_eligible("collective", "timePearl"), "non-specialist after grace")
		assert_true(not Market.outside_craft_eligible("guild", "timePearl"), "specialist is never an outside crafter")
		# Keystone opts out by recipe flag, however long it stays pinned.
		GameState.state["market"]["aboveDays"]["keystone"] = grace + 5
		assert_true(not Market.outside_craft_eligible("collective", "keystone"), "keystone opted out")
	)

	run_case("quote_avg2_without_history_is_todays_quote", func():
		GameState.reset()
		_time()["price"] = 70
		assert_eq(Market.quote_avg2("ore", "time"), 70)
	)

	run_case("quote_avg2_averages_the_last_two_days", func():
		GameState.reset()
		_time()["history"] = [40, 60, 51]
		_time()["price"] = 51
		assert_eq(Market.quote_avg2("ore", "time"), 56, "(60 + 51) / 2 rounds to 56")
	)

	# ── rollover ───────────────────────────────────────────────────────

	run_case("idle_independents_only_market_settles_high_and_holds", func():
		GameState.reset()
		assert_eq(Market.quote("ore", "time"), 75, "a new game opens at base")
		_tick(80)
		assert_true(Market.quote("ore", "time") > 75, "independents alone leave a scarce market")
		assert_true(Market.quote("ore", "time") <= 300, "within the ceiling")
		assert_eq(_time()["history"].size(), 28, "history is capped")
	)

	run_case("idle_london_stays_sane_with_factions_trading", func():
		Rng.set_seed(13)  # before reset: GameState.reset() draws the stockpile pick
		GameState.reset()
		Factions.seed_day_one_veins()
		for i in range(30):
			GameState.state["world"]["day"] += 1
			TimeSystem.daily_tick()
		for kind in Market.KINDS:
			for good_type in GameState.state["market"]["goods"][kind]:
				var mult: float = float(Market.quote(kind, good_type)) / Market.base_price(kind, good_type)
				# Prices run high until faction trade uses real stock.
				var ceiling := 4.0
				assert_true(mult >= 0.5 and mult <= ceiling, "%s %s idles at %.2fx base after 30 real days" % [kind, good_type, mult])
	)

	run_case("history_is_bounded", func():
		GameState.reset()
		for i in range(40):
			Market.daily_reprice()
		assert_eq(_time()["history"].size(), int(GameData.MARKET["historyDays"]))
	)

	run_case("archie_ore_dump_sells_at_todays_quote_and_lands_in_stock", func():
		var seed := SeedSearch.find_seed_for(200, func():
			GameState.reset()
			GameState.state["market"] = Market.new_state()
			GameState.state["player"]["orichalchum"]["time"] = 730
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 730 }])
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		assert_eq(GameState.state["modal"]["data"]["gross"], Market.line_total("ore", 75, 730), "the sale executes at today's quote")
		var before: int = _time()["stock"]
		assert_true(Market.availability("ore", "time")[0] > before + 600, "the 730 shows in today's availability")
		_tick(1)
		assert_true(_time()["stock"] > before + 500, "the 730 sat in London's stock")
		assert_true(Market.quote("ore", "time") < 75, "the glut lowers the price")
	)

	run_case("repeated_dumps_approach_but_never_pass_the_floor", func():
		GameState.reset()
		for i in range(12):
			Market.record_supply("ore", "time", 5000, "player")
			_tick(1)
			assert_true(Market.quote("ore", "time") >= 15, "never below 0.2x base")
		assert_eq(Market.quote("ore", "time"), 15, "sits on the floor")
	)

	run_case("forced_shortage_never_passes_the_ceiling", func():
		GameState.reset()
		for i in range(12):
			Market.record_demand("ore", "time", 5000, "player")
			_tick(1)
			assert_true(Market.quote("ore", "time") <= 300, "never above 4x base")
		assert_true(Market.quote("ore", "time") > 125, "a shortage drives the price well up")
	)

	run_case("mugged_archie_ore_sale_still_records_supply", func():
		var seed := SeedSearch.find_seed_for(200, func():
			GameState.reset()
			GameState.state["player"]["orichalchum"]["time"] = 10
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 3 }])
			return result.get("mugged", false)
		)
		assert_true(seed != -1, "should find a mugged roll within 200 tries")
		assert_eq(GameState.state["market"]["supply"]["ore"]["time"], { "player": 3 }, "the mugged sale still counts as supply")
		Market.daily_reprice()
		assert_eq(GameState.state["market"]["supply"]["ore"], {}, "tallies clear at reprice")
	)

	run_case("sim_start_bizA2_quotes_base_and_skips_reprice", func():
		var saved_start: String = GameData.MARKET["simStart"]
		GameData.MARKET["simStart"] = "bizA2"
		GameState.reset()
		assert_eq(GameState.state["market"]["startedDay"], null, "not started yet")
		_time()["price"] = 99
		assert_eq(Market.quote("ore", "time"), 75, "quote is base before start")
		Market.record_supply("ore", "time", 50, "player")
		var before: Dictionary = GameState.deep_copy(GameState.state["market"])
		_tick(3)
		assert_eq(GameState.state["market"], before, "reprice is a no-op before start")
		GameData.MARKET["simStart"] = saved_start
		GameState.reset()
	)

	_tiered_cases()

	# ── Ticker item demand ─────────────────────────────────────────────

	run_case("war_lifts_shield_then_physics_ore_over_following_days", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		var shield_idle: int = _price("consumable", "shield")
		var physics_idle: int = _price("ore", "physics")
		_set_ticker("political", "war")
		_tick(1)
		assert_true(_price("consumable", "shield") > shield_idle, "shield price rises on the first rollover")
		_tick(4)
		# Direction only: at London's item volume the ore lift is small; the
		# +50-100% feel target is deferred to Ticker work (R§3.13).
		assert_true(Market.derived_ore_demand("physics") > 0.0, "war item shortages feed physics demand")
		assert_true(_price("ore", "physics") >= physics_idle, "physics does not fall under war")
	)

	run_case("player_shield_supply_dampens_the_physics_rise", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		_set_ticker("political", "war")
		_tick(5)
		var unfilled: float = Market.derived_ore_demand("physics")
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		_set_ticker("political", "war")
		for i in range(5):
			Market.record_supply("consumable", "shield", 12, "player")
			_tick(1)
		var filled: float = Market.derived_ore_demand("physics")
		assert_true(filled < unfilled, "crafting shields cools physics demand (%.1f vs %.1f)" % [filled, unfilled])
	)

	run_case("mixed_recipe_shortage_lifts_both_ingredient_ores", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		var time_idle: int = _price("ore", "time")
		var time_stock_idle: int = GameState.state["market"]["goods"]["ore"]["time"]["stock"]
		var life_stock_idle: int = GameState.state["market"]["goods"]["ore"]["life"]["stock"]
		for i in range(4):
			Market.record_demand("consumable", "healingBurst", 50, "player")
			_tick(1)
		var ore_goods: Dictionary = GameState.state["market"]["goods"]["ore"]
		assert_true(_price("ore", "time") > time_idle, "healingBurst shortage lifts time")
		# Life's price moves under a whole pound at the larger roster, so its stock is the signal.
		assert_true(int(ore_goods["time"]["stock"]) < time_stock_idle, "healingBurst shortage draws down time stock")
		assert_true(int(ore_goods["life"]["stock"]) < life_stock_idle, "healingBurst shortage draws down life stock")
	)

	run_case("demand_all_lifts_and_lowers_every_item", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		var idle := {}
		for recipe_key in GameData.RECIPES:
			idle[recipe_key] = GameState.state["market"]["goods"]["consumable"][recipe_key]["stock"]
		# A real boom (+10%) moves London's small item stocks by under a whole
		# unit, so this pins the mechanism with a stronger demandAll.
		var boom: Dictionary = GameData.BAROMETER_STATES["economic"]["boom"]["effects"]
		GameData.BAROMETER_STATES["economic"]["boom"]["effects"] = { "demandAll": 0.5 }
		_set_ticker("economic", "boom")
		_tick(3)
		GameData.BAROMETER_STATES["economic"]["boom"]["effects"] = boom
		for recipe_key in GameData.RECIPES:
			assert_true(GameState.state["market"]["goods"]["consumable"][recipe_key]["stock"] < idle[recipe_key], "boom drains %s stock" % recipe_key)
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		var saved: Dictionary = GameData.BAROMETER_STATES["economic"]["recession"]["effects"]
		GameData.BAROMETER_STATES["economic"]["recession"]["effects"] = { "demandAll": -0.9 }
		_set_ticker("economic", "recession")
		_tick(3)
		GameData.BAROMETER_STATES["economic"]["recession"]["effects"] = saved
		for recipe_key in GameData.RECIPES:
			assert_true(GameState.state["market"]["goods"]["consumable"][recipe_key]["stock"] > idle[recipe_key], "a negative demandAll swells %s stock" % recipe_key)
	)

	run_case("election_mutes_the_war_shield_effect", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		_set_ticker("political", "war")
		_tick(8)
		var war_only: int = _price("consumable", "shield")
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		var saved: Dictionary = GameData.BAROMETER_STATES["social"]["festival"]["effects"]
		GameData.BAROMETER_STATES["social"]["festival"]["effects"] = { "effectMod": -0.5 }
		_set_ticker("political", "war")
		_set_ticker("social", "festival")
		_tick(8)
		GameData.BAROMETER_STATES["social"]["festival"]["effects"] = saved
		assert_true(_price("consumable", "shield") < war_only, "effectMod scales itemDemand down (%d vs %d)" % [_price("consumable", "shield"), war_only])
	)

	# ── annotations ────────────────────────────────────────────────────

	run_case("ticker_shift_annotates_the_items_it_touches", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		_tick(1)
		_set_ticker("political", "war")
		_tick(1)
		var shield_notes := _notes_of("consumable", "shield", "ticker")
		assert_eq(shield_notes.size(), 1, "war shift annotates shield once")
		assert_eq(shield_notes[0]["source"], "war")
		assert_eq(shield_notes[0]["day"], GameState.state["world"]["day"])
		assert_eq(_notes_of("ore", "physics", "ticker").size(), 0, "ores are not annotated by a Ticker shift")
		_tick(1)
		assert_eq(_notes_of("consumable", "shield", "ticker").size(), 1, "no new shift, no new annotation")
	)

	run_case("dump_above_threshold_annotates_dump_and_crash", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		Market.record_supply("ore", "time", 730, "player")
		_tick(1)
		var dumps := _notes_of("ore", "time", "dump")
		assert_eq(dumps.size(), 1, "730 in a day is a dump")
		assert_eq(dumps[0]["source"], "player")
		assert_eq(dumps[0]["value"], 730)
		assert_eq(dumps[0]["day"], GameState.state["world"]["day"])
		assert_eq(_notes_of("ore", "time", "crash").size(), 1, "the dump's price drop is a crash")
	)

	run_case("a_big_faction_buy_or_sell_is_annotated_with_the_faction", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		Market.record_supply("ore", "time", 730, "firm")
		Market.record_demand("ore", "life", 730, "guild")
		Market.record_demand("ore", "fate", 730, "player")
		Market.daily_reprice()
		var dumps := _notes_of("ore", "time", "dump")
		assert_eq(dumps.size(), 1, "the Firm's 730 is a dump")
		assert_eq(dumps[0]["source"], "firm")
		var buys := _notes_of("ore", "life", "buy")
		assert_eq(buys.size(), 1, "the Guild's 730 buy is annotated")
		assert_eq(buys[0]["source"], "guild")
		assert_eq(buys[0]["value"], 730)
		assert_eq(_notes_of("ore", "fate", "buy").size(), 0, "only faction buys are annotated")
	)

	run_case("a_flood_is_annotated_with_the_faction_at_any_volume_and_not_as_a_dump", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		GameState.state["market"]["startedDay"] = 1
		Market.record_move("flood", "ore", "time", 40, "firm")
		Market.record_move("flood", "ore", "life", 730, "collective")
		Market.daily_reprice()
		var floods := _notes_of("ore", "time", "flood")
		assert_eq(floods.size(), 1, "a small flood is still annotated")
		assert_eq(floods[0]["source"], "firm")
		assert_eq(floods[0]["value"], 40)
		assert_eq(_notes_of("ore", "life", "flood").size(), 1)
		assert_eq(_notes_of("ore", "life", "dump").size(), 0, "a big flood isn't also a dump")
		assert_true(not GameState.state["market"].has("floods"), "cleared with the tallies")
	)

	run_case("ordinary_supply_is_not_a_dump", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		Market.record_supply("ore", "time", 104, "player")
		_tick(1)
		assert_eq(_notes_of("ore", "time", "dump").size() + _notes_of("ore", "time", "crash").size(), 0, "a normal day's selling leaves no dump or crash annotation")
	)

	run_case("forced_shortage_annotates_a_spike", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		Market.record_demand("ore", "fate", 730, "player")
		_tick(1)
		var spikes := _notes_of("ore", "fate", "spike")
		assert_eq(spikes.size(), 1)
		assert_eq(spikes[0]["source"], "market")
		assert_true(int(spikes[0]["value"]) > 0, "spike carries a positive £ move")
	)

	run_case("annotations_are_bounded_by_the_cap", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		var saved: int = GameData.MARKET["annotations"]["cap"]
		GameData.MARKET["annotations"]["cap"] = 3
		for i in range(5):
			Market.record_supply("ore", "time", 730, "player")
			_tick(1)
		var notes: Array = GameState.state["market"]["annotations"]
		GameData.MARKET["annotations"]["cap"] = saved
		assert_eq(notes.size(), 3, "oldest annotations drop past the cap")
		assert_eq(notes[-1]["day"], GameState.state["world"]["day"], "newest kept")
	)

	run_case("sold_this_week_sums_a_sources_last_seven_days_of_sales", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state()
		for day in range(1, 10):
			GameState.state["world"]["day"] = day
			Market.record_supply("ore", "time", day, "player")
			Market.record_supply("consumable", "timePearl", 1, "firm")
			if day < 9:
				Market.daily_reprice()
		var sold := Market.sold_this_week("player")
		assert_eq(sold, { "ore:time": 3 + 4 + 5 + 6 + 7 + 8 + 9 }, "days 3-9, today's live tally included")
		assert_eq(Market.sold_this_week("firm"), { "consumable:timePearl": 7 })
		assert_eq(GameState.state["market"]["salesHistory"].size(), 6, "history keeps the prior six days")
	)

	run_case("prev_quote_and_day_move_read_yesterday", func():
		GameState.reset()
		_time()["price"] = 66
		_time()["prevPrice"] = 60
		assert_eq(Market.prev_quote("ore", "time"), 60)
		assert_eq(Market.day_move("ore", "time"), 6)
	)

	run_case("post_story_posts_headline_raises_emotion_demand_then_lapses", func():
		GameState.reset()
		var day: int = GameState.state["world"]["day"]
		Market.daily_reprice()
		var control_stock: int = GameState.state["market"]["goods"]["ore"]["emotion"]["stock"]

		GameState.reset()
		Events.apply_effects([{ "op": "post_story", "story": "prologueSqueeze" }])
		var headline: Dictionary = Barometer.headlines()[0]
		assert_eq(headline["source"], "prologueSqueeze", "article posted")
		assert_eq(headline["day"], day, "posted today")
		assert_true(Barometer.wire_article(headline)["body"].contains("Emotion") or Barometer.wire_article(headline)["body"].contains("emotion"), "article renders the ore")
		var rise: Dictionary = GameState.state["market"]["storyRises"][0]
		assert_eq(rise["endDay"], day + 7, "lasts 7 days")
		assert_eq(Market.story_rise_fraction("emotion"), 0.2, "emotion rise active")
		assert_eq(Market.story_rise_fraction("time"), 0.0, "other ores untouched")
		Market.daily_reprice()
		assert_true(GameState.state["market"]["goods"]["ore"]["emotion"]["stock"] < control_stock, "extra demand drains emotion stock")

		GameState.state["world"]["day"] = day + 7
		assert_eq(Market.story_rise_fraction("emotion"), 0.0, "rise lapses at endDay")
		Market.daily_reprice()
		assert_eq(GameState.state["market"]["storyRises"].size(), 0, "expired rise pruned")
	)


func _tiers(good_type: String) -> Dictionary:
	return GameState.state["market"]["goods"]["consumable"][good_type]["tiers"]


func _stock_total(good_type: String) -> int:
	var total := 0
	for qty in _tiers(good_type).values():
		total += int(qty)
	return total


func _tiered_cases() -> void:
	run_case("item_stock_is_held_per_tier_and_sums_to_the_total", func():
		GameState.reset()
		var good: Dictionary = GameState.state["market"]["goods"]["consumable"]["timePearl"]
		assert_eq(good["tiers"].size(), 5, "tiers 1 to 5")
		assert_eq(_stock_total("timePearl"), good["stock"], "tier stock sums to the stock")
		assert_eq(good["stock"], GameData.MARKET["goods"]["consumable"]["timePearl"]["normalStock"], "starts at normal")
		assert_true(int(good["tiers"]["1"]) > int(good["tiers"]["5"]), "weighted to low tiers")
		assert_true(not GameState.state["market"]["goods"]["ore"]["time"].has("tiers"), "ore is untiered")
	)

	run_case("a_tiers_price_is_the_quote_times_the_quality_multiplier", func():
		GameState.reset()
		var quote: int = Market.quote("consumable", "timePearl")
		assert_eq(Market.tier_price("timePearl", 1), quote)
		assert_eq(Market.tier_price("timePearl", 5), GameState.round_epsilon(quote * Economy.quality_price_multiplier(5)))
	)

	run_case("stock_change_equals_the_sum_of_the_flows", func():
		GameState.reset()
		var good: Dictionary = GameState.state["market"]["goods"]["consumable"]["timePearl"]
		var indep := int(Market.independents_supply("consumable", "timePearl"))
		var nameless := GameState.round_epsilon(Market.civilian_demand("consumable", "timePearl") * Barometer.get_item_demand_mult("timePearl") * Market.demand_mult("consumable", "timePearl"))
		var before: int = good["stock"]
		Market.record_supply("consumable", "timePearl", 30, "player", 3)
		Market.record_demand("consumable", "timePearl", 10, "firm")
		Market.daily_reprice()
		assert_eq(good["stock"], before + indep + 30 - nameless - 10, "change equals the sum of the flows")
		assert_eq(_stock_total("timePearl"), good["stock"], "tiers still sum to the stock")
	)

	run_case("recorded_supply_enters_at_its_tier_and_untiered_enters_at_tier_one", func():
		GameState.reset()
		var t3_before: int = _tiers("timePearl")["3"]
		var t1_before: int = _tiers("timePearl")["1"]
		Market.record_supply("consumable", "timePearl", 400, "player", 3)
		Market.record_supply("consumable", "timePearl", 400, "player", 0)
		var plan := Market.availability("consumable", "timePearl")
		assert_true(plan[3] >= t3_before + 300, "tier 3 holds the tier-3 goods")
		assert_true(plan[1] >= t1_before + 300, "tier 0 enters as tier 1")
	)

	run_case("nameless_demand_falls_as_price_rises_down_to_a_floor", func():
		GameState.reset()
		var low := Market.demand_mult("ore", "time")
		_time()["price"] = 150
		var high := Market.demand_mult("ore", "time")
		_time()["price"] = 100000
		var floor_mult := Market.demand_mult("ore", "time")
		assert_true(high < low, "dearer, fewer buyers")
		assert_eq(floor_mult, float(GameData.MARKET["demandFloor"]), "bottoms out at the floor")
	)

	run_case("independents_supply_rises_with_price_up_to_a_cap", func():
		GameState.reset()
		var base_supply := Market.independents_supply("ore", "time")
		_time()["price"] = 150
		var dearer := Market.independents_supply("ore", "time")
		_time()["price"] = 100000
		var capped := Market.independents_supply("ore", "time")
		assert_true(dearer > base_supply, "dear goods draw more supply")
		assert_eq(capped, base_supply * float(GameData.MARKET["supplyCap"]), "stops at the cap")
	)

	run_case("independents_shares_stay_and_enter_weighted_to_low_tiers", func():
		GameState.reset()
		assert_eq(GameData.MARKET["independentsShare"], 0.1)
		assert_eq(GameData.MARKET["independentsOreShare"], 1.5)
		_tiers("healingBurst").merge({ "1": 0, "2": 0, "3": 0, "4": 0, "5": 0 }, true)
		GameState.state["market"]["goods"]["consumable"]["healingBurst"]["stock"] = 0
		var plan := Market.availability("consumable", "healingBurst")
		assert_true(plan[1] >= plan[5], "low tiers are fuller")
	)

	run_case("demand_draws_across_tiers_in_proportion_in_whole_units", func():
		GameState.reset()
		var good: Dictionary = GameState.state["market"]["goods"]["consumable"]["timePearl"]
		good["tiers"] = { "1": 100, "2": 100, "3": 0, "4": 0, "5": 0 }
		good["stock"] = 200
		Market.record_demand("consumable", "timePearl", 51, "firm")
		var plan := Market.availability("consumable", "timePearl")
		assert_true(absi(int(plan[1]) - int(plan[2])) <= 6, "the two stocked tiers drain about evenly")
		assert_eq(typeof(plan[1]), TYPE_INT, "whole units")
	)

	run_case("availability_floors_at_zero_when_demand_outruns_stock", func():
		GameState.reset()
		Market.record_demand("consumable", "timePearl", 100000, "firm")
		for qty in Market.availability("consumable", "timePearl").values():
			assert_eq(qty, 0)
	)

	run_case("migration_rescales_stock_and_splits_by_mix_with_prices_steady", func():
		GameState.reset()
		var legacy := {
			"goods": {
				"ore": { "time": { "stock": 620, "price": 90, "prevPrice": 90, "history": [] } },
				"consumable": { "timePearl": { "stock": 40, "price": 160, "prevPrice": 160, "history": [] } },
			},
		}
		Market.migrate_legacy(legacy)
		var pearl: Dictionary = legacy["goods"]["consumable"]["timePearl"]
		assert_eq(pearl["tiers"].size(), 5)
		var summed := 0
		for qty in pearl["tiers"].values():
			summed += int(qty)
		assert_eq(summed, pearl["stock"], "tiers sum to the stock")
		assert_true(absi(Market.target_price("consumable", "timePearl", pearl["stock"]) - 160) <= 2, "the price curve still reads the same price")
		assert_true(absi(Market.target_price("ore", "time", legacy["goods"]["ore"]["time"]["stock"]) - 90) <= 1)
		var again: Dictionary = GameState.deep_copy(legacy)
		Market.migrate_legacy(legacy)
		assert_eq(legacy, again, "migrates once")
	)

	run_case("tiered_stock_repeats_under_the_same_input_and_stays_pure_data", func():
		GameState.reset()
		Market.record_supply("consumable", "timePearl", 25, "player", 4)
		var snapshot: Dictionary = GameState.deep_copy(GameState.state["market"])
		Market.daily_reprice()
		var first: Dictionary = GameState.deep_copy(GameState.state["market"])
		GameState.state["market"] = GameState.deep_copy(snapshot)
		Market.daily_reprice()
		assert_eq(GameState.state["market"], first, "same input, same result")
		var parsed: Variant = JSON.parse_string(JSON.stringify(first))
		assert_eq(typeof(parsed["goods"]["consumable"]["timePearl"]["tiers"]), TYPE_DICTIONARY, "pure data survives JSON")
	)


func _notes_of(kind: String, good_type: String, note_kind: String) -> Array:
	return Market.annotations_for(kind, good_type).filter(func(n): return n["kind"] == note_kind)
