extends "res://tests/test_base.gd"

const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")
const OffersSystem := preload("res://systems/offers.gd")

const SALVE := "healingSalve"
const LIMITS := { "careful": 4, "steady": 8, "eager": 18 }  # at London stock 210
const OFFER_SOURCED_XP := 5


func run() -> void:
	calendar_start_weekday = 0  # fixtures count days from a Monday day 1

	run_case("new_and_old_saves_default_to_off", func():
		_setup()
		assert_eq(GameState.state["autoSell"], {}, "new game has no rules")
		var old_save: Dictionary = GameState.deep_copy(GameState.state)
		old_save.erase("autoSell")
		assert_eq(SaveManager.backfill_defaults(old_save)["autoSell"], {}, "old save backfills empty")
		assert_eq(AutoSell.rule(SALVE)["mood"], "off")
		assert_eq(AutoSell.rule(SALVE)["sellAbove"], GameData.PRODUCTION_TARGET_MAX, "cutoff starts at the top of the bar")
	)

	run_case("rule_is_pure_data_and_survives_a_save_round_trip", func():
		_setup()
		_rule("eager", 7)
		var exported: String = SaveManager.export_string()
		GameState.state["autoSell"] = {}
		assert_true(SaveManager.import_string(exported)["ok"])
		assert_eq(GameState.state["autoSell"][SALVE], { "sellAbove": 7, "mood": "eager" })
		assert_eq(typeof(GameState.state["autoSell"][SALVE]["sellAbove"]), TYPE_INT, "sellAbove restores as int")
	)

	run_case("no_one_in_sales_sells_nothing", func():
		_setup(false)
		_rule("eager", 0)
		_stock(30)
		assert_eq(AutoSell.daily_pass(), {})
		assert_eq(Crafting.inventory_qty(SALVE), 30)
	)

	run_case("mood_off_and_missing_rule_sell_nothing", func():
		_setup()
		_stock(30)
		assert_eq(AutoSell.daily_pass(), {}, "no rule")
		_rule("off", 0)
		assert_eq(AutoSell.daily_pass(), {}, "explicit Off")
		assert_eq(Crafting.inventory_qty(SALVE), 30)
	)

	run_case("only_production_list_recipes_sell", func():
		_setup()
		assert_true(not Rooms.production_recipes().has("timePearl"), "fixture: Owen can't make Time Pearls")
		GameState.state["autoSell"]["timePearl"] = { "sellAbove": 0, "mood": "eager" }
		Crafting.inventory_add("timePearl", 1, 30)
		assert_eq(AutoSell.daily_pass(), {})
		assert_eq(Crafting.inventory_qty("timePearl"), 30)
	)

	run_case("stock_stops_at_the_sell_above_floor", func():
		_setup()
		_rule("eager", 20)
		_stock(25)
		assert_eq(AutoSell.daily_pass()[SALVE]["qty"], 5)
		assert_eq(Crafting.inventory_qty(SALVE), 20)
		assert_eq(AutoSell.daily_pass(), {}, "at the floor nothing more sells")
	)

	run_case("keep_alone_raises_the_floor_above_sell_above", func():
		_setup()
		_rule("eager", 10)
		GameState.state["labThresholds"][SALVE] = 28
		_stock(30)
		assert_eq(AutoSell.protected_floor(SALVE), 28)
		assert_eq(AutoSell.daily_pass()[SALVE]["qty"], 2)
	)

	run_case("contract_need_raises_the_floor_only_while_covering_contracts", func():
		_setup()
		_rule("eager", 10)
		GameState.state["labThresholds"][SALVE] = 5
		var created: Dictionary = OffersSystem.create_offer({
			"id": "t_auto_sell", "source": "scripted", "contractType": "recurring", "weekday": 1,
			"request": { "kind": "consumable", "type": SALVE, "qty": 20 },
		})
		OffersSystem.accept_offer(created["offer"]["id"])
		assert_eq(AutoSell.protected_floor(SALVE), 10, "not covering contracts: need doesn't count")
		GameState.state["labCoverContracts"][SALVE] = true
		assert_eq(AutoSell.protected_floor(SALVE), 25, "Keep + contract need beats sellAbove")
		_stock(30)
		assert_eq(AutoSell.daily_pass()[SALVE]["qty"], 5)
		assert_eq(Crafting.inventory_qty(SALVE), 25)
	)

	run_case("below_the_moods_minimum_price_nothing_sells", func():
		for mood in LIMITS:
			_setup()
			_rule(mood, 0)
			_stock(30)
			var cfg: Dictionary = GameData.MARKET["autoSell"]["moods"][mood]
			var minimum := int(ceil(Market.base_price("consumable", SALVE) * float(cfg["minPriceMult"]) - 0.0001))
			_price(minimum - 1)
			assert_eq(AutoSell.sellable_qty(SALVE), 0, "%s one under its minimum" % mood)
			_price(minimum)
			assert_eq(AutoSell.sellable_qty(SALVE), LIMITS[mood], "%s at its minimum" % mood)
	)

	run_case("exact_minimum_price_survives_float_error", func():
		_setup()
		var original: int = GameData.CONSUMABLE_PRICES[SALVE]
		GameData.CONSUMABLE_PRICES[SALVE] = 100
		_rule("careful", 0)
		_stock(30)
		_price(110)
		var qty := AutoSell.sellable_qty(SALVE)
		GameData.CONSUMABLE_PRICES[SALVE] = original
		assert_eq(qty, LIMITS["careful"], "100 × 1.1 isn't exactly 110 in floats")
	)

	run_case("daily_volume_is_the_mood_limit_capped_by_surplus", func():
		for mood in LIMITS:
			_setup()
			_rule(mood, 0)
			_price(Market.base_price("consumable", SALVE) * 2)
			_stock(100)
			assert_eq(AutoSell.market_limit(SALVE, GameData.MARKET["autoSell"]["moods"][mood]["maxPriceDrop"]), LIMITS[mood])
			assert_eq(AutoSell.daily_pass()[SALVE]["qty"], LIMITS[mood], "%s capped by the limit" % mood)
		_setup()
		_rule("eager", 0)
		_stock(3)
		assert_eq(AutoSell.daily_pass()[SALVE]["qty"], 3, "capped by the surplus")
	)

	run_case("mood_numbers_and_xp_come_from_data", func():
		_setup()
		var cfg: Dictionary = GameData.MARKET["autoSell"]
		var saved: Dictionary = GameState.deep_copy(cfg)
		cfg["moods"]["steady"]["maxPriceDrop"] = 0.12
		cfg["salesXp"] = 7
		_rule("steady", 0)
		_stock(30)
		var before: int = _sales_xp()
		var sold: Dictionary = AutoSell.daily_pass()
		var gained: int = _sales_xp() - before
		GameData.MARKET["autoSell"] = saved
		assert_eq(sold[SALVE]["qty"], LIMITS["eager"], "limit follows the data")
		assert_eq(gained, 7, "XP follows the data")
	)

	run_case("pays_quote_times_quality_lowest_tier_first_with_no_cut", func():
		_setup()
		_rule("eager", 0)
		var price: int = Market.base_price("consumable", SALVE) * 2
		_price(price)
		Crafting.inventory_add(SALVE, 3, 30)
		Crafting.inventory_add(SALVE, 1, 2)
		var cash: int = GameState.state["player"]["cash"]
		var relation: int = GameState.state["contacts"]["archie"]["relation"]
		_market_stock(100)  # eager limit 8: two tier 1, six tier 3
		var income: int = 2 * price + 6 * (price * 3 / 2)
		var sold: Dictionary = AutoSell.daily_pass()
		assert_eq(sold[SALVE], { "qty": 8, "income": income })
		assert_eq(Crafting.inventory_qty(SALVE, 3), 24)
		assert_eq(Crafting.inventory_qty(SALVE), 24, "tier 1 went first")
		assert_eq(GameState.state["player"]["cash"], cash + income, "no Archie cut")
		assert_eq(GameState.state["bankLog"][-1]["label"], "Auto-sales")
		assert_eq(GameState.state["bankLog"][-1]["amount"], income, "one banked total")
		assert_eq(GameState.state["contacts"]["archie"]["relation"], relation, "no relation gain")
		assert_eq(GameState.state["pendingSaleCut"], 0, "no mugging")
		assert_eq(int(GameState.state["flags"]["consSoldCount"]), 0, "not a hand sale")
	)

	run_case("revenue_goes_to_the_pot_while_active", func():
		_setup()
		Business.activate()
		_rule("eager", 0)
		_stock(4)
		var cash: int = GameState.state["player"]["cash"]
		var receipts: int = GameState.state["business"]["week"]["receipts"]
		var income: int = AutoSell.daily_pass()[SALVE]["income"]
		assert_true(income > 0)
		assert_eq(GameState.state["player"]["cash"], cash, "cash untouched")
		assert_eq(GameState.state["business"]["week"]["receipts"], receipts + income)
	)

	run_case("sales_go_through_the_supply_record_by_tier", func():
		_setup()
		_rule("eager", 0)
		Crafting.inventory_add(SALVE, 1, 1)
		Crafting.inventory_add(SALVE, 2, 2)
		AutoSell.daily_pass()
		var market: Dictionary = GameState.state["market"]
		assert_eq(market["supply"]["consumable"][SALVE]["player"], 3)
		assert_eq(market["supplyTiers"][SALVE], { "1": 1, "2": 2 })
	)

	run_case("rollover_sells_lowers_the_price_and_reports", func():
		_rollover_fixture("off")
		TimeSystem.daily_tick()
		var unsold_stock := Market.stock("consumable", SALVE)
		var unsold_price := Market.quote("consumable", SALVE)
		assert_eq(MorningAccountsSystem.latest()["sales"], {}, "control rolls no sales")

		_rollover_fixture("eager")
		var quoted := Market.quote("consumable", SALVE)
		TimeSystem.daily_tick()
		var sale: Dictionary = MorningAccountsSystem.latest()["sales"][SALVE]
		assert_eq(sale, { "qty": LIMITS["eager"], "income": quoted * LIMITS["eager"] })
		assert_eq(Crafting.inventory_qty(SALVE), 100 - LIMITS["eager"])
		assert_true(Market.stock("consumable", SALVE) > unsold_stock, "London took the stock")
		assert_true(Market.quote("consumable", SALVE) < unsold_price, "the price responds")
		assert_true(MorningAccountsSystem.has_operations(MorningAccountsSystem.latest()))
		var label: String = MorningAccountsSystem.sale_label(SALVE, sale)
		assert_true(label.contains(GameData.RECIPES[SALVE]["name"]) and label.contains(str(sale["qty"])) and label.contains("£%d" % sale["income"]), label)
	)

	run_case("rollover_delivers_contracts_before_auto_selling", func():
		_rollover_fixture("eager")
		var created: Dictionary = OffersSystem.create_offer({
			"id": "t_auto_sell_roll", "source": "scripted", "contractType": "recurring", "weekday": 1,
			"request": { "kind": "consumable", "type": SALVE, "qty": 90 },
		})
		OffersSystem.accept_offer(created["offer"]["id"])
		TimeSystem.daily_tick()
		assert_eq(MorningAccountsSystem.latest()["sales"][SALVE]["qty"], 10, "only the stock the delivery left")
		assert_eq(Crafting.inventory_qty(SALVE), 0)
	)

	run_case("a_sale_day_awards_sales_xp_once_and_a_quiet_day_none", func():
		_rollover_fixture("eager")
		GameState.state["autoSell"]["bloom"] = { "sellAbove": 0, "mood": "eager" }
		Crafting.inventory_add("bloom", 1, 50)
		assert_eq(_xp_from_a_rollover(), 2, "one flat award for the day")
		assert_eq(MorningAccountsSystem.latest()["sales"].size(), 2, "two items sold")

		_rollover_fixture("off")
		assert_eq(_xp_from_a_rollover(), 0, "no auto-sale, no XP")
	)


