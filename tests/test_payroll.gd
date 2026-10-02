extends "res://tests/test_base.gd"

const PayrollSystem := preload("res://systems/payroll.gd")
const OffersSystem := preload("res://systems/offers.gd")
const ContractsSystem := preload("res://systems/contracts.gd")


# Marks contact_id as owed a business wage the pot couldn't cover.
static func _owe_wage(contact_id: String, owed: int) -> void:
	GameState.state["business"]["potActive"] = true
	GameState.state["business"]["wages"][contact_id] = {
		"weekly": 250, "owed": owed, "unpaid": true,
		"hiredDay": 1, "daysWorked": 0, "promptPending": true,
	}


func run() -> void:
	run_case("a_room_hire_works_unless_the_business_owes_them", func():
		GameState.reset()
		GameState.state["contacts"]["des"]["recruited"] = true
		Contacts.assign_to_room("des", "lab")
		assert_true(PayrollSystem.is_working("des"), "no wage owed, so Des works")
		_owe_wage("des", 100)
		assert_true(not PayrollSystem.is_working("des"))
	)

	run_case("no_rollover_debits_player_cash_for_room_wages", func():
		GameState.reset()
		GameState.state["contacts"]["des"]["recruited"] = true
		Contacts.assign_to_room("des", "ops")
		GameState.state["player"]["cash"] = 5000
		for i in 8:
			TimeSystem.daily_tick()
		for entry in GameState.state["bankLog"]:
			assert_true(not String(entry["label"]).begins_with("Wages"), "no cash wage line: %s" % entry["label"])
		assert_true(PayrollSystem.is_working("des"))
	)

	run_case("unpaid_lab_hire_crafts_nothing_but_resumes_once_paid", func():
		GameState.reset()
		GameState.state["contacts"]["des"]["recruited"] = true
		Contacts.assign_to_room("des", "lab")
		GameState.state["contacts"]["des"]["specialities"] = ["time"]
		GameState.state["labThresholds"]["timePearl"] = 5
		GameState.state["player"]["orichalchum"]["time"] = 1000
		_owe_wage("des", 100)
		for i in TimeSystem.BLOCKS_PER_DAY:
			Rooms.process_staff_block()
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "an unpaid producer should do no crafting")

		GameState.state["player"]["cash"] = 1000
		assert_true(Business.top_up_and_pay_owed("des")["ok"])
		for i in 100:
			Rooms.process_staff_block()
		assert_eq(Crafting.inventory_qty("timePearl"), 5, "once paid, the same producer resumes working")
	)

	run_case("unpaid_sales_hire_blocks_delivery_and_offer_sourcing", func():
		GameState.reset()
		GameState.state["contacts"]["hakim"]["recruited"] = true
		Contacts.assign_to_room("hakim", "ops")
		_owe_wage("hakim", 100)

		var created: Dictionary = OffersSystem.create_scripted_offer("scripted_life_order")
		var contract: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])["contract"]
		GameState.state["player"]["orichalchum"]["life"] = 5
		ContractsSystem.process_sales_deliveries()
		assert_eq(ContractsSystem.delivered_qty(contract), 0, "an unpaid Sales hire should not deliver, even though stock now fully covers it")

		var pending_before: int = OffersSystem.pending_offers().size()
		OffersSystem.daily_tick()
		assert_eq(OffersSystem.pending_offers().size(), pending_before, "an unpaid Sales hire should source no offer, regardless of the random roll")
	)

	run_case("has_staffed_sales_counts_a_founder_sales_role_with_no_room", func():
		GameState.reset()
		assert_true(not ContractsSystem.has_staffed_sales())
		Contacts.force_recruit("archie")
		GameState.state["flags"]["bizArchieSalesRole"] = true
		Contacts.set_role("archie", "sales")
		GameState.state["player"]["cash"] = 0
		assert_true(ContractsSystem.has_staffed_sales(), "Archie's Sales role staffs Sales wage-free")
		GameState.state["contacts"]["archie"]["salesSkill"] = 3
		assert_eq(OffersSystem.sales_skill(), 3, "a founder Sales role drives sourcing skill")
	)
