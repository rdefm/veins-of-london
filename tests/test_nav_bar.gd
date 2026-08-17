extends "res://tests/test_base.gd"

# 11-phone-os-shell ticket 11: the dock restructure -- 3 slots (Phone · Map ·
# HQ), Phone as a home button, Map's lock rendered as a padlocked AppTile
# instead of the old tab-label-overwrite hack.
#
# NavBar.new()/_ready() is safe to call directly without a live scene tree,
# same reasoning tests/test_phone_home_grid.gd documents for PhoneScreen --
# nothing UI.anchor_bottom_wide()/AppTile.configure() touches depends on
# get_tree()/get_viewport(), and AppTile self-heals its own _ready() via
# _ensure_built() (app_tile.gd) regardless of whether its parent is ever
# actually added to a processing tree.


func _synthetic_tap() -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	return event


func run() -> void:
	run_case("dock_has_exactly_three_slots_phone_map_hq_in_order", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		var ids: Array[String] = []
		for tab in NavBar.TABS:
			ids.append(tab["screen"])
		assert_eq(ids, ["phone", "map", "hq"], "dock is exactly Phone, Map, HQ, in that order")
		assert_eq(nav._tiles.size(), 3, "dock has exactly 3 slots")

		nav.free()
	)

	run_case("bag_and_you_are_not_among_the_dock_slots", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		assert_true(not nav._tiles.has("bag"), "no bag slot in the dock")
		assert_true(not nav._tiles.has("you"), "no you slot in the dock")

		nav.free()
	)

	run_case("map_slot_renders_locked_before_archie_is_met", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		var map_tile: AppTile = nav._tiles["map"]
		assert_true(map_tile._lock_overlay.visible, "Map renders locked -- the same padlock overlay every other locked app uses")

		nav.free()
	)

	run_case("map_slot_carries_the_lock_hint_as_a_tooltip_while_locked", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		var map_tile: AppTile = nav._tiles["map"]
		assert_eq(map_tile.tooltip_text, NavBar.LOCKED_MAP_LABEL, "the locked hint surfaces as a hover tooltip too, not just a toast on tap")

		nav.free()
	)

	run_case("map_slot_tooltip_clears_once_unlocked", func():
		GameState.reset()
		GameState.state["flags"]["archiePartnerSeen"] = true
		var nav := NavBar.new()
		nav._ready()

		var map_tile: AppTile = nav._tiles["map"]
		assert_eq(map_tile.tooltip_text, "", "no lock tooltip once Map is unlocked")

		nav.free()
	)

	run_case("map_slot_unlocks_once_archie_is_met", func():
		GameState.reset()
		GameState.state["flags"]["archiePartnerSeen"] = true
		var nav := NavBar.new()
		nav._ready()

		var map_tile: AppTile = nav._tiles["map"]
		assert_true(not map_tile._lock_overlay.visible, "Map renders unlocked once archiePartnerSeen is true")

		nav.free()
	)

	run_case("tapping_the_locked_map_slot_pushes_a_toast_instead_of_navigating", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var nav := NavBar.new()
		nav._ready()

		var map_tile: AppTile = nav._tiles["map"]
		map_tile._on_gui_input(_synthetic_tap())

		assert_eq(GameState.state["currentScreen"], "hq", "a locked Map tap never navigates")
		var notifications: Array = GameState.state["notifications"]
		assert_eq(notifications.size(), 1, "a toast notification is pushed instead of navigating")
		assert_eq(notifications[0]["text"], NavBar.LOCKED_MAP_LABEL, "the toast carries the same lock hint text as before")

		nav.free()
	)

	run_case("tapping_map_once_unlocked_navigates_normally", func():
		GameState.reset()
		GameState.state["flags"]["archiePartnerSeen"] = true
		var nav := NavBar.new()
		nav._ready()

		var map_tile: AppTile = nav._tiles["map"]
		map_tile._on_gui_input(_synthetic_tap())

		assert_eq(GameState.state["currentScreen"], "map", "an unlocked Map tap navigates to the map screen")

		nav.free()
	)

	run_case("tapping_hq_navigates_to_hq", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		var hq_tile: AppTile = nav._tiles["hq"]
		hq_tile._on_gui_input(_synthetic_tap())

		assert_eq(GameState.state["currentScreen"], "hq", "the HQ slot navigates to hq")

		nav.free()
	)

	run_case("phone_slot_from_elsewhere_navigates_to_phone_and_resets_to_the_grid", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		GameState.state["phoneNav"]["app"] = "notes"
		var nav := NavBar.new()
		nav._ready()

		var phone_tile: AppTile = nav._tiles["phone"]
		phone_tile._on_gui_input(_synthetic_tap())

		assert_eq(GameState.state["currentScreen"], "phone", "the Phone slot returns to the phone screen from elsewhere")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "the Phone slot resets phoneNav back to the app grid")

		nav.free()
	)

	run_case("phone_slot_from_inside_an_app_returns_to_the_grid_without_a_screen_change", func():
		GameState.reset()
		GameState.state["currentScreen"] = "phone"
		GameState.state["phoneNav"]["app"] = "notes"

		var received: Array[String] = []
		var on_screen := func(screen: String): received.append(screen)
		EventBus.screen_changed.connect(on_screen)

		var nav := NavBar.new()
		nav._ready()

		var phone_tile: AppTile = nav._tiles["phone"]
		phone_tile._on_gui_input(_synthetic_tap())

		EventBus.screen_changed.disconnect(on_screen)

		assert_eq(GameState.state["phoneNav"]["app"], "home", "the Phone slot returns to the grid from inside an app")
		assert_eq(received, [], "no screen_changed fires -- currentScreen was already phone, so this must not re-navigate")

		nav.free()
	)

	run_case("phone_slot_while_already_on_the_grid_is_a_true_no_op", func():
		GameState.reset()
		GameState.state["currentScreen"] = "phone"
		GameState.state["phoneNav"]["app"] = "home"

		var nav := NavBar.new()
		nav._ready()

		var screen_events: Array[String] = []
		var state_event_count := 0
		var on_screen := func(screen: String): screen_events.append(screen)
		var on_state := func(): state_event_count += 1
		EventBus.screen_changed.connect(on_screen)
		EventBus.state_changed.connect(on_state)

		var phone_tile: AppTile = nav._tiles["phone"]
		phone_tile._on_gui_input(_synthetic_tap())

		EventBus.screen_changed.disconnect(on_screen)
		EventBus.state_changed.disconnect(on_state)

		assert_eq(screen_events, [], "no re-navigation while already on the grid")
		assert_eq(state_event_count, 0, "no state_changed emission (no flicker) while already on the grid")

		nav.free()
	)
