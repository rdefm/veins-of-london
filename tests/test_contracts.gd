extends "res://tests/test_base.gd"

const OffersSystem := preload("res://systems/offers.gd")
const ContractsSystem := preload("res://systems/contracts.gd")
const Fixtures := preload("res://tests/support/fixtures.gd")


func run() -> void:
	run_case("request_ore_types_covers_ore_mixed_and_crafted", func():
		assert_eq(ContractsSystem.request_ore_types({ "kind": "ore", "type": "life", "qty": 3 }), ["life"])
		assert_eq(ContractsSystem.request_ore_types({ "kind": "consumable", "type": "timePearl", "qty": 2 }), ["time"])
		assert_eq(ContractsSystem.request_ore_types({ "kind": "consumable", "type": "healingBurst", "qty": 1 }), ["time", "life"], "multi-ingredient recipe, ORE_TYPES order")
		assert_eq(ContractsSystem.request_ore_types({ "types": [
			{ "kind": "ore", "type": "emotion", "qty": 2 },
			{ "kind": "ore", "type": "time", "qty": 2 },
			{ "kind": "consumable", "type": "timePearl", "qty": 1 },
		] }), ["time", "emotion"], "mixed: one glyph per type, deduped")
	)

	run_case("cancel_one_off_removes_records_and_pays_nothing", func():
		_staff_sales()
		var contract := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 2
		ContractsSystem.process_sales_deliveries()
		var cash: int = GameState.state["player"]["cash"]
		assert_true(ContractsSystem.cancel(contract["id"])["ok"])
		var sales: Dictionary = GameState.state["sales"]
		assert_true(ContractsSystem.active_contracts().is_empty())
		assert_true(not sales["priorityOrder"].has(contract["id"]))
		assert_eq(sales["settlements"].size(), 0, "no settlement")
		assert_eq(GameState.state["player"]["cash"], cash, "pays nothing")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 0, "delivered ore not refunded")
		var entry: Dictionary = sales["contractHistory"].back()
		assert_true(ContractsSystem.is_cancelled(entry))
		assert_eq(entry["contract"]["status"], "cancelled")
		assert_eq(entry["cancelledDay"], GameState.state["world"]["day"])
		assert_true(not ContractsSystem.cancel(contract["id"])["ok"], "already gone")
	)

	run_case("cancel_recurring_ends_it_for_good", func():
		var contract := _proof_contract()
		_fill_and_settle(contract)
		assert_true(ContractsSystem.cancel(contract["id"])["ok"])
		assert_true(ContractsSystem.active_contracts().is_empty())
		var settled: int = GameState.state["sales"]["settlements"].size()
		GameState.state["world"]["day"] = int(contract["dueDay"]) + 7
		ContractsSystem.daily_tick()
		assert_eq(GameState.state["sales"]["settlements"].size(), settled, "no further periods")
		assert_true(ContractsSystem.is_cancelled(GameState.state["sales"]["contractHistory"].back()))
	)

	run_case("cancelled_contracts_count_toward_no_objective", func():
		var contract := _proof_contract()
		_fill_and_settle(contract)
		var before_count := Objectives.completed_contract_count()
		var before_template := Objectives.completed_period_count(contract["templateId"])
		var before_proof := Objectives.recurring_proof()
		ContractsSystem.cancel(contract["id"])
		var one_off := _accept_life_contract()
		ContractsSystem.cancel(one_off["id"])
		assert_eq(Objectives.completed_contract_count(), before_count)
		assert_eq(Objectives.completed_period_count(contract["templateId"]), before_template)
		assert_eq(Objectives.completed_period_count(one_off["templateId"]), 0)
		assert_eq(Objectives.recurring_proof(), before_proof)
	)

	run_case("unattended_short_first_period_qualifies", func():
		var contract := _proof_contract()
		var settlement := _fill_and_settle(contract)
		assert_true(settlement["complete"])
		assert_true(settlement["qualified"], "untouched, after the flag")
	)

	run_case("unattended_needs_recurring_completion_and_the_flag", func():
		var contract := _proof_contract()
		GameState.state["flags"].erase(ContractsSystem.PROOF_FLAG)
		assert_true(not _fill_and_settle(contract)["qualified"], "settled before the Beat 7 flag")
		GameState.state["flags"][ContractsSystem.PROOF_FLAG] = true
		_next_period(contract)
		_next_period(contract)
		var last: Dictionary = GameState.state["sales"]["settlements"].back()
		assert_true(not last["complete"] and not last["qualified"], "an empty period is incomplete")
		assert_true(_fill_and_settle(contract)["qualified"])

		_accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 5
		ContractsSystem.process_sales_deliveries()
		assert_true(not GameState.state["sales"]["settlements"].back()["qualified"], "one-offs never qualify")
	)

	run_case("unattended_player_actions_on_the_requested_type_taint", func():
		var contract := _proof_contract()
		Economy.execute_faction_purchase("guild", [{ "kind": "ore", "type": "physics", "qty": 1 }])
		assert_true(not _fill_and_settle(contract)["qualified"], "bought the requested ore")
		_next_period(contract)

		GameState.state["player"]["stash"]["orichalchum"]["physics"] = 1
		Stash.move_ore_to_shared("physics", 1)
		assert_true(not _fill_and_settle(contract)["qualified"], "unstashed the requested ore")

		var pearls := _add_weekly_contract({ "kind": "consumable", "type": "timePearl", "qty": 1 })
		_craft_one_time_pearl()
		ContractsSystem.process_sales_deliveries()
		var settlements: Array = GameState.state["sales"]["settlements"]
		assert_eq(settlements.back()["contractId"], pearls["id"])
		assert_true(not settlements.back()["qualified"], "crafted the requested recipe")
	)

	run_case("unattended_tending_a_cultivator_vein_taints_every_period", func():
		var contract := _proof_contract()
		GameState.state["player"]["veins"] = [Fixtures.player_vein_with()]
		GameState.state["contacts"]["owen"]["recruited"] = true
		GameState.state["flags"]["bizOwenCultivationRole"] = true
		Contacts.set_role("owen", "cultivation")
		Rooms.assign_vein("owen", "v1")
		assert_true(Cultivating.cultivate("v1")["ok"])
		assert_true(not _fill_and_settle(contract)["qualified"], "cultivated an assigned vein")
		_next_period(contract)
		assert_true(Cultivating.prune("v1", GameData.VEIN_GROWTH["pruneLightDepth"])["ok"])
		assert_true(not _fill_and_settle(contract)["qualified"], "pruned an assigned vein")
	)

	run_case("unattended_unrelated_player_actions_leave_the_period_intact", func():
		var contract := _proof_contract()
		GameState.state["player"]["veins"] = [Fixtures.player_vein_with()]
		assert_true(Cultivating.cultivate("v1")["ok"], "a vein on no cultivator's list")
		assert_true(Cultivating.prune("v1", GameData.VEIN_GROWTH["pruneLightDepth"])["ok"])
		GameState.state["player"]["orichalchum"]["time"] = 100
		Crafting.attempt_craft("timePearl")
		Economy.execute_faction_purchase("guild", [{ "kind": "ore", "type": "time", "qty": 1 }])
		GameState.state["player"]["stash"]["orichalchum"]["life"] = 1
		Stash.move_ore_to_shared("life", 1)
		assert_true(_fill_and_settle(contract)["qualified"])
	)

	run_case("unattended_sales_calc_purchases_never_taint", func():
		_setup_buy_calc_lanes()
		GameState.state["business"]["pot"] = 5000
		var created: Dictionary = OffersSystem.create_offer({
			"id": "t_life_weekly", "source": "scripted", "contractType": "recurring", "weekday": 1,
			"request": { "kind": "ore", "type": "life", "qty": 2 },
		})
		var contract: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])["contract"]
		ContractsSystem.set_buy_calc(contract["id"], true)
		ContractsSystem.process_daily_sales()
		assert_eq(GameState.state["business"]["week"]["expenses"].size(), 1)
		assert_true(GameState.state["sales"]["settlements"][0]["qualified"])
	)

	run_case("block_advance_delivers_coverable_contracts_after_the_staff_step", func():
		_staff_sales()
		var contract := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 5
		assert_eq(ContractsSystem.delivered_qty(contract), 0, "nothing moves mid-block")
		TimeSystem.advance_time_block()
		assert_eq(GameState.state["sales"]["settlements"].size(), 1)
		assert_true(GameState.state["sales"]["settlements"][0]["complete"])
		assert_eq(GameState.state["contacts"]["archie"]["salesXP"], ContractsSystem.COMPLETE_XP)
	)

	run_case("stock_added_mid_block_waits_for_the_next_block", func():
		_staff_sales()
		var ore := _accept_life_contract()
		var pearls := _add_weekly_contract({ "kind": "consumable", "type": "timePearl", "qty": 1 })
		# Pruning ends its block first, then yields ore into shared stock.
		GameState.state["player"]["veins"] = [Fixtures.player_vein_with({ "oreType": "life" })]
		assert_true(Cultivating.prune("v1", GameData.VEIN_GROWTH["pruneLightDepth"])["ok"])
		GameState.state["player"]["stash"]["orichalchum"]["life"] = 2
		Stash.move_ore_to_shared("life", 2)
		_craft_one_time_pearl()
		assert_eq(ContractsSystem.delivered_qty(ore), 0, "unstashed and pruned ore waits")
		assert_eq(GameState.state["sales"]["settlements"].size(), 0, "a crafted pearl waits")
		TimeSystem.advance_time_block()
		assert_true(ContractsSystem.delivered_qty(ore) >= 2, "delivered at the block's end")
		assert_true(_settled_ids().has(pearls["id"]), "the pearl period closes at the block's end")
	)

	run_case("stashed_stock_is_never_taken", func():
		_staff_sales()
		var contract := _accept_life_contract()
		GameState.state["player"]["stash"]["orichalchum"]["life"] = 5
		GameState.state["player"]["orichalchum"]["life"] = 1
		TimeSystem.advance_time_block()
		assert_eq(ContractsSystem.delivered_qty(contract), 1, "only shared stock")
		assert_eq(GameState.state["player"]["stash"]["orichalchum"]["life"], 5, "stash untouched")
	)

	run_case("unassigned_sales_delivers_nothing", func():
		GameState.reset()
		var contract := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 5
		TimeSystem.advance_time_block()
		ContractsSystem.process_daily_sales()
		assert_eq(ContractsSystem.delivered_qty(contract), 0)
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 5)
	)

	run_case("delivery_notes_the_counterparty_hook_and_records_no_supply", func():
		_staff_sales()
		var contract := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 2
		ContractsSystem.process_sales_deliveries()
		var deliveries: Array = GameState.state["market"]["deliveries"]
		assert_eq(deliveries.size(), 1)
		assert_eq(deliveries[0]["counterparty"], contract["counterparty"])
		assert_eq(deliveries[0]["goodKind"], "ore")
		assert_eq(deliveries[0]["good"], "life")
		assert_eq(deliveries[0]["qty"], 2)
		assert_true(GameState.state["market"]["supply"]["ore"].is_empty(), "no supply tally")
		for i in int(GameData.MARKET["deliveries"]["cap"]) + 5:
			Market.note_contract_delivery("firm", "ore", "time", 1)
		assert_eq(deliveries.size(), int(GameData.MARKET["deliveries"]["cap"]), "bounded")
	)

	run_case("partial_delivery_spends_shared_stock_only_and_no_time", func():
		_staff_sales()
		var contract := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 2
		var cash_before: int = GameState.state["player"]["cash"]
		ContractsSystem.process_sales_deliveries()
		assert_eq(ContractsSystem.delivered_qty(contract), 2)
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 0)
		assert_eq(GameState.state["world"]["timeBlocksDone"].size(), 0, "delivery costs no time")
		assert_eq(GameState.state["player"]["cash"], cash_before, "a partial delivery does not settle")
		assert_eq(GameState.state["sales"]["settlements"].size(), 0)
		assert_eq(ContractsSystem.active_contracts().size(), 1)
	)

	run_case("settlement_pays_the_business_pot_while_active_else_the_player", func():
		_staff_sales()
		_accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 5
		var cash_before: int = GameState.state["player"]["cash"]
		ContractsSystem.process_sales_deliveries()
		var first: Dictionary = GameState.state["sales"]["settlements"].back()
		assert_eq(GameState.state["player"]["cash"], cash_before + first["payment"], "before the pot, the player is paid")
		assert_eq(GameState.state["business"]["pot"], 0)

		# Accepted before the pot started, settled after: routed by settle day.
		_accept_life_contract()
		Business.activate()
		cash_before = GameState.state["player"]["cash"]
		GameState.state["player"]["orichalchum"]["life"] = 5
		ContractsSystem.process_sales_deliveries()
		var second: Dictionary = GameState.state["sales"]["settlements"].back()
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

	run_case("sales_allocates_partial_stock_in_priority_order", func():
		_staff_sales()
		var first := _accept_life_contract()
		var second := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 7
		ContractsSystem.process_sales_deliveries()
		assert_eq(_settled_ids(), [first["id"]], "the first closes")
		assert_eq(ContractsSystem.delivered_qty(second), 2)
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 0)
	)

	run_case("fully_coverable_periods_close_before_higher_priority_partials", func():
		_staff_sales()
		var mixed := _accept_mixed_contract()
		var fate := _add_weekly_contract({ "kind": "ore", "type": "fate", "qty": 3 })
		GameState.state["player"]["orichalchum"]["fate"] = 3
		ContractsSystem.process_sales_deliveries()
		assert_eq(_settled_ids(), [fate["id"]], "the coverable lower-priority period closes first")
		assert_eq(ContractsSystem.delivered_qty(mixed, "fate"), 0, "nothing left for the uncoverable partial")
	)

	# Production contract-coverage toggle: the personal-target portion of a
	# covered item's shared stock is a protected buffer.
	run_case("delivery_cannot_draw_below_the_covered_personal_target_reserve", func():
		_staff_sales()
		GameState.state["labThresholds"]["timePearl"] = 5
		Rooms.set_lab_cover_contracts("timePearl", true)
		Crafting.inventory_add("timePearl", 1, 8)
		var created: Dictionary = OffersSystem.create_offer({ "id": "t_reserve", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "timePearl", "qty": 10 } })
		var contract: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])["contract"]
		ContractsSystem.process_sales_deliveries()
		assert_eq(ContractsSystem.delivered_qty(contract), 3, "only the unreserved portion (8 in stock minus the 5 reserve) should be deliverable")
		assert_eq(Crafting.inventory_qty("timePearl"), 5, "the personal-target reserve should remain untouched")
	)

	run_case("shared_stock_is_undivided_when_the_item_is_not_covering_contracts", func():
		_staff_sales()
		GameState.state["labThresholds"]["timePearl"] = 5
		Crafting.inventory_add("timePearl", 1, 8)
		var created: Dictionary = OffersSystem.create_offer({ "id": "t_open", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "timePearl", "qty": 10 } })
		var contract: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])["contract"]
		ContractsSystem.process_sales_deliveries()
		assert_eq(ContractsSystem.delivered_qty(contract), 8, "toggle off -- no reserve, full shared stock available")
	)

	run_case("full_oneoff_delivery_settles_immediately_and_cannot_repeat", func():
		_staff_sales()
		var contract := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 5
		var cash_before: int = GameState.state["player"]["cash"]
		ContractsSystem.process_sales_deliveries()
		var settlement: Dictionary = GameState.state["sales"]["settlements"].back()
		assert_eq(settlement["payment"], contract["quote"]["payment"])
		assert_true(settlement["complete"])
		assert_eq(GameState.state["player"]["cash"], cash_before + contract["quote"]["payment"])
		assert_eq(GameState.state["sales"]["settlements"].size(), 1)
		assert_eq(ContractsSystem.active_contracts().size(), 0)
		assert_true(not GameState.state["sales"]["priorityOrder"].has(contract["id"]))
		assert_true(not ContractsSystem.settle(contract["id"])["ok"], "removed period cannot pay again")
		GameState.state["world"]["day"] = contract["dueDay"]
		ContractsSystem.daily_tick()
		assert_eq(GameState.state["player"]["cash"], cash_before + contract["quote"]["payment"], "due-day tick does not pay again")
	)

	run_case("full_recurring_fill_pays_once_and_locks_until_monday", func():
		var contract := _proof_contract()
		var old_period: String = contract["periodId"]
		var old_due: int = contract["dueDay"]
		var payment: int = contract["quote"]["payment"]
		var qty: int = ContractsSystem.remaining_qty(contract)
		GameState.state["player"]["orichalchum"]["physics"] = qty * 3
		var cash_before: int = GameState.state["player"]["cash"]
		ContractsSystem.process_sales_deliveries()
		assert_eq(GameState.state["player"]["cash"], cash_before + payment)
		assert_eq(ContractsSystem.active_contracts().size(), 1, "recurring contract stays active")
		assert_true(ContractsSystem.is_period_filled(contract))
		assert_eq(contract["periodId"], old_period, "no new period until Monday")
		assert_eq(contract["dueDay"], old_due, "due day does not move forward")
		ContractsSystem.process_sales_deliveries()
		assert_eq(GameState.state["sales"]["settlements"].size(), 1, "locked: no second fill this week")
		assert_eq(GameState.state["player"]["orichalchum"]["physics"], qty * 2, "no stock taken while locked")
		assert_true(not ContractsSystem.settle(contract["id"])["ok"], "a filled period cannot settle twice")
		GameState.state["world"]["day"] = old_due - 1
		ContractsSystem.daily_tick()
		assert_true(ContractsSystem.is_period_filled(contract), "still locked the day before Monday")
		GameState.state["world"]["day"] = old_due
		ContractsSystem.daily_tick()
		assert_eq(GameState.state["player"]["cash"], cash_before + payment, "Monday does not pay the filled period again")
		assert_eq(GameState.state["sales"]["settlements"].size(), 1)
		assert_true(not ContractsSystem.is_period_filled(contract), "Monday opens a fresh period")
		assert_true(contract["periodId"] != old_period)
		assert_eq(contract["dueDay"], old_due + 7)
		assert_eq(ContractsSystem.delivered_qty(contract), 0, "the fresh period waits for the next Sales pass")
		ContractsSystem.process_sales_deliveries()
		assert_eq(GameState.state["player"]["cash"], cash_before + payment * 2, "the new period takes deliveries")
		assert_true(GameState.state["sales"]["settlements"].back()["qualified"])
	)

	run_case("unfilled_recurring_period_settles_partial_on_monday_and_renews", func():
		var contract := _proof_contract()
		var due: int = contract["dueDay"]
		GameState.state["player"]["orichalchum"]["physics"] = 1
		ContractsSystem.process_sales_deliveries()
		GameState.state["world"]["day"] = due
		ContractsSystem.daily_tick()
		var settlement: Dictionary = GameState.state["sales"]["settlements"].back()
		assert_true(not settlement["complete"])
		assert_true(settlement["payment"] > 0, "a partial period still pays its partial share")
		assert_true(not ContractsSystem.is_period_filled(contract))
		assert_eq(contract["dueDay"], due + 7)
		assert_eq(ContractsSystem.delivered_qty(contract), 0)
	)

	run_case("deadline_settlement_still_pays_partial_for_incomplete_oneoff", func():
		_staff_sales()
		var contract := _accept_life_contract()
		GameState.state["player"]["orichalchum"]["life"] = 2
		ContractsSystem.process_sales_deliveries()
		assert_eq(GameState.state["sales"]["settlements"].size(), 0)
		GameState.state["world"]["day"] = contract["dueDay"]
		ContractsSystem.daily_tick()
		assert_eq(GameState.state["sales"]["settlements"].size(), 1)
		assert_true(not GameState.state["sales"]["settlements"][0]["complete"])
		assert_eq(ContractsSystem.active_contracts().size(), 0)
	)

	run_case("delivery_spans_every_requested_type", func():
		_staff_sales()
		var contract := _accept_mixed_contract()
		GameState.state["player"]["orichalchum"]["fate"] = 5
		Crafting.inventory_add("timePearl", 1, 5)
		ContractsSystem.process_sales_deliveries()
		assert_eq(GameState.state["player"]["orichalchum"]["fate"], 2, "each type capped by its own remaining need")
		assert_eq(Crafting.inventory_qty("timePearl"), 3)
		assert_eq(_settled_ids(), [contract["id"]], "full mixed delivery settles immediately")
	)

	run_case("mixed_delivery_caps_each_type_by_its_own_shared_stock_independently", func():
		_staff_sales()
		var contract := _accept_mixed_contract()
		GameState.state["player"]["orichalchum"]["fate"] = 1
		Crafting.inventory_add("timePearl", 1, 5)
		ContractsSystem.process_sales_deliveries()
		assert_eq(ContractsSystem.delivered_qty(contract, "fate"), 1, "only 1 fate available")
		assert_eq(ContractsSystem.delivered_qty(contract, "timePearl"), 2, "timePearl fully covered even though fate is short")
		assert_eq(ContractsSystem.active_contracts().size(), 1, "fate line still short, period stays open")
	)

	run_case("mixed_oneoff_settlement_is_quoted_value_weighted", func():
		_staff_sales()
		var contract := _accept_mixed_contract()
		GameState.state["player"]["orichalchum"]["fate"] = 3
		ContractsSystem.process_sales_deliveries()
		GameState.state["world"]["day"] = contract["dueDay"]
		var settled: Dictionary = ContractsSystem.settle(contract["id"])
		assert_true(settled["ok"])
		assert_true(not settled["settlement"]["complete"])
		assert_eq(settled["settlement"]["payment"], 324, "quote £765 × (270/510 quoted-value-weighted) × 0.80")
	)

	run_case("settlement_falls_back_to_the_flat_ratio_for_a_quote_with_no_lines", func():
		_staff_sales()
		var contract := _accept_life_contract()
		contract["quote"].erase("lines")
		GameState.state["player"]["orichalchum"]["life"] = 2
		ContractsSystem.process_sales_deliveries()
		GameState.state["world"]["day"] = contract["dueDay"]
		var settled: Dictionary = ContractsSystem.settle(contract["id"])
		assert_true(settled["ok"], "a quote with no lines must still settle, not KeyError")
		assert_eq(settled["settlement"]["payment"], GameState.round_epsilon(float(contract["quote"]["payment"]) * (2.0 / 5.0) * 0.80))
	)

	run_case("partial_recurring_settlement_penalises_then_renews_with_new_period_id", func():
		_staff_sales()
		var created: Dictionary = OffersSystem.create_scripted_offer("scripted_physics_weekly")
		var accepted: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])
		var contract: Dictionary = accepted["contract"]
		var old_period: String = contract["periodId"]
		GameState.state["player"]["orichalchum"]["physics"] = 1
		ContractsSystem.process_sales_deliveries()
		GameState.state["world"]["day"] = contract["dueDay"]
		var settled: Dictionary = ContractsSystem.settle(contract["id"])
		assert_true(settled["ok"])
		assert_eq(settled["settlement"]["payment"], GameState.round_epsilon(float(contract["quote"]["payment"]) / 3.0 * 0.80))
		assert_true(contract["periodId"] != old_period)
		assert_eq(contract["dueDay"], 15)
		assert_eq(ContractsSystem.delivered_qty(contract), 0)
	)


	run_case("buy_calc_buys_the_shortfall_cheapest_lane_first_and_spills_over", func():
		_setup_buy_calc_lanes()
		GameState.state["business"]["pot"] = 5000
		var contract := _accept_life_contract()
		assert_true(ContractsSystem.set_buy_calc(contract["id"], true)["ok"])
		GameState.state["player"]["orichalchum"]["life"] = 1
		var cash_before: int = GameState.state["player"]["cash"]
		var collective_price := Economy.get_faction_buy_price("collective", "ore", "life", false)
		var guild_price := Economy.get_faction_buy_price("guild", "ore", "life", false)
		assert_true(collective_price < guild_price, "the Collective's relation discount makes it cheapest")
		ContractsSystem.process_daily_sales()
		var expenses: Array = GameState.state["business"]["week"]["expenses"]
		assert_eq(expenses.size(), 2, "the shortfall of 4 spills from 2 Collective to 2 Guild")
		assert_eq(expenses[0]["kind"], "calc")
		assert_eq(expenses[0]["source"], GameData.FACTIONS["collective"]["name"])
		assert_eq(expenses[0]["qty"], 2)
		assert_eq(expenses[0]["amount"], collective_price * 2)
		assert_eq(expenses[0]["contractId"], contract["id"])
		assert_eq(expenses[1]["source"], GameData.FACTIONS["guild"]["name"])
		assert_eq(expenses[1]["qty"], 2)
		assert_eq(GameState.state["factions"]["collective"]["oreStock"]["life"], 0)
		assert_eq(GameState.state["business"]["pot"], 5000 - collective_price * 2 - guild_price * 2 + int(GameState.state["business"]["week"]["receipts"]))
		assert_eq(GameState.state["player"]["cash"], cash_before, "player cash is never touched")
		assert_eq(GameState.state["sales"]["settlements"].size(), 1, "bought ore enters shared stock and delivers")
		assert_true(GameState.state["sales"]["settlements"][0]["complete"])
		assert_eq(GameState.state["market"]["demand"]["ore"]["life"], { "player": 4 }, "calc bought for the contract records London demand")
	)

	run_case("buy_calc_skips_a_purchase_the_pot_cannot_cover_in_full", func():
		_setup_buy_calc_lanes()
		GameState.state["business"]["pot"] = 1
		var contract := _accept_life_contract()
		ContractsSystem.set_buy_calc(contract["id"], true)
		var cash_before: int = GameState.state["player"]["cash"]
		ContractsSystem.process_daily_sales()
		assert_eq(GameState.state["business"]["week"]["expenses"].size(), 0)
		assert_eq(GameState.state["business"]["pot"], 1)
		assert_eq(GameState.state["factions"]["collective"]["oreStock"]["life"], 2)
		assert_eq(int(GameState.state["player"]["orichalchum"].get("life", 0)), 0)
		assert_eq(GameState.state["player"]["cash"], cash_before)
	)

	run_case("buy_calc_off_buys_nothing", func():
		_setup_buy_calc_lanes()
		GameState.state["business"]["pot"] = 5000
		_accept_life_contract()
		ContractsSystem.process_daily_sales()
		assert_eq(GameState.state["business"]["week"]["expenses"].size(), 0, "toggle off")
	)

	run_case("buy_calc_crafted_need_uses_the_lowest_cost_working_producer", func():
		_setup_buy_calc_lanes()
		var contacts: Dictionary = GameState.state["contacts"]
		contacts["owen"]["recruited"] = true
		contacts["owen"]["craftingSkill"] = 1
		Contacts.assign_to_room("owen", "lab")
		contacts["james"]["recruited"] = true
		contacts["james"]["craftingSkill"] = 5
		contacts["james"]["assignedRole"] = "production"
		var created: Dictionary = OffersSystem.create_offer({
			"id": "t_pearl_order", "source": "scripted", "contractType": "oneOff",
			"expiresAfterDays": 6, "deadlineAfterDays": 5,
			"request": { "kind": "consumable", "type": "timePearl", "qty": 2 },
		})
		var contract: Dictionary = OffersSystem.accept_offer(created["offer"]["id"])["contract"]
		var per_unit: int = Crafting.calc_cost("timePearl", 5)["time"]
		assert_eq(ContractsSystem.calc_need(contract), { "time": 2 * per_unit })
		GameState.state["player"]["orichalchum"]["time"] = 1
		GameState.state["business"]["pot"] = 5000
		ContractsSystem.set_buy_calc(contract["id"], true)
		ContractsSystem.process_daily_sales()
		var bought := 0
		for expense in GameState.state["business"]["week"]["expenses"]:
			bought += int(expense["qty"])
		assert_eq(bought, 2 * per_unit - 1, "minus shared stock of that ore")
	)


