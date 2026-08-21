extends "res://tests/test_base.gd"


func _has_notification(text: String) -> bool:
	for n in GameState.state["notifications"]:
		if n["text"] == text:
			return true
	return false


# M1-LONDON D5's `choices` card type — installed as a synthetic event so
# these tests don't depend on ticket 09's real content. Returns the
# original GameData.EVENTS so callers can restore it afterward.
func _install_choice_event() -> Dictionary:
	var original_events: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_choice_event"] = {
		"id": "test_choice_event",
		"cards": [
			{ "type": "narration", "label": null, "speaker": null, "text": "Setup" },
			{
				"type": "choice", "label": null, "speaker": null, "text": "Pick one",
				"choices": [
					{ "label": "Give £20", "effects": [{ "op": "add", "path": "player.cash", "value": -20 }], "result_text": "You handed over the cash." },
					{ "label": "Walk away", "effects": [], "result_text": "You walked away." },
				],
			},
			{ "type": "narration", "label": null, "speaker": null, "text": "Aftermath" },
		],
		"on_complete": [{ "op": "set_flag", "flag": "choiceEventDone", "value": true }],
	}
	return original_events


# vein-raiding ticket 02: fixtures for a faction-owned site, mirroring
# test_factions.gd's own _faction_vein_of/_site_with_vein helpers.
static func _faction_vein_of(level: int, ore_type: String, security: String = "none", faction_id: String = "collective") -> Dictionary:
	return {
		"id": "fv_test", "factionId": faction_id, "oreType": ore_type, "growth": 20 * level - 10,
		"rampantDays": 0, "security": security,
		"location": "Test St, nowhere", "claimedOnDay": 0, "district": "shoreditch",
		"siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
	}


