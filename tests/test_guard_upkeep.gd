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

	run_case("short_cash_takes_nothing_and_returns_short", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 1999
		var before: Dictionary = GameState.deep_copy(GameState.state)
		var result := GuardUpkeep.pay_monday_bill()
		assert_true(result["short"], "short result")
		assert_eq(result["due"], 2000)
		assert_eq(result["paid"], 0)
		assert_eq(GameState.state, before, "cash, guards and records untouched")
	)

	run_case("pot_active_monday_is_left_to_the_payday", func():
		var monday := _seed_guards()
		GameState.state["world"]["day"] = monday
		GameState.state["player"]["cash"] = 100000
		GameState.state["business"]["potActive"] = true
		assert_eq(GuardUpkeep.pay_monday_bill()["billed"], false)
		assert_eq(GameState.state["player"]["cash"], 100000)
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