# Fresh state with Archie working Sales from the Operations Room.
func _staff_sales() -> void:
	GameState.reset()
	GameState.state["contacts"]["archie"]["recruited"] = true
	Contacts.assign_to_room("archie", "ops")


# Pot active, Sales staffed; the Guild (joined, low relation) and the
# Collective (unlocked, high relation, 2 life in stock) both sell ore.
func _setup_buy_calc_lanes() -> void:
	_staff_sales()
	Business.activate()
	GameState.state["factions"]["guild"]["joined"] = true
	GameState.state["factions"]["guild"]["relation"] = 0
	GameState.state["flags"]["collectiveLaneUnlocked"] = true
	GameState.state["factions"]["collective"]["relation"] = 90
	GameState.state["factions"]["collective"]["oreStock"] = { "life": 2 }
	GameState.state["flags"][ContractsSystem.PROOF_FLAG] = true


# Fresh state with the Beat 7 flag set and Sales staffed, then a weekly
# physics ×3 contract.
func _proof_contract() -> Dictionary:
	_staff_sales()
	GameState.state["flags"][ContractsSystem.PROOF_FLAG] = true
	GameState.state["player"]["cash"] = 100000
	return _add_weekly_contract({ "kind": "ore", "type": "physics", "qty": 3 })


func _add_weekly_contract(request: Dictionary) -> Dictionary:
	var created: Dictionary = OffersSystem.create_offer({
		"id": "t_weekly_%s" % request["type"], "source": "scripted", "contractType": "recurring", "weekday": 1,
		"request": request,
	})
	return OffersSystem.accept_offer(created["offer"]["id"])["contract"]


