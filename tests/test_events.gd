extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const Preferences := preload("res://systems/preferences.gd")


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


# ui-vision.md §11: a choice event whose first option carries an "image"
# key, followed by a card with no "image" key (sticky) and a card that
# explicitly clears it (image: null) -- Events.current_image_path()'s own
# fixtures.
func _install_image_choice_event() -> Dictionary:
	var original_events: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_image_choice_event"] = {
		"id": "test_image_choice_event",
		"cards": [
			{ "type": "narration", "label": null, "speaker": null, "text": "Setup" },
			{
				"type": "choice", "label": null, "speaker": null, "text": "Pick one",
				"choices": [
					{ "label": "With image", "effects": [], "result_text": "Resolved with image.", "image": "res://assets/combat/dummy/attack.png" },
					{ "label": "No image", "effects": [], "result_text": "Resolved with no image." },
				],
			},
			{ "type": "narration", "label": null, "speaker": null, "text": "Sticky" },
			{ "type": "narration", "label": null, "speaker": null, "text": "Cleared", "image": null },
		],
		"on_complete": [{ "op": "set_flag", "flag": "imageChoiceEventDone", "value": true }],
	}
	return original_events


# vein-raiding ticket 02: fixtures for a faction-owned site (paired with
# Fixtures.site_with_vein).
static func _faction_vein_of_level(level: int, ore_type: String, security: String = "none", faction_id: String = "collective") -> Dictionary:
	return {
		"id": "fv_test", "factionId": faction_id, "oreType": ore_type, "growth": 20 * level - 10,
		"rampantDays": 0, "security": security,
		"location": "Test St, nowhere", "claimedOnDay": 0, "district": "shoreditch",
		"siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
	}


