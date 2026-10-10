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


# A one-card event with `at` timing; returns the original GameData.EVENTS.
func _install_timed_event(block: String, advance: bool) -> Dictionary:
	var original_events: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_timed_event"] = {
		"id": "test_timed_event",
		"at": { "block": block, "advance": advance },
		"cards": [{ "type": "narration", "label": null, "speaker": null, "text": "Later." }],
		"on_complete": [{ "op": "set_screen", "screen": "phone" }],
	}
	return original_events


# A choice card whose first option is a check at fixed odds `p` (no mods,
# clamp [0, 1]) and whose second is a plain option.
static func _check_choice_card(p: float) -> Dictionary:
	return {
		"type": "choice", "label": null, "speaker": null, "text": "Push your luck?",
		"choices": [
			{
				"id": "push", "label": "Push for more",
				"check": { "base": p, "mods": [], "min": 0.0, "max": 1.0, "show": "odds" },
				"success": { "result_text": "It worked.", "effects": [{ "op": "add", "path": "player.cash", "value": 30 }], "goto": null },
				"fail": { "result_text": "It didn't.", "effects": [{ "op": "set_flag", "flag": "checkFailed", "value": true }], "goto": null },
			},
			{ "id": "leave", "label": "Leave it", "effects": [], "result_text": "You left it." },
		],
	}


func _install_check_event(p: float) -> Dictionary:
	var original_events: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_check_event"] = {
		"id": "test_check_event",
		"cards": [
			{ "type": "narration", "label": null, "speaker": null, "text": "Setup" },
			_check_choice_card(p),
			{ "type": "narration", "label": null, "speaker": null, "text": "Aftermath" },
		],
		"on_complete": [],
	}
	return original_events


# The check event with an optional Prophet's Breath mod (+0.25) on its check option.
func _install_item_check_event(p: float, consume: bool) -> Dictionary:
	var original_events := _install_check_event(p)
	GameData.EVENTS["test_check_event"]["cards"][1]["choices"][0]["check"]["mods"] = [
		{ "item": "prophetsBreath", "optional": true, "consume": consume, "add": 0.25, "label": "Breath" },
	]
	return original_events


# The check event with a multi-attempt check: each success adds one Time
# Pearl, result text keyed by success count for 0 and 2 (others fall back).
func _install_attempts_check_event(p: float, attempts: int) -> Dictionary:
	var original_events := _install_check_event(p)
	var option: Dictionary = GameData.EVENTS["test_check_event"]["cards"][1]["choices"][0]
	option["check"]["attempts"] = attempts
	option["check"]["perSuccess"] = [{ "op": "add_item", "item": "timePearl", "qty": 1 }]
	option["bySuccesses"] = {
		"0": { "result_text": "None took.", "effects": [{ "op": "set_flag", "flag": "noneTook", "value": true }] },
		"2": { "result_text": "Two took.", "effects": [] },
	}
	return original_events


# Gated options and short branches: option 0 needs £50 (disabled with a
# reason) and jumps to card 3; option 1 needs secretFlag (hidden); option 2
# is plain; option 3 is a sure check whose success jumps to card 3. Card 2
# is the branch a goto skips.
func _install_gated_event() -> Dictionary:
	var original_events: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_gated_event"] = {
		"id": "test_gated_event",
		"cards": [
			{ "type": "narration", "label": null, "speaker": null, "text": "Setup" },
			{
				"type": "choice", "label": null, "speaker": null, "text": "Pick one",
				"choices": [
					{ "id": "pay", "label": "Pay", "requires": { "cash": { "atLeast": 50 }, "display": "disable", "reason": "Needs £50" }, "effects": [{ "op": "add", "path": "player.cash", "value": -50 }], "result_text": "Paid.", "goto": 3 },
					{ "id": "secret", "label": "Secret", "requires": { "flag": "secretFlag" }, "effects": [], "result_text": "Secret." },
					{ "id": "walk", "label": "Walk", "effects": [], "result_text": "Walked." },
					{
						"id": "push", "label": "Push",
						"check": { "base": 1.0, "mods": [], "min": 0.0, "max": 1.0 },
						"success": { "result_text": "Pushed through.", "effects": [], "goto": 3 },
						"fail": { "result_text": "Stalled.", "effects": [], "goto": null },
					},
				],
			},
			{ "type": "narration", "label": null, "speaker": null, "text": "Branch", "image": "res://branch.png" },
			{ "type": "narration", "label": null, "speaker": null, "text": "Rejoin" },
		],
		"on_complete": [],
	}
	return original_events


static func _texts(cards: Array) -> Array:
	return cards.map(func(c: Dictionary) -> String: return c["text"])


