extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")


func run() -> void:
	run_case("home_dock_has_exactly_phone_messages_settings_in_equal_slots", func():
		GameState.reset()
		var phone := PhoneScreen.new()
		phone._ready()
		var dock := phone._home_dock
		var ids: Array[String] = []
		for tile in dock.tiles:
			ids.append(tile._app_id)
			assert_eq(tile.size_flags_horizontal, Control.SIZE_EXPAND_FILL, "each dock slot expands equally")
		assert_eq(ids, ["dialer", "messages", "settings"])
		assert_eq(dock.tiles.size(), 3)
		assert_true(dock.visible, "dock is visible on home")
		phone.free()
	)

	run_case("dock_routes_work_and_it_hides_inside_every_app", func():
		for app_id in ["dialer", "messages", "settings"]:
			GameState.reset()
			var phone := PhoneScreen.new()
			phone._ready()
			var tile: AppTile = phone._home_dock.tiles[["dialer", "messages", "settings"].find(app_id)]
			tile.tile_pressed.emit(app_id)
			assert_eq(GameState.state["phoneNav"]["app"], app_id, "%s routes via PhoneNav" % app_id)
			assert_true(not phone._home_dock.visible, "dock hidden in %s" % app_id)
			phone.free()
	)

	run_case("messages_badge_totals_unread_and_clears_after_opening_threads", func():
		GameState.reset()
		Messages.append("archie", "them", "One")
		Messages.append("archie", "them", "Two")
		Messages.append("james", "them", "Three")
		var phone := PhoneScreen.new()
		phone._ready()
		var messages_tile := phone._home_dock.tiles[1]
		assert_eq(messages_tile._badge.count, 3, "badge sums unread across contacts")
		PhoneNav.select_conversation("archie")
		PhoneNav.go_home()
		assert_eq(messages_tile._badge.count, 1, "badge updates after one thread is marked read")
		PhoneNav.select_conversation("james")
		PhoneNav.go_home()
		assert_true(not messages_tile._badge.visible, "zero unread hides badge")
		phone.free()
	)

	run_case("dock_apps_are_absent_from_main_grid_and_external_nav_is_unchanged", func():
		GameState.reset()
		var grid_ids: Array[String] = []
		for app in PhoneApps.apps():
			grid_ids.append(app["id"])
		assert_true(not grid_ids.has("dialer") and not grid_ids.has("messages") and not grid_ids.has("settings"))
		var external_ids: Array[String] = []
		for tab in NavBar.TABS:
			external_ids.append(tab["screen"])
		assert_eq(external_ids, ["phone", "map", "hq"])
	)

	run_case("phone_recent_calls_placeholder_has_no_actions", func():
		GameState.reset()
		PhoneNav.open_app("dialer")
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(NodeQuery.label_texts(phone).has("No recent calls."))
		assert_eq(NodeQuery.button_texts(phone), ["‹ Back"], "Phone adds no calling action")
		phone.free()
	)
