extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")


func run() -> void:
	run_case("monday_rollover_bills_every_vein_and_hq_guard_from_cash", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 100000
		TimeSystem.daily_tick()
		var guard_records: Array = GameState.state["bankLog"].filter(func(e): return e["label"] == "Guard wages")
		assert_eq(guard_records.size(), 1, "one Guard wages record")
		assert_eq(guard_records[0]["amount"], -500 * 4, "2 guards on v1, 1 on v2, 1 at HQ")
		var history: Array = GameState.state["guardUpkeep"]["history"]
		assert_eq(history[-1], { "day": monday, "places": { "v1": 1000, "v2": 500, "home": 500 } })
		assert_true(Fixtures.has_notification("Guard wages: -£2000 for 4 guards this week."), "paid notification")
		var account: Dictionary = MorningAccounts.latest()
		assert_eq(account["guardWages"], { "amount": 2000, "guards": 4 })
		assert_eq(MorningAccounts.guard_wages_label(account["guardWages"]), "Guard wages, 4 guards −£2000")
		assert_true(MorningAccounts.has_operations(account))
	)

	run_case("monday_bill_takes_cash_and_records_a_guard_expense", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 2500
		var result := GuardUpkeep.pay_monday_bill()
		assert_eq(result["paid"], 2000)
		assert_eq(GameState.state["player"]["cash"], 500)
		assert_eq(GameState.state["businessStats"]["today"]["expensesGuard"], 2000)
		assert_eq(GameState.state["businessStats"]["today"]["expenses"], 2000)
	)

	run_case("non_monday_rollovers_bill_nothing", func():
		var monday := _seed_guards()
		GameState.state["player"]["cash"] = 100000
		for offset in range(1, 7):
			GameState.state["world"]["day"] = monday + offset
			TimeSystem.daily_tick()
		assert_eq(GameState.state["bankLog"].filter(func(e): return e["label"] == "Guard wages").size(), 0)
		assert_eq(GameState.state["guardUpkeep"]["history"], [])
		assert_eq(MorningAccounts.latest()["guardWages"], null)
	)

	run_case("an_old_save_loaded_midweek_is_first_billed_next_monday", func():
		var monday := _seed_guards()
		GameState.state["player"]["cash"] = 100000
		for offset in range(2, 7):
			GameState.state["world"]["day"] = monday + offset
			assert_eq(GuardUpkeep.pay_monday_bill()["paid"], 0, "day %d isn't billed" % offset)
		assert_eq(GameState.state["player"]["cash"], 100000)
		GameState.state["world"]["day"] = monday + 7
		assert_eq(GuardUpkeep.pay_monday_bill()["paid"], 2000, "the next Monday bills")
	)

	run_case("guards_on_a_lost_vein_and_hq_guards_lost_to_a_tier_move_are_not_billed", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 100000
		GameState.state["player"]["veins"] = GameState.state["player"]["veins"].filter(func(v): return v["id"] != "v1")
		Home.change_tier("safehouse", "rented")
		assert_eq(GameState.state["player"]["cash"], 100000, "no refund for the lost guards")
		var result := GuardUpkeep.pay_monday_bill()
		assert_eq(result["guards"], 1, "only v2's tier guard is left")
		assert_eq(GameState.state["player"]["cash"], 100000 - 500)
		assert_eq(GameState.state["guardUpkeep"]["history"][-1]["places"], { "v2": 500 })
	)

	run_case("short_cash_takes_nothing_and_starts_a_shortfall", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 1999
		var before: Dictionary = GameState.deep_copy(GameState.state)
		var result := GuardUpkeep.pay_monday_bill()
		assert_true(result["short"], "short result")
		assert_eq(result["due"], 2000)
		assert_eq(result["paid"], 0)
		assert_eq(GameState.state["player"]["cash"], 1999, "cash untouched")
		assert_eq(GameState.state["bankLog"], before["bankLog"])
		assert_eq(GameState.state["guardUpkeep"]["history"], [])
		assert_eq(GuardUpkeep.player_guards_by_place(), { "v1": 2, "v2": 1, "home": 1 }, "guards untouched")
		assert_eq(GuardUpkeep.pending_shortfall()["reserve"], 0, "the short-pay flow starts")
	)

	run_case("pot_active_monday_is_left_to_the_payday", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 100000
		GameState.state["business"]["potActive"] = true
		assert_eq(GuardUpkeep.pay_monday_bill()["billed"], false)
		assert_eq(GameState.state["player"]["cash"], 100000)
	)

	run_case("payday_pays_staff_then_guards_then_splits_the_rest", func():
		_seed_pot_monday(2336, 0)
		TimeSystem.daily_tick()
		var business: Dictionary = GameState.state["business"]
		var record: Dictionary = business["ledger"][-1]
		assert_eq(record["expenses"], [
			{ "kind": "wage", "contactId": "owen", "amount": 36 },
			{ "kind": "guard", "placeId": "v1", "amount": 1000 },
			{ "kind": "guard", "placeId": "v2", "amount": 500 },
			{ "kind": "guard", "placeId": "home", "amount": 500 },
		])
		# R = 2336 − 36 − 2000 = 300 → 100 each.
		assert_eq(record["shares"], { "player": 100, "archie": 100, "james": 100 })
		assert_eq(GameState.state["player"]["cash"], 100, "cash only gains the player's share")
		assert_eq(GameState.state["bankLog"].filter(func(e): return e["label"] == "Guard wages").size(), 0)
		assert_eq(GameState.state["guardUpkeep"]["history"][-1]["places"], { "v1": 1000, "v2": 500, "home": 500 })
		assert_eq(GameState.state["businessStats"]["days"][-1]["expensesGuard"], 2000)
		assert_eq(GameState.state["businessStats"]["days"][-1]["expensesStaff"], 36)
		assert_true(Fixtures.has_notification("Guard wages: £2000 from the business for 4 guards this week."), "paid notification")
		var lines := MorningAccounts.payday_lines(MorningAccounts.latest()["payday"])
		assert_true(lines.has("Guards, HQ −£500"), "payday statement lists HQ guards")
		assert_eq(lines.filter(func(l): return l.begins_with("Guards, ")).size(), 3)
	)

	run_case("float_covers_the_guard_bill_the_pot_cant_and_is_never_split", func():
		_seed_pot_monday(1036, 1500)
		TimeSystem.daily_tick()
		var business: Dictionary = GameState.state["business"]
		assert_eq(business["pot"], 0)
		assert_eq(business["float"], 500)
		assert_eq(business["ledger"][-1]["shares"], { "player": 0, "archie": 0, "james": 0 })
		assert_eq(GameState.state["player"]["cash"], 0)
	)

	run_case("short_pot_and_float_pay_staff_then_set_the_rest_aside_as_reserve", func():
		_seed_pot_monday(1500, 100)
		var result := Business.daily_tick()
		var business: Dictionary = GameState.state["business"]
		assert_eq(Business.owed("owen"), 0, "staff are paid before guards")
		var guards: Dictionary = result["guards"]
		assert_true(guards["short"], "short result")
		assert_eq(guards["due"], 2000)
		assert_eq(guards["paid"], 0)
		assert_eq(guards["reserve"], 1564, "1500 + 100 − 36 staff")
		assert_eq(business["pot"], 0)
		assert_eq(business["float"], 0)
		assert_eq(business["ledger"][-1]["shares"], { "player": 0, "archie": 0, "james": 0 })
		assert_eq(business["ledger"][-1]["expenses"], [{ "kind": "wage", "contactId": "owen", "amount": 36 }])
		assert_eq(GameState.state["player"]["cash"], 0)
		assert_eq(GameState.state["guardUpkeep"]["history"], [])
	)

	run_case("short_pre_pot_monday_starts_a_shortfall_with_one_grace_day", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 0
		TimeSystem.daily_tick()
		assert_eq(GuardUpkeep.pending_shortfall(), { "day": monday, "deadline": monday + 1, "places": { "v1": 2, "v2": 1, "home": 1 }, "reserve": 0 })
		assert_eq(GameState.state["bankLog"].filter(func(e): return e["label"] == "Guard wages").size(), 0, "nothing taken yet")
		var v1 := GuardUpkeep.place_label("v1")
		var warning := "Guard wages short: £2000 due. Unpaid guards walk on %s — %s, %s, HQ." % [Calendar.format_day(monday + 1), v1, GuardUpkeep.place_label("v2")]
		assert_true(Fixtures.has_notification(warning), "shortfall notification")
		var exception: Dictionary = MorningAccounts.latest()["exceptions"].filter(func(e): return e["kind"] == "guardShortfall")[0]
		assert_eq(exception, { "kind": "guardShortfall", "due": 2000, "reserve": 0, "deadline": monday + 1, "places": ["v1", "v2", "home"] })
		assert_true(MorningAccounts.guard_shortfall_label(exception).begins_with("Exception: guard wages short, £2000 due. Unpaid guards walk on "))
	)

	run_case("short_pot_era_monday_starts_a_shortfall_holding_the_reserve", func():
		_seed_pot_monday(1500, 100)
		var monday: int = GameState.state["world"]["day"]
		TimeSystem.daily_tick()
		assert_eq(GuardUpkeep.pending_shortfall(), { "day": monday, "deadline": monday + 1, "places": { "v1": 2, "v2": 1, "home": 1 }, "reserve": 1564 })
		assert_eq(MorningAccounts.latest()["exceptions"].filter(func(e): return e["kind"] == "guardShortfall")[0]["reserve"], 1564)
	)

	run_case("guards_stay_on_duty_and_defend_during_grace", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 0
		var v1: Dictionary = Cultivating.find_vein("v1")
		var resist := Cultivating.vein_raid_resist(v1)
		var repel := Home.guard_repel_chance(Home.get_guard_count())
		GuardUpkeep.pay_monday_bill()
		assert_true(GuardUpkeep.pending_shortfall() != null)
		assert_eq(GuardUpkeep.resolve_due_shortfall(), {}, "not due before the grace rollover")
		assert_eq(Cultivating.vein_raid_resist(v1), resist, "raid resist unchanged")
		assert_eq(Home.guard_repel_chance(Home.get_guard_count()), repel, "HQ repel unchanged")
		assert_eq(GuardUpkeep.player_guards_by_place(), { "v1": 2, "v2": 1, "home": 1 })
	)

	run_case("ignored_pot_era_shortfall_keeps_what_the_reserve_funds_and_floats_the_rest", func():
		_seed_pot_monday(1500, 100)
		var monday: int = GameState.state["world"]["day"]
		TimeSystem.daily_tick()
		GameState.state["world"]["day"] = monday + 1
		var result := GuardUpkeep.resolve_due_shortfall()
		assert_eq(result, { "paid": 1500, "kept": 3, "walked": { "v1": 1 } })
		var v1: Dictionary = Cultivating.find_vein("v1")
		assert_eq([v1["security"], v1["extraGuards"]], ["guarded", 0], "the extra walks first")
		assert_eq(GameState.state["business"]["float"], 64, "1564 − 1500 back to the float")
		assert_eq(GameState.state["player"]["cash"], 0, "cash never funds a pot-era shortfall")
		assert_eq(GameState.state["guardUpkeep"]["history"][-1], { "day": monday + 1, "places": { "v1": 500, "v2": 500, "home": 500 } })
		assert_eq(GuardUpkeep.pending_shortfall(), null)
		assert_true(Fixtures.has_notification("Unpaid guards walked off: %s (1)." % GuardUpkeep.place_label("v1")))
	)

	run_case("grace_rollover_resolves_early_and_notes_walk_offs_in_the_morning_account", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 0
		TimeSystem.daily_tick()
		GameState.state["player"]["cash"] = 1000
		GameState.state["world"]["day"] = monday + 1
		TimeSystem.daily_tick()
		assert_eq(GuardUpkeep.pending_shortfall(), null)
		assert_eq(GameState.state["player"]["cash"], 0, "two guards kept from cash")
		assert_eq(GameState.state["bankLog"].filter(func(e): return e["label"] == "Guard wages")[-1]["amount"], -1000)
		var account: Dictionary = MorningAccounts.latest()
		assert_eq(account["guardWages"], { "amount": 1000, "guards": 2 })
		var walked: Array = account["exceptions"].filter(func(e): return e["kind"] == "guardsWalked")
		assert_eq(walked.size(), 1)
		assert_eq(MorningAccounts.guard_shortfall_label(walked[0]), "Exception: unpaid guards walked off: %s." % GuardUpkeep.walked_text(walked[0]["walked"]))
	)

	run_case("drop_order_is_extras_least_valuable_first_then_tier_guards_then_hq", func():
		for case in [[1500, ["guarded", 0], ["guarded", 0], 1], [500, ["warded", 0], ["warded", 0], 1], [1000, ["warded", 0], ["guarded", 0], 1], [0, ["warded", 0], ["warded", 0], 0], [2000, ["guarded", 0], ["guarded", 1], 1]]:
			var monday := _seed_guards()
			var v1: Dictionary = Cultivating.find_vein("v1")
			var v2: Dictionary = Cultivating.find_vein("v2")
			v2["extraGuards"] = 1
			v2["level"] = 3
			GameState.state["world"]["day"] = monday
			GameState.state["player"]["cash"] = 0
			GuardUpkeep.pay_monday_bill()
			GameState.state["player"]["cash"] = case[0]
			GameState.state["world"]["day"] = monday + 1
			GuardUpkeep.resolve_due_shortfall()
			assert_eq([v1["security"], v1["extraGuards"]], case[1], "v1 with £%d" % case[0])
			assert_eq([v2["security"], v2["extraGuards"]], case[2], "v2 with £%d" % case[0])
			assert_eq(Home.get_guard_count(), case[3], "HQ with £%d" % case[0])
			assert_eq(Cultivating.find_vein("v3")["security"], "warded", "a ward rune is never lost")
			assert_eq(GameState.state["player"]["cash"], case[0] % 500, "kept guards paid from cash")
	)

	run_case("only_one_shortfall_is_ever_pending", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 0
		GuardUpkeep.pay_monday_bill()
		GameState.state["world"]["day"] = monday + 7
		GameState.state["player"]["cash"] = 500
		GuardUpkeep.start_shortfall({ "home": 1 }, 0, 500)
		assert_eq(GuardUpkeep.pending_shortfall()["places"], { "home": 1 }, "the older shortfall resolved first")
		assert_eq(Cultivating.find_vein("v1")["security"], "warded", "and its guards walked")
		assert_eq(Home.get_guard_count(), 1, "the new shortfall's guards are still on duty")
	)

	run_case("a_vein_lost_during_grace_isnt_paid_for", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 0
		GuardUpkeep.pay_monday_bill()
		GameState.state["player"]["veins"] = GameState.state["player"]["veins"].filter(func(v): return v["id"] != "v1")
		GameState.state["player"]["cash"] = 5000
		GameState.state["world"]["day"] = monday + 1
		assert_eq(GuardUpkeep.resolve_due_shortfall(), { "paid": 1000, "kept": 2, "walked": {} })
		assert_eq(GameState.state["player"]["cash"], 4000)
	)

	run_case("short_pay_confirm_pays_kept_guards_from_cash_and_walks_the_rest", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 1200
		GuardUpkeep.pay_monday_bill()
		assert_eq(GuardUpkeep.short_pay_quote({ "v1": 1, "v2": 0, "home": 1 }), { "cost": 1000, "reserve": 0, "cashNeeded": 1000 })
		var result := GuardUpkeep.confirm_shortfall({ "v1": 1, "v2": 0, "home": 1 })
		assert_eq(result, { "ok": true, "paid": 1000, "walked": { "v1": 1, "v2": 1 } })
		var v1: Dictionary = Cultivating.find_vein("v1")
		assert_eq([v1["security"], v1["extraGuards"]], ["guarded", 0], "the extra walks, the tier guard stays")
		assert_eq(Cultivating.find_vein("v2")["security"], "warded", "keeping 0 loses the tier")
		assert_eq(Home.get_guard_count(), 1)
		assert_eq(GameState.state["player"]["cash"], 200)
		assert_eq(GameState.state["bankLog"][-1]["label"], "Guard wages")
		assert_eq(GameState.state["bankLog"][-1]["amount"], -1000)
		assert_eq(GameState.state["guardUpkeep"]["history"][-1], { "day": monday, "places": { "v1": 500, "home": 500 } })
		assert_eq(GuardUpkeep.pending_shortfall(), null)
		assert_eq(MorningAccounts.attention_items().filter(func(i): return i["kind"] == "guardShortfall"), [], "the attention row clears")
	)

	run_case("short_pay_confirm_draws_the_reserve_before_cash_and_floats_leftover", func():
		_seed_pot_monday(1500, 100)
		TimeSystem.daily_tick()
		GameState.state["player"]["cash"] = 500
		var float_before: int = GameState.state["business"]["float"]
		var result := GuardUpkeep.confirm_shortfall({ "v1": 2, "v2": 1, "home": 1 })
		assert_eq(result, { "ok": true, "paid": 2000, "walked": {} })
		assert_eq(GameState.state["player"]["cash"], 500 - (2000 - 1564), "cash covers what the reserve can't")
		assert_eq(GameState.state["business"]["float"], float_before)
		_seed_pot_monday(1500, 100)
		TimeSystem.daily_tick()
		GameState.state["player"]["cash"] = 0
		float_before = GameState.state["business"]["float"]
		GuardUpkeep.confirm_shortfall({ "v1": 1, "v2": 1, "home": 1 })
		assert_eq(GameState.state["player"]["cash"], 0, "no cash needed")
		assert_eq(GameState.state["business"]["float"], float_before + 64, "1564 − 1500 leftover to the float")
		assert_eq(GuardUpkeep.pending_shortfall(), null)
	)

	run_case("short_pay_confirm_is_refused_when_cash_cant_cover_it", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 900
		GuardUpkeep.pay_monday_bill()
		var before: Dictionary = GameState.state.duplicate(true)
		assert_eq(GuardUpkeep.confirm_shortfall({ "v1": 2 }), { "ok": false, "reason": "Not enough cash." })
		assert_eq(GameState.state, before, "nothing changed")
	)

	run_case("attention_row_notification_and_board_tap_open_the_short_pay_menu", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 0
		GuardUpkeep.pay_monday_bill()
		var items := MorningAccounts.attention_items().filter(func(i): return i["kind"] == "guardShortfall")
		assert_eq(items.size(), 1, "a Brief attention row")
		MorningAccounts.open_attention(items[0])
		assert_eq([GameState.state["currentScreen"], GameState.state["phoneNav"]["app"], GameState.state["phoneNav"]["bizbriefView"]], ["phone", "bizbrief", "shortPay"])
		PhoneNav.go_home()
		var warning: Dictionary = GameState.state["notifications"][-1]
		assert_true(GuardUpkeep.is_pending_shortfall_notification(warning), "the warning links to the menu")
		assert_true(TopBar.open_notifications_log())
		assert_eq([GameState.state["phoneNav"]["app"], GameState.state["phoneNav"]["bizbriefView"]], ["bizbrief", "shortPay"], "the board tap deep-links")
		GuardUpkeep.confirm_shortfall({})
		assert_true(not GuardUpkeep.is_pending_shortfall_notification(warning), "not once it's resolved")
	)

	run_case("cost_series_per_place_come_from_history_bounded_to_the_window", func():
		var monday := _seed_guards()
		var days := int(GameData.GUARD_UPKEEP["guardCostHistoryDays"])
		GameState.state["world"]["day"] = monday
		GuardUpkeep.record_payment("v1", 700)
		GameState.state["world"]["day"] = monday + days
		GuardUpkeep.record_payment("home", 300)
		GuardUpkeep.record_payment("v2", 200)
		var window := GuardUpkeep.history_window_days()
		assert_eq([window.size(), window[0], window[-1]], [days, monday + 1, monday + days], "the last guardCostHistoryDays days through today")
		assert_eq(GuardUpkeep.cost_series("v1").reduce(func(a, b): return a + b, 0), 0, "v1's payment fell out of the window")
		assert_eq(GuardUpkeep.cost_series("home")[-1], 300)
		assert_eq(GuardUpkeep.cost_series("v2").reduce(func(a, b): return a + b, 0), 200)
	)

	run_case("history_window_never_starts_before_day_one", func():
		GameState.reset()
		GameState.state["world"]["day"] = 3
		assert_eq(GuardUpkeep.history_window_days(), [1, 2, 3])
	)

	run_case("cost_places_are_hq_then_player_veins_then_lost_veins_with_history", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GuardUpkeep.record_payment("gone", 500)
		assert_eq(GuardUpkeep.cost_places(), ["home", "v1", "v2", "v3", "gone"])
		GameState.state["world"]["day"] = monday + int(GameData.GUARD_UPKEEP["guardCostHistoryDays"])
		assert_eq(GuardUpkeep.cost_places(), ["home", "v1", "v2", "v3"], "a lost vein drops out with its history")
	)

	run_case("next_monday_bill_is_every_current_guard_at_the_weekly_wage", func():
		_seed_guards()
		assert_eq(GuardUpkeep.next_monday_bill(), 500 * 4)
	)

	run_case("open_guard_costs_lands_on_the_bizbrief_sub_view_before_the_pot", func():
		_seed_guards()
		assert_true(not Business.is_pot_active())
		PhoneNav.open_guard_costs()
		assert_eq([GameState.state["currentScreen"], GameState.state["phoneNav"]["app"], GameState.state["phoneNav"]["bizbriefView"]], ["phone", "bizbrief", "guardCosts"])
		PhoneNav.close_bizbrief_view()
		assert_eq(GameState.state["phoneNav"]["bizbriefView"], null)
	)


# v1: tier guard + 1 extra, v2: tier guard, v3: ward rune only, HQ: 1 guard
# at the compound. Returns the first Monday.
func _seed_guards() -> int:
	GameState.reset()
	Rng.set_seed(1)
	var v1 := Fixtures.seed_vein("v1", 50)
	v1["security"] = "guarded"
	v1["extraGuards"] = 1
	var v2 := Fixtures.seed_vein("v2", 50)
	v2["security"] = "guarded"
	var v3 := Fixtures.seed_vein("v3", 50)
	v3["security"] = "warded"
	GameState.state["home"]["tier"] = "compound"
	GameState.state["home"]["guardCount"] = 1
	return Calendar.monday_on_or_after(8)


# _seed_guards() on its first Monday with the pot activated that day (Owen's
# first payday wage: one day, £36), `pot` in the pot, `float_amount` donated
# and player cash left at 0.
func _seed_pot_monday(pot: int, float_amount: int) -> void:
	GameState.state["world"]["day"] = _seed_guards()
	Business.activate()
	GameState.state["player"]["cash"] = float_amount
	if float_amount > 0:
		Business.donate(float_amount)
	Business.receive(pot)
