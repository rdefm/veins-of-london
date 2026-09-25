extends "res://tests/test_base.gd"

const UiSim := preload("res://tests/support/ui_sim.gd")
const Preferences := preload("res://systems/preferences.gd")

# 11-phone-os-shell ticket 11: the dock restructure -- 3 slots (Phone · Map ·
# HQ), Phone as a home button, Map's lock rendered as a padlock overlay
# instead of the old tab-label-overwrite hack.
#
# field-kit-chrome ticket 04: the dock's own tile rendering (previously
# shared AppTile.gd with the phone home grid) is replaced by nav_bar.gd's
# own dock-local _DockTile/_TileIcon classes -- a flat TfL-style tile strip
# per ui-vision.md §5. These cases assert against that new structure
# (`_DockTile.locked`/`.active`, `_TileIcon.kind`/`.colour`, `_lock_badge`)
# instead of AppTile's frame-style/lock-overlay fields.
#
# NavBar.new()/_ready() is safe to call directly without a live scene tree,
# same reasoning tests/test_phone_home_grid.gd documents for PhoneScreen --
# nothing UI.anchor_bottom_wide()/_DockTile.configure() touches depends on
# get_tree()/get_viewport(), and _DockTile self-heals its own _ready() via
# _ensure_built() (nav_bar.gd) regardless of whether its parent is ever
# actually added to a processing tree.


