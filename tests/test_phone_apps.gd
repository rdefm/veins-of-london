extends "res://tests/test_base.gd"

# 11-phone-os-shell ticket 07: PhoneApps registry + build_tile_configs()
# tested standalone against a synthetic roster, same reasoning
# tests/test_app_tile.gd documents for AppTile -- proves the locked-tile
# mechanism even though today's real apps() roster is all-unlocked.


func run() -> void:
	run_case("apps_lists_the_twelve_main_apps_in_the_locked_order_and_labels", func():
		GameState.reset()
		var ids: Array[String] = []
		var labels: Array[String] = []
		for app in PhoneApps.apps():
			ids.append(app["id"])
			labels.append(app["label"])
		assert_eq(ids, ["alarms", "todo", "bizbrief", "ticker", "factions", "bank", "property", "profile", "contacts", "vfl", "notifications", "saveload"], "grid slot order comes straight from the registry order")
		assert_eq(labels, ["Alarms", "ToDo", "BizBrief", "The Ticker", "Factions", "Reynard's", "Harrow's", "My File", "Contacts", "VfL", "Notifications", "Save/Load"], "player-facing launcher labels are exact")
	)

	# 01-debug-app: the Debug tile is genuinely absent from the roster on a
	# normal save (not merely locked -- see PhoneApps.apps()'s own comment),
	# and appears (unlocked) only once flags.debugStartUsed is true.
	run_case("debug_app_is_absent_from_the_roster_on_a_normal_new_game", func():
		GameState.reset()
		var ids: Array[String] = []
		for app in PhoneApps.apps():
			ids.append(app["id"])
		assert_true(not ids.has("debug"), "a normally-started game never sees a debug entry")
	)

	run_case("debug_app_appears_unlocked_once_debugStartUsed_is_true", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		var apps := PhoneApps.apps()
		var ids: Array[String] = []
		for app in apps:
			ids.append(app["id"])
		assert_eq(ids[-1], "debug", "debug appends after Save/Load")
		assert_eq(ids[-2], "saveload", "Save/Load remains slot 12 before conditional Debug")

		var debug_locked: Callable
		for app in apps:
			if app["id"] == "debug":
				debug_locked = app["locked"]
		assert_true(not debug_locked.call(), "the debug tile itself is never locked once visible")
	)

	run_case("todays_roster_is_entirely_unlocked_except_vfl", func():
		GameState.reset()
		for app in PhoneApps.apps():
			var locked_check: Callable = app["locked"]
			var expected_locked: bool = app["id"] == "vfl"
			assert_eq(locked_check.call(), expected_locked, "lock state for %s" % app["id"])
	)

	run_case("vfl_locked_predicate_mirrors_archiePartnerSeen", func():
		GameState.reset()
		var vfl_locked: Callable
		for app in PhoneApps.apps():
			if app["id"] == "vfl":
				vfl_locked = app["locked"]
		assert_true(vfl_locked.call(), "vfl starts locked before archiePartnerSeen")

		GameState.state["flags"]["archiePartnerSeen"] = true
		assert_true(not vfl_locked.call(), "vfl unlocks once archiePartnerSeen is true")
	)

	run_case("build_tile_configs_reflects_each_apps_locked_predicate", func():
		var synthetic: Array[Dictionary] = [
			{ "id": "alpha", "label": "Alpha", "locked": func(): return false },
			{ "id": "beta", "label": "Beta", "locked": func(): return true },
		]
		var configs := PhoneApps.build_tile_configs(synthetic, func(_id): return 0)

		assert_eq(configs[0]["locked"], false, "alpha's own predicate says unlocked")
		assert_eq(configs[1]["locked"], true, "beta's own predicate says locked")
	)

	run_case("build_tile_configs_wires_non_negative_numeric_badge_counts_per_app_id", func():
		var synthetic: Array[Dictionary] = [
			{ "id": "messages", "label": "Messages", "locked": func(): return false },
			{ "id": "todo", "label": "ToDo", "locked": func(): return false },
		]
		var configs := PhoneApps.build_tile_configs(synthetic, func(id): return 7 if id == "messages" else -4)

		assert_eq(configs[0]["badge"], 7, "messages gets the live numeric count")
		assert_eq(configs[1]["badge"], 0, "negative counts are clamped to zero")
	)

	run_case("fixed_slot_order_and_count_survive_a_lock_state_change", func():
		var state := { "beta_locked": true }
		var synthetic: Array[Dictionary] = [
			{ "id": "alpha", "label": "Alpha", "locked": func(): return false },
			{ "id": "beta", "label": "Beta", "locked": func(): return state["beta_locked"] },
			{ "id": "gamma", "label": "Gamma", "locked": func(): return false },
		]
		var badge_for := func(_id): return 0

		var before := PhoneApps.build_tile_configs(synthetic, badge_for)
		state["beta_locked"] = false
		var after := PhoneApps.build_tile_configs(synthetic, badge_for)

		var before_ids: Array = before.map(func(c): return c["id"])
		var after_ids: Array = after.map(func(c): return c["id"])
		assert_eq(before_ids, ["alpha", "beta", "gamma"], "slot order before the unlock")
		assert_eq(after_ids, ["alpha", "beta", "gamma"], "slot order is unchanged after the unlock -- no reflow")
		assert_eq(before[1]["locked"], true, "beta reads locked before the state change")
		assert_eq(after[1]["locked"], false, "beta reads unlocked after the state change, same slot")
	)

	run_case("every_main_grid_and_debug_icon_exists_as_a_square_128px_alpha_png", func():
		var ids := ["alarms", "todo", "bizbrief", "ticker", "factions", "bank", "property", "profile", "contacts", "vfl", "notifications", "saveload", "debug"]
		for id in ids:
			var path := AppTile.icon_path(id)
			assert_true(FileAccess.file_exists(path), "%s icon exists at the ADR contract path" % id)
			var image := Image.load_from_file(path)
			assert_eq(image.get_size(), Vector2i(128, 128), "%s icon is exactly 128x128" % id)
			assert_eq(image.get_format(), Image.FORMAT_RGBA8, "%s icon carries an alpha channel" % id)
	)
