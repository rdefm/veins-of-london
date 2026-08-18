extends "res://tests/test_base.gd"

# Same headless-scene pattern as tests/test_lab_screen.gd: HqScreen.new()
# then _ready(), no live tree needed.


static func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


static func _find_button_starting_with(root: Node, prefix: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text.begins_with(prefix):
			return b
	return null


# Index (among _content's direct children -- each card/section is added as
# one direct child) of whichever child contains a descendant Label or Button
# whose text matches `text`/`prefix` -- bugfixes ticket 24: used to assert
# the actionable cards render above the passive Rooms/Security sections.
static func _direct_child_index_containing(content: Node, text: String) -> int:
	var children := content.get_children()
	for i in children.size():
		var child: Node = children[i]
		if child is Label and (child as Label).text == text:
			return i
		if child is Button and (child as Button).text.begins_with(text):
			return i
		for n in child.find_children("*", "", true, false):
			if n is Label and (n as Label).text == text:
				return i
			if n is Button and (n as Button).text.begins_with(text):
				return i
	return -1


func run() -> void:
	run_case("hq_ready_starts_home_raid_intro_and_never_builds_the_normal_ui_when_pending_and_unseen", func():
		GameState.reset()
		GameState.state["flags"]["homeRaidEventPending"] = true
		GameState.state["flags"]["homeRaidEventSeen"] = false
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		assert_eq(GameState.state["currentScreen"], "event", "a qualifying HQ visit must start the event, same as the old home screen")
		assert_eq(GameState.state["event"]["eventId"], "home_raid_intro")
		assert_eq(hq.get_child_count(), 0, "the check must run before UI.screen_body()/back_button() are ever added -- starting the event navigates away and this node is about to be freed")

		hq.free()
	)

	run_case("hq_ready_does_not_retrigger_once_the_event_has_been_seen", func():
		GameState.reset()
		# homeRaidEventPending stays true forever once set (per
		# systems/debug_start.gd's comment) -- homeRaidEventSeen is the only
		# thing gating a re-fire, so this is the true one-shot check.
		GameState.state["flags"]["homeRaidEventPending"] = true
		GameState.state["flags"]["homeRaidEventSeen"] = true
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		assert_eq(GameState.state["currentScreen"], "hq", "already-seen must not start the event again")
		assert_true(hq.get_child_count() > 0, "normal HQ UI must build once the one-shot has already fired")

		hq.free()
	)

	run_case("hq_ready_does_not_trigger_when_no_raid_is_pending", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		assert_eq(GameState.state["currentScreen"], "hq", "a fresh game with nothing pending must render HQ normally")
		assert_true(_find_button(hq, "Rest") != null, "Rest action must be reachable on a normal HQ visit")

		hq.free()
	)

	run_case("hq_rest_action_is_reachable_even_while_hq_is_locked", func():
		GameState.reset()
		# homeUnlocked defaults false (autoload/GameState.gd) for the whole
		# pre-raid stretch of a fresh game -- Rest must never be gated
		# behind it, or HQ recreates the dead-end this ticket removes.
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		assert_true(_find_button(hq, "Locked") == null, "sanity: HQ heading text is 'Locked' as a heading, not a button")
		assert_true(_find_button(hq, "Rest") != null, "Rest must render even on a locked HQ visit")

		hq.free()
	)

	run_case("hq_back_button_routes_to_phone_home_not_the_retired_home_screen", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["currentScreen"] = "hq"
		PhoneNav.open_app("messages")

		var hq := HqScreen.new()
		hq._ready()

		var back_button := _find_button(hq, "‹ Back")
		assert_true(back_button != null, "HQ must render a generic back button")
		back_button.pressed.emit()

		assert_eq(GameState.state["currentScreen"], "phone", "the generic back affordance should route to the phone app grid, not the retired home screen")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "should land on the grid itself, not whatever app was last open")

		hq.free()
	)

	run_case("hq_rest_button_produces_identical_effects_to_TimeSystem_do_rest", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["world"]["day"] = 3
		GameState.state["world"]["timeBlock"] = 2
		GameState.state["player"]["hp"] = 50
		GameState.state["player"]["hpMax"] = 100

		var hq := HqScreen.new()
		hq._ready()

		var rest_button := _find_button(hq, "Rest")
		assert_true(rest_button != null, "HQ must render a Rest action")
		rest_button.pressed.emit()

		assert_eq(GameState.state["world"]["day"], 4, "resting from HQ must advance the day, same as TimeSystem.do_rest()")
		assert_eq(GameState.state["world"]["timeBlock"], 0, "resting from HQ must reset the time block")
		assert_eq(GameState.state["player"]["hp"], 70, "50 + round(100*0.2) = 70, same heal formula as today")

		hq.free()
	)

	# ── bugfixes ticket 24: collapsible Rooms/Security, actionable cards to top ──

	run_case("hq_actionable_cards_render_above_the_passive_rooms_and_security_sections", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		var lab_index := _direct_child_index_containing(hq._content, "The Lab")
		var workbench_index := _direct_child_index_containing(hq._content, "Workbench")
		var recipes_index := _direct_child_index_containing(hq._content, "Recipes")
		var devices_progress_index := _direct_child_index_containing(hq._content, "Devices in progress")
		var devices_start_index := _direct_child_index_containing(hq._content, "Start a new device")
		var security_index := _direct_child_index_containing(hq._content, "Security (")
		var rooms_index := _direct_child_index_containing(hq._content, "Rooms (")

		assert_true(lab_index != -1, "sanity: the Lab card must render")
		assert_true(workbench_index != -1, "sanity: the Workbench card must render")
		assert_true(recipes_index != -1, "sanity: the Recipes heading must render")
		assert_true(devices_progress_index != -1, "sanity: the Devices in progress heading must render")
		assert_true(devices_start_index != -1, "sanity: the Start a new device heading must render")
		assert_true(security_index != -1, "sanity: the Security section must render")
		assert_true(rooms_index != -1, "sanity: the Rooms section must render")

		for actionable_index in [lab_index, workbench_index, recipes_index, devices_progress_index, devices_start_index]:
			assert_true(actionable_index < security_index, "actionable HQ content must render above the Security section")
			assert_true(actionable_index < rooms_index, "actionable HQ content must render above the Rooms section")

		hq.free()
	)

	run_case("hq_security_and_rooms_sections_start_collapsed", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		var security_header := _find_button_starting_with(hq, "Security (")
		var rooms_header := _find_button_starting_with(hq, "Rooms (")
		assert_true(security_header != null, "sanity: Security header must render")
		assert_true(rooms_header != null, "sanity: Rooms header must render")
		assert_true(security_header.text.ends_with("▸"), "Security section must start collapsed")
		assert_true(rooms_header.text.ends_with("▸"), "Rooms section must start collapsed")

		hq.free()
	)

	run_case("hq_expanding_the_security_section_persists_across_a_same_session_refresh", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		var security_header := _find_button_starting_with(hq, "Security (")
		security_header.pressed.emit()
		assert_true(security_header.text.ends_with("▾"), "tapping the header must expand the section")

		hq._refresh()

		var refreshed_header := _find_button_starting_with(hq, "Security (")
		assert_true(refreshed_header.text.ends_with("▾"), "expansion must survive a same-session _refresh(), not reset to collapsed")
		# The other section's own state must be untouched by expanding this one.
		assert_true(_find_button_starting_with(hq, "Rooms (").text.ends_with("▸"), "expanding Security must not also expand Rooms")

		hq.free()
	)

	run_case("hq_expanding_the_rooms_section_persists_across_a_same_session_refresh", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		var rooms_header := _find_button_starting_with(hq, "Rooms (")
		rooms_header.pressed.emit()
		assert_true(rooms_header.text.ends_with("▾"), "tapping the header must expand the section")

		hq._refresh()

		var refreshed_header := _find_button_starting_with(hq, "Rooms (")
		assert_true(refreshed_header.text.ends_with("▾"), "expansion must survive a same-session _refresh(), not reset to collapsed")
		assert_true(_find_button_starting_with(hq, "Security (").text.ends_with("▸"), "expanding Rooms must not also expand Security")

		hq.free()
	)
