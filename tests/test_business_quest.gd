extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const EventPlay := preload("res://tests/support/event_play.gd")


func run() -> void:
	run_case("beat_1_fires_at_two_veins_with_no_collective_progress", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Fixtures.seed_vein("v1", 40, "time")
		TimeSystem.do_rest()
		assert_true(not GameState.state["flags"]["bizA1Proposed"], "one vein is not enough")

		GameState.state["player"]["cash"] = 100000
		Fixtures.seed_faction_vein("fv1", 40)
		assert_true(VeinTrade.buy_from_faction("fv1", "collective")["ok"])
		assert_true(not GameState.state["flags"].get("colA1Started", false), "no Collective progress")
		assert_true(GameState.state["flags"]["bizA1Proposed"], "second vein fires Beat 1")
		assert_eq(_pending_kinds("archie"), [BusinessQuest.PROPOSITION_KIND])
		assert_true(GameState.state["objectives"]["biz_a1_proposition"]["active"], "ToDo shows the proposition")

		TimeSystem.do_rest()
		assert_eq(_pending_kinds("archie"), [BusinessQuest.PROPOSITION_KIND], "the permanent flag blocks re-firing")
	)

	run_case("beat_1_waits_for_archie_to_be_recruited_then_backstop_fires", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = false
		Fixtures.seed_vein("v1", 40, "time")
		Fixtures.seed_vein("v2", 40, "life")
		TimeSystem.do_rest()
		assert_true(not GameState.state["flags"]["bizA1Proposed"])
		GameState.state["contacts"]["archie"]["recruited"] = true
		TimeSystem.do_rest()
		assert_true(GameState.state["flags"]["bizA1Proposed"], "rollover backstop")
	)

	run_case("beat_1_scene_opens_sales_role_and_first_starter", func():
		_to_beat_1()
		assert_true(not Contacts.is_role_available("archie", "sales"))
		EventPlay.play_event(BusinessQuest.PROPOSITION_KIND)
		assert_true(GameState.state["flags"]["bizA1PropositionSeen"])
		assert_true(Contacts.is_role_available("archie", "sales"), "Archie's Sales role opens at Beat 2")
		assert_eq(_starter_offer_templates(), ["biz_starter_1"])
		var offer: Dictionary = _starter_offers()[0]
		assert_eq(offer["request"], { "kind": "ore", "type": "time", "qty": 4 })
		assert_true(GameState.state["objectives"]["biz_a1_market_proof"]["active"])
		assert_true(not GameState.state["objectives"]["biz_a1_market_proof"]["complete"])
	)

	run_case("three_prior_completions_satisfy_beat_2_instantly", func():
		_to_beat_1()
		for i in 3:
			_complete_life_order()
		EventPlay.play_event(BusinessQuest.PROPOSITION_KIND)
		assert_true(GameState.state["flags"]["bizA1MarketProven"], "earlier completions count")
		assert_eq(_starter_offer_templates(), [], "no starter once Beat 2 is met")
	)

	run_case("partial_settlement_does_not_count_toward_beat_2", func():
		_to_beat_1()
		EventPlay.play_event(BusinessQuest.PROPOSITION_KIND)
		var created: Dictionary = Offers.create_scripted_offer("scripted_life_order")
		var contract: Dictionary = Offers.accept_offer(created["offer"]["id"])["contract"]
		GameState.state["player"]["orichalchum"]["life"] = 2
		Contracts.deliver(contract["id"], 2)
		Contracts.settle(contract["id"])
		assert_eq(Objectives.completed_contract_count(), 0)
	)

	run_case("expired_starter_reissues_after_one_day", func():
		_to_beat_1()
		EventPlay.play_event(BusinessQuest.PROPOSITION_KIND)
		var expires_day: int = _starter_offers()[0]["expiresDay"]
		while GameState.state["world"]["day"] < expires_day:
			_tick()
			assert_true(_starter_offers().size() <= 1, "never more than one starter outstanding")
		assert_eq(_starter_offer_templates(), [], "expired on its expiry day, not reissued the same rollover")
		_tick()
		assert_eq(_starter_offer_templates(), ["biz_starter_1"], "the same starter reissued a day later")
	)

	run_case("declined_starter_reissues_next_day_and_completed_one_advances", func():
		_to_beat_1()
		EventPlay.play_event(BusinessQuest.PROPOSITION_KIND)
		Offers.decline_offer(_starter_offers()[0]["id"])
		BusinessQuest.maybe_issue_starter()
		assert_eq(_starter_offer_templates(), [], "not the same day")
		_tick()
		assert_eq(_starter_offer_templates(), ["biz_starter_1"])

		var contract: Dictionary = Offers.accept_offer(_starter_offers()[0]["id"])["contract"]
		_tick()
		assert_eq(_starter_offer_templates(), [], "an active starter contract is the outstanding one")
		GameState.state["player"]["orichalchum"]["time"] = 4
		assert_true(Contracts.deliver(contract["id"], 4)["complete"])
		assert_eq(Objectives.completed_contract_count(), 1)
		_tick()
		assert_eq(_starter_offer_templates(), ["biz_starter_2"], "the next starter a day after completion")
		assert_eq(_starter_offers()[0]["request"], { "kind": "consumable", "type": "timePearl", "qty": 3 })
	)

	run_case("todo_business_empire_shows_progress_toward_three", func():
		GameState.reset()
		var section := _business_section()
		assert_eq(section["status"], "placeholder", "unstarted questline shows its empty text")
		_to_beat_1()
		EventPlay.play_event(BusinessQuest.PROPOSITION_KIND)
		_complete_life_order()
		section = _business_section()
		assert_eq(section["status"], "active")
		var proof: Dictionary = section["items"][section["items"].size() - 1]
		assert_eq(proof["detail"], "1 of 3")
		assert_true(not proof["done"])
	)


	run_case("beat_2_met_queues_james_owen_intro_once", func():
		_to_beat_2()
		assert_true(GameState.state["flags"]["bizA1OwenIntroQueued"])
		assert_eq(_pending_kinds("james"), [BusinessQuest.OWEN_INTRO_KIND])
		assert_true(GameState.state["objectives"]["biz_a1_meet_owen"]["active"], "ToDo shows the Beat 3 nudge")
		TimeSystem.do_rest()
		assert_eq(_pending_kinds("james"), [BusinessQuest.OWEN_INTRO_KIND], "the permanent flag blocks re-firing")
	)

	run_case("prior_completions_queue_owen_intro_from_the_beat_1_scene", func():
		_to_beat_1()
		for i in 3:
			_complete_life_order()
		EventPlay.play_event(BusinessQuest.PROPOSITION_KIND)
		assert_eq(_pending_kinds("james"), [BusinessQuest.OWEN_INTRO_KIND])
	)

	run_case("beat_3_scene_recruits_owen_and_activates_the_pot", func():
		_to_beat_2()
		assert_true(not Contacts.is_role_available("owen", "cultivation"))
		EventPlay.play_event(BusinessQuest.OWEN_INTRO_KIND)
		var owen: Dictionary = GameState.state["contacts"]["owen"]
		assert_true(owen["unlocked"], "Owen appears in Contacts")
		assert_true(owen["recruited"])
		assert_true(Contacts.is_role_available("owen", "cultivation"))
		assert_true(GameState.state["flags"]["bizStaffTabOpen"])
		var business: Dictionary = GameState.state["business"]
		assert_true(business["potActive"])
		assert_eq(business["partners"], ["archie", "james"])
		assert_eq(business["wages"]["owen"]["hiredDay"], GameState.state["world"]["day"])
		assert_true(GameState.state["objectives"]["biz_a1_meet_owen"]["complete"])
	)

	run_case("settlement_before_beat_3_pays_player_after_pays_pot", func():
		_to_beat_2()
		var cash_before: int = GameState.state["player"]["cash"]
		_complete_life_order()
		var paid_to_player: int = GameState.state["player"]["cash"] - cash_before
		assert_true(paid_to_player > 0, "pre-business settlement pays the player")
		assert_eq(GameState.state["business"]["pot"], 0)

		EventPlay.play_event(BusinessQuest.OWEN_INTRO_KIND)
		cash_before = GameState.state["player"]["cash"]
		_complete_life_order()
		assert_eq(GameState.state["player"]["cash"], cash_before, "post-Beat 3 settlement skips the player")
		assert_eq(GameState.state["business"]["pot"], paid_to_player)
	)

	run_case("owen_on_cultivation_harvests_into_shared_stock_at_block_end", func():
		_to_beat_2()
		EventPlay.play_event(BusinessQuest.OWEN_INTRO_KIND)
		assert_true(Contacts.set_role("owen", "cultivation")["ok"])
		assert_true(Rooms.assign_vein("owen", "v1")["ok"])
		Cultivating.find_vein("v1")["growth"] = 95
		var ore_before: int = GameState.state["player"]["orichalchum"].get("time", 0)
		TimeSystem.advance_time_block()
		assert_true(GameState.state["player"]["orichalchum"].get("time", 0) > ore_before, "Owen pruned v1 into shared stock")
		assert_true(Cultivating.find_vein("v1")["growth"] < 95)
	)

	run_case("todo_shows_owens_level_and_the_workshop_as_checklist_items", func():
		_to_beat_3()
		var item: Dictionary = _business_item("biz_a1_apprentice")
		assert_eq(item["checks"].map(func(c): return [c["detail"], c["done"]]), [["level 1 of 2", false], ["", false]])
		_build_workshop()
		item = _business_item("biz_a1_apprentice")
		assert_eq(item["checks"].map(func(c): return c["done"]), [false, true])
	)

	run_case("prior_workshop_satisfies_beat_4_when_owen_levels", func():
		_to_beat_2()
		_build_workshop()
		EventPlay.play_event(BusinessQuest.OWEN_INTRO_KIND)
		assert_true(not GameState.state["flags"]["bizA1ApprenticeReady"], "Owen is still level 1")
		GameState.state["contacts"]["owen"]["cultivatingSkill"] = 2
		TimeSystem.advance_time_block()
		assert_true(GameState.state["flags"]["bizA1ApprenticeReady"], "the existing Workshop counts")
		assert_eq(_partnership_texts(), 1)
		assert_true(GameState.state["objectives"]["biz_a1_partnership"]["active"])
		TimeSystem.do_rest()
		assert_eq(_partnership_texts(), 1, "the permanent flag blocks re-firing")
	)

	run_case("tier_move_wiping_the_workshop_un_meets_beat_4", func():
		_to_beat_3()
		_build_workshop()
		Home.change_tier("townhouse", "rented")
		assert_eq(_business_item("biz_a1_apprentice")["checks"][1]["done"], false, "the Workshop check is live")
		GameState.state["contacts"]["owen"]["cultivatingSkill"] = 2
		TimeSystem.do_rest()
		assert_true(not GameState.state["flags"]["bizA1ApprenticeReady"])
		assert_eq(_partnership_texts(), 0)

		_build_workshop()
		assert_true(GameState.state["flags"]["bizA1ApprenticeReady"], "rebuilding meets it on the build")
		assert_eq(_partnership_texts(), 1)
	)

	run_case("beat_5_scene_recruits_james_as_a_crafter", func():
		_to_beat_5()
		assert_true(not Contacts.is_role_available("james", "production"))
		EventPlay.play_event(BusinessQuest.PARTNERSHIP_KIND)
		var james: Dictionary = GameState.state["contacts"]["james"]
		assert_true(james["recruited"])
		assert_eq(james["craftingSkill"], GameData.BUSINESS_JAMES_JOIN_CRAFTING_SKILL)
		assert_eq(james["craftingSkill"], 5)
		assert_true(Contacts.is_role_available("james", "production"))
		assert_true(Contacts.set_role("james", "production")["ok"])
		assert_true(GameState.state["objectives"]["biz_a1_partnership"]["complete"])
	)

	run_case("beat_5_scene_plays_cleanly_when_james_is_already_recruited", func():
		_to_beat_5()
		var james: Dictionary = GameState.state["contacts"]["james"]
		james["recruited"] = true
		james["craftingXP"] = 1500
		var partners_before: Array = GameState.state["business"]["partners"].duplicate()
		EventPlay.play_event(BusinessQuest.PARTNERSHIP_KIND)
		assert_true(james["recruited"])
		assert_eq(james["craftingSkill"], 5)
		assert_eq(james["craftingXP"], 1500, "XP already past the level is kept")
		assert_eq(GameState.state["business"]["partners"], partners_before, "no second partner entry")
		assert_true(GameState.state["flags"]["bizA1JamesJoined"])
	)

	run_case("beat_6_scene_unlocks_delegation_and_issues_the_recurring_offers", func():
		_to_beat_5()
		EventPlay.play_event(BusinessQuest.PARTNERSHIP_KIND)
		assert_eq(_pending_kinds("archie").count(BusinessQuest.PUT_TO_WORK_KIND), 1)
		assert_true(GameState.state["objectives"]["biz_a1_demo"]["active"])
		var created: Dictionary = Offers.create_scripted_offer("scripted_life_order")
		var early: Dictionary = Offers.accept_offer(created["offer"]["id"])["contract"]
		assert_true(not Contracts.set_delegated(early["id"], true)["ok"], "delegation is gated on Beat 6")
		_strip_random_offers()
		EventPlay.play_event(BusinessQuest.PUT_TO_WORK_KIND)
		assert_true(Contracts.delegation_unlocked())
		assert_true(Contracts.set_delegated(early["id"], true)["ok"])
		assert_eq(_beat6_offer_templates(), ["biz_recurring_time_pearl", "biz_recurring_time_ore", "biz_recurring_life_ore"])
		assert_eq(_beat6_offer("biz_recurring_time_pearl")["request"], { "kind": "consumable", "type": "timePearl", "qty": 5 })
		assert_eq(_beat6_offer("biz_recurring_time_ore")["request"], { "kind": "ore", "type": "time", "qty": 6 })
		assert_eq(_beat6_offer("biz_recurring_life_ore")["request"], { "kind": "ore", "type": "life", "qty": 6 })
		assert_eq(_beat6_offer("biz_recurring_time_pearl")["contractType"], "recurring")
		assert_true(GameState.state["objectives"]["biz_a1_put_to_work"]["active"])
	)

	run_case("beat_6_offers_stay_open_until_beat_6_is_met", func():
		_to_beat_6()
		for i in 10:
			_tick()
		assert_eq(_beat6_offer_templates().size(), 3, "no expiry while Beat 6 is unmet")
		GameState.state["flags"]["bizA1ProofDone"] = true
		_tick()
		assert_eq(_beat6_offer_templates().size(), 0, "normal expiry once Beat 6 is met")
	)

	run_case("declined_beat_6_offer_reissues_next_day_once_the_pending_cap_allows", func():
		_to_beat_6()
		Offers.decline_offer(_beat6_offer("biz_recurring_time_pearl")["id"])
		while Offers.pending_offers().size() < Offers.PENDING_CAP:
			Offers.create_offer(Offers.random_templates()[0])
		TimeSystem.do_rest()
		assert_true(_beat6_offer("biz_recurring_time_pearl").is_empty(), "the cap is full, so the reissue waits")
		# Two free slots, so the day's random roll can't refill the cap first.
		for offer in Offers.pending_offers().duplicate():
			if not BusinessQuest.is_beat6_template(offer["templateId"]):
				Offers.decline_offer(offer["id"])
		_tick()
		assert_true(not _beat6_offer("biz_recurring_time_pearl").is_empty())
	)

	run_case("declined_choice_is_not_reissued_while_the_other_choice_runs", func():
		_to_beat_6()
		Offers.accept_offer(_beat6_offer("biz_recurring_time_ore")["id"])
		Offers.decline_offer(_beat6_offer("biz_recurring_life_ore")["id"])
		_tick()
		_tick()
		assert_true(_beat6_offer("biz_recurring_life_ore").is_empty())
	)

	run_case("beat_6_needs_two_qualified_contracts_one_crafted_in_any_weeks", func():
		_to_beat_6()
		var time_ore := _accept_delegated("biz_recurring_time_ore")
		var life_ore := _accept_delegated("biz_recurring_life_ore")
		_stock_ore("time", 6)
		for i in 8:
			_tick()
		_stock_ore("life", 6)
		assert_eq(Objectives.recurring_proof(), { "contracts": 2, "crafted": 0 })
		assert_true(not GameState.state["flags"]["bizA1ProofDone"], "two ore orders alone don't prove it")
		var todo_checks: Array = _business_item("biz_a1_put_to_work")["checks"]
		assert_eq(todo_checks[0]["detail"], "2 of 2")
		assert_true(not todo_checks[1]["done"])
		var pearls := _accept_delegated("biz_recurring_time_pearl")
		_stock_pearls(5)
		assert_true(GameState.state["flags"]["bizA1ProofDone"])
		assert_true(_business_item("biz_a1_put_to_work")["done"])
		assert_true(time_ore["id"] != life_ore["id"] and pearls["id"] != time_ore["id"])
	)

	run_case("pre_existing_delegated_recurring_contract_counts", func():
		_to_beat_5()
		EventPlay.play_event(BusinessQuest.PARTNERSHIP_KIND)
		var created: Dictionary = Offers.create_scripted_offer("scripted_physics_weekly")
		var physics: Dictionary = Offers.accept_offer(created["offer"]["id"])["contract"]
		# A save from before the delegation gate and period tracking.
		physics["delegated"] = true
		physics.erase("delegatedWholePeriod")
		physics.erase("periodStartDay")
		_strip_random_offers()
		EventPlay.play_event(BusinessQuest.PUT_TO_WORK_KIND)
		Contacts.set_role("archie", "sales")
		_stock_ore("physics", 3)
		assert_eq(Objectives.recurring_proof()["contracts"], 1)
		_accept_delegated("biz_recurring_time_pearl")
		_stock_pearls(5)
		assert_true(GameState.state["flags"]["bizA1ProofDone"])
	)

	run_case("sales_calc_purchases_do_not_disqualify_the_proof", func():
		_to_beat_6()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["business"]["pot"] = 5000
		var time_ore := _accept_delegated("biz_recurring_time_ore")
		Contracts.set_buy_calc(time_ore["id"], true)
		Contracts.process_delegated_deliveries()
		var settlement: Dictionary = GameState.state["sales"]["settlements"].back()
		assert_eq(settlement["contractId"], time_ore["id"])
		assert_true(settlement["complete"] and settlement["qualified"])
		assert_eq(Objectives.recurring_proof()["contracts"], 1)
	)

	run_case("beat_7_waits_for_payday_then_closes_the_act_and_business_runs_on", func():
		_to_beat_6()
		var pearls := _accept_delegated("biz_recurring_time_pearl")
		var time_ore := _accept_delegated("biz_recurring_time_ore")
		_stock_pearls(5)
		_stock_ore("time", 6)
		assert_true(GameState.state["flags"]["bizA1ProofDone"])
		assert_true(not GameState.state["flags"]["bizA1ClosingQueued"])
		var ledger: Array = GameState.state["business"]["ledger"]
		var ledger_before := ledger.size()
		while ledger.size() == ledger_before:
			assert_true(_pending_kinds("archie").count(BusinessQuest.CLOSING_KIND) == 0, "no closing before payday")
			_tick()
		var entries: Array = Messages.pending_for("archie").filter(func(e): return e["kind"] == BusinessQuest.CLOSING_KIND)
		assert_eq(entries.size(), 1)
		var record: Dictionary = ledger.back()
		var payload: Dictionary = entries[0]["payload"]
		var receipts: int = int(pearls["quote"]["payment"]) + int(time_ore["quote"]["payment"])
		assert_eq(record["receipts"], receipts)
		assert_eq(payload["receipts"], "£%d" % receipts)
		assert_eq(payload["playerShare"], "£%d" % int(record["shares"]["player"]))
		assert_eq(payload["jamesShare"], "£%d" % int(record["shares"]["james"]))
		assert_true(String(payload["periodOne"]).begins_with("Time Pearl ×5"), "the crafted order reads first")
		assert_true(String(payload["owenWage"]) != "£0")

		Events.start_event(BusinessQuest.CLOSING_KIND, payload)
		Events.advance()
		assert_true(String(Events.revealed_cards()[1]["text"]).contains(payload["periodOne"]))
		for i in GameData.EVENTS[BusinessQuest.CLOSING_KIND]["cards"].size() - 1:
			Events.advance()
		assert_true(GameState.state["flags"]["bizA1Complete"])
		assert_eq(_business_section()["status"], "done")

		for i in 7:
			_tick()
		assert_eq(ledger.size(), ledger_before + 2, "payday keeps running after the act")
		assert_true(GameState.state["business"]["potActive"])
		assert_eq(_pending_kinds("archie").count(BusinessQuest.CLOSING_KIND), 1, "the closing plays once")
	)

	run_case("two_realistic_recurring_orders_leave_a_positive_weekly_share", func():
		_to_beat_6()
		var weekly: int = int(_beat6_offer("biz_recurring_time_pearl")["quote"]["payment"]) + int(_beat6_offer("biz_recurring_time_ore")["quote"]["payment"])
		var owen_wage: int = GameData.BUSINESS_WEEKLY_WAGES["owen"]
		assert_true(Business.split(weekly - owen_wage, 2)["player"] > 0)
	)

	run_case("owen_craft_event_queues_from_the_beat_5_scene_once", func():
		_to_beat_5()
		assert_eq(_owen_craft_texts(), 0, "James not yet recruited")
		EventPlay.play_event(BusinessQuest.PARTNERSHIP_KIND)
		assert_eq(_owen_craft_texts(), 1, "event completion checks the trigger")
		TimeSystem.do_rest()
		assert_eq(_owen_craft_texts(), 1, "the permanent flag blocks re-firing")
		assert_true(not GameState.state["flags"]["bizA1Complete"], "not an Act 1 beat")
	)

	run_case("owen_craft_event_waits_for_the_workshop_then_rollover_fires_it", func():
		_to_beat_3()
		GameState.state["contacts"]["james"]["recruited"] = true
		GameState.state["contacts"]["owen"]["cultivatingSkill"] = 2
		TimeSystem.do_rest()
		assert_eq(_owen_craft_texts(), 0, "no Workshop yet")
		_build_workshop()
		TimeSystem.do_rest()
		assert_eq(_owen_craft_texts(), 1)
	)

	run_case("owen_craft_scene_opens_production_and_swapping_leaves_his_veins_untended", func():
		_to_beat_5()
		EventPlay.play_event(BusinessQuest.PARTNERSHIP_KIND)
		assert_true(Contacts.set_role("owen", "cultivation")["ok"])
		assert_true(Rooms.assign_vein("owen", "v1")["ok"])
		assert_true(not Contacts.set_role("owen", "production")["ok"], "Production locked before the scene")
		EventPlay.play_event(BusinessQuest.OWEN_CRAFT_KIND)
		assert_true(Contacts.set_role("owen", "production")["ok"])
		assert_eq(Rooms.cultivator_veins("owen"), ["v1"], "his veins keep their list")
		assert_eq(Contacts.contacts_in_role("cultivation"), [], "no active cultivator")
		Cultivating.find_vein("v1")["growth"] = 95
		TimeSystem.advance_time_block()
		assert_eq(Cultivating.find_vein("v1")["growth"], 95, "untended while he crafts")
		assert_true(Contacts.set_role("owen", "cultivation")["ok"])
		TimeSystem.advance_time_block()
		assert_true(Cultivating.find_vein("v1")["growth"] < 95, "tended again from the next block end")
	)