# ui-vision.md §11: a choice event whose first option carries an "image"
# key, followed by a card with no "image" key (sticky) and a card that
# explicitly clears it (image: null) -- Events.current_image_path()'s own
# fixtures.
# Card-level routing (R§3.9a "Goto"): card 0 routes to 3 on routeFlag, else
# to 2; card 2 ends the event; card 3 jumps to 5. Cards 1 and 4 are skipped.
func _install_routed_event() -> Dictionary:
	var original_events: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_routed_event"] = {
		"id": "test_routed_event",
		"cards": [
			{ "type": "narration", "label": null, "speaker": null, "text": "Setup", "goto": [{ "if": { "flag": "routeFlag" }, "card": 3 }, { "card": 2 }] },
			{ "type": "narration", "label": null, "speaker": null, "text": "Skipped", "image": "res://skipped.png" },
			{ "type": "narration", "label": null, "speaker": null, "text": "Else", "image": "res://else.png", "end": true },
			{ "type": "narration", "label": null, "speaker": null, "text": "Flagged", "image": "res://flagged.png", "goto": 5 },
			{ "type": "narration", "label": null, "speaker": null, "text": "Never", "image": "res://never.png" },
			{ "type": "narration", "label": null, "speaker": null, "text": "Finale" },
		],
		"on_complete": [{ "op": "set_flag", "flag": "routedDone", "value": true }],
	}
	return original_events


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

	run_case("schema_validation_accepts_an_on_complete_that_only_chains_into_another_event", func():
		var original_events: Dictionary = GameData.EVENTS
		GameData.EVENTS = GameData.EVENTS.duplicate()
		GameData.EVENTS["test_chains_on"] = {
			"id": "test_chains_on",
			"cards": [{ "type": "narration", "label": null, "speaker": null, "text": "Card 1" }],
			"on_complete": [{ "op": "start_event", "event": "intro" }],
		}

		var errors := GameData.validate_tables(GameData.snapshot())
		var relevant := errors.filter(func(e): return e.begins_with("events.test_chains_on"))
		assert_eq(relevant, [], "start_event navigates to the chained event -- no separate set_screen needed")

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

	# ── choice memory (opening-choices spec "Choice memory") ────────────

	run_case("choose_records_the_option_id_under_event_id_and_card_index", func():
		GameState.reset()
		var original_events := _install_choice_event()
		GameData.EVENTS["test_choice_event"] = GameData.EVENTS["test_choice_event"].duplicate(true)
		GameData.EVENTS["test_choice_event"]["cards"][1]["choices"][0]["id"] = "pay"

		Events.start_event("test_choice_event")
		Events.advance()
		assert_eq(Events.choice_id("test_choice_event", 1), null, "nothing recorded before the pick")
		Events.choose(0)
		assert_eq(Events.choice_id("test_choice_event", 1), "pay")
		assert_eq(GameState.state["flags"]["choices"]["test_choice_event"]["1"], { "id": "pay" })

		GameData.EVENTS = original_events
	)

	run_case("choose_records_the_index_for_an_option_without_an_id", func():
		GameState.reset()
		var original_events := _install_choice_event()

		Events.start_event("test_choice_event")
		Events.advance()
		Events.choose(1)
		assert_eq(Events.choice_id("test_choice_event", 1), "1", "falls back to the option's index")
		assert_eq(Events.choice_record("test_choice_event", 1), { "id": "1" })
		assert_eq(Events.choice_record("test_choice_event", 0), {}, "unpicked card reads empty")
		assert_eq(Events.choice_record("no_such_event", 1), {}, "unknown event reads empty")

		GameData.EVENTS = original_events
	)

	run_case("rewind_removes_the_choice_record", func():
		GameState.reset()
		var original_events := _install_choice_event()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }

		Events.start_event("test_choice_event")
		Events.advance()
		Events.choose(0)
		assert_eq(Events.choice_id("test_choice_event", 1), "0")
		assert_true(Events.rewind()["ok"])
		assert_eq(Events.choice_id("test_choice_event", 1), null, "rewind past the pick drops its record")

		GameData.EVENTS = original_events
	)

	run_case("choice_memory_backfills_empty_for_saves_missing_it", func():
		var save: Dictionary = GameState.new_game_state()
		save["flags"].erase("choices")
		var backfilled: Dictionary = SaveManager.backfill_defaults(save)
		assert_eq(backfilled["flags"]["choices"], {})
	)

	# ── checks (opening-choices spec "Event engine") ────────────────────

	run_case("check_odds_is_empty_for_a_plain_option", func():
		GameState.reset()
		var original_events := _install_choice_event()
		Events.start_event("test_choice_event")
		Events.advance()
		assert_eq(Events.check_odds(0), {})
		GameData.EVENTS = original_events
	)

	run_case("odds_are_base_plus_mods_clamped_to_min_and_max", func():
		GameState.reset()
		GameState.state["flags"]["testFlag"] = true
		var mod := { "flag": "testFlag", "add": 0.3, "label": "Flag" }
		assert_almost_eq(Events.odds_for({ "base": 0.4, "mods": [mod], "min": 0.0, "max": 1.0 })["probability"], 0.7, 0.0001, "unclamped sum")
		assert_almost_eq(Events.odds_for({ "base": 0.8, "mods": [mod], "min": 0.05, "max": 0.95 })["probability"], 0.95, 0.0001, "clamped to max")
		assert_almost_eq(Events.odds_for({ "base": 0.0, "mods": [], "min": 0.05, "max": 0.95 })["probability"], 0.05, 0.0001, "clamped to min")
		assert_almost_eq(Events.odds_for({ "base": 0.0 })["probability"], GameData.EVENT_CHECKS["defaultMin"], 0.0001, "default min from data")
		var odds := Events.odds_for({ "base": 0.4, "mods": [mod, { "flag": "unsetFlag", "add": 0.2, "label": "Unset" }] })
		assert_eq(odds["mods"].size(), 1, "only matching mods are listed")
		assert_eq(odds["mods"][0]["label"], "Flag")
		assert_almost_eq(odds["mods"][0]["delta"], 0.3, 0.0001)
		assert_eq(odds["show"], "odds", "show defaults to odds")
	)

	run_case("flag_mod_applies_only_when_the_flag_is_set", func():
		GameState.reset()
		var check := { "base": 0.4, "mods": [{ "flag": "testFlag", "add": 0.15, "label": "F" }], "min": 0.0, "max": 1.0 }
		assert_almost_eq(Events.odds_for(check)["probability"], 0.4, 0.0001, "unset")
		GameState.state["flags"]["testFlag"] = true
		assert_almost_eq(Events.odds_for(check)["probability"], 0.55, 0.0001, "set")
	)

	run_case("choice_mod_reads_choice_memory_by_id_or_index", func():
		GameState.reset()
		var by_id := { "base": 0.4, "mods": [{ "choice": { "event": "intro", "card": 6, "option": "brave" }, "add": 0.1, "label": "C" }], "min": 0.0, "max": 1.0 }
		var by_index := { "base": 0.4, "mods": [{ "choice": { "event": "intro", "card": 6, "option": 1 }, "add": 0.1, "label": "C" }], "min": 0.0, "max": 1.0 }
		assert_almost_eq(Events.odds_for(by_id)["probability"], 0.4, 0.0001, "no memory")
		GameState.state["flags"]["choices"]["intro"] = { "6": { "id": "brave" } }
		assert_almost_eq(Events.odds_for(by_id)["probability"], 0.5, 0.0001, "matching id")
		assert_almost_eq(Events.odds_for(by_index)["probability"], 0.4, 0.0001, "other option")
		GameState.state["flags"]["choices"]["intro"] = { "6": { "id": "1" } }
		assert_almost_eq(Events.odds_for(by_index)["probability"], 0.5, 0.0001, "matching index")
	)

	run_case("path_mod_adds_per_point_above_the_floor", func():
		GameState.reset()
		var check := { "base": 0.4, "mods": [{ "path": "player.craftingSkill", "perPoint": 0.05, "above": 1, "label": "P" }], "min": 0.0, "max": 1.0 }
		GameState.state["player"]["craftingSkill"] = 1
		assert_almost_eq(Events.odds_for(check)["probability"], 0.4, 0.0001, "at the floor")
		assert_eq(Events.odds_for(check)["mods"], [], "zero delta isn't listed")
		GameState.state["player"]["craftingSkill"] = 4
		assert_almost_eq(Events.odds_for(check)["probability"], 0.55, 0.0001, "3 points above")
	)

	run_case("relation_mod_applies_at_least_the_threshold", func():
		GameState.reset()
		var check := { "base": 0.4, "mods": [{ "relation": "archie", "atLeast": 15, "add": 0.1, "label": "R" }], "min": 0.0, "max": 1.0 }
		GameState.state["contacts"]["archie"]["relation"] = 14
		assert_almost_eq(Events.odds_for(check)["probability"], 0.4, 0.0001, "below")
		GameState.state["contacts"]["archie"]["relation"] = 15
		assert_almost_eq(Events.odds_for(check)["probability"], 0.5, 0.0001, "at threshold")
	)

	run_case("cash_mod_applies_at_least_the_threshold", func():
		GameState.reset()
		var check := { "base": 0.4, "mods": [{ "cash": { "atLeast": 50 }, "add": -0.05, "label": "£" }], "min": 0.0, "max": 1.0 }
		GameState.state["player"]["cash"] = 49
		assert_almost_eq(Events.odds_for(check)["probability"], 0.4, 0.0001, "below")
		GameState.state["player"]["cash"] = 50
		assert_almost_eq(Events.odds_for(check)["probability"], 0.35, 0.0001, "at threshold, signed delta")
		assert_almost_eq(Events.odds_for(check)["mods"][0]["delta"], -0.05, 0.0001)
	)

	run_case("hint_words_follow_the_data_thresholds", func():
		assert_eq(Events.hint_word(0.65), "Likely")
		assert_eq(Events.hint_word(0.64), "Even")
		assert_eq(Events.hint_word(0.35), "Even")
		assert_eq(Events.hint_word(0.34), "Risky")
		assert_eq(Events.hint_word(0.05), "Risky")
	)

	run_case("a_sure_check_resolves_success_text_effects_and_memory", func():
		GameState.reset()
		var original_events := _install_check_event(1.0)
		var cash_before: int = GameState.state["player"]["cash"]
		Events.start_event("test_check_event")
		Events.advance()
		Events.choose(0)
		assert_eq(Events.choice_record("test_check_event", 1), { "id": "push", "outcome": "success" })
		var resolution: Dictionary = Events.revealed_cards().back()
		assert_eq(resolution["text"], "It worked.")
		assert_eq(resolution["outcome"], "success")
		assert_eq(GameState.state["player"]["cash"], cash_before + 30, "success effects applied")
		assert_true(not GameState.state["flags"].get("checkFailed", false), "fail effects not applied")
		GameData.EVENTS = original_events
	)

	run_case("a_hopeless_check_resolves_fail_text_effects_and_memory", func():
		GameState.reset()
		var original_events := _install_check_event(0.0)
		var cash_before: int = GameState.state["player"]["cash"]
		Events.start_event("test_check_event")
		Events.advance()
		Events.choose(0)
		assert_eq(Events.choice_record("test_check_event", 1), { "id": "push", "outcome": "fail" })
		assert_eq(Events.revealed_cards().back()["text"], "It didn't.")
		assert_eq(Events.revealed_cards().back()["outcome"], "fail")
		assert_eq(GameState.state["player"]["cash"], cash_before, "success effects not applied")
		assert_true(GameState.state["flags"]["checkFailed"], "fail effects applied")
		GameData.EVENTS = original_events
	)

	run_case("a_rewound_check_rerolls_best_of_two_and_lists_the_advantage", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		var original_events := _install_check_event(0.5)
		Events.start_event("test_check_event")
		Events.advance()
		assert_almost_eq(Events.check_odds(0)["probability"], 0.5, 0.0001, "first roll: plain odds")
		var first_roll: float = Events.check_roll(0)
		Events.choose(0)
		assert_true(Events.rewind()["ok"])
		assert_eq(Events.prior_rolls(0), 1, "roll count survives the rewind")
		var odds: Dictionary = Events.check_odds(0)
		assert_almost_eq(odds["probability"], 0.75, 0.0001, "best of two: 1 - 0.5^2")
		assert_eq(odds["mods"].back()["label"], GameData.EVENT_CHECKS["rewoundLabel"])
		assert_almost_eq(odds["mods"].back()["delta"], 0.25, 0.0001)
		assert_true(Events.check_roll(0) != first_roll, "a fresh roll, not a replay")
		assert_eq(Events.check_odds(1), {}, "plain option untouched")
		GameData.EVENTS = original_events
	)

	run_case("a_check_rewound_past_keeps_its_advantage_when_reached_again", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 2 }
		var original_events := _install_check_event(0.5)
		Events.start_event("test_check_event")
		Events.advance()
		Events.choose(0)
		assert_true(Events.rewind()["ok"])
		assert_true(Events.rewind()["ok"])
		assert_eq(GameState.state["event"]["cardIndex"], 0, "back before the check card")
		Events.advance()
		assert_almost_eq(Events.check_odds(0)["probability"], 0.75, 0.0001, "still advantaged")
		GameData.EVENTS = original_events
	)

	run_case("advantaged_rerolls_succeed_about_three_quarters_of_the_time_at_even_odds", func():
		var successes := 0
		for roll_seed in range(1, 201):
			GameState.reset()
			GameState.state["world"]["rollSeed"] = roll_seed
			GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
			var original_events := _install_check_event(0.5)
			Events.start_event("test_check_event")
			Events.advance()
			Events.choose(0)
			Events.rewind()
			Events.choose(0)
			if Events.choice_record("test_check_event", 1)["outcome"] == "success":
				successes += 1
			GameData.EVENTS = original_events
		assert_true(successes > 130 and successes < 170, "best-of-two near 75%% (got %d/200)" % successes)
	)

	run_case("same_seed_and_roll_count_give_the_same_roll", func():
		var outcomes: Array = []
		for i in range(2):
			GameState.reset()
			GameState.state["world"]["rollSeed"] = 99
			var original_events := _install_check_event(0.5)
			Events.start_event("test_check_event")
			Events.advance()
			outcomes.append(Events.check_roll(0))
			GameData.EVENTS = original_events
		assert_eq(outcomes[0], outcomes[1], "a reload can't fish for a new roll")
	)

	run_case("a_check_never_touches_the_global_rng_stream", func():
		# The global stream after the same flow with the plain option: the
		# check must leave it exactly where a plain choice does.
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		var plain_events := _install_check_event(0.5)
		Rng.set_seed(4242)
		Events.start_event("test_check_event")
		Events.advance()
		Events.choose(1)
		assert_true(Events.rewind()["ok"])
		Events.choose(1)
		var expected_first: float = Rng.randf()
		GameData.EVENTS = plain_events
		# Different roll seeds give both outcomes at even odds, so this
		# also shows the roll isn't constant.
		var seen := {}
		for roll_seed in range(1, 41):
			GameState.reset()
			GameState.state["world"]["rollSeed"] = roll_seed
			GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
			var original_events := _install_check_event(0.5)
			Rng.set_seed(4242)
			Events.start_event("test_check_event")
			Events.advance()
			Events.choose(0)
			var first: Variant = Events.choice_record("test_check_event", 1)["outcome"]
			assert_true(Events.rewind()["ok"])
			Events.choose(0)
			assert_eq(Rng.randf(), expected_first, "global stream untouched (seed %d)" % roll_seed)
			seen[first] = true
			GameData.EVENTS = original_events
		assert_eq(seen.size(), 2, "different seeds reach both outcomes")
	)

	# ── check item mods (spec "Item toggle in state") ───────────────────

	run_case("an_equipped_item_mod_counts_only_when_equipped", func():
		GameState.reset()
		var check := { "base": 0.4, "mods": [{ "item": "timePearl", "equipped": true, "add": 0.15, "label": "Pearl" }], "min": 0.0, "max": 1.0 }
		Crafting.inventory_add("timePearl", 1, 1)
		assert_almost_eq(Events.odds_for(check)["probability"], 0.4, 0.0001, "held but not equipped")
		assert_true(Loadout.equip(0, "timePearl", 1)["ok"])
		assert_almost_eq(Events.odds_for(check)["probability"], 0.55, 0.0001, "equipped")
	)

	run_case("an_optional_toggle_lives_in_event_state_and_moves_the_odds", func():
		GameState.reset()
		var original_events := _install_item_check_event(0.4, true)
		Events.start_event("test_check_event")
		Events.advance()
		assert_eq(Events.item_toggles(0)[0]["held"], false, "none held")
		assert_true(not Events.toggle_item(0, "prophetsBreath")["ok"], "can't switch on without one")
		Crafting.inventory_add("prophetsBreath", 1, 1)
		assert_true(Events.toggle_item(0, "prophetsBreath")["ok"])
		assert_eq(GameState.state["event"]["toggles"], { "1|0": ["prophetsBreath"] }, "pure data in state.event")
		assert_almost_eq(Events.check_odds(0)["probability"], 0.65, 0.0001, "counted while on")
		assert_eq(Events.check_odds(0)["mods"][0]["label"], "Breath")
		assert_true(not Events.toggle_item(1, "prophetsBreath")["ok"], "not an item for the plain option")
		assert_true(Events.toggle_item(0, "prophetsBreath")["ok"])
		assert_almost_eq(Events.check_odds(0)["probability"], 0.4, 0.0001, "off again")
		GameData.EVENTS = original_events
	)

	run_case("a_toggled_consumable_is_spent_only_on_committing_its_option", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		Crafting.inventory_add("prophetsBreath", 1, 1)
		var original_events := _install_item_check_event(0.4, true)
		Events.start_event("test_check_event")
		Events.advance()
		Events.toggle_item(0, "prophetsBreath")
		Events.choose(1)
		assert_eq(Crafting.inventory_qty("prophetsBreath"), 1, "picking the other option spends nothing")
		assert_true(Events.rewind()["ok"])
		assert_eq(Events.active_toggles(0), ["prophetsBreath"], "Rewind keeps the preparation")
		Events.choose(0)
		assert_eq(Crafting.inventory_qty("prophetsBreath"), 0, "spent on commit")
		GameData.EVENTS = original_events
	)

	run_case("rewinding_a_committed_toggle_returns_the_item", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		Crafting.inventory_add("prophetsBreath", 1, 1)
		var original_events := _install_item_check_event(0.4, true)
		Events.start_event("test_check_event")
		Events.advance()
		Events.toggle_item(0, "prophetsBreath")
		Events.choose(0)
		assert_true(Events.rewind()["ok"])
		assert_eq(Crafting.inventory_qty("prophetsBreath"), 1, "rewind loses nothing")
		GameData.EVENTS = original_events
	)

	run_case("a_non_consuming_optional_item_is_kept_on_commit", func():
		GameState.reset()
		Crafting.inventory_add("prophetsBreath", 1, 1)
		var original_events := _install_item_check_event(0.4, false)
		Events.start_event("test_check_event")
		Events.advance()
		Events.toggle_item(0, "prophetsBreath")
		Events.choose(0)
		assert_eq(Crafting.inventory_qty("prophetsBreath"), 1)
		GameData.EVENTS = original_events
	)

	run_case("the_toggled_item_set_is_part_of_the_roll_key", func():
		GameState.reset()
		GameState.state["world"]["rollSeed"] = 99
		Crafting.inventory_add("prophetsBreath", 1, 1)
		var original_events := _install_item_check_event(0.4, true)
		Events.start_event("test_check_event")
		Events.advance()
		var bare: float = Events.check_roll(0)
		Events.toggle_item(0, "prophetsBreath")
		var prepared: float = Events.check_roll(0)
		assert_true(prepared != bare, "changed preparation, different roll")
		Events.toggle_item(0, "prophetsBreath")
		assert_eq(Events.check_roll(0), bare, "same preparation, same roll")
		GameData.EVENTS = original_events
	)

	run_case("roll_seed_is_backfilled_for_saves_missing_it", func():
		var save: Dictionary = GameState.new_game_state()
		save["world"].erase("rollSeed")
		var backfilled: Dictionary = SaveManager.backfill_defaults(save)
		assert_true(backfilled["world"].has("rollSeed"))
	)

	run_case("check_events_pass_the_event_validator", func():
		var errors: Array[String] = []
		GameData._validate_choice_card(_check_choice_card(0.5), "test", errors)
		assert_eq(errors, [] as Array[String])
	)

	# ── multi-attempt checks (R§3.9a "Attempts") ────────────────────────

	run_case("a_sure_multi_attempt_check_applies_per_success_effects_and_count_text", func():
		GameState.reset()
		var original_events := _install_attempts_check_event(1.0, 2)
		var cash_before: int = GameState.state["player"]["cash"]
		Events.start_event("test_check_event")
		Events.advance()
		assert_eq(Events.check_odds(0)["attempts"], 2)
		Events.choose(0)
		assert_eq(Crafting.inventory_qty("timePearl"), 2, "one pearl per success")
		assert_eq(Events.choice_record("test_check_event", 1), { "id": "push", "outcome": "success", "successes": 2 })
		var resolution: Dictionary = Events.revealed_cards().back()
		assert_eq(resolution["text"], "Two took.", "text keyed by success count")
		assert_eq([resolution["successes"], resolution["attempts"]], [2, 2])
		assert_eq(GameState.state["player"]["cash"], cash_before, "a keyed outcome replaces the success fallback")
		GameData.EVENTS = original_events
	)

	run_case("a_hopeless_multi_attempt_check_uses_the_zero_count_outcome", func():
		GameState.reset()
		var original_events := _install_attempts_check_event(0.0, 4)
		Events.start_event("test_check_event")
		Events.advance()
		Events.choose(0)
		assert_eq(Crafting.inventory_qty("timePearl"), 0)
		assert_eq(Events.choice_record("test_check_event", 1), { "id": "push", "outcome": "fail", "successes": 0 })
		assert_eq(Events.revealed_cards().back()["text"], "None took.")
		assert_true(GameState.state["flags"].get("noneTook", false))
		assert_true(not GameState.state["flags"].get("checkFailed", false), "fail fallback not used")
		GameData.EVENTS = original_events
	)

	run_case("an_unkeyed_success_count_falls_back_to_success", func():
		GameState.reset()
		var original_events := _install_attempts_check_event(1.0, 3)
		var cash_before: int = GameState.state["player"]["cash"]
		Events.start_event("test_check_event")
		Events.advance()
		Events.choose(0)
		assert_eq(Crafting.inventory_qty("timePearl"), 3)
		assert_eq(Events.revealed_cards().back()["text"], "It worked.")
		assert_eq(GameState.state["player"]["cash"], cash_before + 30)
		GameData.EVENTS = original_events
	)

	run_case("each_attempt_rolls_its_own_deterministic_value", func():
		var counts: Array = []
		for i in range(2):
			GameState.reset()
			GameState.state["world"]["rollSeed"] = 77
			var original_events := _install_attempts_check_event(0.5, 4)
			Events.start_event("test_check_event")
			Events.advance()
			var rolls: Array = []
			for a in range(4):
				rolls.append(Events.check_roll(0, a))
			assert_eq(rolls[0], Events.check_roll(0), "attempt 0 is the single-check roll")
			assert_true(rolls[1] != rolls[0] and rolls[2] != rolls[1], "attempts roll independently")
			Events.choose(0)
			var expected: int = rolls.filter(func(r: float) -> bool: return r < 0.5).size()
			assert_eq(Events.choice_record("test_check_event", 1)["successes"], expected, "one success per roll under p")
			counts.append(expected)
			GameData.EVENTS = original_events
		assert_eq(counts[0], counts[1], "same seed, same rolls")
	)

	run_case("a_rewound_multi_attempt_check_rerolls_every_attempt_best_of_two", func():
		var successes := 0
		for roll_seed in range(1, 201):
			GameState.reset()
			GameState.state["world"]["rollSeed"] = roll_seed
			GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
			var original_events := _install_attempts_check_event(0.5, 2)
			Events.start_event("test_check_event")
			Events.advance()
			var first: Array = [Events.check_roll(0, 0), Events.check_roll(0, 1)]
			Events.choose(0)
			Events.rewind()
			assert_eq(Crafting.inventory_qty("timePearl"), 0, "rewind returns the pearls")
			assert_true(Events.check_roll(0, 1) != first[1], "attempt re-rolls fresh")
			Events.choose(0)
			successes += int(Events.choice_record("test_check_event", 1)["successes"])
			GameData.EVENTS = original_events
		assert_true(successes > 260 and successes < 340, "best-of-two per attempt near 75%% (got %d/400)" % successes)
	)

	run_case("an_earlier_check_outcome_mod_applies_to_every_attempt", func():
		GameState.reset()
		GameState.state["world"]["rollSeed"] = 5
		var original_events := _install_check_event(1.0)
		GameData.EVENTS["test_check_event"]["cards"][1]["choices"][0]["success"]["effects"] = [{ "op": "set_flag", "flag": "jamesWatching", "value": true }]
		Events.start_event("test_check_event")
		Events.advance()
		Events.choose(0)
		GameData.EVENTS = original_events

		original_events = _install_attempts_check_event(0.45, 4)
		GameData.EVENTS["test_check_event"]["cards"][1]["choices"][0]["check"]["mods"] = [{ "flag": "jamesWatching", "add": 0.1, "label": "James is watching" }]
		Events.start_event("test_check_event")
		Events.advance()
		assert_almost_eq(Events.check_odds(0)["probability"], 0.55, 0.0001, "the earlier success lifts the odds")
		var expected := 0
		for a in range(4):
			if Events.check_roll(0, a) < 0.55:
				expected += 1
		Events.choose(0)
		assert_eq(Events.choice_record("test_check_event", 1)["successes"], expected, "every attempt rolls against the lifted odds")
		GameData.EVENTS = original_events
	)

	run_case("multi_attempt_checks_pass_the_event_validator", func():
		var original_events := _install_attempts_check_event(0.5, 2)
		var errors: Array[String] = []
		GameData._validate_choice_card(GameData.EVENTS["test_check_event"]["cards"][1], "test", errors)
		assert_eq(errors, [] as Array[String])
		var bad: Dictionary = GameData.EVENTS["test_check_event"]["cards"][1].duplicate(true)
		bad["choices"][0]["bySuccesses"]["many"] = { "result_text": "x", "effects": [] }
		GameData._validate_choice_card(bad, "test", errors)
		assert_eq(errors.size(), 1, "a non-count key is flagged")
		GameData.EVENTS = original_events
	)

	# ── requires and goto (R§3.9a "Requires", "Goto") ───────────────────

	run_case("requires_and_mods_share_one_condition_evaluator", func():
		GameState.reset()
		var conditions: Array = [
			{ "flag": "condFlag" },
			{ "choice": { "event": "condEvent", "card": 2, "option": "brave" } },
			{ "path": "player.craftingSkill", "atLeast": 3 },
			{ "relation": "archie", "atLeast": 15 },
			{ "cash": { "atLeast": 50 } },
			{ "item": "enhancementPowder" },
			{ "item": "timePearl", "equipped": true },
		]
		GameState.state["player"]["cash"] = 0
		GameState.state["player"]["craftingSkill"] = 1
		for cond in conditions:
			assert_true(not Events.condition_met(cond), "unmet: %s" % str(cond))
			var mod: Dictionary = cond.duplicate()
			mod["add"] = 0.1
			assert_almost_eq(Events.odds_for({ "base": 0.4, "mods": [mod], "min": 0.0, "max": 1.0 })["probability"], 0.4, 0.0001, "mod off: %s" % str(cond))
		GameState.state["flags"]["condFlag"] = true
		GameState.state["flags"]["choices"]["condEvent"] = { "2": { "id": "brave" } }
		GameState.state["player"]["craftingSkill"] = 3
		GameState.state["contacts"]["archie"]["relation"] = 15
		GameState.state["player"]["cash"] = 50
		Crafting.inventory_add("timePearl", 1, 1)
		Crafting.inventory_add("enhancementPowder", 1, 1)
		assert_true(Loadout.equip(0, "timePearl", 1)["ok"])
		for cond in conditions:
			assert_true(Events.condition_met(cond), "met: %s" % str(cond))
			var mod: Dictionary = cond.duplicate()
			mod["add"] = 0.1
			assert_almost_eq(Events.odds_for({ "base": 0.4, "mods": [mod], "min": 0.0, "max": 1.0 })["probability"], 0.5, 0.0001, "mod on: %s" % str(cond))
	)

	run_case("a_gated_option_hides_or_disables_and_cant_be_committed", func():
		GameState.reset()
		var original_events := _install_gated_event()
		GameState.state["player"]["cash"] = 20
		Events.start_event("test_gated_event")
		Events.advance()
		var snapshots_before: int = GameState.state["event"]["snapshots"].size()
		assert_eq(Events.option_gate(0), { "display": "disable", "reason": "Needs £50" })
		assert_eq(Events.option_gate(1)["display"], "hide", "display defaults to hide")
		assert_eq(Events.option_gate(2), { "display": "show", "reason": "" }, "no requires: shows")
		Events.choose(0)
		Events.choose(1)
		assert_true(Events.is_awaiting_choice(), "neither gated option commits")
		assert_eq(GameState.state["player"]["cash"], 20, "no effects ran")
		assert_eq(Events.choice_record("test_gated_event", 1), {}, "nothing remembered")
		assert_eq(GameState.state["event"]["snapshots"].size(), snapshots_before, "no snapshot taken")
		GameState.state["player"]["cash"] = 60
		GameState.state["flags"]["secretFlag"] = true
		assert_eq(Events.option_gate(0)["display"], "show", "met: shows")
		assert_eq(Events.option_gate(1)["display"], "show")
		Events.choose(0)
		assert_eq(GameState.state["player"]["cash"], 10, "a met gate commits")
		GameData.EVENTS = original_events
	)

	run_case("a_plain_option_goto_jumps_forward_past_the_branch", func():
		GameState.reset()
		var original_events := _install_gated_event()
		GameState.state["player"]["cash"] = 60
		Events.start_event("test_gated_event")
		Events.advance()
		Events.choose(0)
		Events.advance()
		assert_eq(GameState.state["event"]["cardIndex"], 3)
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Pick one", "Paid.", "Rejoin"], "the skipped card is never revealed")
		assert_eq(Events.current_image_path(), null, "the skipped card's image never shows")
		assert_true(Events.is_last_card())
		GameData.EVENTS = original_events
	)

	run_case("an_option_without_goto_plays_on_to_the_next_card", func():
		GameState.reset()
		var original_events := _install_gated_event()
		Events.start_event("test_gated_event")
		Events.advance()
		Events.choose(2)
		Events.advance()
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Pick one", "Walked.", "Branch"])
		assert_eq(Events.current_image_path(), "res://branch.png")
		Events.advance()
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Pick one", "Walked.", "Branch", "Rejoin"])
		GameData.EVENTS = original_events
	)

	run_case("a_check_outcome_goto_jumps_forward", func():
		GameState.reset()
		var original_events := _install_gated_event()
		Events.start_event("test_gated_event")
		Events.advance()
		Events.choose(3)
		Events.advance()
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Pick one", "Pushed through.", "Rejoin"])
		GameData.EVENTS = original_events
	)

	run_case("a_backwards_same_card_or_out_of_range_goto_is_rejected", func():
		var original_events := _install_gated_event()
		for bad in [0, 1, 4, 99, -1, "3"]:
			GameState.reset()
			GameState.state["player"]["cash"] = 60
			GameData.EVENTS["test_gated_event"]["cards"][1]["choices"][0]["goto"] = bad
			Events.start_event("test_gated_event")
			Events.advance()
			Events.choose(0)
			assert_true(not GameState.state["event"]["choiceResults"]["1"].has("goto"), "goto %s not recorded" % str(bad))
			Events.advance()
			assert_eq(GameState.state["event"]["cardIndex"], 2, "goto %s falls through to the next card" % str(bad))
		GameData.EVENTS = original_events
	)

	run_case("rewind_across_a_goto_restores_the_revealed_history", func():
		GameState.reset()
		var original_events := _install_gated_event()
		GameState.state["player"]["cash"] = 60
		Crafting.inventory_add("rewind", 1, 2)
		Events.start_event("test_gated_event")
		Events.advance()
		Events.choose(0)
		Events.advance()
		assert_eq(GameState.state["event"]["cardIndex"], 3)
		assert_true(Events.rewind()["ok"])
		assert_eq(GameState.state["event"]["cardIndex"], 1, "back on the resolved choice card")
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Pick one", "Paid."])
		assert_true(Events.rewind()["ok"])
		assert_true(Events.is_awaiting_choice(), "the pick is undone")
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Pick one"])
		assert_eq(GameState.state["player"]["cash"], 60)
		Events.choose(2)
		Events.advance()
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Pick one", "Walked.", "Branch"], "a different pick takes the branch")
		GameData.EVENTS = original_events
	)

	run_case("a_goto_survives_a_save_round_trip_as_a_float", func():
		GameState.reset()
		var original_events := _install_gated_event()
		GameState.state["player"]["cash"] = 60
		Events.start_event("test_gated_event")
		Events.advance()
		Events.choose(0)
		GameState.state["event"]["choiceResults"]["1"]["goto"] = 3.0  # as JSON reloads it
		Events.advance()
		assert_eq(GameState.state["event"]["cardIndex"], 3)
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Pick one", "Paid.", "Rejoin"])
		GameData.EVENTS = original_events
	)

	# ── card-level goto and end (R§3.9a "Goto") ─────────────────────────

	run_case("a_card_goto_and_a_matching_conditional_entry_jump_on_continue", func():
		GameState.reset()
		var original_events := _install_routed_event()
		GameState.state["flags"]["routeFlag"] = true
		Events.start_event("test_routed_event")
		Events.advance()
		assert_eq(GameState.state["event"]["cardIndex"], 3, "the first matching entry wins")
		Events.advance()
		assert_eq(GameState.state["event"]["cardIndex"], 5, "a plain card goto jumps")
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Flagged", "Finale"])
		assert_eq(Events.current_image_path(), "res://flagged.png", "skipped cards' images never show")
		GameState.state["flags"]["routeFlag"] = false
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Flagged", "Finale"], "the path is fixed once taken")
		assert_true(Events.is_last_card())
		GameData.EVENTS = original_events
	)

	run_case("the_else_entry_routes_and_end_finishes_the_event_there", func():
		GameState.reset()
		var original_events := _install_routed_event()
		Events.start_event("test_routed_event")
		Events.advance()
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Else"])
		assert_eq(Events.current_image_path(), "res://else.png")
		assert_true(Events.is_last_card(), "an end card is the last card")
		Events.advance()
		assert_eq(GameState.state["event"], null, "Continue on an end card finishes the event")
		assert_true(GameState.state["flags"].get("routedDone", false), "on_complete ran")
		GameData.EVENTS = original_events
	)

	run_case("a_conditional_goto_with_no_match_plays_on_to_the_next_card", func():
		GameState.reset()
		var original_events := _install_routed_event()
		GameData.EVENTS["test_routed_event"]["cards"][0]["goto"] = [{ "if": { "flag": "routeFlag" }, "card": 3 }]
		Events.start_event("test_routed_event")
		Events.advance()
		assert_eq(GameState.state["event"]["cardIndex"], 1)
		assert_eq(Events.current_image_path(), "res://skipped.png")
		GameData.EVENTS = original_events
	)

	run_case("a_backwards_or_out_of_range_card_goto_is_rejected", func():
		var original_events := _install_routed_event()
		for bad in [0, 3, 99, "5", [{ "card": 1 }]]:
			GameState.reset()
			GameState.state["flags"]["routeFlag"] = true
			GameData.EVENTS["test_routed_event"]["cards"][3]["goto"] = bad
			Events.start_event("test_routed_event")
			Events.advance()
			Events.advance()
			assert_eq(GameState.state["event"]["cardIndex"], 4, "card goto %s falls through to the next card" % str(bad))
		GameData.EVENTS = original_events
	)

	run_case("rewind_across_a_card_goto_reroutes_on_the_live_condition", func():
		GameState.reset()
		var original_events := _install_routed_event()
		Crafting.inventory_add("rewind", 1, 2)
		GameState.state["flags"]["routeFlag"] = true
		Events.start_event("test_routed_event")
		Events.advance()
		Events.advance()
		assert_true(Events.rewind()["ok"])
		assert_eq(GameState.state["event"]["cardIndex"], 3)
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Flagged"])
		assert_true(Events.rewind()["ok"])
		assert_eq(_texts(Events.revealed_cards()), ["Setup"])
		GameState.state["flags"]["routeFlag"] = false
		Events.advance()
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Else"], "a re-continue evaluates the conditions afresh")
		GameData.EVENTS = original_events
	)

	run_case("an_option_goto_overrides_its_choice_cards_end", func():
		var original_events := _install_gated_event()
		GameData.EVENTS["test_gated_event"]["cards"][1]["end"] = true
		GameState.reset()
		Events.start_event("test_gated_event")
		Events.advance()
		Events.choose(2)
		assert_true(Events.is_last_card(), "an option without goto ends at an end card")
		Events.advance()
		assert_eq(GameState.state["event"], null)
		GameState.reset()
		GameState.state["player"]["cash"] = 60
		Events.start_event("test_gated_event")
		Events.advance()
		Events.choose(0)
		assert_true(not Events.is_last_card(), "an option goto overrides end")
		Events.advance()
		assert_eq(GameState.state["event"]["cardIndex"], 3)
		GameData.EVENTS = original_events
	)

	run_case("a_choice_cards_own_goto_applies_when_its_option_has_none", func():
		var original_events := _install_gated_event()
		GameData.EVENTS["test_gated_event"]["cards"][1]["goto"] = 3
		GameState.reset()
		Events.start_event("test_gated_event")
		Events.advance()
		Events.choose(2)
		Events.advance()
		assert_eq(_texts(Events.revealed_cards()), ["Setup", "Pick one", "Walked.", "Rejoin"])
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
		var expected: Variant = "res://assets/events/intro/intro_card1.png"
		assert_eq(Events.current_image_path(), expected, "opening card discovers intro_card1.png")

		# card indexes are zero-based; intro_card5 to intro_card9 are found by convention, the rest are explicit keys
		var wired_at := { 4: "res://assets/events/intro/intro_card5.png", 5: "res://assets/events/intro/intro_card6.png", 6: "res://assets/events/intro/intro_card7.png", 7: "res://assets/events/intro/intro_card8.png", 8: "res://assets/events/intro/intro_card9.png", 10: "res://assets/events/intro/3.png", 17: "res://assets/events/intro/4.png" }
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

	run_case("start_raid_combat_vein_guards_spawns_one_enemy_per_vein_guard_extras_queue", func():
		for case in [["warded", 0, 1], ["guarded", 1, 2], ["guarded", 3, 4]]:
			GameState.reset()
			var vein := _faction_vein_of_level(2, "physics", case[0])
			vein["extraGuards"] = case[1]
			GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
			Events.apply_effects([{ "op": "start_raid_combat", "site_id": "s1", "guards": Events.RAID_GUARDS_FROM_VEIN }])
			var combat: Dictionary = GameState.state["combat"]
			assert_eq(combat["enemies"].size() + combat["enemyQueue"].size(), case[2], "%s + %d extras -> %d enemies" % case)
	)

	run_case("start_raid_combat_integer_guards_still_spawns_that_many", func():
		GameState.reset()
		var vein := _faction_vein_of_level(2, "physics", "guarded")
		vein["extraGuards"] = 3
		GameState.state["world"]["sites"] = [Fixtures.site_with_vein("s1", vein)]
		Events.apply_effects([{ "op": "start_raid_combat", "site_id": "s1", "guards": 2 }])
		assert_eq(GameState.state["combat"]["enemies"].size(), 2, "a literal count ignores the vein's guards")
	)

	run_case("vein_raid_event_uses_the_vein_guards_form", func():
		var caught_ops: Array = []
		for choice in GameData.EVENTS["vein_raid"]["cards"][1]["choices"]:
			for op in choice["effects"][0]["on_caught"]:
				if op["op"] == "start_raid_combat":
					caught_ops.append(op)
		assert_eq(caught_ops.size(), 2)
		assert_true(caught_ops.all(func(op): return op["guards"] == Events.RAID_GUARDS_FROM_VEIN), "vein_raid sizes its squad to the vein's guards")
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
		assert_true(CombatPrep.commit()["ok"])
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
		assert_true(CombatPrep.commit()["ok"])
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

	run_case("start_event_with_an_unknown_id_opens_nothing", func():
		GameState.reset()
		var screen_before = GameState.state["currentScreen"]
		Events.start_event("no_such_event")
		assert_eq(GameState.state["event"], null, "no state.event for an id with no definition")
		assert_eq(GameState.state["currentScreen"], screen_before, "no navigation to a blank event screen")
	)


	run_case("at_advance_moves_the_clock_forward_running_skipped_staff_blocks", func():
		GameState.reset()
		Rng.set_seed(99)
		GameState.state["flags"]["bizA1JamesJoined"] = true  # LodedInnit posts once per staff block step
		var original_events := _install_timed_event("evening", true)
		Events.start_event("test_timed_event")
		var world: Dictionary = GameState.state["world"]
		GameData.EVENTS = original_events
		assert_eq(world["timeBlock"], 2, "moved to evening")
		assert_eq(world["timeBlocksDone"], [0, 1], "skipped blocks counted as done")
		assert_eq(world["day"], 1, "same day")
		assert_eq(GameState.state["hiring"]["feed"].size(), 2, "one staff block step per skipped block")
	)

	run_case("at_advance_never_moves_backwards", func():
		GameState.reset()
		GameState.state["world"]["timeBlock"] = 2
		GameState.state["world"]["timeBlocksDone"] = [0, 1]
		var original_events := _install_timed_event("morning", true)
		Events.start_event("test_timed_event")
		GameData.EVENTS = original_events
		assert_eq(GameState.state["world"]["timeBlock"], 2, "a passed block runs in the current one")
		assert_eq(GameState.state["world"]["day"], 1)
		assert_eq(GameState.state["event"]["eventId"], "test_timed_event", "the event still runs")
	)

	run_case("at_night_never_moves_the_clock", func():
		GameState.reset()
		var original_events := _install_timed_event("night", true)
		Events.start_event("test_timed_event")
		GameData.EVENTS = original_events
		assert_eq(GameState.state["world"]["timeBlock"], 0)
		assert_eq(GameState.state["world"]["timeBlocksDone"], [])
		assert_eq(GameState.state["world"]["day"], 1)
	)

	run_case("at_without_advance_leaves_the_clock", func():
		GameState.reset()
		var original_events := _install_timed_event("evening", false)
		Events.start_event("test_timed_event")
		GameData.EVENTS = original_events
		assert_eq(GameState.state["world"]["timeBlock"], 0)
	)

	run_case("new_game_intro_runs_in_the_evening_of_tuesday_day_one", func():
		GameState.reset()
		Events.start_event("intro")
		assert_eq(GameState.state["world"]["day"], 1)
		assert_eq(GameState.state["world"]["timeBlock"], 2, "intro runs in Evening")
		assert_eq(Calendar.format_day(1).substr(0, 3), "TUE")
	)