# Archie on Sales (when staffed) and Owen available for Production, on a
# non-Monday, with Healing Salve stock at London's normal 210.
func _setup(staffed: bool = true) -> void:
	GameState.reset()
	GameState.state["world"]["day"] = 3
	GameState.state["contacts"]["owen"]["recruited"] = true
	GameState.state["flags"]["bizOwenProductionRole"] = true
	if staffed:
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "ops")


func _rollover_fixture(mood: String, sell_above: int = 0) -> void:
	_setup()
	_rule(mood, sell_above)
	_stock(100)
	_price(Market.base_price("consumable", SALVE) * 2)


func _rule(mood: String, sell_above: int) -> void:
	GameState.state["autoSell"][SALVE] = { "sellAbove": sell_above, "mood": mood }


func _stock(qty: int) -> void:
	Crafting.inventory_add(SALVE, 1, qty)


func _price(price: int) -> void:
	GameState.state["market"]["goods"]["consumable"][SALVE]["price"] = price


func _market_stock(qty: int) -> void:
	var good: Dictionary = GameState.state["market"]["goods"]["consumable"][SALVE]
	good["tiers"] = { "1": qty }
	good["stock"] = qty


# Sales XP gained over one rollover, less the award for any random offer the
# role sourced in it.
func _xp_from_a_rollover() -> int:
	var xp := _sales_xp()
	var offers: int = OffersSystem.random_pending_count()
	TimeSystem.daily_tick()
	return _sales_xp() - xp - OFFER_SOURCED_XP * (OffersSystem.random_pending_count() - offers)


func _sales_xp() -> int:
	return int(GameState.state["contacts"]["archie"]["salesXP"])
