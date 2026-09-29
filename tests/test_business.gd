extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")


func run() -> void:
	run_case("split_rounds_remainders_to_the_player", func():
		assert_eq(Business.split(100, 2), { "partner": 33, "player": 34 })
		assert_eq(Business.split(5, 2), { "partner": 1, "player": 3 })
		assert_eq(Business.split(0, 2), { "partner": 0, "player": 0 })
		assert_eq(Business.split(99, 2), { "partner": 33, "player": 33 })
	)

	run_case("prorated_wage_rounds_a_partial_week", func():
		assert_eq(Business.prorated_wage(250, 7), 250)
		assert_eq(Business.prorated_wage(250, 2), 71)
		assert_eq(Business.prorated_wage(250, 6), 214)
		assert_eq(Business.prorated_wage(250, 0), 0)
	)

	run_case("activate_sets_partners_and_owens_hire_day_once", func():
		GameState.reset()
		GameState.state["world"]["day"] = 4
		assert_true(Business.activate()["ok"])
		var business: Dictionary = GameState.state["business"]
		assert_true(business["potActive"])
		assert_eq(business["partners"], ["archie", "james"])
		assert_eq(business["wages"]["owen"]["hiredDay"], 4)
		assert_eq(business["wages"]["owen"]["weekly"], 250)
		assert_true(not Business.activate()["ok"], "a second activation is refused")
	)

	run_case("payday_pays_a_prorated_first_week_then_splits_the_rest", func():
		GameState.reset()
		GameState.state["world"]["day"] = 6
		Business.activate()
		Business.receive(500)
		TimeSystem.do_rest()
		assert_eq(GameState.state["business"]["ledger"].size(), 0, "no payday before MON day 8")
		TimeSystem.do_rest()
		var business: Dictionary = GameState.state["business"]
		assert_eq(business["ledger"].size(), 1)
		var record: Dictionary = business["ledger"][0]
		assert_eq(record["payday"], "payday-1")
		assert_eq(record["day"], 8)
		assert_eq(record["receipts"], 500)
		assert_eq(record["expenses"], [{ "kind": "wage", "contactId": "owen", "amount": 71 }])
		# R = 500 − 71 = 429 → 143 each.
		assert_eq(record["shares"], { "player": 143, "archie": 143, "james": 143 })
		assert_eq(business["pot"], 0)
		assert_eq(business["week"], { "startDay": 8, "receipts": 0, "expenses": [] })
		assert_eq(business["nextPaydayId"], 2)
		var share_entries: Array = GameState.state["bankLog"].filter(func(e): return e["label"] == "Business share")
		assert_eq(share_entries.size(), 1)
		assert_eq(share_entries[0]["amount"], 143)
		var account: Dictionary = MorningAccounts.latest()
		assert_eq(account["payday"], record)
	)

	run_case("a_full_week_pays_the_full_wage", func():
		GameState.reset()
		GameState.state["world"]["day"] = 8
		Business.activate()
		Business.receive(1000)
		for i in 7:
			TimeSystem.do_rest()
		var record: Dictionary = GameState.state["business"]["ledger"][0]
		assert_eq(record["day"], 15)
		assert_eq(record["expenses"][0]["amount"], 250)
		assert_eq(record["shares"], { "player": 250, "archie": 250, "james": 250 })
	)

	run_case("payday_fires_only_on_the_rollover_into_each_monday", func():
		GameState.reset()
		Business.activate()
		for i in 15:
			TimeSystem.do_rest()
		var days: Array = GameState.state["business"]["ledger"].map(func(r): return r["day"])
		assert_eq(days, [8, 15], "paydays on MON day 8 and MON day 15 only")
	)

	run_case("declined_wage_prompt_stops_owen_and_full_payment_resumes_him", func():
		GameState.reset()
		GameState.state["world"]["day"] = 2
		_staff_owen()
		Business.activate()
		for i in 6:
			TimeSystem.do_rest()
		# MON day 8, empty pot: 6 days' wage (£214) goes owed.
		var wage: Dictionary = GameState.state["business"]["wages"]["owen"]
		assert_eq(wage["owed"], 214)
		assert_true(Business.is_unpaid("owen"))
		assert_eq(Business.pending_wage_prompts(), ["owen"])
		var account: Dictionary = MorningAccounts.latest()
		assert_true(account["exceptions"].has({ "kind": "wageShortfall", "contactId": "owen", "amount": 214 }))

		Business.decline_wage_prompt("owen")
		assert_eq(Business.pending_wage_prompts(), [])
		assert_true(Business.is_unpaid("owen"), "No leaves him unpaid")
		var xp_before: int = GameState.state["contacts"]["owen"]["cultivatingXP"]
		TimeSystem.run_staff_block()
		assert_eq(GameState.state["contacts"]["owen"]["cultivatingXP"], xp_before, "unpaid Owen does not act")

		Business.receive(100)
		TimeSystem.do_rest()
		assert_eq(wage["owed"], 214, "a pot short of the full owed amount pays nothing")
		assert_eq(wage["daysWorked"], 0, "no wage accrues while unpaid")

		GameState.state["player"]["cash"] = 1000
		var paid: Dictionary = Business.pay_owed_from_cash("owen")
		assert_true(paid["ok"])
		assert_eq(GameState.state["player"]["cash"], 786)
		assert_eq(GameState.state["bankLog"].back()["amount"], -214)
		assert_true(not Business.is_unpaid("owen"))
		assert_eq(wage["owed"], 0)
		TimeSystem.run_staff_block()
		assert_true(GameState.state["contacts"]["owen"]["cultivatingXP"] > xp_before, "paid Owen acts again")
		assert_true(not Business.pay_owed_from_cash("owen")["ok"], "nothing left to pay")
	)

	run_case("owed_wages_wait_for_the_next_monday_payday", func():
		GameState.reset()
		GameState.state["world"]["day"] = 2
		Business.activate()
		for i in 6:
			TimeSystem.do_rest()
		assert_eq(Business.owed("owen"), 214)
		Business.receive(300)
		TimeSystem.do_rest()
		assert_eq(Business.owed("owen"), 214, "no mid-week retry")
		for i in 6:
			TimeSystem.do_rest()
		var business: Dictionary = GameState.state["business"]
		assert_eq(GameState.state["world"]["day"], 15)
		assert_eq(Business.owed("owen"), 0)
		assert_true(not Business.is_unpaid("owen"))
		assert_eq(Business.pending_wage_prompts(), [])
		var record: Dictionary = business["ledger"][-1]
		assert_eq(record["expenses"], [{ "kind": "wage", "contactId": "owen", "amount": 214 }])
		# R = 300 − 214 = 86 → 28 each partner, 30 to the player.
		assert_eq(record["shares"], { "player": 30, "archie": 28, "james": 28 })
	)

	run_case("pay_now_refuses_without_enough_cash", func():
		GameState.reset()
		GameState.state["world"]["day"] = 2
		Business.activate()
		for i in 6:
			TimeSystem.do_rest()
		GameState.state["player"]["cash"] = 10
		assert_true(not Business.pay_owed_from_cash("owen")["ok"])
		assert_eq(Business.owed("owen"), 214)
		assert_eq(GameState.state["player"]["cash"], 10)
	)

	run_case("business_state_survives_a_save_round_trip_as_ints", func():
		GameState.reset()
		Business.activate()
		Business.receive(40)
		var text := SaveManager.export_string()
		assert_true(SaveManager.import_string(text)["ok"])
		var business: Dictionary = GameState.state["business"]
		assert_eq(typeof(business["pot"]), TYPE_INT)
		assert_eq(typeof(business["wages"]["owen"]["weekly"]), TYPE_INT)
		assert_eq(typeof(business["week"]["receipts"]), TYPE_INT)
	)

	run_case("rollover_snapshots_the_ended_day_and_resets_the_tally", func():
		GameState.reset()
		GameState.state["world"]["day"] = 3
		Business.activate()
		Business.receive(120)
		BusinessStats.record_expense(45, BusinessStats.EXPENSE_STAFF)
		GameState.state["productionLog"] = [{ "day": 3, "blocks": [{ "block": 0, "entries": [{ "contactId": "james", "made": { "timePearl": { "1": 2, "2": 1 } }, "failed": { "timePearl": 4 }, "oreShort": null }] }] }]
		TimeSystem.do_rest()
		var stats: Dictionary = GameState.state["businessStats"]
		var snapshot: Dictionary = stats["days"][-1]
		assert_eq(snapshot["day"], 3)
		assert_eq(snapshot["revenue"], 120)
		assert_true(snapshot["expenses"] >= 45, "recorded expenses land in the ended day")
		assert_eq(snapshot["items"], 3, "made items, not failed attempts")
		assert_true(snapshot["expensesStaff"] >= 45, "the staff kind lands in the ended day too")
		assert_eq(stats["today"], { "revenue": 0, "expenses": 0, "expensesStaff": 0, "expensesGuard": 0, "expensesCalc": 0, "oreCultivator": 0, "orePlayer": 0 })
	)

	run_case("expenses_split_by_kind_sum_to_the_total", func():
		GameState.reset()
		BusinessStats.record_expense(40, BusinessStats.EXPENSE_STAFF)
		BusinessStats.record_expense(500, BusinessStats.EXPENSE_GUARD)
		BusinessStats.record_expense(25, BusinessStats.EXPENSE_CALC)
		var today: Dictionary = GameState.state["businessStats"]["today"]
		assert_eq(today["expensesStaff"], 40)
		assert_eq(today["expensesGuard"], 500)
		assert_eq(today["expensesCalc"], 25)
		assert_eq(today["expenses"], 565, "kinds sum to the existing total")
	)

	run_case("calc_purchase_records_a_calc_expense", func():
		GameState.reset()
		Business.activate()
		Business.receive(100)
		assert_true(Business.pay_calc_purchase("c1", [{ "source": "des", "oreType": "time", "qty": 2, "amount": 60 }]))
		var today: Dictionary = GameState.state["businessStats"]["today"]
		assert_eq(today["expensesCalc"], 60)
		assert_eq(today["expenses"], 60)
	)

	run_case("donate_and_withdraw_move_cash_within_bounds_without_revenue", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 300
		assert_true(not Business.donate(100)["ok"], "donate is refused before the pot is active")
		assert_eq(GameState.state["business"]["float"], 0)
		Business.activate()
		assert_true(not Business.donate(0)["ok"])
		assert_true(not Business.donate(301)["ok"])
		assert_true(Business.donate(300)["ok"], "all of the player's cash is allowed")
		assert_eq(GameState.state["player"]["cash"], 0)
		assert_eq(GameState.state["business"]["float"], 300)
		assert_eq(GameState.state["bankLog"].back()["amount"], -300)
		assert_true(not Business.withdraw(0)["ok"])
		assert_true(not Business.withdraw(301)["ok"])
		assert_true(Business.withdraw(120)["ok"])
		assert_eq(GameState.state["player"]["cash"], 120)
		assert_eq(GameState.state["business"]["float"], 180)
		assert_eq(GameState.state["bankLog"].back()["amount"], 120)
		assert_eq(GameState.state["businessStats"]["today"]["revenue"], 0, "the float is not revenue")
		assert_eq(GameState.state["business"]["week"]["receipts"], 0)
	)

	run_case("payday_never_splits_the_float", func():
		GameState.reset()
		GameState.state["world"]["day"] = 7
		Business.activate()
		GameState.state["player"]["cash"] = 1000
		Business.donate(1000)
		Business.receive(600)
		TimeSystem.do_rest()
		var business: Dictionary = GameState.state["business"]
		# One day's wage: round(250 / 7) = 36; R = 564 → 188 each.
		assert_eq(business["ledger"][-1]["shares"], { "player": 188, "archie": 188, "james": 188 })
		assert_eq(business["float"], 1000)
		assert_eq(business["pot"], 0)
	)

	run_case("a_wage_the_pot_cant_cover_draws_on_the_float", func():
		GameState.reset()
		GameState.state["world"]["day"] = 2
		Business.activate()
		GameState.state["player"]["cash"] = 200
		Business.donate(200)
		Business.receive(100)
		for i in 6:
			TimeSystem.do_rest()
		# MON day 8: £214 due; pot 100 + float 114.
		var business: Dictionary = GameState.state["business"]
		assert_eq(Business.owed("owen"), 0)
		assert_true(not Business.is_unpaid("owen"))
		assert_eq(business["float"], 86)
		assert_eq(business["ledger"][-1]["shares"]["player"], 0)
		assert_eq(business["ledger"][-1]["expenses"], [{ "kind": "wage", "contactId": "owen", "amount": 214 }])
	)

	run_case("a_wage_pot_and_float_cant_cover_goes_owed_untouched", func():
		GameState.reset()
		GameState.state["world"]["day"] = 2
		Business.activate()
		GameState.state["player"]["cash"] = 50
		Business.donate(50)
		Business.receive(100)
		for i in 6:
			TimeSystem.do_rest()
		assert_eq(Business.owed("owen"), 214)
		assert_eq(Business.pending_wage_prompts(), ["owen"])
		assert_eq(GameState.state["business"]["float"], 50, "a failed wage takes nothing from the float")
	)

	run_case("calc_purchase_uses_pot_then_float_all_or_nothing", func():
		GameState.reset()
		Business.activate()
		GameState.state["player"]["cash"] = 50
		Business.donate(50)
		Business.receive(40)
		var business: Dictionary = GameState.state["business"]
		assert_true(not Business.pay_calc_purchase("c1", [{ "source": "des", "oreType": "time", "qty": 1, "amount": 91 }]))
		assert_eq(business["pot"], 40)
		assert_eq(business["float"], 50)
		assert_true(Business.pay_calc_purchase("c1", [{ "source": "des", "oreType": "time", "qty": 1, "amount": 70 }]))
		assert_eq(business["pot"], 0)
		assert_eq(business["float"], 20)
		assert_eq(GameState.state["player"]["cash"], 0, "player cash is never touched")
	)

	run_case("no_snapshot_before_the_pot_is_active", func():
		GameState.reset()
		Business.receive(50)
		TimeSystem.do_rest()
		assert_eq(GameState.state["businessStats"]["days"], [])
		assert_eq(GameState.state["businessStats"]["today"]["revenue"], 0, "the tally still resets")
	)

	run_case("snapshots_trim_to_the_last_ten_days", func():
		GameState.reset()
		Business.activate()
		for i in 12:
			TimeSystem.do_rest()
		var days: Array = GameState.state["businessStats"]["days"]
		var last_day: int = GameState.state["world"]["day"] - 1
		assert_eq(days.size(), GameData.BUSINESS_STATS_DAYS)
		assert_eq(days[0]["day"], last_day - GameData.BUSINESS_STATS_DAYS + 1)
		assert_eq(days[-1]["day"], last_day)
	)

	run_case("series_fills_days_without_a_snapshot_with_zero", func():
		GameState.reset()
		GameState.state["world"]["day"] = 15
		GameState.state["businessStats"]["days"] = [{ "day": 12, "revenue": 70, "expenses": 0, "oreCultivator": 0, "orePlayer": 0, "items": 0 }]
		var window := BusinessStats.window_days()
		assert_eq(window.size(), 10)
		assert_eq(window[0], 5)
		assert_eq(window[-1], 14)
		assert_eq(BusinessStats.series("revenue"), [0, 0, 0, 0, 0, 0, 0, 70, 0, 0])

		GameState.state["world"]["day"] = 4
		assert_eq(BusinessStats.window_days(), [1, 2, 3], "the window never reaches before day 1")
	)

	run_case("expense_kind_series_are_zero_filled_and_sum_to_expenses", func():
		GameState.reset()
		Business.activate()
		BusinessStats.record_expense(40, BusinessStats.EXPENSE_STAFF)
		BusinessStats.record_expense(500, BusinessStats.EXPENSE_GUARD)
		TimeSystem.do_rest()
		BusinessStats.record_expense(25, BusinessStats.EXPENSE_CALC)
		TimeSystem.do_rest()
		var total := BusinessStats.series("expenses")
		var kinds: Array = []
		for kind in BusinessStats.EXPENSE_KIND_METRICS:
			var values := BusinessStats.series(BusinessStats.EXPENSE_KIND_METRICS[kind])
			assert_eq(values.size(), BusinessStats.window_days().size(), "%s is zero-filled over the window" % kind)
			kinds.append(values)
		for i in total.size():
			var summed := 0
			for values in kinds:
				summed += int(values[i])
			assert_eq(summed, total[i], "day %d kinds sum to the total" % BusinessStats.window_days()[i])
		assert_eq(BusinessStats.series("expensesGuard").count(0), total.size() - 1, "guard wages land on one day only")
	)

	run_case("ore_tally_splits_cultivator_output_from_player_prunes", func():
		GameState.reset()
		Business.activate()
		_staff_owen()
		GameState.state["player"]["veins"][0]["growth"] = 90
		Rooms.set_vein_station_target("v1", 50)
		GameState.state["player"]["veins"].append(Fixtures.player_vein("v2", "s2", "shoreditch", "life", 90, "fair"))
		var ore: Dictionary = GameState.state["player"]["orichalchum"]
		var time_before: int = ore.get("time", 0)
		var life_before: int = ore.get("life", 0)
		var result := Cultivating.prune("v2", GameData.VEIN_GROWTH["pruneHardDepth"])
		assert_true(result["ok"])
		var today: Dictionary = GameState.state["businessStats"]["today"]
		assert_true(today["orePlayer"] > 0)
		assert_eq(today["orePlayer"], ore["life"] - life_before, "the player's prune counts as player ore")
		assert_true(today["oreCultivator"] > 0)
		assert_eq(today["oreCultivator"], ore["time"] - time_before, "Owen's block prune counts as cultivator ore")
	)


func _staff_owen() -> void:
	GameState.state["player"]["veins"] = [Fixtures.player_vein_with()]
	GameState.state["contacts"]["owen"]["recruited"] = true
	GameState.state["flags"]["bizOwenCultivationRole"] = true
	Contacts.set_role("owen", "cultivation")
	Rooms.assign_vein("owen", "v1")
	Rooms.set_vein_station_target("v1", 100)
