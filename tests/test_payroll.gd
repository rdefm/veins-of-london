extends "res://tests/test_base.gd"

const PayrollSystem := preload("res://systems/payroll.gd")
const OffersSystem := preload("res://systems/offers.gd")
const ContractsSystem := preload("res://systems/contracts.gd")


func run() -> void:
	run_case("wage_for_room_is_100_plus_50_per_skill_level_above_1_for_every_role", func():
		GameState.reset()
		GameState.state["contacts"]["des"]["recruited"] = true
		Contacts.assign_to_room("des", "lab")
		GameState.state["contacts"]["des"]["craftingSkill"] = 3
		assert_eq(PayrollSystem.wage_for_room("lab"), 200, "£100 + £50 * (3-1) = £200")

		GameState.state["contacts"]["nadia"]["recruited"] = true
		Contacts.assign_to_room("nadia", "veinStation")
		GameState.state["contacts"]["nadia"]["cultivatingSkill"] = 1
		assert_eq(PayrollSystem.wage_for_room("veinStation"), 100, "skill 1 -> base wage only")

		GameState.state["contacts"]["hakim"]["recruited"] = true
		Contacts.assign_to_room("hakim", "ops")
		GameState.state["contacts"]["hakim"]["salesSkill"] = 5
		assert_eq(PayrollSystem.wage_for_room("ops"), 300, "£100 + £50 * (5-1) = £300")
	)

	run_case("wage_for_room_is_zero_when_unassigned", func():
		GameState.reset()
		assert_eq(PayrollSystem.wage_for_room("lab"), 0)
		assert_eq(PayrollSystem.wage_for_room("veinStation"), 0)
		assert_eq(PayrollSystem.wage_for_room("ops"), 0)
	)

	run_case("daily_tick_pays_wages_after_living_costs", func():
		GameState.reset()
		GameState.state["contacts"]["des"]["recruited"] = true
		Contacts.assign_to_room("des", "ops")
		GameState.state["player"]["cash"] = 1000
		TimeSystem.daily_tick()
		# Day 1, stable barometer: living cost 50, then the ops wage (skill 1 -> £100).
		assert_eq(GameState.state["player"]["cash"], 1000 - 50 - 100, "living costs then wage should both be deducted")
		var log: Array = GameState.state["bankLog"]
		assert_eq(log[0]["label"], "Living costs", "living costs should be recorded first")
		assert_eq(log[1]["label"], "Wages: Des", "the wage should be recorded right after living costs")
		assert_eq(log[1]["amount"], -100)
	)

	run_case("wages_come_from_cash_left_after_arrears_and_bill", func():
		GameState.reset()
		GameState.state["contacts"]["des"]["recruited"] = true
		Contacts.assign_to_room("des", "ops")
		GameState.state["home"]["arrears"] = 400
		GameState.state["home"]["arrearsDays"] = 5
		GameState.state["player"]["cash"] = 600
		TimeSystem.daily_tick()
		# ADR 0006 recovery: interest 20, pays 420 arrears + 50 bill -> 130, then the ops wage 100.
		assert_eq(GameState.state["home"]["arrears"], 0)
		assert_eq(GameState.state["player"]["cash"], 30)
		var log: Array = GameState.state["bankLog"]
		assert_eq(log[0]["label"], "Arrears")
		assert_eq(log[0]["amount"], -420)
		assert_eq(log[1]["label"], "Living costs")
		assert_eq(log[2]["label"], "Wages: Des")
	)

	run_case("insufficient_cash_pays_affordable_roles_in_priority_order_and_skips_the_rest", func():
		GameState.reset()
		GameState.state["contacts"]["des"]["recruited"] = true
		Contacts.assign_to_room("des", "lab")
		GameState.state["contacts"]["nadia"]["recruited"] = true
		Contacts.assign_to_room("nadia", "veinStation")
		GameState.state["contacts"]["hakim"]["recruited"] = true
		Contacts.assign_to_room("hakim", "ops")
		# Living cost 50 + lab 100 + veinStation 100 = 250, exactly covered;
		# nothing left over for the ops wage (100).
		GameState.state["player"]["cash"] = 250
		TimeSystem.daily_tick()

		assert_eq(GameState.state["player"]["cash"], 0, "the two affordable wages should be paid, ops skipped -- no partial charge")
		var paid_today: Dictionary = GameState.state["payroll"]["paidToday"]
		assert_true(paid_today["lab"], "lab (first in priority order) should be paid")
		assert_true(paid_today["veinStation"], "veinStation (second in priority order) should be paid")
		assert_true(not paid_today["ops"], "ops (last in priority order, unaffordable) should be skipped")

		var summary: Dictionary = GameState.state["payroll"]["lastSummary"]
		assert_eq(summary["day"], 1)
		var ops_entry: Dictionary = summary["entries"][2]
		assert_eq(ops_entry["room"], "ops")
		assert_eq(ops_entry["contactId"], "hakim")
		assert_eq(ops_entry["wage"], 100)
		assert_true(not ops_entry["paid"])

		assert_eq(GameState.state["contacts"]["hakim"]["assignedRoom"], "ops", "an unpaid role stays assigned, no debt or eviction")
		assert_true(not ContractsSystem.has_staffed_sales(), "unpaid ops should not count as staffed for the rest of the day")
	)

	run_case("an_unpaid_role_is_retried_fresh_next_rollover_with_no_debt", func():
		GameState.reset()
		GameState.state["contacts"]["hakim"]["recruited"] = true
		Contacts.assign_to_room("hakim", "ops")
		GameState.state["player"]["cash"] = 50  # exactly living costs, nothing for the £100 wage
		TimeSystem.daily_tick()
		assert_eq(GameState.state["player"]["cash"], 0)
		assert_true(not GameState.state["payroll"]["paidToday"]["ops"], "unpaid on day 1")

		GameState.state["player"]["cash"] = 1000
		TimeSystem.daily_tick()
		# Day 2 living cost 50, then the ops wage 100 -- no carried-over debt from day 1.
		assert_eq(GameState.state["player"]["cash"], 1000 - 50 - 100, "the wage should be retried fresh, not doubled up as a debt")
		assert_true(GameState.state["payroll"]["paidToday"]["ops"], "paid on the retry")
	)

	run_case("unpaid_lab_role_crafts_nothing_that_day_but_resumes_once_paid", func():
		GameState.reset()
		GameState.state["contacts"]["des"]["recruited"] = true
		Contacts.assign_to_room("des", "lab")
		GameState.state["flags"]["craftingUnlocked"] = true
		GameState.state["labThresholds"]["timePearl"] = 5
		GameState.state["player"]["orichalchum"]["time"] = 1000

		GameState.state["player"]["cash"] = 0
		PayrollSystem.pay_wages()
		assert_true(not PayrollSystem.is_paid_today("lab"))
		for i in TimeSystem.BLOCKS_PER_DAY:
			Rooms.process_staff_block()
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "an unpaid Production role should do no crafting")

		GameState.state["player"]["cash"] = 1000
		PayrollSystem.pay_wages()
		assert_true(PayrollSystem.is_paid_today("lab"))
		for i in 100:
			Rooms.process_staff_block()
		assert_eq(Crafting.inventory_qty("timePearl"), 5, "once paid, the same role resumes working normally")
	)

	run_case("pay_now_clears_an_unpaid_role_using_cash_that_arrives_later_the_same_day", func():
		GameState.reset()
		GameState.state["contacts"]["des"]["recruited"] = true
		Contacts.assign_to_room("des", "lab")
		GameState.state["player"]["cash"] = 0
		PayrollSystem.pay_wages()
		assert_true(not PayrollSystem.is_paid_today("lab"))

		var too_poor: Dictionary = PayrollSystem.pay_now("lab")
		assert_true(not too_poor["ok"], "should refuse without enough cash")

		GameState.state["player"]["cash"] = 500
		var result: Dictionary = PayrollSystem.pay_now("lab")
		assert_true(result["ok"])
		assert_eq(result["wage"], 100)
		assert_eq(GameState.state["player"]["cash"], 400)
		assert_true(PayrollSystem.is_paid_today("lab"), "the role should count as staffed for the rest of today")

		var summary_entry: Dictionary = GameState.state["payroll"]["lastSummary"]["entries"][0]
		assert_eq(summary_entry["room"], "lab")
		assert_true(summary_entry["paid"], "the reviewable summary should reflect the override")

		var again: Dictionary = PayrollSystem.pay_now("lab")
		assert_true(not again["ok"], "should refuse a role already paid today")
	)

	run_case("pay_now_refuses_an_unassigned_room", func():
		GameState.reset()
		var result: Dictionary = PayrollSystem.pay_now("lab")
		assert_true(not result["ok"])
	)

	run_case("unpaid_sales_role_blocks_realtime_delegated_delivery_and_offer_sourcing", func():
		GameState.reset()
		GameState.state["contacts"]["hakim"]["recruited"] = true
		Contacts.assign_to_room("hakim", "ops")
		GameState.state["player"]["cash"] = 0
		PayrollSystem.pay_wages()
		assert_true(not PayrollSystem.is_paid_today("ops"))

		GameState.state["flags"][ContractsSystem.DELEGATION_FLAG] = true
		var created: Dictionary = OffersSystem.create_scripted_offer("scripted_life_order")
		var contract: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])["contract"]
		ContractsSystem.set_delegated(contract["id"], true)
		GameState.state["player"]["orichalchum"]["life"] = 5
		EventBus.shared_stock_increased.emit()
		assert_eq(ContractsSystem.delivered_qty(contract), 0, "an unpaid Sales role should not deliver, even though stock now fully covers it")

		var pending_before: int = OffersSystem.pending_offers().size()
		OffersSystem.daily_tick()
		assert_eq(OffersSystem.pending_offers().size(), pending_before, "an unpaid Sales role should source no offer, regardless of the random roll")
	)

	run_case("founders_never_draw_a_daily_wage", func():
		GameState.reset()
		GameState.state["contacts"]["james"]["recruited"] = true
		Contacts.assign_to_room("james", "lab")
		GameState.state["contacts"]["des"]["recruited"] = true
		Contacts.assign_to_room("des", "veinStation")
		GameState.state["player"]["cash"] = 1000
		PayrollSystem.pay_wages()
		assert_eq(GameState.state["player"]["cash"], 900, "only the room hire's £100 is charged")
		assert_eq(PayrollSystem.wage_for_room("lab"), 0)
		assert_true(PayrollSystem.is_paid_today("lab"), "a founder is never unpaid")
	)

	run_case("has_staffed_sales_counts_a_founder_sales_role_with_no_room", func():
		GameState.reset()
		assert_true(not ContractsSystem.has_staffed_sales())
		Contacts.force_recruit("archie")
		GameState.state["flags"]["bizArchieSalesRole"] = true
		Contacts.set_role("archie", "sales")
		GameState.state["player"]["cash"] = 0
		PayrollSystem.pay_wages()
		assert_true(ContractsSystem.has_staffed_sales(), "Archie's Sales role staffs Sales wage-free")
		GameState.state["contacts"]["archie"]["salesSkill"] = 3
		assert_eq(OffersSystem.sales_skill(), 3, "a founder Sales role drives sourcing skill")
	)
