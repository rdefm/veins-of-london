extends "res://tests/test_base.gd"

const FACTION_IDS := ["collective", "firm", "guild", "network", "conclave"]


func run() -> void:
	run_case("every_faction_has_key_members_a_speaker_gift_prefs_and_two_sample_favours", func():
		GameState.reset()
		for faction_id in FACTION_IDS:
			var members: Array = KeyMembers.members(faction_id)
			assert_true(not members.is_empty(), "%s has key members" % faction_id)
			var speaker := KeyMembers.speaker_for(faction_id)
			assert_true(members.any(func(m): return m["contactId"] == speaker), "%s speaker is one of its members" % faction_id)
			for m in members:
				assert_true(GameState.state["contacts"].has(m["contactId"]), "%s is a contact" % m["contactId"])
				assert_eq(m["giftPrefs"].size(), 2, "%s has two gift prefs" % m["id"])
				for item in m["giftPrefs"]:
					assert_true(GameData.RECIPES.has(item), "%s gift pref %s is a real item" % [m["id"], item])
			assert_true(GameData.FACTIONS[faction_id]["sampleFavours"].size() >= 2, "%s has sample favours" % faction_id)
	)

	run_case("speaker_for_resolves_each_faction_to_its_voice", func():
		GameState.reset()
		assert_eq(KeyMembers.speaker_for("collective"), "nadia")
		assert_eq(KeyMembers.speaker_for("network"), "handler")
		assert_eq(KeyMembers.speaker_for("firm"), "lusk")
		assert_eq(KeyMembers.speaker_for("guild"), "ingram")
		assert_eq(KeyMembers.speaker_for("conclave"), "fairweather")
		assert_eq(KeyMembers.faction_of("hakim"), "collective")
		assert_eq(KeyMembers.faction_of("archie"), "")
	)

	run_case("first_message_unlocks_a_new_key_member_with_their_intro_first", func():
		GameState.reset()
		assert_true(not GameState.state["contacts"]["lusk"]["unlocked"], "locked at start")
		assert_true(not Contacts.directory_ids().has("lusk"), "not in the directory yet")

		assert_true(KeyMembers.send("firm", "A word."), "sent")
		assert_true(GameState.state["contacts"]["lusk"]["unlocked"], "unlocked by the message")
		var thread: Array = GameState.state["messages"]["lusk"]
		assert_eq(thread.size(), 2, "intro then the message")
		assert_eq(thread[0]["text"], KeyMembers.member("lusk")["intro"])
		assert_eq(thread[1]["text"], "A word.")
		assert_eq(Contacts.display_name("lusk"), "Lusk")
		assert_true(Contacts.directory_ids().has("lusk"), "listed once unlocked")

		KeyMembers.send("firm", "Another.")
		assert_eq(GameState.state["messages"]["lusk"].size(), 3, "no second intro")
	)

	run_case("a_kind_queues_an_actionable_pending_message", func():
		GameState.reset()
		KeyMembers.send("conclave", "Call us.", "some_event", { "x": 1 })
		var pending := Messages.pending_for("fairweather")
		assert_eq(pending.size(), 1)
		assert_eq(pending[0]["kind"], "some_event")
		assert_eq(pending[0]["payload"], { "x": 1 })
	)

	run_case("a_quest_gated_speaker_stays_silent_until_its_questline_unlocks_them", func():
		GameState.reset()
		assert_true(not KeyMembers.send("collective", "Numbers."), "Nadia not met yet")
		assert_true(not GameState.state["contacts"]["nadia"]["unlocked"], "still locked")
		assert_true(not GameState.state["messages"].has("nadia"), "nothing sent")

		GameState.state["contacts"]["nadia"]["unlocked"] = true
		assert_true(KeyMembers.send("collective", "Numbers."), "speaks once met")
		assert_eq(GameState.state["messages"]["nadia"].size(), 1, "no intro for an existing contact")
	)

	run_case("directory_ids_is_sorted_by_display_name", func():
		GameState.reset()
		for contact_id in ["des", "handler", "james", "fairweather"]:
			GameState.state["contacts"][contact_id]["unlocked"] = true
		assert_eq(Contacts.directory_ids(), ["archie", "des", "fairweather", "handler", "james"])
	)


	run_case("every_faction_has_a_speaker_and_lieutenant_with_opposing_outlooks", func():
		GameState.reset()
		for faction_id in FACTION_IDS:
			var contenders := KeyMembers.contenders(faction_id)
			assert_eq(contenders.size(), 2, "%s has two contenders" % faction_id)
			assert_eq(contenders[0]["seat"], "speaker")
			assert_eq(contenders[1]["seat"], "lieutenant")
			assert_true(contenders[0]["outlook"] != contenders[1]["outlook"], "%s outlooks oppose" % faction_id)
			for m in contenders:
				assert_true(m["outlook"] in ["hawk", "dove"])
				assert_true(str(m["want"]) != "", "%s has a want" % m["id"])
				assert_true(m.has("aggressionMult") and m.has("relationBaseline"))
			assert_eq(contenders[0]["contactId"], GameData.FACTIONS[faction_id]["speaker"], "speaker leads at start")
		assert_eq(KeyMembers.member("hakim")["seat"], "member")
		assert_eq(KeyMembers.contenders("collective").map(func(m): return m["id"]), ["nadia", "des"])
		for contact_id in ["mercer", "wren", "courier", "pryce"]:
			assert_true(KeyMembers.member(contact_id).get("proseReview", false), "%s flagged" % contact_id)
	)

	run_case("new_game_has_standing_and_leader_and_speaker_follows_the_leader", func():
		GameState.reset()
		var col: Dictionary = GameState.state["factions"]["collective"]
		assert_eq(col["leader"], "nadia")
		assert_eq(col["standing"], { "nadia": 50, "des": 50 })
		col["leader"] = "des"
		assert_eq(KeyMembers.speaker_for("collective"), "des")
		assert_eq(KeyMembers.leader_of("collective"), "des")
	)

	run_case("old_saves_backfill_standing_and_leader_from_the_speaker", func():
		GameState.reset()
		var save := { "factions": { "firm": { "relation": 3 } } }
		SaveManager._migrate_key_member_standing(save)
		assert_eq(save["factions"]["firm"]["leader"], "lusk")
		assert_eq(save["factions"]["firm"]["standing"], { "lusk": 50, "mercer": 50 })
		save["factions"]["firm"]["standing"]["lusk"] = 80
		save["factions"]["firm"]["leader"] = "mercer"
		SaveManager._migrate_key_member_standing(save)
		assert_eq(save["factions"]["firm"]["standing"]["lusk"], 80, "kept")
		assert_eq(save["factions"]["firm"]["leader"], "mercer", "kept")
	)
