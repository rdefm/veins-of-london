extends "res://tests/test_base.gd"

const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")
const OffersSystem := preload("res://systems/offers.gd")

const SALVE := "healingSalve"
const LIMITS := { "cautious": 4, "balanced": 8, "aggressive": 18 }  # at London stock 210
const OFFER_SOURCED_XP := 5


func run() -> void:
	calendar_start_weekday = 0  # fixtures count days from a Monday day 1

	run_case("new_and_old_saves_default_to_off", func():
		_setup()
		assert_eq(GameState.state["production"]["overrides"], {}, "new game has no overrides")
		var old_save: Dictionary = GameState.deep_copy(GameState.state)
		old_save.erase("production")
		assert_eq(SaveManager.backfill_defaults(old_save)["production"]["overrides"], {}, "old save backfills empty")
		assert_eq(AutoSell.rule(SALVE)["mood"], "balanced")
		assert_eq(AutoSell.rule(SALVE)["sellAbove"], GameData.PRODUCTION_TARGET_MAX, "cutoff starts at the top of the bar")
	)

	run_case("rule_is_pure_data_and_survives_a_save_round_trip", func():
		_setup()
		_rule("aggressive", 7)
		var exported: String = SaveManager.export_string()
		ProductionSettings.revert(SALVE)
		assert_true(SaveManager.import_string(exported)["ok"])
		assert_eq(AutoSell.rule(SALVE)["sellAbove"], 7)
		assert_eq(AutoSell.rule(SALVE)["mood"], "aggressive")
		assert_eq(typeof(AutoSell.rule(SALVE)["sellAbove"]), TYPE_INT, "sellAbove restores as int")
	)

	run_case("no_one_in_sales_sells_nothing", func():
		_setup(false)
		_rule("aggressive", 0)
		_stock(30)
		assert_eq(AutoSell.daily_pass(), {})
		assert_eq(Crafting.inventory_qty(SALVE), 30)
	)

	run_case("cutoff_at_the_top_and_missing_rule_sell_nothing_whatever_the_stock", func():
		_setup()
		var over_the_top: int = GameData.PRODUCTION_TARGET_MAX + 10
		_stock(over_the_top)
		assert_eq(AutoSell.daily_pass(), {}, "no rule")
		_rule("aggressive", GameData.PRODUCTION_TARGET_MAX)
		assert_eq(AutoSell.daily_pass(), {}, "cutoff at the top")
		assert_eq(Crafting.inventory_qty(SALVE), over_the_top)
	)

	run_case("v13_save_migrates_to_master_defaults", func():
		_setup()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save["meta"]["saveVersion"] = 13
		save["autoSell"] = {
			"bloom": { "sellAbove": 7, "mood": "careful" },
			"blast": { "sellAbove": 8, "mood": "steady" },
			SALVE: { "sellAbove": 9, "mood": "eager" },
			"shield": { "sellAbove": 10, "mood": "off" },
		}
		assert_true(SaveManager.import_string(JSON.stringify(save))["ok"])
		assert_eq(GameState.state["production"], ProductionSettings.default_state())
	)

	run_case("only_production_list_recipes_sell", func():
		_setup()
		assert_true(not Rooms.production_recipes().has("timePearl"), "fixture: Owen can't make Time Pearls")
		ProductionSettings.set_field("timePearl", "sellAbove", 0); ProductionSettings.set_field("timePearl", "mood", "aggressive")
		Crafting.inventory_add("timePearl", 1, 30)
		assert_eq(AutoSell.daily_pass(), {})
		assert_eq(Crafting.inventory_qty("timePearl"), 30)
	)

	run_case("stock_stops_at_the_sell_above_floor", func():
		_setup()
		_rule("aggressive", 20)
		_stock(25)
		assert_eq(AutoSell.daily_pass()[SALVE]["qty"], 5)
		assert_eq(Crafting.inventory_qty(SALVE), 20)
		assert_eq(AutoSell.daily_pass(), {}, "at the floor nothing more sells")
	)

	run_case("daily_pass_adds_sold_units_to_the_lifetime_counter", func():
		_setup()
		_rule("aggressive", 20)
		_stock(25)
		assert_eq(GameState.state["business"]["autoSoldUnits"], 0)
		AutoSell.daily_pass()
		assert_eq(GameState.state["business"]["autoSoldUnits"], 5)
		AutoSell.daily_pass()
		assert_eq(GameState.state["business"]["autoSoldUnits"], 5, "a pass that sells nothing adds nothing")
	)

	run_case("contract_need_raises_the_floor_only_while_covering_contracts", func():
		_setup()
		ProductionSettings.set_master_field("coverContracts", false)
		_rule("aggressive", 10)
		var created: Dictionary = OffersSystem.create_offer({
			"id": "t_auto_sell", "source": "scripted", "contractType": "recurring", "weekday": 1,
			"request": { "kind": "consumable", "type": SALVE, "qty": 20 },
		})
		OffersSystem.accept_offer(created["offer"]["id"])
		assert_eq(AutoSell.protected_floor(SALVE), 10, "not covering contracts: need doesn't count")
		ProductionSettings.set_field(SALVE, "coverContracts", true)
		assert_eq(AutoSell.protected_floor(SALVE), 20, "contract need beats sellAbove")
		_stock(30)
		assert_eq(AutoSell.daily_pass()[SALVE]["qty"], 10)
		assert_eq(Crafting.inventory_qty(SALVE), 20)
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
		_rule("cautious", 0)
		_stock(30)
		_price(110)
		var qty := AutoSell.sellable_qty(SALVE)
		GameData.CONSUMABLE_PRICES[SALVE] = original
		assert_eq(qty, LIMITS["cautious"], "100 × 1.1 isn't exactly 110 in floats")
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
		_rule("aggressive", 0)
		_stock(3)
		assert_eq(AutoSell.daily_pass()[SALVE]["qty"], 3, "capped by the surplus")
	)

	run_case("mood_numbers_and_xp_come_from_data", func():
		_setup()
		var cfg: Dictionary = GameData.MARKET["autoSell"]
		var saved: Dictionary = GameState.deep_copy(cfg)
		cfg["moods"]["balanced"]["maxPriceDrop"] = 0.12
		cfg["salesXp"] = 7
		_rule("balanced", 0)
		_stock(30)
		var before: int = _sales_xp()
		var sold: Dictionary = AutoSell.daily_pass()
		var gained: int = _sales_xp() - before
		GameData.MARKET["autoSell"] = saved
		assert_eq(sold[SALVE]["qty"], LIMITS["aggressive"], "limit follows the data")
		assert_eq(gained, 7, "XP follows the data")
	)

	run_case("pays_quote_times_quality_lowest_tier_first_with_no_cut", func():
		_setup()
		_rule("aggressive", 0)
		var price: int = Market.base_price("consumable", SALVE) * 2
		_price(price)
		Crafting.inventory_add(SALVE, 3, 30)
		Crafting.inventory_add(SALVE, 1, 2)
		var cash: int = GameState.state["player"]["cash"]
		var relation: int = GameState.state["contacts"]["archie"]["relation"]
		_market_stock(100)  # eager limit 8: two tier 1, six tier 3
		var income: int = 2 * price + 6 * (price * 3 / 2)
		var sold: Dictionary = AutoSell.daily_pass()
		assert_eq(sold[SALVE], { "qty": 8, "offMarketQty": 0, "income": income })
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
		_rule("aggressive", 0)
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
		_rule("aggressive", 0)
		Crafting.inventory_add(SALVE, 1, 1)
		Crafting.inventory_add(SALVE, 2, 2)
		AutoSell.daily_pass()
		var market: Dictionary = GameState.state["market"]
		assert_eq(market["supply"]["consumable"][SALVE]["player"], 3)
		assert_eq(market["supplyTiers"][SALVE], { "1": 1, "2": 2 })
	)

	run_case("rollover_sells_lowers_the_price_and_reports", func():
		_rollover_fixture("balanced", GameData.PRODUCTION_TARGET_MAX)
		TimeSystem.daily_tick()
		var unsold_stock := Market.stock("consumable", SALVE)
		var unsold_price := Market.quote("consumable", SALVE)
		assert_eq(MorningAccountsSystem.latest()["sales"], {}, "control rolls no sales")

		_rollover_fixture("aggressive")
		var quoted := Market.quote("consumable", SALVE)
		TimeSystem.daily_tick()
		var sale: Dictionary = MorningAccountsSystem.latest()["sales"][SALVE]
		assert_eq(sale, { "qty": LIMITS["aggressive"], "offMarketQty": 0, "income": quoted * LIMITS["aggressive"] })
		assert_eq(Crafting.inventory_qty(SALVE), 100 - LIMITS["aggressive"])
		assert_true(Market.stock("consumable", SALVE) > unsold_stock, "London took the stock")
		assert_true(Market.quote("consumable", SALVE) < unsold_price, "the price responds")
		assert_true(MorningAccountsSystem.has_operations(MorningAccountsSystem.latest()))
		var label: String = MorningAccountsSystem.sale_label(SALVE, sale)
		assert_true(label.contains(GameData.RECIPES[SALVE]["name"]) and label.contains(str(sale["qty"])) and label.contains("£%d" % sale["income"]), label)
	)

	run_case("rollover_delivers_contracts_before_auto_selling", func():
		_rollover_fixture("aggressive")
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
		_rollover_fixture("aggressive")
		ProductionSettings.set_field("bloom", "sellAbove", 0); ProductionSettings.set_field("bloom", "mood", "aggressive")
		Crafting.inventory_add("bloom", 1, 50)
		assert_eq(_xp_from_a_rollover(), 2, "one flat award for the day")
		assert_eq(MorningAccountsSystem.latest()["sales"].size(), 2, "two items sold")

		_rollover_fixture("balanced", GameData.PRODUCTION_TARGET_MAX)
		assert_eq(_xp_from_a_rollover(), 0, "no auto-sale, no XP")
	)

	run_case("sell_above_clamps_to_the_bar_and_leaves_production_alone", func():
		_setup()
		AutoSell.set_sell_above(SALVE, 20)
		assert_eq(AutoSell.rule(SALVE)["sellAbove"], 20)
		AutoSell.set_sell_above(SALVE, 0)
		assert_eq(AutoSell.rule(SALVE)["sellAbove"], 0, "Sell all is reachable")
		AutoSell.set_sell_above(SALVE, 999)
		assert_eq(AutoSell.rule(SALVE)["sellAbove"], GameData.PRODUCTION_TARGET_MAX, "tops out at the bar's end")
		assert_eq(Rooms.lab_target(SALVE), 0, "Production is untouched by Sell-above")
	)

	run_case("cutoff_and_mood_are_locked_until_sales_is_staffed", func():
		_setup(false)
		AutoSell.set_sell_above(SALVE, 10)
		AutoSell.set_mood(SALVE, "aggressive")
		assert_eq(AutoSell.rule(SALVE), ProductionSettings.master())
	)

	run_case("master_sell_above_and_production_are_independent", func():
		_setup()
		ProductionSettings.set_master_sell_above(0)
		assert_eq(ProductionSettings.master()["sellAbove"], 0)
		ProductionSettings.set_master_production(GameData.PRODUCTION_TARGET_MAX)
		assert_eq(ProductionSettings.master()["sellAbove"], 0, "Make to doesn't push Sell above")
		Rooms.set_lab_threshold(SALVE, GameData.PRODUCTION_TARGET_MAX)
		assert_eq(Rooms.lab_target(SALVE), GameData.PRODUCTION_TARGET_MAX, "Production ignores Sell-above")
	)

	run_case("set_mood_keeps_the_cutoff_and_refuses_an_unknown_mood", func():
		_setup()
		AutoSell.set_sell_above(SALVE, 15)
		AutoSell.set_mood(SALVE, "balanced")
		AutoSell.set_mood(SALVE, "reckless")
		AutoSell.set_mood(SALVE, "off")
		assert_eq(AutoSell.rule(SALVE)["sellAbove"], 15)
		assert_eq(AutoSell.rule(SALVE)["mood"], "balanced")
	)

	run_case("rule_set_through_the_controls_survives_save_and_load", func():
		_setup()
		AutoSell.set_sell_above(SALVE, 15)
		AutoSell.set_mood(SALVE, "cautious")
		var exported: String = SaveManager.export_string()
		ProductionSettings.revert(SALVE)
		assert_true(SaveManager.import_string(exported)["ok"])
		assert_eq(AutoSell.rule(SALVE)["sellAbove"], 15)
		assert_eq(AutoSell.rule(SALVE)["mood"], "cautious")
	)

	run_case("projection_matches_what_the_rollover_sells_across_mixed_tiers", func():
		_rollover_fixture("aggressive", 10)
		GameState.state["player"]["inventory"][SALVE] = { "1": 5, "3": 20 }
		var before: Dictionary = GameState.state["player"]["inventory"].duplicate(true)
		var projected := AutoSell.projection(SALVE)
		assert_eq(GameState.state["player"]["inventory"], before, "projecting takes no stock")
		assert_eq(projected["qty"], 15, "fixture: the sale crosses both tiers")
		var sold: Dictionary = AutoSell.daily_pass()
		assert_eq(projected["reason"], "")
		assert_eq([projected["qty"], projected["income"]], [sold[SALVE]["qty"], sold[SALVE]["income"]])
	)

	run_case("projection_previews_an_unstored_cutoff", func():
		_rollover_fixture("aggressive", 10)
		_held(45)
		var limit := AutoSell.market_limit(SALVE, GameData.MARKET["autoSell"]["moods"]["aggressive"]["maxPriceDrop"])
		assert_eq(AutoSell.projection(SALVE)["qty"], mini(35, limit))
		assert_eq(AutoSell.projection(SALVE, 40)["qty"], 5, "a dragged cutoff")
		assert_eq(AutoSell.projection(SALVE, GameData.PRODUCTION_TARGET_MAX)["reason"], AutoSell.REASON_SELL_NONE, "dragged to the top")
		assert_eq(AutoSell.rule(SALVE)["sellAbove"], 10, "preview stores nothing")
	)

	run_case("projection_names_why_nothing_sells", func():
		_setup(false)
		assert_eq(AutoSell.projection(SALVE)["reason"], AutoSell.REASON_NO_SALES)

		_rollover_fixture("aggressive", GameData.PRODUCTION_TARGET_MAX)
		assert_eq(AutoSell.projection(SALVE)["reason"], AutoSell.REASON_SELL_NONE)

		_rollover_fixture("aggressive", 40)
		_held(30)
		assert_eq(AutoSell.projection(SALVE)["reason"], AutoSell.REASON_UNDER_CUTOFF)

		_rollover_fixture("aggressive", 45)
		_cover_contracts(110)
		assert_eq(AutoSell.protected_floor(SALVE), 110, "fixture: contract need lifts the floor over the stock")
		assert_eq(AutoSell.projection(SALVE)["reason"], AutoSell.REASON_CONTRACTS)

		_rollover_fixture("aggressive")
		_price(1)
		assert_eq(AutoSell.projection(SALVE)["reason"], AutoSell.REASON_PRICE)

		_rollover_fixture("aggressive")
		_market_stock(1)
		assert_eq(AutoSell.projection(SALVE)["reason"], AutoSell.REASON_MARKET_FULL)
	)

	run_case("level_1_sales_places_nothing_privately", func():
		_rollover_fixture("aggressive")
		assert_eq(AutoSell.projection(SALVE)["offMarketQty"], 0)
		assert_eq(AutoSell.daily_pass()[SALVE]["offMarketQty"], 0)
		assert_eq(Crafting.inventory_qty(SALVE), 100 - LIMITS["aggressive"])
	)

	run_case("off_market_units_scale_with_sales_level_rounded_down", func():
		var aggressive_by_level := { 1: 0, 2: 1, 3: 3, 4: 5, 5: 7 }  # of 18
		for level in aggressive_by_level:
			_rollover_fixture("aggressive")
			_sales_level(level)
			var sold: Dictionary = AutoSell.daily_pass()[SALVE]
			assert_eq(sold["qty"], LIMITS["aggressive"], "level %d: market sale unchanged" % level)
			assert_eq(sold["offMarketQty"], aggressive_by_level[level], "level %d" % level)
			assert_eq(Crafting.inventory_qty(SALVE), 100 - LIMITS["aggressive"] - aggressive_by_level[level])
		var level_5_by_mood := { "cautious": 1, "balanced": 3 }
		for mood in level_5_by_mood:
			_rollover_fixture(mood)
			_sales_level(5)
			assert_eq(AutoSell.projection(SALVE)["offMarketQty"], level_5_by_mood[mood], "%s limit at level 5" % mood)
	)

	run_case("off_market_rate_comes_from_data", func():
		_rollover_fixture("aggressive")
		_sales_level(3)
		var cfg: Dictionary = GameData.MARKET["autoSell"]
		var saved: float = cfg["offMarketPerSalesLevel"]
		cfg["offMarketPerSalesLevel"] = 0.25
		var limit := AutoSell.off_market_limit(LIMITS["aggressive"])
		cfg["offMarketPerSalesLevel"] = saved
		assert_eq(limit, 9)
	)

	run_case("off_market_pays_like_the_market_but_leaves_london_untouched", func():
		_rollover_fixture("aggressive")
		_sales_level(5)
		var quoted := Market.quote("consumable", SALVE)
		var cash: int = GameState.state["player"]["cash"]
		var shares_before: Array = GameState.deep_copy(GameState.state["shares"]["days"])
		var sold: Dictionary = AutoSell.daily_pass()[SALVE]
		var market: Dictionary = GameState.state["market"]
		var income: int = quoted * (LIMITS["aggressive"] + 7)
		assert_eq(sold, { "qty": LIMITS["aggressive"], "offMarketQty": 7, "income": income })
		assert_eq(GameState.state["player"]["cash"], cash + income, "one banked total for both channels")
		assert_eq(market["supply"]["consumable"][SALVE]["player"], LIMITS["aggressive"], "only market units reach the supply record")
		assert_eq(market["supplyTiers"][SALVE], { "1": LIMITS["aggressive"] }, "nor its tier record")
		assert_eq(GameState.state["shares"]["days"], shares_before, "selling adds nothing to the share tallies")
	)

	run_case("off_market_lots_follow_the_market_up_the_tiers", func():
		_rollover_fixture("aggressive")
		_sales_level(5)
		GameState.state["player"]["inventory"][SALVE] = { "1": 20, "3": 20 }
		var quoted := Market.quote("consumable", SALVE)
		var projected := AutoSell.projection(SALVE)
		var sold: Dictionary = AutoSell.daily_pass()[SALVE]
		var tier_three: int = GameState.round_epsilon(quoted * Economy.quality_price_multiplier(3))
		assert_eq(sold["income"], 20 * quoted + 5 * tier_three, "2 private units at tier 1, 5 at tier 3")
		assert_eq(projected["income"], sold["income"], "the live line matches the pass")
		assert_eq(GameState.state["market"]["supplyTiers"][SALVE], { "1": 18 }, "tier 3 went private")
	)

	run_case("off_market_stays_on_top_of_the_floor_and_price", func():
		_rollover_fixture("aggressive", 35)
		_held(45)
		_sales_level(5)
		var whole_surplus: Dictionary = AutoSell.daily_pass()[SALVE]
		assert_eq([whole_surplus["qty"], whole_surplus["offMarketQty"]], [10, 0], "market takes the whole surplus")
		assert_eq(Crafting.inventory_qty(SALVE), 35)

		_rollover_fixture("aggressive", 25)
		_held(45)
		_sales_level(5)
		assert_eq(AutoSell.projection(SALVE)["offMarketQty"], 2, "only the surplus left after the market")
		AutoSell.daily_pass()
		assert_eq(Crafting.inventory_qty(SALVE), 25)

		_rollover_fixture("aggressive")
		_sales_level(5)
		_price(1)
		assert_eq(AutoSell.daily_pass(), {}, "under the minimum price nothing sells")
		assert_eq(Crafting.inventory_qty(SALVE), 100)
	)

	run_case("rollover_keeps_london_as_if_the_private_units_never_existed", func():
		_rollover_fixture("aggressive")
		AutoSell.daily_pass()
		Market.daily_reprice()
		var market_only := [Market.stock("consumable", SALVE), Market.quote("consumable", SALVE)]

		_rollover_fixture("aggressive")
		_sales_level(5)
		assert_eq(AutoSell.daily_pass()[SALVE]["offMarketQty"], 7)
		Market.daily_reprice()
		assert_eq([Market.stock("consumable", SALVE), Market.quote("consumable", SALVE)], market_only)

		_rollover_fixture("aggressive")
		_sales_level(5)
		TimeSystem.daily_tick()
		assert_eq(MorningAccountsSystem.latest()["sales"][SALVE]["offMarketQty"], 7, "the report carries them")
	)

	run_case("morning_line_shows_private_units_separately", func():
		_setup()
		var both: String = MorningAccountsSystem.sale_label(SALVE, { "qty": 8, "offMarketQty": 2, "income": 500 })
		assert_true(both.contains("Sold 8") and both.contains("+2 placed privately") and both.contains("£500"), both)
		assert_true(not MorningAccountsSystem.sale_label(SALVE, { "qty": 8, "offMarketQty": 0, "income": 500 }).contains("privately"))
		assert_true(not MorningAccountsSystem.sale_label(SALVE, { "qty": 8, "income": 500 }).contains("privately"), "older save's account")
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


func _cover_contracts(qty: int) -> void:
	var created: Dictionary = OffersSystem.create_offer({ "id": "bar_need", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": SALVE, "qty": qty } })
	OffersSystem.accept_offer(created["offer"]["id"])
	Rooms.set_lab_cover_contracts(SALVE, true)


func _rule(mood: String, sell_above: int) -> void:
	ProductionSettings.set_field(SALVE, "sellAbove", sell_above); ProductionSettings.set_field(SALVE, "mood", mood)


func _stock(qty: int) -> void:
	Crafting.inventory_add(SALVE, 1, qty)


func _held(qty: int) -> void:
	GameState.state["player"]["inventory"][SALVE] = { "1": qty }


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


func _sales_level(level: int) -> void:
	GameState.state["contacts"]["archie"]["salesSkill"] = level


func _sales_xp() -> int:
	return int(GameState.state["contacts"]["archie"]["salesXP"])
