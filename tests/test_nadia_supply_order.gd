extends "res://tests/test_base.gd"


func _activate_order() -> void:
	GameState.state["flags"]["colA1NadiaMet"] = true
	Objectives.refresh()


func run() -> void:
	run_case("nadia_supply_accepts_partial_and_final_deliveries_at_the_live_collective_price", func():
		GameState.reset()
		_activate_order()
		GameState.state["player"]["orichalchum"]["time"] = 20
		var price: int = Economy.get_faction_sell_price("collective", "ore", "time")
		var cash_before: int = GameState.state["player"]["cash"]

		var first := Collective.supply_nadia(12)
		assert_true(first["ok"])
		assert_eq(first["earned"], Market.line_total("ore", price, 12))
		assert_eq(GameState.state["objectives"]["col_a1_nadia_supply"]["progress"]["delivered"], 12)
		assert_eq(GameState.state["player"]["cash"], cash_before + Market.line_total("ore", price, 12))
		assert_true(not GameState.state["flags"].get("colA1NadiaSupplied", false))

		var second := Collective.supply_nadia(8)
		assert_true(second["ok"])
		assert_eq(GameState.state["objectives"]["col_a1_nadia_supply"]["progress"]["delivered"], 20)
		assert_true(GameState.state["flags"]["colA1NadiaSupplied"])
	)

	run_case("nadia_supply_pays_in_full_past_the_collective_wallet_and_floors_it_at_zero", func():
		GameState.reset()
		_activate_order()
		GameState.state["factions"]["collective"]["resources"] = 10
		GameState.state["player"]["orichalchum"]["time"] = 20
		var price: int = Economy.get_faction_sell_price("collective", "ore", "time")

		var result := Collective.supply_nadia(20)
		assert_true(result["ok"])
		assert_eq(result["earned"], Market.line_total("ore", price, 20), "the questline order is exempt from the wallet cap")
		assert_eq(GameState.state["factions"]["collective"]["resources"], 0, "wallet floored, never negative")
		assert_eq(FactionSim.ore_held("collective", "time"), 20, "the delivery joins the Collective's holdings")
		assert_true(GameState.state["flags"]["colA1NadiaSupplied"])
	)

	run_case("nadia_supply_rejects_insufficient_stock_and_does_not_pay_or_progress", func():
		GameState.reset()
		_activate_order()
		GameState.state["player"]["orichalchum"]["time"] = 5
		var cash_before: int = GameState.state["player"]["cash"]

		var result := Collective.supply_nadia(6)
		assert_true(not result["ok"])
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 5)
		assert_eq(GameState.state["player"]["cash"], cash_before)
		assert_eq(GameState.state["objectives"]["col_a1_nadia_supply"]["progress"].get("delivered", 0), 0)
	)

	run_case("nadia_supply_accepts_an_over_delivery_once_and_cannot_settle_twice", func():
		GameState.reset()
		_activate_order()
		GameState.state["player"]["orichalchum"]["time"] = 25
		var price: int = Economy.get_faction_sell_price("collective", "ore", "time")
		var cash_before: int = GameState.state["player"]["cash"]

		var first := Collective.supply_nadia(25)
		assert_true(first["ok"])
		assert_eq(first["earned"], Market.line_total("ore", price, 25))
		assert_eq(GameState.state["objectives"]["col_a1_nadia_supply"]["progress"]["delivered"], 20)
		assert_eq(GameState.state["player"]["cash"], cash_before + Market.line_total("ore", price, 25))

		var second := Collective.supply_nadia(1)
		assert_true(not second["ok"])
		assert_eq(GameState.state["player"]["cash"], cash_before + Market.line_total("ore", price, 25))
	)

	run_case("ordinary_collective_trades_do_not_advance_nadias_order", func():
		GameState.reset()
		_activate_order()
		GameState.state["player"]["orichalchum"]["time"] = 30
		GameState.state["sellState"]["ore_time"] = 30

		Collective.complete_trade("des")
		assert_eq(GameState.state["objectives"]["col_a1_nadia_supply"]["progress"].get("delivered", 0), 0)
		assert_true(not GameState.state["flags"].get("colA1NadiaSupplied", false))
	)

	run_case("legacy_incomplete_order_credits_only_post_activation_collective_time_sales", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["flags"]["colA1NadiaMet"] = true
		legacy["factions"]["collective"]["oreSold"]["time"] = { "units": 27, "transactions": 3 }
		legacy["objectives"]["col_a1_nadia_supply"] = {
			"active": true, "complete": false,
			"progress": { "activatedDay": 2, "baseline": { "units": 15, "transactions": 1 } },
		}

		var result := SaveManager.import_string(JSON.stringify(legacy))
		assert_true(result["ok"])
		assert_eq(GameState.state["objectives"]["col_a1_nadia_supply"]["progress"]["delivered"], 12)
		assert_true(not GameState.state["objectives"]["col_a1_nadia_supply"]["complete"])
	)

	run_case("legacy_completed_order_remains_completed_without_replaying_a_supply", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["flags"]["colA1NadiaMet"] = true
		legacy["flags"]["colA1NadiaSupplied"] = true
		legacy["objectives"]["col_a1_nadia_supply"] = { "active": true, "complete": true, "progress": { "baseline": { "units": 0, "transactions": 0 } } }
		var cash_before: int = legacy["player"]["cash"]

		var result := SaveManager.import_string(JSON.stringify(legacy))
		assert_true(result["ok"])
		assert_true(GameState.state["objectives"]["col_a1_nadia_supply"]["complete"])
		assert_true(GameState.state["flags"]["colA1NadiaSupplied"])
		assert_eq(GameState.state["player"]["cash"], cash_before)
		assert_true(not Collective.supply_nadia(1)["ok"])
	)
