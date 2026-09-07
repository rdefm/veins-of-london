extends "res://tests/test_base.gd"

# hq-diorama ticket 02: HqScreen is now the single room plate
# (scenes/components/hq_diorama.gd rendering GameData.HQ_VISUALS["rooms"])
# instead of a scrolling card stack. Zone-dispatch tests below simulate a
# tap by building a synthetic InputEventScreenTouch at a region's own
# centre point (read from HqDiorama.region_rects(), never a hardcoded
# coordinate) and feeding it through hq._on_diorama_gui_input() -- the same
# path a real tap takes. What each destination actually renders (the old
# inline Security/Rooms/Ore-store/Dial cards) is now covered by
# tests/test_modal_layer.gd's "hq_*" cases, since that's where the content
# moved to.


static func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


# A tap InputEventScreenTouch at `pos`, in HqDiorama's own local coordinate
# space (matches the space hq._on_diorama_gui_input() reads gui_input events
# in -- see dial_widget.gd's own _gui_input() for the same convention).
static func _tap_at(pos: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	event.position = pos
	return event


static func _tap_zone(hq: HqScreen, zone_id: String) -> void:
	var rect: Rect2 = hq._diorama.region_rects()[zone_id]
	hq._on_diorama_gui_input(_tap_at(rect.get_center()))


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
		assert_eq(hq.get_child_count(), 0, "the check must run before any room UI is ever added -- starting the event navigates away and this node is about to be freed")

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
		assert_true(hq._diorama != null, "the room plate must build once the one-shot has already fired")

		hq.free()
	)

	run_case("hq_ready_does_not_trigger_when_no_raid_is_pending", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		assert_eq(GameState.state["currentScreen"], "hq", "a fresh game with nothing pending must render HQ normally")
		assert_true(hq._diorama != null, "the room plate must render on a normal HQ visit")

		hq.free()
	)

	# ── locked HQ: no room plate yet, Rest/Defend stay reachable ──────────

	run_case("hq_locked_view_shows_the_locked_message_and_no_room_plate", func():
		GameState.reset()
		# homeUnlocked defaults false (autoload/GameState.gd) for the whole
		# pre-raid stretch of a fresh game.
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		assert_true(hq._diorama == null, "the room plate has nothing to show while HQ is locked")
		var heading_texts: Array[String] = []
		for l in hq.find_children("", "Label", true, false):
			heading_texts.append((l as Label).text)
		assert_true(heading_texts.has("Locked"), "a locked HQ visit must show the Locked heading")

		hq.free()
	)

	run_case("hq_rest_action_is_reachable_even_while_hq_is_locked", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		assert_true(_find_button(hq, "Rest") != null, "Rest must render even on a locked HQ visit")

		hq.free()
	)

	run_case("hq_locked_view_shows_a_defend_button_while_a_raid_is_pending", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		GameState.state["home"]["pendingRaid"] = true
		GameState.state["home"]["pendingRaidNotificationId"] = "n1"

		var hq := HqScreen.new()
		hq._ready()

		var defend_button := _find_button(hq, "Defend")
		assert_true(defend_button != null, "Defend must render on the locked fallback while a raid is pending")

		defend_button.pressed.emit()

		assert_true(GameState.state["combat"]["active"], "tapping Defend should start combat immediately")
		assert_eq(GameState.state["combat"]["context"], "home_raid")
		assert_true(not GameState.state["home"]["pendingRaid"], "the pending raid should be popped from the queue")

		hq.free()
	)

	run_case("hq_locked_view_has_no_defend_button_when_nothing_is_pending", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"

		var hq := HqScreen.new()
		hq._ready()

		assert_true(_find_button(hq, "Defend") == null, "Defend must not render with no raid pending")

		hq.free()
	)

	# hq-diorama ticket 02: the old HQ-screen Defend shortcut is intentionally
	# not carried into the normal (unlocked) room view -- §8's hostile-door
	# state is ticket 5's job, and a pending raid stays reachable via the
	# Notifications app's own Defend button in the meantime (phone.gd), so
	# this isn't a lost mechanic, just a removed redundant entry point.
	run_case("hq_room_view_has_no_defend_shortcut_even_while_a_raid_is_pending", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["home"]["pendingRaid"] = true
		GameState.state["home"]["pendingRaidNotificationId"] = "n1"

		var hq := HqScreen.new()
		hq._ready()

		assert_true(_find_button(hq, "Defend") == null, "the room view has no Defend shortcut -- ticket 5's hostile-door state owns this now")

		hq.free()
	)

	# ── the room plate and its zones ──────────────────────────────────────

	run_case("hq_room_view_builds_a_diorama_sized_to_the_bedsit_plate", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		assert_true(hq._diorama != null, "sanity: the room plate must build")
		assert_eq(hq._diorama.size, Vector2(390, 660), "the diorama must be sized to the bedsit plate's own width/height")

		hq.free()
	)

	run_case("hq_room_view_falls_back_to_the_bedsit_plate_for_a_tier_with_no_manifest_entry_yet", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		# v1 (docs/hq-diorama-vision.md §10) ships only the bedsit plate --
		# a player already at a later tier (art not shipped yet) must still
		# get a navigable room, not a crash or a blank screen.
		GameState.state["home"]["tier"] = "flat"

		var hq := HqScreen.new()
		hq._ready()

		assert_true(hq._diorama != null, "a tier with no manifest entry must still render a room, falling back to bedsit")
		assert_eq(hq._diorama.size, Vector2(390, 660), "the fallback must be the bedsit plate's own size")

		hq.free()
	)

	run_case("hq_dial_zone_tap_opens_the_hq_dial_modal", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		assert_eq(GameState.state["modal"], null, "sanity: no modal open yet")
		_tap_zone(hq, "dial")
		assert_eq(GameState.state["modal"]["type"], "hq_dial", "tapping the Dial zone must open its destination modal")

		hq.free()
	)

	run_case("hq_lab_zone_tap_navigates_straight_to_the_lab_screen_unchanged", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["currentScreen"] = "hq"
		GameState.state["benchNav"]["view"] = "picker"

		var hq := HqScreen.new()
		hq._ready()

		_tap_zone(hq, "lab")

		assert_eq(GameState.state["currentScreen"], "lab", "tapping the Lab zone must open the Lab screen, same destination the old 'Open' button used")
		assert_eq(GameState.state["benchNav"]["view"], "home", "BenchNav.go_home() must reset the bench to its own default view, same as the old Lab card's Open button")

		hq.free()
	)

	run_case("hq_security_zone_tap_opens_the_hq_security_list_modal", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		_tap_zone(hq, "security")
		assert_eq(GameState.state["modal"]["type"], "hq_security_list", "tapping the Security zone must open its destination modal")

		hq.free()
	)

	run_case("hq_rooms_zone_tap_opens_the_hq_rooms_list_modal", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		_tap_zone(hq, "rooms")
		assert_eq(GameState.state["modal"]["type"], "hq_rooms_list", "tapping the Rooms zone must open its destination modal")

		hq.free()
	)

	run_case("hq_ore_store_zone_tap_opens_the_hq_ore_readout_modal", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		_tap_zone(hq, "oreStore")
		assert_eq(GameState.state["modal"]["type"], "hq_ore_readout", "tapping the Ore store zone must open its destination readout modal, not a sub-view")

		hq.free()
	)

	run_case("hq_rest_zone_tap_performs_the_rest_action_directly_with_no_intermediate_view", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true
		GameState.state["world"]["day"] = 3
		GameState.state["world"]["timeBlock"] = 2
		GameState.state["player"]["hp"] = 50
		GameState.state["player"]["hpMax"] = 100

		var hq := HqScreen.new()
		hq._ready()

		_tap_zone(hq, "rest")

		assert_eq(GameState.state["modal"], null, "Rest must act directly, with no intermediate modal or view")
		assert_eq(GameState.state["world"]["day"], 4, "tapping Rest must advance the day, same as TimeSystem.do_rest()")
		assert_eq(GameState.state["world"]["timeBlock"], 0, "tapping Rest must reset the time block")
		# do_rest's daily_tick also fires passive regen (bugfixes-42): 50 + round(100*0.05) = 55,
		# then the rest heal itself: 55 + round(100*0.2) = 75.
		assert_eq(GameState.state["player"]["hp"], 75, "50 + passive regen 5 + rest heal 20 = 75, same as TimeSystem.do_rest()")

		hq.free()
	)

	run_case("hq_tapping_outside_every_region_opens_nothing", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		# The bedsit plate is 390x660 (data/hq_visuals.json); none of its
		# regions cover this corner (see that manifest's own region rects).
		hq._on_diorama_gui_input(_tap_at(Vector2(2, 2)))

		assert_eq(GameState.state["modal"], null, "a tap outside every region must not open anything")

		hq.free()
	)

	run_case("hq_non_press_input_on_the_diorama_does_nothing", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		var release := InputEventScreenTouch.new()
		release.pressed = false
		release.position = hq._diorama.region_rects()["dial"].get_center()
		hq._on_diorama_gui_input(release)

		assert_eq(GameState.state["modal"], null, "a release event must not dispatch a zone tap")

		hq.free()
	)

	# hq-diorama ticket 02: Gym is wired into the bedsit plate despite §3.1's
	# own "First tier present" being "flat" -- a deliberate, human-approved
	# deviation (see hq.gd's own top-of-file comment and data/hq_visuals.
	# json's "gymDeviation" meta note). What the destination modal itself
	# renders (Train button/gating) is covered by tests/test_modal_layer.gd's
	# "hq_gym_*" cases, same split every other zone's destination content uses.
	run_case("hq_gym_zone_tap_opens_the_hq_gym_modal", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		_tap_zone(hq, "gym")
		assert_eq(GameState.state["modal"]["type"], "hq_gym", "tapping the Gym zone must open its destination modal")

		hq.free()
	)

	# ── debug region overlay (ticket 01) ───────────────────────────────────

	run_case("hq_debug_regions_button_toggles_the_diorama_overlay_and_survives_a_refresh", func():
		GameState.reset()
		GameState.state["flags"]["homeUnlocked"] = true

		var hq := HqScreen.new()
		hq._ready()

		assert_true(not hq._diorama.is_debug_overlay_enabled(), "the debug overlay must default to off")

		_find_button(hq, "Debug regions").pressed.emit()
		assert_true(hq._diorama.is_debug_overlay_enabled(), "the Debug regions button must toggle the overlay on")

		hq._refresh()
		assert_true(hq._diorama.is_debug_overlay_enabled(), "the toggle must survive a same-session _refresh(), same as the old collapsible-section persistence pattern")

		hq.free()
	)
