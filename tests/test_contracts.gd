extends "res://tests/test_base.gd"

const OffersSystem := preload("res://systems/offers.gd")
const ContractsSystem := preload("res://systems/contracts.gd")


func run() -> void:
	run_case("manual_partial_delivery_spends_shared_stock_only_and_no_time", func():
		GameState.reset()
		var contract := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 4
		var cash_before: int = GameState.state["player"]["cash"]
		var result: Dictionary = ContractsSystem.deliver(contract["id"], 2)
		assert_true(result["ok"])
		assert_eq(result["delivered"], 2)
		assert_true(not result["complete"])
		assert_eq(ContractsSystem.delivered_qty(contract), 2)
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 2)
		assert_eq(GameState.state["world"]["timeBlock"], 0, "manual delivery costs no time")
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 0, "manual delivery costs no time")
		assert_eq(GameState.state["player"]["cash"], cash_before, "a partial delivery does not settle")
		assert_eq(GameState.state["sales"]["settlements"].size(), 0)
		assert_eq(ContractsSystem.active_contracts().size(), 1)
		contract["delegated"] = true
		assert_true(not ContractsSystem.deliver(contract["id"], 1)["ok"], "manual path rejects delegated contracts")
	)

	run_case("settlement_pays_the_business_pot_while_active_else_the_player", func():
		GameState.reset()
		var before_pot := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 10
		var cash_before: int = GameState.state["player"]["cash"]
		var first: Dictionary = ContractsSystem.deliver(before_pot["id"], 5)["settlement"]
		assert_eq(GameState.state["player"]["cash"], cash_before + first["payment"], "before the pot, the player is paid")
		assert_eq(GameState.state["business"]["pot"], 0)

		# Accepted before the pot started, settled after: routed by settle day.
		var after_pot := _accept_life_contract()
		Business.activate()
		cash_before = GameState.state["player"]["cash"]
		var second: Dictionary = ContractsSystem.deliver(after_pot["id"], 5)["settlement"]
		assert_eq(GameState.state["player"]["cash"], cash_before, "the pot takes the payment")
		assert_eq(GameState.state["business"]["pot"], second["payment"])
		assert_eq(GameState.state["business"]["week"]["receipts"], second["payment"])
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

	run_case("full_manual_oneoff_delivery_settles_immediately_and_cannot_repeat", func():
		GameState.reset()
		var contract := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 5
		var cash_before: int = GameState.state["player"]["cash"]
		var result: Dictionary = ContractsSystem.deliver(contract["id"], 5)
		assert_true(result["ok"])
		assert_true(result["complete"])
		assert_eq(result["settlement"]["payment"], contract["quote"]["payment"])
		assert_true(result["settlement"]["complete"])
		assert_eq(GameState.state["player"]["cash"], cash_before + contract["quote"]["payment"])
		assert_eq(GameState.state["sales"]["settlements"].size(), 1)
		assert_eq(ContractsSystem.active_contracts().size(), 0)
		assert_true(not GameState.state["sales"]["priorityOrder"].has(contract["id"]))
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 0, "manual delivery costs no time")
		assert_true(not ContractsSystem.settle(contract["id"])["ok"], "removed period cannot pay again")
		GameState.state["world"]["day"] = contract["dueDay"]
		ContractsSystem.daily_tick()
		assert_eq(GameState.state["player"]["cash"], cash_before + contract["quote"]["payment"], "due-day tick does not pay again")
	)

	run_case("full_manual_recurring_delivery_settles_and_renews_without_double_pay", func():
		GameState.reset()
		var created: Dictionary = OffersSystem.create_scripted_offer("scripted_physics_weekly")
		var contract: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])["contract"]
		var old_period: String = contract["periodId"]
		var old_due: int = contract["dueDay"]
		var payment: int = contract["quote"]["payment"]
		GameState.state["player"]["orichalchum"]["physics"] = ContractsSystem.remaining_qty(contract)
		var cash_before: int = GameState.state["player"]["cash"]
		var result: Dictionary = ContractsSystem.deliver(contract["id"], ContractsSystem.remaining_qty(contract))
		assert_true(result["ok"])
		assert_true(result["complete"])
		assert_eq(GameState.state["player"]["cash"], cash_before + payment)
		assert_eq(ContractsSystem.active_contracts().size(), 1, "recurring contract stays active")
		assert_true(contract["periodId"] != old_period)
		assert_eq(contract["dueDay"], old_due + 7)
		assert_eq(ContractsSystem.delivered_qty(contract), 0)
		GameState.state["world"]["day"] = old_due
		ContractsSystem.daily_tick()
		assert_eq(GameState.state["player"]["cash"], cash_before + payment, "old due day does not pay the closed period again")
		assert_eq(GameState.state["sales"]["settlements"].size(), 1)
	)

	run_case("deadline_settlement_still_pays_partial_for_incomplete_oneoff", func():
		GameState.reset()
		var contract := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 2
		ContractsSystem.deliver(contract["id"], 2)
		assert_eq(GameState.state["sales"]["settlements"].size(), 0)
		GameState.state["world"]["day"] = contract["dueDay"]
		ContractsSystem.daily_tick()
		assert_eq(GameState.state["sales"]["settlements"].size(), 1)
		assert_true(not GameState.state["sales"]["settlements"][0]["complete"])
		assert_eq(ContractsSystem.active_contracts().size(), 0)
	)

	# ticket 32: mixed one-off delivery/settlement.
	run_case("manual_delivery_spans_every_requested_type_at_no_time_cost", func():
		GameState.reset()
		var contract := _accept_mixed_contract()
		GameState.state["player"]["orichalchum"]["fate"] = 5
		Crafting.inventory_add("timePearl", 1, 5)
		var result: Dictionary = ContractsSystem.deliver(contract["id"], 10)
		assert_true(result["ok"])
		assert_eq(result["delivered"], 5, "3 fate + 2 timePearl, each capped by its own remaining need")
		assert_eq(ContractsSystem.delivered_qty(contract, "fate"), 3)
		assert_eq(ContractsSystem.delivered_qty(contract, "timePearl"), 2)
		assert_true(result["complete"])
		assert_eq(GameState.state["world"]["timeBlock"], 0, "manual delivery costs no time")
		assert_eq(GameState.state["sales"]["settlements"].size(), 1, "full mixed delivery settles immediately")
	)

	run_case("mixed_delivery_caps_each_type_by_its_own_shared_stock_independently", func():
		GameState.reset()
		var contract := _accept_mixed_contract()
		GameState.state["player"]["orichalchum"]["fate"] = 1
		Crafting.inventory_add("timePearl", 1, 5)
		var result: Dictionary = ContractsSystem.deliver(contract["id"], 10)
		assert_true(result["ok"])
		assert_eq(result["delivered"], 3, "1 fate (all that's available) + 2 timePearl (fully covered)")
		assert_eq(ContractsSystem.delivered_qty(contract, "fate"), 1)
		assert_eq(ContractsSystem.delivered_qty(contract, "timePearl"), 2)
		assert_true(not result["complete"], "fate still short by 2")
	)

	run_case("delegated_mixed_contract_only_closes_when_every_type_is_fully_covered", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "ops")
		var contract := _accept_mixed_contract()
		ContractsSystem.set_delegated(contract["id"], true)
		GameState.state["player"]["orichalchum"]["fate"] = 3
		Crafting.inventory_add("timePearl", 1, 1)
		ContractsSystem.shared_stock_increased()
		assert_eq(ContractsSystem.active_contracts().size(), 1, "timePearl line still short -- not fully deliverable yet")
		assert_eq(ContractsSystem.delivered_qty(contract, "fate"), 0, "no partial delivery on the realtime recheck")
		Crafting.inventory_add("timePearl", 1, 1)
		ContractsSystem.shared_stock_increased()
		assert_eq(ContractsSystem.active_contracts().size(), 0, "now fully fundable across every type -- closes immediately")
		assert_eq(GameState.state["contacts"]["archie"]["salesXP"], ContractsSystem.COMPLETE_XP)
	)

	run_case("daily_partial_pass_fills_each_mixed_type_independently", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "ops")
		var contract := _accept_mixed_contract()
		ContractsSystem.set_delegated(contract["id"], true)
		GameState.state["player"]["orichalchum"]["fate"] = 1
		Crafting.inventory_add("timePearl", 1, 5)
		ContractsSystem.process_delegated_deliveries()
		assert_eq(ContractsSystem.delivered_qty(contract, "fate"), 1, "only 1 fate available")
		assert_eq(ContractsSystem.delivered_qty(contract, "timePearl"), 2, "timePearl fully covered even though fate is short")
		assert_eq(ContractsSystem.active_contracts().size(), 1, "fate line still short, period stays open")
	)

	run_case("mixed_oneoff_settlement_is_quoted_value_weighted", func():
		GameState.reset()
		var contract := _accept_mixed_contract()
		GameState.state["player"]["orichalchum"]["fate"] = 3
		ContractsSystem.deliver(contract["id"], 3, false)
		GameState.state["world"]["day"] = contract["dueDay"]
		var settled: Dictionary = ContractsSystem.settle(contract["id"])
		assert_true(settled["ok"])
		assert_true(not settled["settlement"]["complete"])
		assert_eq(settled["settlement"]["payment"], 324, "quote £765 × (270/510 quoted-value-weighted) × 0.80")
	)

	run_case("settlement_falls_back_to_the_flat_ratio_for_a_pre_ticket32_quote_with_no_lines", func():
		GameState.reset()
		var contract := _accept_life_contract()
		contract["quote"].erase("lines")
		GameState.state["player"]["orichalchum"]["life"] = 2
		ContractsSystem.deliver(contract["id"], 2, false)
		GameState.state["world"]["day"] = contract["dueDay"]
		var settled: Dictionary = ContractsSystem.settle(contract["id"])
		assert_true(settled["ok"], "a contract accepted before ticket 32 must still settle, not KeyError")
		assert_eq(settled["settlement"]["payment"], GameState.round_epsilon(float(contract["quote"]["payment"]) * (2.0 / 5.0) * 0.80))
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


# ticket 32: fate ore qty 3 + timePearl qty 2 (business-spec.md's mixed
# one-off support). Built inline rather than via data/offers.json: the real
# scripted/random mixed-offer catalogue is deferred to tickets 33/34.
func _accept_mixed_contract() -> Dictionary:
	var created: Dictionary = OffersSystem.create_offer({
		"id": "t_mixed_calc_order", "source": "scripted", "contractType": "oneOff",
		"expiresAfterDays": 6, "deadlineAfterDays": 5,
		"request": { "types": [{ "kind": "ore", "type": "fate", "qty": 3 }, { "kind": "consumable", "type": "timePearl", "qty": 2 }] },
	})
	return OffersSystem.accept_offer(created["offer"]["id"])["contract"]