func run() -> void:
	await run_case("dark_mode_darkens_the_dock_only_on_map_and_follows_the_toggle_live", func():
		var tree := Engine.get_main_loop() as SceneTree
		GameState.reset()
		GameState.state["flags"]["archiePartnerSeen"] = true
		var nav := NavBar.new()
		tree.root.add_child(nav)
		await tree.process_frame

		for screen_id in ["phone", "map", "hq"]:
			Nav.go_to(screen_id)
			_assert_dock(nav, false, "dark off on %s" % screen_id)

		Preferences.set_map_dark_mode(true)
		Nav.go_to("phone")
		_assert_dock(nav, false, "dark on, Phone")
		Nav.go_to("map")
		_assert_dock(nav, true, "dark on, Map")
		assert_true(nav._tiles["map"]._active_bar.visible, "Map's active bar still shows in dark")
		Nav.go_to("hq")
		_assert_dock(nav, false, "dark on, HQ")

		Nav.go_to("map")
		Preferences.set_map_dark_mode(false)
		_assert_dock(nav, false, "toggled off live on Map")
		Preferences.set_map_dark_mode(true)
		_assert_dock(nav, true, "toggled on live on Map")

		nav.free()
		GameState.reset()
	)

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

	run_case("the_bar_renders_a_background_panel_behind_the_tiles", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		var bg: Panel = null
		for child in nav.get_children():
			if child is Panel:
				bg = child
				break
		assert_true(bg != null, "NavBar has its own background Panel, distinct from the tiles' own frames")
		assert_true(bg.visible, "the bar background is visible")

		nav.free()
	)

	run_case("ticket_04_tile_row_has_thin_vertical_dividers_between_the_three_cells", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		var row: HBoxContainer = null
		for child in nav.get_children():
			if child is HBoxContainer:
				row = child
				break
		assert_true(row != null, "the tile row exists")

		var dividers := 0
		for child in row.get_children():
			if child is ColorRect:
				dividers += 1
		assert_eq(dividers, 2, "a thin divider sits between each of the 3 cells (2 dividers total)")

		nav.free()
	)

	run_case("ticket_04_each_tab_carries_its_own_new_line_icon_kind", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		assert_eq(nav._tiles["phone"]._icon.kind, "phone", "Phone tab uses the phone icon")
		assert_eq(nav._tiles["map"]._icon.kind, "map", "Map tab uses the map icon")
		assert_eq(nav._tiles["hq"]._icon.kind, "hq", "HQ tab uses the hq icon")

		nav.free()
	)

	run_case("ticket_04_icon_and_label_colour_is_ui_action_red_not_blue", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		var expected: Color = GameData.PALETTE.get("ui_action_red", UI.ACTION_COLOUR_FALLBACK)
		var hq_tile: NavBar._DockTile = nav._tiles["hq"]
		assert_eq(hq_tile._icon.colour, expected, "HQ tab's icon uses ui_action_red")
		assert_eq(hq_tile._label.get_theme_color("font_color"), expected, "HQ tab's label uses ui_action_red")

		nav.free()
	)

	run_case("hq_tile_highlights_active_when_currentScreen_is_hq", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var nav := NavBar.new()
		nav._ready()

		var hq_tile: NavBar._DockTile = nav._tiles["hq"]
		var phone_tile: NavBar._DockTile = nav._tiles["phone"]
		assert_true(hq_tile.active, "HQ tile is active while on the hq screen")
		assert_true(hq_tile._active_bar.visible, "HQ tile shows its active-tab indicator bar")
		assert_true(not phone_tile.active, "Phone tile is not active while on the hq screen")
		assert_true(not phone_tile._active_bar.visible, "Phone tile shows no active-tab indicator")

		nav.free()
	)

	run_case("phone_tile_highlights_active_only_on_the_app_grid_not_inside_an_open_app", func():
		GameState.reset()
		GameState.state["currentScreen"] = "phone"
		GameState.state["phoneNav"]["app"] = "home"
		var nav := NavBar.new()
		nav._ready()

		var phone_tile: NavBar._DockTile = nav._tiles["phone"]
		assert_true(phone_tile.active, "Phone tile is active while parked on the app grid")

		GameState.state["phoneNav"]["app"] = "todo"
		EventBus.state_changed.emit()
		assert_true(not phone_tile.active, "Phone tile stops being active once an app is open, even though currentScreen is still phone")

		nav.free()
	)

	run_case("map_slot_renders_locked_before_archie_is_met", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		var map_tile: NavBar._DockTile = nav._tiles["map"]
		assert_true(map_tile.locked, "Map tile reports locked")
		assert_true(map_tile._lock_badge.visible, "Map renders locked -- the same padlock overlay every other locked slot uses")

		nav.free()
	)

	run_case("map_slot_carries_the_lock_hint_as_a_tooltip_while_locked", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		var map_tile: NavBar._DockTile = nav._tiles["map"]
		assert_eq(map_tile.tooltip_text, NavBar.LOCKED_MAP_LABEL, "the locked hint surfaces as a hover tooltip too, not just a toast on tap")

		nav.free()
	)

	run_case("map_slot_tooltip_clears_once_unlocked", func():
		GameState.reset()
		GameState.state["flags"]["archiePartnerSeen"] = true
		var nav := NavBar.new()
		nav._ready()

		var map_tile: NavBar._DockTile = nav._tiles["map"]
		assert_eq(map_tile.tooltip_text, "", "no lock tooltip once Map is unlocked")

		nav.free()
	)

	run_case("map_slot_unlocks_once_archie_is_met", func():
		GameState.reset()
		GameState.state["flags"]["archiePartnerSeen"] = true
		var nav := NavBar.new()
		nav._ready()

		var map_tile: NavBar._DockTile = nav._tiles["map"]
		assert_true(not map_tile.locked, "Map renders unlocked once archiePartnerSeen is true")
		assert_true(not map_tile._lock_badge.visible, "no padlock once Map is unlocked")

		nav.free()
	)

	run_case("locked_map_still_renders_its_padlock_alongside_the_new_bar_chrome", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		var bg: Panel = null
		for child in nav.get_children():
			if child is Panel:
				bg = child
				break
		var map_tile: NavBar._DockTile = nav._tiles["map"]
		assert_true(bg != null and bg.visible, "the bar background still renders with a locked Map slot present")
		assert_true(map_tile._lock_badge.visible, "Map's padlock still renders unaffected by the bar chrome")
		assert_true(not map_tile.active, "a locked Map slot is never also shown as the active tab")
		assert_true(not map_tile._active_bar.visible, "a locked Map slot shows no active-tab indicator")

		nav.free()
	)

	run_case("tapping_the_locked_map_slot_pushes_a_toast_instead_of_navigating", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var nav := NavBar.new()
		nav._ready()

		var map_tile: NavBar._DockTile = nav._tiles["map"]
		map_tile._on_gui_input(UiSim.synthetic_tap())

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

		var map_tile: NavBar._DockTile = nav._tiles["map"]
		map_tile._on_gui_input(UiSim.synthetic_tap())

		assert_eq(GameState.state["currentScreen"], "map", "an unlocked Map tap navigates to the map screen")

		nav.free()
	)

	run_case("tapping_hq_navigates_to_hq", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		var hq_tile: NavBar._DockTile = nav._tiles["hq"]
		hq_tile._on_gui_input(UiSim.synthetic_tap())

		assert_eq(GameState.state["currentScreen"], "hq", "the HQ slot navigates to hq")

		nav.free()
	)

	run_case("phone_slot_from_elsewhere_navigates_to_phone_and_resets_to_the_grid", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		GameState.state["phoneNav"]["app"] = "todo"
		var nav := NavBar.new()
		nav._ready()

		var phone_tile: NavBar._DockTile = nav._tiles["phone"]
		phone_tile._on_gui_input(UiSim.synthetic_tap())

		assert_eq(GameState.state["currentScreen"], "phone", "the Phone slot returns to the phone screen from elsewhere")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "the Phone slot resets phoneNav back to the app grid")

		nav.free()
	)

	run_case("phone_slot_from_inside_an_app_returns_to_the_grid_without_a_screen_change", func():
		GameState.reset()
		GameState.state["currentScreen"] = "phone"
		GameState.state["phoneNav"]["app"] = "todo"

		var received: Array[String] = []
		var on_screen := func(screen: String): received.append(screen)
		EventBus.screen_changed.connect(on_screen)

		var nav := NavBar.new()
		nav._ready()

		var phone_tile: NavBar._DockTile = nav._tiles["phone"]
		phone_tile._on_gui_input(UiSim.synthetic_tap())

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

		var phone_tile: NavBar._DockTile = nav._tiles["phone"]
		phone_tile._on_gui_input(UiSim.synthetic_tap())

		EventBus.screen_changed.disconnect(on_screen)
		EventBus.state_changed.disconnect(on_state)

		assert_eq(screen_events, [], "no re-navigation while already on the grid")
		assert_eq(state_event_count, 0, "no state_changed emission (no flicker) while already on the grid")

		nav.free()
	)

	run_case("alarm_arrived_off_tree_pulses_safely_with_no_live_tree_to_tween_against", func():
		GameState.reset()
		var nav := NavBar.new()
		nav._ready()

		# Same is_inside_tree() guard turn_order_strip.gd's drain_ghost_to()
		# uses -- create_tween() requires a live SceneTree, and this off-tree
		# build (this file's own established convention) has none.
		EventBus.alarm_arrived.emit()
		assert_true(true, "the Phone-tab pulse no-ops safely with no live tree")

		nav.free()
	)


func _assert_dock(nav: NavBar, dark: bool, context: String) -> void:
	var paper: Color = MapPalette.colour_in("chromePaper", true) if dark else NavBar._BG_COLOR
	var divider: Color = MapPalette.colour_in("chromeBorder", true) if dark else NavBar._DIVIDER_COLOR
	var action: Color = MapPalette.colour_in("cardAction", true) if dark else UI.action_colour()
	assert_eq(nav._bg_style.bg_color, paper, "%s: dock background" % context)
	assert_eq(nav._bg_style.border_color, divider, "%s: dock top border" % context)
	for line in nav._dividers:
		assert_eq(line.color, divider, "%s: tile divider" % context)
	for screen_id in nav._tiles:
		var tile: NavBar._DockTile = nav._tiles[screen_id]
		assert_eq(tile._icon.colour, action, "%s: %s icon" % [context, screen_id])
		assert_eq(tile._label.get_theme_color("font_color"), action, "%s: %s label" % [context, screen_id])
		assert_eq(tile._active_bar.color, action, "%s: %s active bar" % [context, screen_id])