func _owen_craft_texts() -> int:
	return _pending_kinds("james").count(BusinessQuest.OWEN_CRAFT_KIND)


func _to_beat_1() -> void:
	GameState.reset()
	GameState.state["contacts"]["archie"]["recruited"] = true
	Fixtures.seed_vein("v1", 40, "time")
	Fixtures.seed_vein("v2", 40, "life")
	TimeSystem.do_rest()


# Beat 2 met by three completions after the Beat 1 scene.
func _to_beat_2() -> void:
	_to_beat_1()
	EventPlay.play_event(BusinessQuest.PROPOSITION_KIND)
	for i in 3:
		_complete_life_order()


func _to_beat_3() -> void:
	_to_beat_2()
	EventPlay.play_event(BusinessQuest.OWEN_INTRO_KIND)


# Beat 4 met (Workshop + Owen level 2): James's partnership text queued.
func _to_beat_5() -> void:
	_to_beat_3()
	GameState.state["contacts"]["owen"]["cultivatingSkill"] = 2
	_build_workshop()


# Beat 6 scene played, Archie in Sales, the three recurring offers pending.
func _to_beat_6() -> void:
	_to_beat_5()
	EventPlay.play_event(BusinessQuest.PARTNERSHIP_KIND)
	_strip_random_offers()
	EventPlay.play_event(BusinessQuest.PUT_TO_WORK_KIND)
	assert_true(Contacts.set_role("archie", "sales")["ok"])