# Rolls to the contract's due Monday so a filled period opens the next one.
func _next_period(contract: Dictionary) -> void:
	GameState.state["world"]["day"] = contract["dueDay"]
	ContractsSystem.daily_tick()


# Stocks the contract's ore and lets Sales close the period.
func _fill_and_settle(contract: Dictionary) -> Dictionary:
	var ore_type: String = contract["request"]["type"]
	GameState.state["player"]["orichalchum"][ore_type] = ContractsSystem.remaining_qty(contract)
	ContractsSystem.process_sales_deliveries()
	return GameState.state["sales"]["settlements"].back()


# Crafts until one Time Pearl lands in shared stock (seeded, so deterministic).
func _craft_one_time_pearl() -> void:
	GameState.state["player"]["orichalchum"]["time"] = 1000
	Rng.set_seed(1)
	for attempt in 50:
		if Crafting.inventory_qty("timePearl") > 0:
			return
		Crafting.attempt_craft("timePearl")


func _settled_ids() -> Array:
	var ids: Array = []
	for settlement in GameState.state["sales"]["settlements"]:
		ids.append(settlement["contractId"])
	return ids


func _accept_life_contract() -> Dictionary:
	var created: Dictionary = OffersSystem.create_scripted_offer("scripted_life_order")
	return OffersSystem.accept_offer(created["offer"]["id"])["contract"]


# Fate ore qty 3 + timePearl qty 2, built inline rather than from
# data/offers.json.
func _accept_mixed_contract() -> Dictionary:
	var created: Dictionary = OffersSystem.create_offer({
		"id": "t_mixed_calc_order", "source": "scripted", "contractType": "oneOff",
		"expiresAfterDays": 6, "deadlineAfterDays": 5,
		"request": { "types": [{ "kind": "ore", "type": "fate", "qty": 3 }, { "kind": "consumable", "type": "timePearl", "qty": 2 }] },
	})
	return OffersSystem.accept_offer(created["offer"]["id"])["contract"]
