extends "res://tests/test_base.gd"

const OffersSystem := preload("res://systems/offers.gd")
const ContractsSystem := preload("res://systems/contracts.gd")


func run() -> void:
	run_case("manual_partial_delivery_spends_one_block_and_shared_stock_only", func():
		GameState.reset()
		var contract := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 4
		var result: Dictionary = ContractsSystem.deliver(contract["id"], 2)
		assert_true(result["ok"])
		assert_eq(result["delivered"], 2)
		assert_eq(ContractsSystem.delivered_qty(contract), 2)
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 2)
		assert_eq(GameState.state["world"]["timeBlock"], 1, "one action costs one block regardless of quantity")
		contract["delegated"] = true
		assert_true(not ContractsSystem.deliver(contract["id"], 1)["ok"], "manual path rejects delegated contracts")
	)

	run_case("priority_order_is_pure_state_and_reorders_active_contracts", func():
		GameState.reset()
		var first := _accept_life_contract()
		var second := _accept_life_contract()
		assert_eq(GameState.state["sales"]["priorityOrder"], [first["id"], second["id"]])
		assert_true(ContractsSystem.reorder(second["id"], 0))
		assert_eq(GameState.state["sales"]["priorityOrder"], [second["id"], first["id"]])
		assert_eq(ContractsSystem.active_contracts()[0]["id"], second["id"])
	)

	run_case("staffed_sales_closes_a_fully_stocked_delegated_period_immediately", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "ops")
		var contract := _accept_life_contract()
		assert_true(ContractsSystem.set_delegated(contract["id"], true)["ok"])
		GameState.state["player"]["orichalchum"]["life"] = 5
		EventBus.shared_stock_increased.emit()
		assert_eq(ContractsSystem.active_contracts().size(), 0)
		assert_eq(GameState.state["sales"]["settlements"].size(), 1)
		assert_eq(GameState.state["contacts"]["archie"]["salesXP"], ContractsSystem.COMPLETE_XP)
	)

	run_case("daily_sales_allocates_partial_stock_in_priority_order", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "ops")
		var first := _accept_life_contract()
		var second := _accept_life_contract()
		ContractsSystem.set_delegated(first["id"], true)
		ContractsSystem.set_delegated(second["id"], true)
		GameState.state["player"]["orichalchum"]["life"] = 7
		ContractsSystem.process_delegated_deliveries()
		assert_eq(ContractsSystem.delivered_qty(first), 5)
		assert_eq(ContractsSystem.delivered_qty(second), 2)
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 0)
	)

	# ticket 30: Production contract-coverage toggle -- the personal-target
	# portion of a covered item's shared stock is a protected buffer.
	run_case("delivery_cannot_draw_below_the_covered_personal_target_reserve", func():
		GameState.reset()
		GameState.state["labThresholds"]["timePearl"] = 5
		Rooms.set_lab_cover_contracts("timePearl", true)
		Crafting.inventory_add("timePearl", 1, 8)
		var created: Dictionary = OffersSystem.create_offer({ "id": "t_reserve", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "timePearl", "qty": 10 } })
		var contract: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])["contract"]
		var result: Dictionary = ContractsSystem.deliver(contract["id"], 10)
		assert_true(result["ok"])
		assert_eq(result["delivered"], 3, "only the unreserved portion (8 in stock minus the 5 reserve) should be deliverable")
		assert_eq(Crafting.inventory_qty("timePearl"), 5, "the personal-target reserve should remain untouched")
	)

	run_case("shared_stock_is_undivided_when_the_item_is_not_covering_contracts", func():
		GameState.reset()
		GameState.state["labThresholds"]["timePearl"] = 5
		Crafting.inventory_add("timePearl", 1, 8)
		var created: Dictionary = OffersSystem.create_offer({ "id": "t_open", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "timePearl", "qty": 10 } })
		var contract: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])["contract"]
		var result: Dictionary = ContractsSystem.deliver(contract["id"], 10)
		assert_eq(result["delivered"], 8, "toggle off -- no reserve, full shared stock available as before ticket 30")
	)

	run_case("due_oneoff_records_receipt_before_payment_and_cannot_repeat", func():
		GameState.reset()
		var contract := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 5
		ContractsSystem.deliver(contract["id"], 5, false)
		GameState.state["world"]["day"] = contract["dueDay"]
		var cash_before: int = GameState.state["player"]["cash"]
		var settled: Dictionary = ContractsSystem.settle(contract["id"])
		assert_true(settled["ok"])
		assert_eq(settled["settlement"]["payment"], contract["quote"]["payment"])
		assert_eq(GameState.state["player"]["cash"], cash_before + contract["quote"]["payment"])
		assert_eq(GameState.state["sales"]["settlements"].size(), 1)
		assert_eq(ContractsSystem.active_contracts().size(), 0)
		assert_true(not ContractsSystem.settle(contract["id"])["ok"], "removed period cannot pay again")
	)

	run_case("partial_recurring_settlement_penalises_then_renews_with_new_period_id", func():
		GameState.reset()
		var created: Dictionary = OffersSystem.create_scripted_offer("scripted_physics_weekly")
		var accepted: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])
		var contract: Dictionary = accepted["contract"]
		var old_period: String = contract["periodId"]
		GameState.state["player"]["orichalchum"]["physics"] = 1
		ContractsSystem.deliver(contract["id"], 1, false)
		GameState.state["world"]["day"] = contract["dueDay"]
		var settled: Dictionary = ContractsSystem.settle(contract["id"])
		assert_true(settled["ok"])
		assert_eq(settled["settlement"]["payment"], GameState.round_epsilon(float(contract["quote"]["payment"]) / 3.0 * 0.80))
		assert_true(contract["periodId"] != old_period)
		assert_eq(contract["dueDay"], 15)
		assert_eq(ContractsSystem.delivered_qty(contract), 0)
	)


func _accept_life_contract() -> Dictionary:
	var created: Dictionary = OffersSystem.create_scripted_offer("scripted_life_order")
	return OffersSystem.accept_offer(created["offer"]["id"])["contract"]
