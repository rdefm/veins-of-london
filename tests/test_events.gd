extends "res://tests/test_base.gd"


func run() -> void:
	run_case("schema_all_9_event_files_and_sms_threads_validate", func():
		var errors := GameData.validate_tables(GameData.snapshot())
		var relevant := errors.filter(func(e): return e.begins_with("events") or e.begins_with("sms"))
		assert_eq(relevant, [], "event/sms tables should validate cleanly: %s" % str(relevant))

		for expected_id in GameData.EVENT_IDS:
			assert_true(GameData.EVENTS.has(expected_id), "missing event file '%s'" % expected_id)
		assert_true(GameData.SMS_THREADS.has("archie_1"), "missing SMS thread archie_1")
		assert_true(GameData.SMS_THREADS.has("archie_2"), "missing SMS thread archie_2")
	)

	run_case("start_event_sets_state_and_screen", func():
		GameState.reset()
		Events.start_event("intro")
		assert_eq(GameState.state["event"]["eventId"], "intro")
		assert_eq(GameState.state["event"]["cardIndex"], 0)
		assert_eq(GameState.state["event"]["snapshots"], [])
		assert_eq(GameState.state["currentScreen"], "event")
	)

	run_case("advance_reveals_next_card_and_pushes_a_snapshot", func():
		GameState.reset()
		Events.start_event("intro")
		Events.advance()
		assert_eq(GameState.state["event"]["cardIndex"], 1, "should advance to card 1")
		assert_eq(GameState.state["event"]["snapshots"].size(), 1, "should push one snapshot")
	)

	run_case("revealed_cards_grows_with_cardIndex", func():
		GameState.reset()
		Events.start_event("intro")
		assert_eq(Events.revealed_cards().size(), 1, "only card 0 revealed at the start")
		Events.advance()
		assert_eq(Events.revealed_cards().size(), 2, "advancing reveals one more card")
	)

	run_case("apply_effects_covers_every_op", func():
		GameState.reset()
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_all_ops"] = {
			"id": "test_all_ops",
			"cards": [{ "type": "narration", "label": null, "speaker": null, "text": "Card 1" }],
			"on_complete": [
				{ "op": "set_flag", "flag": "metArchie", "value": true },
				{ "op": "add", "path": "player.cash", "value": 10 },
				{ "op": "add", "path": "contacts.james.unlocked", "value": true },
				{ "op": "add", "path": "world.archieChatUnlockDay", "value": 1 },
				{ "op": "add_ore", "type": "time", "qty": 5 },
				{ "op": "add_item", "item": "timePearl", "qty": 2 },
				{ "op": "relation", "contact": "archie", "value": 3 },
				{ "op": "grant_vein", "vein": { "oreType": "fate", "level": 2, "devBar": 1, "charged": true, "chargeBlocks": 0, "security": "none", "location": "Test St, nowhere", "district": "shoreditch", "hospitability": { "tier": "fair", "bonuses": [] } } },
				{ "op": "notify", "text": "Test notification" },
				{ "op": "set_stage", "value": "free" },
				{ "op": "set_screen", "screen": "home" },
			],
		}

		var cash_before: int = GameState.state["player"]["cash"]
		var archie_relation_before: int = GameState.state["contacts"]["archie"]["relation"]
		var world_day: int = GameState.state["world"]["day"]

		Events.start_event("test_all_ops")
		Events.advance()  # only card -> final continue -> on_complete + clear

		assert_eq(GameState.state["event"], null, "event should clear after the final continue")
		assert_true(GameState.state["flags"]["metArchie"], "set_flag")
		assert_eq(GameState.state["player"]["cash"], cash_before + 10, "add: numeric + numeric sums")
		assert_eq(GameState.state["contacts"]["james"]["unlocked"], true, "add: non-numeric target assigns outright")
		assert_eq(GameState.state["world"]["archieChatUnlockDay"], world_day + 1, "add: null world.archieChatUnlockDay means 'today + value'")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 5, "add_ore")
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], 2, "add_item")
		assert_eq(GameState.state["contacts"]["archie"]["relation"], archie_relation_before + 3, "relation")

		assert_eq(GameState.state["player"]["veins"].size(), 1, "grant_vein appends a vein")
		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(vein["oreType"], "fate", "grant_vein carries the template fields")
		assert_eq(vein["levelLabel"], GameData.VEIN_LEVELS["2"]["label"], "grant_vein derives levelLabel from level")
		assert_eq(vein["claimedOnDay"], world_day, "grant_vein derives claimedOnDay from world.day")
		assert_true(String(vein["id"]).length() > 0, "grant_vein derives a fresh id")

		var found_notif := false
		for n in GameState.state["notifications"]:
			if n["text"] == "Test notification":
				found_notif = true
		assert_true(found_notif, "notify")
		assert_eq(GameState.state["flags"]["tutorialStage"], "free", "set_stage")
		assert_eq(GameState.state["currentScreen"], "home", "set_screen")

		GameData.EVENTS = original_events
	)

	run_case("start_home_raid_combat_op_launches_home_raid_combat", func():
		GameState.reset()
		Events.start_event("home_raid_intro")
		for i in range(GameData.EVENTS["home_raid_intro"]["cards"].size()):
			Events.advance()
		assert_eq(GameState.state["event"], null, "event should clear")
		assert_true(GameState.state["combat"]["active"], "start_home_raid_combat should launch combat")
		assert_eq(GameState.state["combat"]["context"], "home_raid")
	)

	run_case("rewind_restores_full_state_without_corruption", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = 1
		Events.start_event("intro")
		var snapshot_before: Dictionary = GameState.deep_copy(GameState.state)
		Events.advance()
		assert_eq(GameState.state["event"]["cardIndex"], 1, "sanity: advanced to card 1")

		var result := Events.rewind()
		assert_true(result["ok"], "rewind should succeed with a rewind consumable in hand")
		assert_eq(GameState.state["event"]["cardIndex"], 0, "cardIndex restored to 0")
		assert_eq(GameState.state["player"]["inventory"]["rewind"], 0, "the rewind consumable should be spent")

		var expected: Dictionary = GameState.deep_copy(snapshot_before)
		expected["player"]["inventory"]["rewind"] = 0
		expected.erase("notifications")  # rewind pushes its own "time unspools" notification
		var actual: Dictionary = GameState.deep_copy(GameState.state)
		actual.erase("notifications")
		assert_eq(actual, expected, "the entire state tree (minus notifications, minus the spent charge) should exactly match the pre-advance snapshot")
	)

	run_case("rewind_pops_one_frame_at_a_time", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = 2
		Events.start_event("intro")
		Events.advance()  # -> card 1
		Events.advance()  # -> card 2
		assert_eq(GameState.state["event"]["cardIndex"], 2)

		Events.rewind()
		assert_eq(GameState.state["event"]["cardIndex"], 1, "one rewind steps back exactly one card")

		Events.rewind()
		assert_eq(GameState.state["event"]["cardIndex"], 0, "a second rewind steps back another card")
	)

	run_case("rewind_blocked_with_no_snapshots_or_no_resource", func():
		GameState.reset()
		Events.start_event("intro")
		var no_snapshots := Events.rewind()
		assert_true(not no_snapshots["ok"], "no snapshots yet -> nothing to rewind")

		Events.advance()
		var no_resource := Events.rewind()
		assert_true(not no_resource["ok"], "a snapshot exists but no rewind consumable/device -> blocked")
	)

	run_case("full_tutorial_playthrough_lands_every_r311_change", func():
		GameState.reset()

		# 1. Intro
		Events.start_event("intro")
		for i in range(GameData.EVENTS["intro"]["cards"].size()):
			Events.advance()
		assert_true(GameState.state["flags"]["metArchie"], "intro: metArchie")
		assert_eq(GameState.state["flags"]["tutorialStage"], "buyer_event", "intro: stage")
		assert_eq(GameState.state["currentScreen"], "home", "intro: -> home")

		# 2. Buyer event
		var cash_before: int = GameState.state["player"]["cash"]
		Events.start_event("buyer")
		for i in range(GameData.EVENTS["buyer"]["cards"].size()):
			Events.advance()
		assert_eq(GameState.state["player"]["cash"], cash_before + 40, "buyer: cash +40")
		assert_true(GameState.state["flags"]["buyerEventSeen"], "buyer: buyerEventSeen")
		assert_eq(GameState.state["flags"]["tutorialStage"], "sms_archie", "buyer: stage")

		# 3. James meeting (SMS thread 1 has no state effects of its own)
		var day: int = GameState.state["world"]["day"]
		Events.start_event("james_meeting")
		for i in range(GameData.EVENTS["james_meeting"]["cards"].size()):
			Events.advance()
		assert_eq(GameState.state["player"]["inventory"]["timePearl"], 2, "james_meeting: +2 timePearl")
		assert_true(GameState.state["flags"]["metJames"], "james_meeting: metJames")
		assert_true(GameState.state["flags"]["craftingUnlocked"], "james_meeting: craftingUnlocked")
		assert_true(GameState.state["contacts"]["james"]["unlocked"], "james_meeting: james unlocked")
		assert_eq(GameState.state["contacts"]["james"]["relation"], 10, "james_meeting: james relation +10")
		assert_eq(GameState.state["flags"]["tutorialStage"], "archie_craft_chat", "james_meeting: stage")
		assert_eq(GameState.state["world"]["archieChatUnlockDay"], day + 1, "james_meeting: archieChatUnlockDay = day+1")
		assert_eq(GameState.state["currentScreen"], "crafting", "james_meeting: -> crafting")

		# 4. Archie falafel chat
		var ore_before: int = GameState.state["player"]["orichalchum"].get("time", 0)
		var archie_relation_before: int = GameState.state["contacts"]["archie"]["relation"]
		Events.start_event("archie_craft_chat")
		for i in range(GameData.EVENTS["archie_craft_chat"]["cards"].size()):
			Events.advance()
		assert_true(GameState.state["flags"]["archieCraftChatSeen"], "archie_craft_chat: seen")
		assert_true(GameState.state["flags"]["canSellConsumables"], "archie_craft_chat: canSellConsumables")
		assert_eq(GameState.state["flags"]["tutorialStage"], "free", "archie_craft_chat: stage")
		assert_eq(GameState.state["contacts"]["archie"]["relation"], archie_relation_before + 5, "archie_craft_chat: archie relation +5")
		assert_eq(GameState.state["player"]["orichalchum"]["time"], ore_before + 20, "archie_craft_chat: +20 time ore")
		assert_true(GameState.state["flags"]["homeRaidEventPending"], "archie_craft_chat: homeRaidEventPending")

		# 5. Home raid chain (R§3.8) — home.gd's _ready() fires this on next
		# visit; drive it the same way here since this test has no screen tree.
		assert_true(GameState.state["flags"]["homeRaidEventPending"] and not GameState.state["flags"]["homeRaidEventSeen"])
		Events.start_event("home_raid_intro")
		for i in range(GameData.EVENTS["home_raid_intro"]["cards"].size()):
			Events.advance()
		assert_true(GameState.state["combat"]["active"], "home_raid_intro: combat started")
		assert_eq(GameState.state["combat"]["context"], "home_raid")

		# Force a deterministic win.
		GameState.state["combat"]["enemy"]["hp"] = 1
		GameState.state["player"]["attackMin"] = 999
		GameState.state["player"]["attackMax"] = 999
		Rng.set_seed(1)
		Combat.player_attack()
		assert_eq(GameState.state["combat"]["outcome"], "win", "sanity: forced win")

		var veins_before: int = GameState.state["player"]["veins"].size()
		Combat.exit_combat()
		assert_eq(GameState.state["event"]["eventId"], "home_raid_debrief_win", "win should chain into the win debrief")

		for i in range(GameData.EVENTS["home_raid_debrief_win"]["cards"].size()):
			Events.advance()
		assert_true(GameState.state["flags"]["homeRaidEventSeen"], "debrief: homeRaidEventSeen")
		assert_true(GameState.state["flags"]["homeRaidWon"], "debrief: homeRaidWon")
		assert_true(GameState.state["flags"]["archiePartnerSeen"], "debrief: archiePartnerSeen")
		assert_true(GameState.state["flags"]["homeUnlocked"], "debrief: homeUnlocked")
		assert_true(GameState.state["flags"]["securityContactUnlocked"], "debrief: securityContactUnlocked")
		assert_eq(GameState.state["player"]["veins"].size(), veins_before + 1, "debrief: grants a vein")
		var granted: Dictionary = GameState.state["player"]["veins"][veins_before]
		assert_eq(granted["oreType"], "time", "granted vein: time-type")
		assert_eq(granted["level"], 1, "granted vein: Lv1")
		assert_eq(granted["district"], "whitechapel", "granted vein: whitechapel")
		assert_eq(GameState.state["currentScreen"], "home", "debrief: -> home")

		# 6. Post-tutorial motion events
		Events.start_event("archie_motion")
		for i in range(GameData.EVENTS["archie_motion"]["cards"].size()):
			Events.advance()
		assert_true(GameState.state["flags"]["archieMotionEventSeen"], "archie_motion: seen")

		var james_relation_before: int = GameState.state["contacts"]["james"]["relation"]
		Events.start_event("james_motion")
		for i in range(GameData.EVENTS["james_motion"]["cards"].size()):
			Events.advance()
		assert_true(GameState.state["flags"]["jamesMotionEventSeen"], "james_motion: seen")
		assert_true(GameState.state["flags"]["enhancementUnlocked"], "james_motion: enhancementUnlocked")
		assert_eq(GameState.state["contacts"]["james"]["relation"], james_relation_before + 1, "james_motion: james relation +1")
	)
