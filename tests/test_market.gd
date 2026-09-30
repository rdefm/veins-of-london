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
	for i in range(days):
		TimeSystem.daily_tick()
	for faction_id in saved:
		GameData.FACTIONS[faction_id]["trading"] = saved[faction_id]


func _resting_price(kind: String, good_type: String) -> int:
	return Market.target_price(kind, good_type, GameState.round_epsilon(Market.resting_stock(kind, good_type)))


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

	run_case("no_player_sales_drifts_to_the_idle_premium_and_holds", func():
		GameState.reset()
		assert_eq(Market.quote("ore", "time"), 75, "a new game opens at base")
		_tick(10)
		var idle: int = Market.quote("ore", "time")
		assert_eq(idle, _resting_price("ore", "time"), "settles at the resting price")
		assert_true(idle >= 83 and idle <= 98, "idle premium sits ~1.1-1.3x base, got %d" % idle)
		_tick(3)
		assert_eq(Market.quote("ore", "time"), idle, "and holds there")
		assert_eq(_time()["history"].size(), 13, "one history entry per rollover")
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
				assert_true(mult >= 0.5 and mult <= 2.0, "%s %s idles at %.2fx base after 30 real days" % [kind, good_type, mult])
	)

	run_case("history_is_bounded", func():
		GameState.reset()
		for i in range(40):
			Market.daily_reprice()
		assert_eq(_time()["history"].size(), int(GameData.MARKET["historyDays"]))
	)

	run_case("archie_ore_dump_sells_at_todays_quote_then_depresses_and_resettles", func():
		var seed := SeedSearch.find_seed_for(200, func():
			GameState.reset()
			GameState.state["market"] = Market.new_state(true)
			GameState.state["player"]["orichalchum"]["time"] = 730
			var result := Economy.execute_sale([{ "kind": "ore", "type": "time", "qty": 730 }])
			return not result["mugged"]
		)
		assert_true(seed != -1, "should find a non-mugged roll within 200 tries")
		var idle: int = _resting_price("ore", "time")
		assert_eq(GameState.state["modal"]["data"]["gross"], Market.line_total("ore", idle, 730), "the sale executes at today's quote")
		_tick(1)
		var dipped: int = Market.quote("ore", "time")
		assert_true(dipped < idle * 0.85, "next day's price is visibly lower (%d vs %d)" % [dipped, idle])
		_tick(3)
		var recovered: int = Market.quote("ore", "time")
		assert_true(absf(recovered - idle) <= idle * 0.1, "back within 10% of equilibrium within 4 days (%d vs %d)" % [recovered, idle])
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

	# ── Ticker item demand ─────────────────────────────────────────────

	run_case("war_lifts_shield_then_physics_ore_over_following_days", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state(true)
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
		assert_eq(_price("ore", "fate"), _resting_price("ore", "fate"), "an ore with no war item stays at rest")
	)

	run_case("player_shield_supply_dampens_the_physics_rise", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state(true)
		_set_ticker("political", "war")
		_tick(5)
		var unfilled: float = Market.derived_ore_demand("physics")
		GameState.reset()
		GameState.state["market"] = Market.new_state(true)
		_set_ticker("political", "war")
		for i in range(5):
			Market.record_supply("consumable", "shield", 12, "player")
			_tick(1)
		var filled: float = Market.derived_ore_demand("physics")
		assert_true(filled < unfilled, "crafting shields cools physics demand (%.1f vs %.1f)" % [filled, unfilled])
	)

	run_case("mixed_recipe_shortage_lifts_both_ingredient_ores", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state(true)
		var time_idle: int = _price("ore", "time")
		var life_idle: int = _price("ore", "life")
		for i in range(4):
			Market.record_demand("consumable", "healingBurst", 50, "player")
			_tick(1)
		assert_true(_price("ore", "time") > time_idle, "healingBurst shortage lifts time")
		assert_true(_price("ore", "life") > life_idle, "healingBurst shortage lifts life")
	)

	run_case("demand_all_lifts_and_lowers_every_item", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state(true)
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
		GameState.state["market"] = Market.new_state(true)
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
		GameState.state["market"] = Market.new_state(true)
		_set_ticker("political", "war")
		_tick(8)
		var war_only: int = _price("consumable", "shield")
		GameState.reset()
		GameState.state["market"] = Market.new_state(true)
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
		GameState.state["market"] = Market.new_state(true)
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
		GameState.state["market"] = Market.new_state(true)
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
		GameState.state["market"] = Market.new_state(true)
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
		GameState.state["market"] = Market.new_state(true)
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
		GameState.state["market"] = Market.new_state(true)
		Market.record_supply("ore", "time", 104, "player")
		_tick(1)
		assert_eq(Market.annotations_for("ore", "time").size(), 0, "a normal day's selling leaves no annotation")
	)

	run_case("forced_shortage_annotates_a_spike", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state(true)
		Market.record_demand("ore", "fate", 730, "player")
		_tick(1)
		var spikes := _notes_of("ore", "fate", "spike")
		assert_eq(spikes.size(), 1)
		assert_eq(spikes[0]["source"], "market")
		assert_true(int(spikes[0]["value"]) > 0, "spike carries a positive £ move")
	)

	run_case("annotations_are_bounded_by_the_cap", func():
		GameState.reset()
		GameState.state["market"] = Market.new_state(true)
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

	run_case("prev_quote_and_day_move_read_yesterday", func():
		GameState.reset()
		_time()["price"] = 66
		_time()["prevPrice"] = 60
		assert_eq(Market.prev_quote("ore", "time"), 60)
		assert_eq(Market.day_move("ore", "time"), 6)
	)


func _notes_of(kind: String, good_type: String, note_kind: String) -> Array:
	return Market.annotations_for(kind, good_type).filter(func(n): return n["kind"] == note_kind)