static func _site_with_vein(id: String, vein: Dictionary) -> Dictionary:
	return {
		"id": id, "district": "shoreditch", "tier": "fair", "oreType": vein["oreType"],
		"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": vein,
		"hasNaturalVein": false,
	}


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

		var found_notif := false
		for n in GameState.state["notifications"]:
			if n["text"] == "Test notification":
				found_notif = true
		assert_true(found_notif, "notify")
		assert_eq(GameState.state["flags"]["tutorialStage"], "free", "set_stage")
		assert_eq(GameState.state["currentScreen"], "home", "set_screen")

		GameData.EVENTS = original_events
	)

	# Ticket 12: set_screen targeting "phone" specifically must also reset
	# phoneNav to its home view (same as every other route-to-phone-home
	# call site) -- a plain set_screen to anything else must leave phoneNav
	# alone.
	run_case("set_screen_to_phone_also_resets_phoneNav_to_home", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "messages"
		GameState.state["phoneNav"]["selectedAxis"] = "economic"
		GameState.state["phoneNav"]["confirmingNewGame"] = true
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_set_screen_phone"] = {
			"id": "test_set_screen_phone",
			"cards": [{ "type": "narration", "label": null, "speaker": null, "text": "Card 1" }],
			"on_complete": [{ "op": "set_screen", "screen": "phone" }],
		}

		Events.start_event("test_set_screen_phone")
		Events.advance()

		assert_eq(GameState.state["currentScreen"], "phone", "set_screen should navigate to phone")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "targeting phone should reset phoneNav to the grid")
		assert_eq(GameState.state["phoneNav"]["selectedAxis"], null, "phoneNav.selectedAxis should reset")
		assert_eq(GameState.state["phoneNav"]["confirmingNewGame"], false, "phoneNav.confirmingNewGame should reset")

		GameData.EVENTS = original_events
	)

	run_case("set_screen_to_a_non_phone_target_leaves_phoneNav_untouched", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "messages"
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_set_screen_hq"] = {
			"id": "test_set_screen_hq",
			"cards": [{ "type": "narration", "label": null, "speaker": null, "text": "Card 1" }],
			"on_complete": [{ "op": "set_screen", "screen": "hq" }],
		}

		Events.start_event("test_set_screen_hq")
		Events.advance()

		assert_eq(GameState.state["currentScreen"], "hq", "set_screen should navigate to hq")
		assert_eq(GameState.state["phoneNav"]["app"], "messages", "a non-phone target must not touch phoneNav")

		GameData.EVENTS = original_events
	)

	# ── grant_vein retired (vein-raiding ticket 09) ─────────────────────

	run_case("grant_vein_is_no_longer_a_valid_effect_op", func():
		assert_true(not GameData.VALID_EFFECT_OPS.has("grant_vein"), "grant_vein must not be in the effect-op vocabulary")

		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_grant_vein_retired"] = {
			"id": "test_grant_vein_retired",
			"cards": [{ "type": "narration", "label": null, "speaker": null, "text": "Card 1" }],
			"on_complete": [
				{ "op": "grant_vein", "vein": { "oreType": "fate", "growth": 20, "rampantDays": 0, "security": "none", "location": "Test St, nowhere", "district": "shoreditch", "hospitability": { "tier": "fair", "bonuses": [] } } },
			],
		}

		var errors := GameData.validate_tables(GameData.snapshot())
		var relevant := errors.filter(func(e): return e.begins_with("events.test_grant_vein_retired"))
		assert_true(relevant.size() > 0, "an event referencing grant_vein should fail validation")

		GameData.EVENTS = original_events
	)

	# ── grant_vein_with_site (D7) ────────────────────────────────────────

	run_case("grant_vein_with_site_creates_a_matching_claimed_site_and_links_it", func():
		GameState.reset()
		var world_day: int = GameState.state["world"]["day"]
		Events.apply_effects([
			{ "op": "grant_vein_with_site", "vein": { "oreType": "time", "growth": 20, "rampantDays": 0, "security": "none", "location": "Whitechapel, behind the old brewery", "district": "whitechapel", "hospitability": { "tier": "fair", "bonuses": [] } } },
		])

		assert_eq(GameState.state["world"]["sites"].size(), 1, "creates exactly one site")
		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_eq(site["district"], "whitechapel")
		assert_eq(site["tier"], "fair")
		assert_eq(site["oreType"], "time")
		assert_eq(site["bonuses"], [])
		assert_true(site["claimed"])
		assert_eq(site["factionVein"], null)
		assert_true(not site["hasNaturalVein"])
		assert_eq(site["discoveredDay"], world_day)

		assert_eq(GameState.state["player"]["veins"].size(), 1, "appends a vein")
		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_eq(vein["siteId"], site["id"], "vein.siteId links back to the created site")
		assert_eq(vein["claimedOnDay"], world_day)
	)

	run_case("grant_vein_with_site_derives_site_tier_and_bonuses_from_hospitability", func():
		GameState.reset()
		Events.apply_effects([
			{ "op": "grant_vein_with_site", "vein": { "oreType": "physics", "growth": 20, "rampantDays": 0, "security": "none", "location": "Test St, nowhere", "district": "camden", "hospitability": { "tier": "rich", "bonuses": ["yield"] } } },
		])
		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_eq(site["tier"], "rich")
		assert_eq(site["bonuses"], ["yield"])
	)

	# ── tutorial_cultivate (D6) ───────────────────────────────────────────

	run_case("tutorial_cultivate_adds_gain_to_the_whitechapel_time_vein", func():
		GameState.reset()
		GameState.state["player"]["cultivatingSkill"] = 1
		Events.apply_effects([
			{ "op": "grant_vein_with_site", "vein": { "oreType": "time", "growth": 20, "rampantDays": 0, "security": "none", "location": "Whitechapel, behind the old brewery", "district": "whitechapel", "hospitability": { "tier": "fair", "bonuses": [] } } },
		])
		Events.apply_effects([{ "op": "tutorial_cultivate" }])

		var vein: Dictionary = GameState.state["player"]["veins"][0]
		var expected_gain: int = Cultivating.cultivate_gain(1, 20, Cultivating.ceiling(vein))
		assert_eq(vein["growth"], 20 + expected_gain, "growth increases by cultivate_gain, no roll involved")
	)

	run_case("tutorial_cultivate_can_push_growth_up_from_any_starting_point", func():
		GameState.reset()
		GameState.state["player"]["cultivatingSkill"] = 2
		Events.apply_effects([
			{ "op": "grant_vein_with_site", "vein": { "oreType": "time", "growth": 60, "rampantDays": 0, "security": "none", "location": "Whitechapel, behind the old brewery", "district": "whitechapel", "hospitability": { "tier": "fair", "bonuses": [] } } },
		])
		Events.apply_effects([{ "op": "tutorial_cultivate" }])

		var vein: Dictionary = GameState.state["player"]["veins"][0]
		assert_true(vein["growth"] > 60, "tutorial_cultivate should raise growth above its starting point")
	)

	run_case("tutorial_cultivate_is_a_no_op_with_no_matching_vein", func():
		GameState.reset()
		var snapshot: Dictionary = GameState.deep_copy(GameState.state["player"])
		Events.apply_effects([{ "op": "tutorial_cultivate" }])
		assert_eq(GameState.state["player"], snapshot, "nothing to cultivate, nothing crashes or mutates")
	)

	run_case("is_awaiting_choice_true_only_on_an_unresolved_choice_card", func():
		GameState.reset()
		var original_events := _install_choice_event()

		Events.start_event("test_choice_event")
		assert_true(not Events.is_awaiting_choice(), "card 0 is a narration card")

		Events.advance()
		assert_true(Events.is_awaiting_choice(), "card 1 is an unresolved choice card")

		Events.choose(0)
		assert_true(not Events.is_awaiting_choice(), "choosing resolves the choice card")

		GameData.EVENTS = original_events
	)

	run_case("advance_is_a_no_op_while_awaiting_a_choice", func():
		GameState.reset()
		var original_events := _install_choice_event()

		Events.start_event("test_choice_event")
		Events.advance()
		assert_eq(GameState.state["event"]["cardIndex"], 1, "sanity: on the choice card")

		Events.advance()
		assert_eq(GameState.state["event"]["cardIndex"], 1, "advance() must not skip an unresolved choice card")

		GameData.EVENTS = original_events
	)

	run_case("choose_applies_effects_and_records_result_text", func():
		GameState.reset()
		var original_events := _install_choice_event()

		Events.start_event("test_choice_event")
		Events.advance()  # -> choice card
		var cash_before: int = GameState.state["player"]["cash"]

		Events.choose(0)  # "Give £20"
		assert_eq(GameState.state["player"]["cash"], cash_before - 20, "the picked choice's effects should apply")

		var cards := Events.revealed_cards()
		assert_eq(cards.size(), 3, "choice card + its synthetic resolution card, revealed so far")
		assert_eq(cards[1]["type"], "choice")
		assert_eq(cards[2]["type"], "resolution")
		assert_eq(cards[2]["text"], "You handed over the cash.", "resolution card carries the picked choice's result_text")

		GameData.EVENTS = original_events
	)

	run_case("choosing_the_other_option_applies_its_own_effects_and_text", func():
		GameState.reset()
		var original_events := _install_choice_event()

		Events.start_event("test_choice_event")
		Events.advance()
		var cash_before: int = GameState.state["player"]["cash"]

		Events.choose(1)  # "Walk away" — no effects
		assert_eq(GameState.state["player"]["cash"], cash_before, "no-effect choice should leave cash untouched")
		assert_eq(Events.revealed_cards()[2]["text"], "You walked away.")

		GameData.EVENTS = original_events
	)

	run_case("continue_after_choosing_proceeds_to_the_next_card_and_on_complete_still_runs", func():
		GameState.reset()
		var original_events := _install_choice_event()

		Events.start_event("test_choice_event")
		Events.advance()       # -> choice card
		Events.choose(1)       # resolve it
		Events.advance()       # -> "Aftermath" card
		assert_eq(GameState.state["event"]["cardIndex"], 2, "Continue after a resolved choice moves to the next real card")

		Events.advance()       # last card -> on_complete
		assert_eq(GameState.state["event"], null, "event should clear after the final continue")
		assert_true(GameState.state["flags"]["choiceEventDone"], "on_complete still runs after a choice card mid-event")

		GameData.EVENTS = original_events
	)

	run_case("rewind_undoes_a_choice_pick", func():
		GameState.reset()
		var original_events := _install_choice_event()
		GameState.state["player"]["inventory"]["rewind"] = 1

		Events.start_event("test_choice_event")
		Events.advance()  # -> choice card
		var cash_before: int = GameState.state["player"]["cash"]

		Events.choose(0)  # "Give £20"
		assert_eq(GameState.state["player"]["cash"], cash_before - 20)

		var result := Events.rewind()
		assert_true(result["ok"])
		assert_eq(GameState.state["player"]["cash"], cash_before, "rewind should undo the choice's effects")
		assert_true(Events.is_awaiting_choice(), "rewind should un-resolve the choice card")

		GameData.EVENTS = original_events
	)

	# ── vein-raiding ticket 02: stealth_check / start_raid_combat /
	# claim_raid_vein / loot_raid_vein ops ───────────────────────────────

	run_case("stealth_check_op_branches_into_on_success_with_a_saturated_bonus", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [_site_with_vein("s1", _faction_vein_of(1, "time"))]
		Events.apply_effects([{
			"op": "stealth_check", "site_id": "s1", "consumable_bonus": 5.0,
			"on_success": [{ "op": "set_flag", "flag": "stealthOutcome", "value": "success" }],
			"on_caught": [{ "op": "set_flag", "flag": "stealthOutcome", "value": "caught" }],
		}])
		assert_eq(GameState.state["flags"]["stealthOutcome"], "success", "a saturated bonus should always succeed")
		assert_true(GameState.state["player"]["stealthXP"] > 0, "the check should award stealth XP")
	)

	run_case("stealth_check_op_branches_into_on_caught_with_a_floored_bonus", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [_site_with_vein("s1", _faction_vein_of(5, "fate", "guarded"))]
		Events.apply_effects([{
			"op": "stealth_check", "site_id": "s1", "consumable_bonus": -5.0,
			"on_success": [{ "op": "set_flag", "flag": "stealthOutcome", "value": "success" }],
			"on_caught": [{ "op": "set_flag", "flag": "stealthOutcome", "value": "caught" }],
		}])
		assert_eq(GameState.state["flags"]["stealthOutcome"], "caught", "a floored bonus should always be caught")
	)

	run_case("start_raid_combat_op_launches_combat_with_event_raid_context", func():
		GameState.reset()
		var vein := _faction_vein_of(2, "physics", "warded")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		Events.apply_effects([{ "op": "start_raid_combat", "site_id": "s1" }])
		assert_true(GameState.state["combat"]["active"], "combat should be launched")
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_EVENT_RAID)
		assert_eq(GameState.state["combat"]["veinId"], "fv_test")
	)

	run_case("claim_raid_vein_op_transfers_ownership", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [_site_with_vein("s1", _faction_vein_of(1, "time"))]
		Events.apply_effects([{ "op": "claim_raid_vein", "site_id": "s1" }])
		assert_eq(GameState.state["player"]["veins"].size(), 1, "the vein should transfer to the player")
		assert_eq(GameState.state["world"]["sites"][0]["factionVein"], null, "the site should no longer be faction-owned")
	)

	run_case("loot_raid_vein_op_grants_ore_without_transferring_ownership", func():
		GameState.reset()
		var vein := _faction_vein_of(1, "life")
		GameState.state["world"]["sites"] = [_site_with_vein("s1", vein)]
		var ore_before: int = GameState.state["player"]["orichalchum"].get("life", 0)
		Events.apply_effects([{ "op": "loot_raid_vein", "site_id": "s1", "caught": true }])
		assert_true(GameState.state["player"]["orichalchum"]["life"] > ore_before, "loot should grant ore")
		assert_eq(GameState.state["player"]["veins"].size(), 0, "ownership should not transfer")
		assert_true(GameState.state["world"]["sites"][0]["factionVein"] != null, "the site should still be faction-owned")
	)

	run_case("start_home_raid_combat_op_launches_home_raid_combat", func():
		GameState.reset()
		Events.start_event("home_raid_intro")
		for i in range(GameData.EVENTS["home_raid_intro"]["cards"].size()):
			Events.advance()
		assert_eq(GameState.state["event"], null, "event should clear")
		assert_true(GameState.state["combat"]["active"], "start_home_raid_combat should launch combat")
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_HOME_RAID)
	)

	run_case("home_raid_debrief_loss_unlocks_hq_and_fires_workbench_notification", func():
		GameState.reset()
		Events.start_event("home_raid_debrief_loss")
		for i in range(GameData.EVENTS["home_raid_debrief_loss"]["cards"].size()):
			Events.advance()
		assert_true(GameState.state["flags"]["homeUnlocked"], "debrief_loss: homeUnlocked")
		assert_true(_has_notification("HQ's workbench is open now."), "debrief_loss: HQ nudge notification")
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
		assert_eq(GameState.state["currentScreen"], "phone", "intro: -> phone home")

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
		assert_eq(GameState.state["currentScreen"], "phone", "james_meeting: -> phone home, no longer hq")
		assert_true(not _has_notification("Crafting unlocked. Try the workbench in HQ."), "james_meeting: no longer fires the HQ notification")

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
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_HOME_RAID)

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
		assert_eq(granted["growth"], GameData.VEIN_GROWTH["seedGrowth"], "granted vein: seedGrowth")
		assert_eq(granted["district"], "whitechapel", "granted vein: whitechapel")
		assert_eq(GameState.state["currentScreen"], "phone", "debrief: -> phone home")
		assert_true(_has_notification("HQ's workbench is open now."), "debrief: HQ nudge notification")

		# D7: the granted vein comes with a matching claimed site.
		assert_eq(GameState.state["world"]["sites"].size(), 1, "debrief: creates exactly one site")
		var granted_site: Dictionary = GameState.state["world"]["sites"][0]
		assert_eq(granted_site["district"], "whitechapel", "granted site: whitechapel")
		assert_eq(granted_site["tier"], "fair", "granted site: fair tier")
		assert_eq(granted_site["bonuses"], [], "granted site: no bonuses")
		assert_true(granted_site["claimed"], "granted site: claimed")
		assert_eq(granted_site["factionVein"], null, "granted site: not faction-claimed")
		assert_eq(granted["siteId"], granted_site["id"], "granted vein: siteId links back to the granted site")

		# 5b. Cultivating tutorial (D6) — real play starts this by tapping its
		# Network-map contact pin (M1.5 T13, systems/map_pins.gd); drive it
		# directly here since this test has no screen tree.
		assert_true(GameState.state["flags"]["archiePartnerSeen"] and not GameState.state["flags"]["cultivationTutorialSeen"])
		var archie_relation_before_cultivation: int = GameState.state["contacts"]["archie"]["relation"]
		var growth_before: int = granted["growth"]
		var expected_gain: int = Cultivating.cultivate_gain(GameState.state["player"]["cultivatingSkill"], growth_before, Cultivating.ceiling(granted))
		Events.start_event("archie_cultivation")
		for i in range(GameData.EVENTS["archie_cultivation"]["cards"].size()):
			Events.advance()
		assert_true(GameState.state["flags"]["cultivationTutorialSeen"], "archie_cultivation: cultivationTutorialSeen")
		assert_eq(GameState.state["contacts"]["archie"]["relation"], archie_relation_before_cultivation + 2, "archie_cultivation: archie relation +2")
		assert_eq(granted["growth"], growth_before + expected_gain, "archie_cultivation: tutorial_cultivate added cultivate_gain growth")
		assert_eq(GameState.state["currentScreen"], "map", "archie_cultivation: -> map")

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