func run() -> void:
	run_case("schema_all_event_files_validate", func():
		var errors := GameData.validate_tables(GameData.snapshot())
		var relevant := errors.filter(func(e): return e.begins_with("events"))
		assert_eq(relevant, [], "event tables should validate cleanly: %s" % str(relevant))
		assert_true(not GameData.EVENTS.is_empty(), "no event files were loaded from data/events/")
	)

	# Bugfixes ticket (col_a1_intro Continue softlock): screens only swap on
	# EventBus.screen_changed, fired by Nav.go_to() -- Events.advance() never
	# calls that on its own, so on_complete is the only place left to
	# navigate away once an event finishes. An event that forgets a
	# "set_screen" op (or a self-navigating op like "start_home_raid_combat")
	# leaves the EventScreen mounted forever with a Continue button that now
	# dereferences a null state.event: it visibly does nothing. This is a
	# future-facing guard -- any event authored from now on that forgets to
	# navigate away fails schema validation immediately, the same way
	# grant_vein_is_no_longer_a_valid_effect_op below catches a retired op.
	run_case("schema_validation_flags_an_event_whose_on_complete_never_navigates_away", func():
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_stuck_on_complete"] = {
			"id": "test_stuck_on_complete",
			"cards": [{ "type": "narration", "label": null, "speaker": null, "text": "Card 1" }],
			"on_complete": [{ "op": "set_flag", "flag": "someFlag", "value": true }],
		}

		var errors := GameData.validate_tables(GameData.snapshot())
		var relevant := errors.filter(func(e): return e.begins_with("events.test_stuck_on_complete"))
		assert_true(relevant.size() > 0, "an on_complete with no set_screen (and no self-navigating op) should fail validation")

		GameData.EVENTS = original_events
	)

	run_case("schema_validation_accepts_an_on_complete_ending_in_set_screen", func():
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_navigates_fine"] = {
			"id": "test_navigates_fine",
			"cards": [{ "type": "narration", "label": null, "speaker": null, "text": "Card 1" }],
			"on_complete": [{ "op": "set_flag", "flag": "someFlag", "value": true }, { "op": "set_screen", "screen": "map" }],
		}

		var errors := GameData.validate_tables(GameData.snapshot())
		var relevant := errors.filter(func(e): return e.begins_with("events.test_navigates_fine"))
		assert_eq(relevant, [], "an on_complete ending in set_screen should validate cleanly")

		GameData.EVENTS = original_events
	)

	run_case("schema_validation_accepts_an_on_complete_that_only_launches_home_raid_combat", func():
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_combat_navigates_itself"] = {
			"id": "test_combat_navigates_itself",
			"cards": [{ "type": "narration", "label": null, "speaker": null, "text": "Card 1" }],
			"on_complete": [{ "op": "start_home_raid_combat" }],
		}

		var errors := GameData.validate_tables(GameData.snapshot())
		var relevant := errors.filter(func(e): return e.begins_with("events.test_combat_navigates_itself"))
		assert_eq(relevant, [], "start_home_raid_combat navigates itself (systems/combat.gd's _start_combat) -- no separate set_screen needed")

		GameData.EVENTS = original_events
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
		assert_eq(Crafting.inventory_qty("timePearl"), 2, "add_item")
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
		# cultivation-refining ticket 03: cultivate_gain is a random uniform
		# roll, so this checks skill 1's [6,10] range rather than an exact value.
		assert_true(vein["growth"] >= 20 + 6 and vein["growth"] <= 20 + 10, "growth increases by cultivate_gain (skill 1: [6,10]), no roll to fail")
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

	# ── current_image_path (ui-vision.md §11) ───────────────────────────

	run_case("current_image_path_is_null_when_nothing_has_specified_one", func():
		GameState.reset()
		var original_events := _install_image_choice_event()

		Events.start_event("test_image_choice_event")
		assert_eq(Events.current_image_path(), null, "the opening narration card sets no image")

		GameData.EVENTS = original_events
	)

	run_case("current_image_path_carries_through_a_picked_choices_image_via_the_resolution_card", func():
		GameState.reset()
		var original_events := _install_image_choice_event()

		Events.start_event("test_image_choice_event")
		Events.advance()  # -> choice card
		assert_eq(Events.current_image_path(), null, "the choice prompt itself sets no image")

		Events.choose(0)  # "With image"
		assert_eq(Events.current_image_path(), "res://assets/combat/dummy/attack.png", "the picked choice's image should surface via its synthetic resolution card")

		GameData.EVENTS = original_events
	)

	run_case("current_image_path_stays_sticky_then_clears_on_an_explicit_null", func():
		GameState.reset()
		var original_events := _install_image_choice_event()

		Events.start_event("test_image_choice_event")
		Events.advance()
		Events.choose(0)
		Events.advance()  # -> "Sticky" card, no "image" key at all
		assert_eq(Events.current_image_path(), "res://assets/combat/dummy/attack.png", "omitting the key means no change")

		Events.advance()  # -> "Cleared" card, image: null
		assert_eq(Events.current_image_path(), null, "an explicit null should clear it")

		GameData.EVENTS = original_events
	)

	run_case("current_image_path_ignores_the_unpicked_choice_option", func():
		GameState.reset()
		var original_events := _install_image_choice_event()

		Events.start_event("test_image_choice_event")
		Events.advance()
		Events.choose(1)  # "No image" -- the option that never sets one
		assert_eq(Events.current_image_path(), null, "picking the imageless option should not surface the other option's image")

		GameData.EVENTS = original_events
	)

	# ── is_vn_mode (event-images ticket 02) ─────────────────────────────

	run_case("is_vn_mode_false_when_no_card_in_the_event_has_an_image", func():
		GameState.reset()
		var original_events := _install_choice_event()  # test_choice_event: no card carries "image"

		Events.start_event("test_choice_event")
		assert_true(not Events.is_vn_mode(), "an event with no image anywhere should not be VN mode")

		GameData.EVENTS = original_events
	)

	run_case("is_vn_mode_true_for_an_image_buried_deep_in_the_array_not_just_the_first_card", func():
		GameState.reset()
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_vn_deep_image"] = {
			"id": "test_vn_deep_image",
			"cards": [
				{ "type": "narration", "label": null, "speaker": null, "text": "1" },
				{ "type": "narration", "label": null, "speaker": null, "text": "2" },
				{ "type": "narration", "label": null, "speaker": null, "text": "3" },
				{ "type": "narration", "label": null, "speaker": null, "text": "4, with an image", "image": "res://assets/combat/dummy/attack.png" },
			],
			"on_complete": [{ "op": "set_screen", "screen": "map" }],
		}

		Events.start_event("test_vn_deep_image")
		assert_true(Events.is_vn_mode(), "an image on a card deep in the array should still make the whole event VN mode")

		GameData.EVENTS = original_events
	)

	run_case("is_vn_mode_is_computed_from_the_full_static_definition_not_revealed_so_far_cards", func():
		GameState.reset()
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_vn_static_scan"] = {
			"id": "test_vn_static_scan",
			"cards": [
				{ "type": "narration", "label": null, "speaker": null, "text": "no image yet" },
				{ "type": "narration", "label": null, "speaker": null, "text": "still none" },
				{ "type": "narration", "label": null, "speaker": null, "text": "here it is", "image": "res://assets/combat/dummy/attack.png" },
			],
			"on_complete": [{ "op": "set_screen", "screen": "map" }],
		}

		Events.start_event("test_vn_static_scan")
		assert_true(Events.is_vn_mode(), "VN mode must be true from card 0, before revealed_cards() ever reaches the wired card")

		GameData.EVENTS = original_events
	)

	run_case("is_vn_mode_true_when_only_a_choice_options_nested_image_is_set_no_top_level_card_has_one", func():
		GameState.reset()
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_vn_nested_choice_image_only"] = {
			"id": "test_vn_nested_choice_image_only",
			"cards": [
				{ "type": "narration", "label": null, "speaker": null, "text": "Setup" },
				{
					"type": "choice", "label": null, "speaker": null, "text": "Pick one",
					"choices": [
						{ "label": "With image", "effects": [], "result_text": "Resolved with image.", "image": "res://assets/combat/dummy/attack.png" },
						{ "label": "No image", "effects": [], "result_text": "Resolved with no image." },
					],
				},
			],
			"on_complete": [{ "op": "set_screen", "screen": "map" }],
		}

		Events.start_event("test_vn_nested_choice_image_only")
		assert_true(Events.is_vn_mode(), "a choice option's own image should count toward VN-mode detection even with no top-level card image anywhere, since current_image_path() could surface it once picked")

		GameData.EVENTS = original_events
	)

	run_case("is_vn_mode_ignores_a_choice_option_that_carries_no_image_when_no_other_option_has_one_either", func():
		GameState.reset()
		var original_events := _install_choice_event()  # neither "Give £20" nor "Walk away" carries an "image"

		Events.start_event("test_choice_event")
		assert_true(not Events.is_vn_mode(), "a choice card with no image on any of its options should not itself trigger VN mode")

		GameData.EVENTS = original_events
	)

	run_case("is_vn_mode_treats_an_explicit_null_image_as_not_counting", func():
		GameState.reset()
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_vn_null_image_only"] = {
			"id": "test_vn_null_image_only",
			"cards": [
				{ "type": "narration", "label": null, "speaker": null, "text": "no change" },
				{ "type": "narration", "label": null, "speaker": null, "text": "explicit clear", "image": null },
			],
			"on_complete": [{ "op": "set_screen", "screen": "map" }],
		}

		Events.start_event("test_vn_null_image_only")
		assert_true(not Events.is_vn_mode(), "an explicit null image key should not itself trigger VN mode")

		GameData.EVENTS = original_events
	)

	# event-images ticket 01: the pilot content wiring on the real "intro"
	# event -- four real cards (authoring-order indices 1, 2, 6, 14) each
	# set a different res://assets/events/intro/<n>.png, proving both the
	# static-image path and the sticky-until-next-entry swap against real
	# data, not a synthetic fixture, and that the wired files actually
	# exist on disk (docs/adr/0005-event-image-asset-contract.md).
	run_case("intro_pilot_images_swap_at_their_wired_cards_and_resolve_to_real_files", func():
		GameState.reset()
		Events.start_event("intro")
		assert_eq(Events.current_image_path(), null, "opening card sets no image")

		var wired_at := { 1: "res://assets/events/intro/1.jpg", 2: "res://assets/events/intro/2.jpg", 6: "res://assets/events/intro/3.png", 14: "res://assets/events/intro/4.png" }
		var expected: Variant = null
		var card_count: int = GameData.EVENTS["intro"]["cards"].size()
		for i in range(card_count - 1):
			Events.advance()
			var card_index: int = GameState.state["event"]["cardIndex"]
			if wired_at.has(card_index):
				expected = wired_at[card_index]
				assert_true(ResourceLoader.exists(expected), "wired image should exist on disk: %s" % expected)
			assert_eq(Events.current_image_path(), expected, "card %d's image should be whatever the last wired card set" % card_index)
	)

	run_case("event_card_images_are_discovered_by_event_id_and_one_based_card_index", func():
		GameState.reset()
		Events.start_event("buyer")

		var wired_at := {
			0: "res://assets/events/buyer/buyer_card1.jpg",
			6: "res://assets/events/buyer/buyer_card7.jpg",
			8: "res://assets/events/buyer/buyer_card9.jpg",
		}
		var expected: String = wired_at[0]
		assert_true(Events.is_vn_mode(), "a convention-named image anywhere in the event should enable VN mode from card 1")
		assert_eq(Events.current_image_path(), expected, "card 1 should discover buyer_card1.jpg")

		var card_count: int = GameData.EVENTS["buyer"]["cards"].size()
		for i in range(card_count - 1):
			Events.advance()
			var card_index: int = GameState.state["event"]["cardIndex"]
			if wired_at.has(card_index):
				expected = wired_at[card_index]
			assert_eq(Events.current_image_path(), expected, "card %d should use the latest convention-named image" % (card_index + 1))
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
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }

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

	run_case("rewind_keeps_the_live_presentation_preferences", func():
		GameState.reset()
		var original_events := _install_choice_event()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }

		Events.start_event("test_choice_event")
		Events.advance()  # -> choice card
		Events.choose(0)  # snapshot taken with mapDarkMode absent
		Preferences.set_map_dark_mode(true)
		Preferences.set_reduced_motion(true)

		assert_true(Events.rewind()["ok"])
		assert_eq(GameState.state["meta"].get("mapDarkMode"), true, "rewind never flips the Map dark mode")
		assert_eq(GameState.state["meta"].get("reducedMotion"), true, "rewind never flips reduced motion")

		GameData.EVENTS = original_events
	)

	# ── vein-raiding ticket 02: stealth_check / start_raid_combat /
	# claim_raid_vein / loot_raid_vein ops ───────────────────────────────

	run_case("stealth_check_op_branches_into_on_success_with_a_saturated_bonus", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", _faction_vein_of_level(1, "time"))]
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
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", _faction_vein_of_level(5, "fate", "guarded"))]
		Events.apply_effects([{
			"op": "stealth_check", "site_id": "s1", "consumable_bonus": -5.0,
			"on_success": [{ "op": "set_flag", "flag": "stealthOutcome", "value": "success" }],
			"on_caught": [{ "op": "set_flag", "flag": "stealthOutcome", "value": "caught" }],
		}])
		assert_eq(GameState.state["flags"]["stealthOutcome"], "caught", "a floored bonus should always be caught")
	)

	run_case("start_raid_combat_op_launches_combat_with_event_raid_context", func():
		GameState.reset()
		var vein := _faction_vein_of_level(2, "physics", "warded")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
		Events.apply_effects([{ "op": "start_raid_combat", "site_id": "s1" }])
		assert_true(GameState.state["combat"]["active"], "combat should be launched")
		assert_eq(GameState.state["combat"]["context"], Combat.CONTEXT_EVENT_RAID)
		assert_eq(GameState.state["combat"]["veinId"], "fv_test")
	)

	run_case("claim_raid_vein_op_transfers_ownership", func():
		GameState.reset()
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", _faction_vein_of_level(1, "time"))]
		Events.apply_effects([{ "op": "claim_raid_vein", "site_id": "s1" }])
		assert_eq(GameState.state["player"]["veins"].size(), 1, "the vein should transfer to the player")
		assert_eq(GameState.state["world"]["sites"][0]["factionVein"], null, "the site should no longer be faction-owned")
	)

	run_case("loot_raid_vein_op_grants_ore_without_transferring_ownership", func():
		GameState.reset()
		var vein := _faction_vein_of_level(1, "life")
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
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
		assert_true(Fixtures.has_notification("HQ's workbench is open now."), "debrief_loss: HQ nudge notification")
	)

	run_case("rewind_restores_full_state_without_corruption", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		Events.start_event("intro")
		var snapshot_before: Dictionary = GameState.deep_copy(GameState.state)
		Events.advance()
		assert_eq(GameState.state["event"]["cardIndex"], 1, "sanity: advanced to card 1")

		var result := Events.rewind()
		assert_true(result["ok"], "rewind should succeed with a rewind consumable in hand")
		assert_eq(GameState.state["event"]["cardIndex"], 0, "cardIndex restored to 0")
		assert_eq(Crafting.inventory_qty("rewind"), 0, "the rewind consumable should be spent")

		var expected: Dictionary = GameState.deep_copy(snapshot_before)
		# Crafting.inventory_remove() erases a bucket once it empties out.
		expected["player"]["inventory"]["rewind"] = {}
		expected.erase("notifications")  # rewind pushes its own "time unspools" notification
		var actual: Dictionary = GameState.deep_copy(GameState.state)
		actual.erase("notifications")
		assert_eq(actual, expected, "the entire state tree (minus notifications, minus the spent charge) should exactly match the pre-advance snapshot")
	)

	run_case("rewind_pops_one_frame_at_a_time", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 2 }
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
		# 83-contacts-archie-james-sms-port: ARCHIE_SMS_1's content now lands
		# in the generic message thread, ending in a pendingMessages entry
		# that starts james_meeting on Continue.
		var archie_thread_after_buyer: Array = GameState.state["messages"]["archie"]
		assert_eq(archie_thread_after_buyer.size(), 3, "buyer: all 3 ARCHIE_SMS_1 lines pushed (2 push_message + the pending entry's own text)")
		assert_eq(Messages.pending_for("archie").size(), 1, "buyer: one pending entry queued")
		assert_eq(Messages.pending_for("archie")[0]["kind"], "james_meeting", "buyer: pending entry starts james_meeting")

		# 3. James meeting (SMS thread 1 has no state effects of its own)
		var day: int = GameState.state["world"]["day"]
		Events.start_event("james_meeting")
		for i in range(GameData.EVENTS["james_meeting"]["cards"].size()):
			Events.advance()
		assert_eq(Crafting.inventory_qty("timePearl"), 2, "james_meeting: +2 timePearl")
		assert_true(GameState.state["flags"]["metJames"], "james_meeting: metJames")
		assert_true(GameState.state["flags"]["craftingUnlocked"], "james_meeting: craftingUnlocked")
		assert_true(GameState.state["contacts"]["james"]["unlocked"], "james_meeting: james unlocked")
		assert_eq(GameState.state["contacts"]["james"]["relation"], 10, "james_meeting: james relation +10")
		assert_eq(GameState.state["flags"]["tutorialStage"], "archie_craft_chat", "james_meeting: stage")
		assert_eq(GameState.state["world"]["archieChatUnlockDay"], day + 1, "james_meeting: archieChatUnlockDay = day+1")
		assert_eq(GameState.state["currentScreen"], "phone", "james_meeting: -> phone home, no longer hq")
		assert_true(not Fixtures.has_notification("Crafting unlocked. Try the workbench in HQ."), "james_meeting: no longer fires the HQ notification")
		# 83-contacts-archie-james-sms-port: the archie_craft_chat trigger now
		# arrives as a pendingMessages entry instead of a bare tutorialStage check.
		var craft_chat_pending := Messages.pending_for("archie")
		assert_true(craft_chat_pending.size() > 0 and craft_chat_pending.back()["kind"] == "archie_craft_chat", "james_meeting: queues the archie_craft_chat pending entry")

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
		GameState.state["combat"]["enemies"][GameState.state["combat"]["selection"]["index"]]["hp"] = 1
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
		assert_true(Fixtures.has_notification("HQ's workbench is open now."), "debrief: HQ nudge notification")

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
		var skill: int = GameState.state["player"]["cultivatingSkill"]
		var min_gain: int = Cultivating.cultivate_min_gain(skill)
		var max_gain: int = Cultivating.cultivate_max_gain(skill)
		Events.start_event("archie_cultivation")
		for i in range(GameData.EVENTS["archie_cultivation"]["cards"].size()):
			Events.advance()
		assert_true(GameState.state["flags"]["cultivationTutorialSeen"], "archie_cultivation: cultivationTutorialSeen")
		assert_eq(GameState.state["contacts"]["archie"]["relation"], archie_relation_before_cultivation + 2, "archie_cultivation: archie relation +2")
		# cultivation-refining ticket 03: cultivate_gain is a random uniform roll,
		# so this checks the skill-dependent range rather than an exact value.
		assert_true(granted["growth"] >= growth_before + min_gain and granted["growth"] <= growth_before + max_gain, "archie_cultivation: tutorial_cultivate added a cultivate_gain-range growth")
		assert_eq(GameState.state["currentScreen"], "map", "archie_cultivation: -> map")

		# 6. Post-tutorial motion events
		Events.start_event("archie_motion")
		for i in range(GameData.EVENTS["archie_motion"]["cards"].size()):
			Events.advance()
		assert_true(GameState.state["flags"]["archieMotionEventSeen"], "archie_motion: seen")
		# 83-contacts-archie-james-sms-port: the "visit James" trigger now
		# arrives as a pendingMessages entry on James's own thread.
		var james_motion_pending := Messages.pending_for("james")
		assert_true(james_motion_pending.size() > 0 and james_motion_pending.back()["kind"] == "james_motion", "archie_motion: queues the james_motion pending entry")

		var james_relation_before: int = GameState.state["contacts"]["james"]["relation"]
		Events.start_event("james_motion")
		for i in range(GameData.EVENTS["james_motion"]["cards"].size()):
			Events.advance()
		assert_true(GameState.state["flags"]["jamesMotionEventSeen"], "james_motion: seen")
		assert_true(GameState.state["flags"]["enhancementUnlocked"], "james_motion: enhancementUnlocked")
		assert_eq(GameState.state["contacts"]["james"]["relation"], james_relation_before + 1, "james_motion: james relation +1")
	)
