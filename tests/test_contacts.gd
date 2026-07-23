extends "res://tests/test_base.gd"


func run() -> void:
	run_case("award_relation_adds_to_the_named_contact", func():
		GameState.reset()
		Contacts.award_relation("archie", 15)
		assert_eq(GameState.state["contacts"]["archie"]["relation"], 25, "10 default + 15")
	)

	run_case("can_recruit_requires_unlocked_not_recruited_and_threshold_met", func():
		GameState.reset()
		# archie: unlocked true, relation 10, threshold 80 by default
		assert_true(not Contacts.can_recruit("archie"), "relation 10 < threshold 80")

		GameState.state["contacts"]["archie"]["relation"] = 80
		assert_true(Contacts.can_recruit("archie"), "unlocked, not recruited, relation meets threshold")

		GameState.state["contacts"]["archie"]["recruited"] = true
		assert_true(not Contacts.can_recruit("archie"), "already recruited")

		# james starts unlocked:false
		GameState.state["contacts"]["james"]["relation"] = 1000
		assert_true(not Contacts.can_recruit("james"), "not unlocked yet, regardless of relation")
	)

	run_case("recruit_sets_recruited_and_notifies", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["relation"] = 80
		var result := Contacts.recruit("archie")
		assert_true(result["ok"], "should succeed once eligible")
		assert_true(GameState.state["contacts"]["archie"]["recruited"], "recruited flag set")
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"].contains("now working with you"):
				found = true
		assert_true(found, "should notify on recruit")
	)

	run_case("recruit_fails_when_not_eligible", func():
		GameState.reset()
		var result := Contacts.recruit("archie")
		assert_true(not result["ok"], "relation 10 < threshold 80, should fail")
		assert_true(not GameState.state["contacts"]["archie"]["recruited"], "not recruited")
	)

	run_case("room_assignment_is_exclusive_one_contact_per_room", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["contacts"]["james"]["recruited"] = true

		Contacts.assign_to_room("archie", "lab")
		assert_eq(Contacts.get_contact_in_room("lab"), "archie", "archie assigned to lab")

		Contacts.assign_to_room("james", "lab")
		assert_eq(Contacts.get_contact_in_room("lab"), "james", "assigning james should vacate archie")
		assert_eq(GameState.state["contacts"]["archie"]["assignedRoom"], null, "archie's assignment cleared")
	)

	run_case("assign_none_vacates_without_assigning_anyone", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "lab")
		Contacts.assign_to_room("none", "lab")
		assert_eq(Contacts.get_contact_in_room("lab"), null, "'none' should vacate the room")
	)

	run_case("award_contact_xp_levels_up_and_notifies", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.award_contact_xp("archie", "crafting", 80)
		assert_eq(GameState.state["contacts"]["archie"]["craftingSkill"], 2, "80 xp should cross the level-2 crafting threshold")
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"].contains("Archie's crafting skill reached level 2"):
				found = true
		assert_true(found, "should notify on contact skill level-up")
	)

	run_case("display_name_maps_known_contacts", func():
		assert_eq(Contacts.display_name("archie"), "Archie", "archie display name")
		assert_eq(Contacts.display_name("james"), "James", "james display name")
	)