func _strip_random_offers() -> void:
	var pending: Array = Offers.pending_offers()
	for offer in pending.duplicate():
		if offer["source"] == "random":
			pending.erase(offer)


func _beat6_offer(template_id: String) -> Dictionary:
	for offer in Offers.pending_offers():
		if offer["templateId"] == template_id:
			return offer
	return {}


func _beat6_offer_templates() -> Array:
	return Offers.pending_offers().filter(func(o): return BusinessQuest.is_beat6_template(o["templateId"])).map(func(o): return o["templateId"])


# Accepted and delegated on its first day, so the whole period is delegated.
func _accept_delegated(template_id: String) -> Dictionary:
	var contract: Dictionary = Offers.accept_offer(_beat6_offer(template_id)["id"])["contract"]
	assert_true(Contracts.set_delegated(contract["id"], true)["ok"])
	return contract


# Stock appearing without the player (as a cultivator or producer would
# supply it); Sales closes any fully covered delegated period.
func _stock_ore(ore_type: String, qty: int) -> void:
	var ore: Dictionary = GameState.state["player"]["orichalchum"]
	ore[ore_type] = int(ore.get(ore_type, 0)) + qty
	EventBus.shared_stock_increased.emit()


func _stock_pearls(qty: int) -> void:
	Crafting.inventory_add("timePearl", 1, qty)
	EventBus.shared_stock_increased.emit()


