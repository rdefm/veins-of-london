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

	# collective1-07, spec §7.1: Des/Nadia/Hakim are never recruitable, even
	# once unlocked with a met (zero) relation threshold.
	run_case("can_recruit_is_false_when_recruitable_is_false_even_with_threshold_met", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "recruited": false, "relation": 0, "recruitThreshold": 0, "recruitable": false }
		assert_true(not Contacts.can_recruit("des"), "recruitable:false blocks recruiting regardless of relation/threshold")
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

	# 21-contact-roles-sales-skill, business-spec.md: "a Sales, Production or
	# Procurement assignment replaces any room assignment on that contact,
	# and vice versa" -- assignedRoom is a single scalar field, so assigning
	# a contact to a different room type (here "ops"/Sales) automatically
	# clears whatever room-type assignment (here "lab"/Production) they held
	# before, with no parallel state model needed.
	run_case("assigning_a_different_role_replaces_the_contacts_prior_room_assignment", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true

		Contacts.assign_to_room("archie", "lab")
		assert_eq(GameState.state["contacts"]["archie"]["assignedRoom"], "lab")

		Contacts.assign_to_room("archie", "ops")
		assert_eq(GameState.state["contacts"]["archie"]["assignedRoom"], "ops", "assigning to ops (Sales) must replace the prior lab (Production) assignment")
		assert_eq(Contacts.get_contact_in_room("lab"), null, "lab must be vacated once archie moves to ops")
		assert_eq(Contacts.get_contact_in_room("ops"), "archie")
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

	# 21-contact-roles-sales-skill: salesSkill/salesXP use the same
	# skill-threshold-ladder mechanism (GameData.SALES_XP_LEVELS, business-
	# spec.md's [0, 0, 80, 220, 500, 1000]) as crafting/cultivating above.
	run_case("award_contact_xp_levels_up_sales_skill_and_notifies", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		assert_eq(GameState.state["contacts"]["archie"]["salesSkill"], 1, "starts at level 1, same as crafting/cultivating")
		Contacts.award_contact_xp("archie", "sales", 80)
		assert_eq(GameState.state["contacts"]["archie"]["salesSkill"], 2, "80 xp should cross the level-2 sales threshold")
		var found := false
		for n in GameState.state["notifications"]:
			if n["text"].contains("Archie's sales skill reached level 2"):
				found = true
		assert_true(found, "should notify on contact skill level-up")
	)

	run_case("display_name_maps_known_contacts", func():
		assert_eq(Contacts.display_name("archie"), "Archie", "archie display name")
		assert_eq(Contacts.display_name("james"), "James", "james display name")
	)

	# ── 44-archie-combat-ally ────────────────────────────────────────────

	run_case("can_join_combat_requires_recruited_and_a_combat_kit", func():
		GameState.reset()
		assert_true(not Contacts.can_join_combat("archie"), "not recruited yet")

		GameState.state["contacts"]["archie"]["recruited"] = true
		assert_true(Contacts.can_join_combat("archie"), "recruited with a combat kit")

		# des has no combat kit defined in constants.json (combatHpMax 0)
		GameState.state["contacts"]["des"]["recruited"] = true
		assert_true(not Contacts.can_join_combat("des"), "recruited but no combat kit -- never eligible")
	)

	run_case("can_join_combat_needs_no_relation_threshold_once_recruited", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["contacts"]["archie"]["relation"] = 0
		assert_true(Contacts.can_join_combat("archie"), "joining a defense fight needs no relation threshold, unlike can_recruit")
	)

	run_case("can_join_combat_blocks_while_on_ko_cooldown_then_reopens", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["world"]["day"] = 5
		GameState.state["contacts"]["archie"]["koCooldownUntilDay"] = 7
		assert_true(not Contacts.can_join_combat("archie"), "still on cooldown")

		GameState.state["world"]["day"] = 7
		assert_true(Contacts.can_join_combat("archie"), "available again once the day reaches the cooldown day")
	)

	run_case("build_combat_ally_snapshots_the_contacts_current_combat_kit", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["combatHp"] = 30
		GameState.state["contacts"]["archie"]["combatStash"] = 1
		var ally := Contacts.build_combat_ally("archie")
		assert_eq(ally["contactId"], "archie")
		assert_eq(ally["name"], "Archie")
		assert_eq(ally["hp"], 30, "current combatHp, not combatHpMax")
		assert_eq(ally["hpMax"], 50)
		assert_eq(ally["attackMin"], 4)
		assert_eq(ally["attackMax"], 9)
		assert_eq(ally["stash"], 1)
		assert_eq(ally["healAmount"], 15)
		assert_true(not ally["koed"], "joins alive")
	)

	run_case("knock_out_sets_a_cooldown_relative_to_the_current_day", func():
		GameState.reset()
		Contacts.knock_out("archie", 10)
		assert_eq(GameState.state["contacts"]["archie"]["koCooldownUntilDay"], 12, "10 + koCooldownDays(2)")
	)

	run_case("replenish_after_combat_tops_up_hp_and_stash_for_every_ally_that_fought", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["combatHp"] = 5
		GameState.state["contacts"]["archie"]["combatStash"] = 0
		Contacts.replenish_after_combat([{ "contactId": "archie" }])
		assert_eq(GameState.state["contacts"]["archie"]["combatHp"], 50)
		assert_eq(GameState.state["contacts"]["archie"]["combatStash"], 2)
	)

	# ── 45-archie-raid-assist ────────────────────────────────────────────

	run_case("can_assist_raid_requires_relation_at_or_above_the_raid_assist_threshold", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["contacts"]["archie"]["relation"] = 49
		assert_true(not Contacts.can_assist_raid("archie"), "relation 49 < raidAssistThreshold 50")

		GameState.state["contacts"]["archie"]["relation"] = 50
		assert_true(Contacts.can_assist_raid("archie"), "relation meets the threshold exactly")
	)

	run_case("can_assist_raid_still_requires_can_join_combats_own_gates", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["relation"] = 100
		assert_true(not Contacts.can_assist_raid("archie"), "high relation alone isn't enough -- not recruited yet")

		GameState.state["contacts"]["archie"]["recruited"] = true
		assert_true(Contacts.can_assist_raid("archie"), "recruited and relation met")

		GameState.state["world"]["day"] = 5
		GameState.state["contacts"]["archie"]["koCooldownUntilDay"] = 7
		assert_true(not Contacts.can_assist_raid("archie"), "still on KO cooldown, regardless of relation")
	)

	run_case("can_assist_raid_is_false_for_a_contact_with_no_raid_assist_threshold_defined", func():
		GameState.reset()
		GameState.state["contacts"]["des"]["recruited"] = true
		GameState.state["contacts"]["des"]["relation"] = 1000
		assert_true(not Contacts.can_assist_raid("des"), "des has no combat kit -- can_join_combat excludes him regardless")
	)

	run_case("recruited_james_joins_combat_with_his_kit_and_full_dial", func():
		GameState.reset()
		GameState.state["contacts"]["james"]["recruited"] = true
		assert_true(Contacts.can_join_combat("james"))
		var ally := Contacts.build_combat_ally("james")
		assert_eq(ally["hpMax"], 35)
		assert_eq(ally["attackMin"], 2)
		assert_eq(ally["attackMax"], 4)
		assert_eq(ally["speed"], 6)
		assert_eq(ally["stash"], 0)
		assert_eq(ally["dialCharges"], 3)
	)

	run_case("dial_charges_carry_over_between_fights_and_refill_daily", func():
		GameState.reset()
		var ally := Contacts.build_combat_ally("james")
		ally["dialCharges"] = 1
		Contacts.replenish_after_combat([ally])
		assert_eq(GameState.state["contacts"]["james"]["dialCharges"], 1, "spent casts stay spent after the fight")
		assert_eq(GameState.state["contacts"]["archie"]["dialCharges"], 0, "archie has no dial")

		Contacts.daily_dial_regen()
		assert_eq(GameState.state["contacts"]["james"]["dialCharges"], 3)
		assert_eq(GameState.state["contacts"]["archie"]["dialCharges"], 0, "no combatDial -- nothing to refill")
	)

	run_case("old_save_with_kitless_james_adopts_the_new_combat_kit", func():
		GameState.reset()
		var save: Dictionary = GameState.state.duplicate(true)
		var james: Dictionary = save["contacts"]["james"]
		for key in ["combatHpMax", "combatHp", "combatAttackMin", "combatAttackMax", "combatSpeed", "koCooldownDays"]:
			james[key] = 0
		james.erase("dialCharges")
		save["contacts"]["archie"]["combatHp"] = 7
		var out: Dictionary = SaveManager.backfill_defaults(save)
		assert_eq(out["contacts"]["james"]["combatHpMax"], 35)
		assert_eq(out["contacts"]["james"]["combatSpeed"], 6)
		assert_eq(out["contacts"]["james"]["dialCharges"], 3)
		assert_eq(out["contacts"]["archie"]["combatHp"], 7, "a contact that already had a kit is untouched")
	)
