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