func _build_workshop() -> void:
	GameState.state["home"]["tier"] = "flat"
	GameState.state["player"]["cash"] += 1000
	assert_true(Home.add_room("workshop")["ok"])


func _business_item(objective_id: String) -> Dictionary:
	var title: String = GameData.OBJECTIVES[objective_id]["title"]
	for item in _business_section()["items"]:
		if item["title"] == title:
			return item
	return {}


# A rollover with random offers stripped, so the pending cap never blocks a
# starter the case is waiting on.
func _tick() -> void:
	TimeSystem.do_rest()
	var pending: Array = Offers.pending_offers()
	for offer in pending.duplicate():
		if offer["source"] == "random":
			pending.erase(offer)


func _complete_life_order() -> void:
	var created: Dictionary = Offers.create_scripted_offer("scripted_life_order")
	var contract: Dictionary = Offers.accept_offer(created["offer"]["id"])["contract"]
	GameState.state["player"]["orichalchum"]["life"] = 5
	Contracts.deliver(contract["id"], 5)


func _pending_kinds(contact_id: String) -> Array:
	return Messages.pending_for(contact_id).map(func(e): return e["kind"])


func _partnership_texts() -> int:
	return _pending_kinds("james").count(BusinessQuest.PARTNERSHIP_KIND)


func _starter_offers() -> Array:
	return Offers.pending_offers().filter(func(o): return BusinessQuest.is_starter(o["templateId"]))


func _starter_offer_templates() -> Array:
	return _starter_offers().map(func(o): return o["templateId"])


func _business_section() -> Dictionary:
	for section in Todo.get_questline_sections():
		if section["questline"] == "business_empire":
			return section
	return {}
