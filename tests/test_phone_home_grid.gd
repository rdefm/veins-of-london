extends "res://tests/test_base.gd"

# 11-phone-os-shell ticket 07: the phone home grid, tested against a real
# PhoneScreen instance (same headless-scene pattern as
# tests/test_hq_screen.gd/test_lab_screen.gd -- PhoneScreen.new()/_ready()
# is safe to call without a live tree).
#
# Nested AppTile children built by PhoneScreen's grid loop are safe to
# inspect here (_lock_overlay.visible, _badge.visible, ...) because
# AppTile.configure() self-heals via _ensure_built() (app_tile.gd) if its
# own _ready() hasn't run yet -- see that file's comment for why a plain
# add_child()-then-configure() in the same synchronous stretch can outrun
# the engine's own NOTIFICATION_READY dispatch under a headless test that
# never adds anything to a live, processing tree.


static func _find_tiles(root: Node) -> Array[AppTile]:
	var tiles: Array[AppTile] = []
	for t in root.find_children("", "AppTile", true, false):
		tiles.append(t as AppTile)
	return tiles


func run() -> void:
	run_case("home_renders_one_fixed_slot_tile_per_registered_app_in_order", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		var tiles := _find_tiles(phone)
		var ids: Array[String] = []
		for t in tiles:
			ids.append(t._app_id)
		assert_eq(ids, ["messages", "notes", "factions", "ticker", "profile", "saveload", "notifications", "bank", "vfl"], "grid renders the registry's apps, in registry order")

		phone.free()
	)

	run_case("grid_slot_count_matches_the_registry_exactly", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		assert_eq(_find_tiles(phone).size(), PhoneApps.apps().size(), "one tile per registry entry, no more, no fewer")

		phone.free()
	)

	run_case("none_of_todays_apps_render_locked_except_vfl_before_archies_partner_scene", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		for t in _find_tiles(phone):
			var expected_locked: bool = t._app_id == "vfl"
			assert_eq(t._lock_overlay.visible, expected_locked, "%s lock render state" % t._app_id)
			var expected_tint := AppTile.LOCKED_TINT if expected_locked else AppTile.NORMAL_TINT
			assert_eq(t._name_label.modulate, expected_tint, "%s label tint" % t._app_id)

		phone.free()
	)

	run_case("badge_dot_visibility_on_the_rendered_tiles_matches_the_pending_predicates", func():
		GameState.reset()
		GameState.state["flags"]["tutorialStage"] = "sms_archie"

		var phone := PhoneScreen.new()
		phone._ready()

		for t in _find_tiles(phone):
			var expected := t._app_id == "messages"
			assert_eq(t._badge.visible, expected, "%s badge dot visibility" % t._app_id)

		phone.free()
	)

	run_case("badge_for_reflects_the_real_pending_messages_predicate", func():
		GameState.reset()
		GameState.state["flags"]["tutorialStage"] = "sms_archie"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(phone._badge_for("messages"), "messages badge follows _has_pending_messages()")

		phone.free()
	)

	run_case("badge_for_reflects_the_real_ticker_rumblings_predicate", func():
		GameState.reset()
		Barometer.ensure_progress()
		# "economic" defaults to active state "stable" -- pushing a
		# different state's progress to the trend-hint threshold
		# (systems/barometer.gd TREND_HINT_THRESHOLD=70) is what
		# _has_ticker_rumblings() checks for.
		GameState.state["barometer"]["progress"]["economic"]["boom"] = 80

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(phone._badge_for("ticker"), "ticker badge follows _has_ticker_rumblings()")

		phone.free()
	)

	run_case("badge_for_is_false_for_both_wired_apps_on_a_fresh_game", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(not phone._badge_for("messages"), "no pending messages on a fresh game")
		assert_true(not phone._badge_for("ticker"), "no rumblings on a fresh game")

		phone.free()
	)

	run_case("badge_for_is_false_for_apps_with_no_wired_predicate", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(not phone._badge_for("notes"), "notes has no badge predicate")
		assert_true(not phone._badge_for("factions"), "factions has no badge predicate")

		phone.free()
	)

	run_case("a_locked_synthetic_app_renders_locked_through_the_real_screen_grid_loop", func():
		# PhoneApps' real, shipped roster is all-unlocked today (no app is
		# gated yet), so this exercises _build_app_grid() -- the same
		# production loop _build_home() calls -- against a synthetic
		# registry to prove the locked path threads through configure()
		# correctly, same reasoning tests/test_phone_apps.gd documents for
		# build_tile_configs() itself.
		GameState.reset()

		var phone := PhoneScreen.new()
		var synthetic: Array[Dictionary] = [
			{ "id": "messages", "label": "Messages", "locked": func(): return false },
			{ "id": "map", "label": "Map", "locked": func(): return true },
		]
		var grid := phone._build_app_grid(synthetic)

		var tiles := _find_tiles(grid)
		assert_eq(tiles.size(), 2, "one tile per synthetic entry")
		assert_true(not tiles[0]._lock_overlay.visible, "messages renders unlocked")
		assert_true(tiles[1]._lock_overlay.visible, "map renders locked -- not hidden, not replaced with hint text")
		assert_true(tiles[1].visible, "the locked tile still occupies its slot rather than being hidden")

		phone.free()
	)

	run_case("fixed_slot_positions_survive_a_lock_state_change_through_the_real_screen_grid_loop", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		var state := { "map_locked": true }
		var synthetic: Array[Dictionary] = [
			{ "id": "messages", "label": "Messages", "locked": func(): return false },
			{ "id": "map", "label": "Map", "locked": func(): return state["map_locked"] },
			{ "id": "notes", "label": "Notes", "locked": func(): return false },
		]

		var before := phone._build_app_grid(synthetic)
		var before_tiles := _find_tiles(before)
		var before_ids: Array[String] = []
		for t in before_tiles:
			before_ids.append(t._app_id)
		assert_eq(before_ids, ["messages", "map", "notes"], "slot order before unlocking")
		assert_true(before_tiles[1]._lock_overlay.visible, "map renders locked before the state change")

		state["map_locked"] = false
		var after := phone._build_app_grid(synthetic)
		var after_tiles := _find_tiles(after)
		var after_ids: Array[String] = []
		for t in after_tiles:
			after_ids.append(t._app_id)
		assert_eq(after_ids, ["messages", "map", "notes"], "slot order is unchanged after unlocking -- no reflow")
		assert_true(not after_tiles[1]._lock_overlay.visible, "map renders unlocked after the state change, same slot")

		before.free()
		after.free()
		phone.free()
	)

	run_case("tapping_a_tile_opens_that_app_via_PhoneNav", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		var notes_tile: AppTile = null
		for t in _find_tiles(phone):
			if t._app_id == "notes":
				notes_tile = t
		assert_true(notes_tile != null, "notes tile must exist")

		var event := InputEventScreenTouch.new()
		event.pressed = true
		notes_tile._on_gui_input(event)

		assert_eq(GameState.state["phoneNav"]["app"], "notes", "tapping a tile routes through PhoneNav.open_app, same as before this ticket")

		phone.free()
	)

	# bugfixes-39: the vfl tile is a cosmetic rebrand of the dock's own Map
	# entry point, not a real PhoneNav app -- these two cases prove it
	# bypasses PhoneNav.open_app() entirely in both lock states.
	run_case("tapping_the_locked_vfl_tile_pushes_the_dock_lock_toast_and_does_not_navigate", func():
		GameState.reset()
		GameState.state["currentScreen"] = "phone"

		var phone := PhoneScreen.new()
		phone._ready()

		var vfl_tile: AppTile = null
		for t in _find_tiles(phone):
			if t._app_id == "vfl":
				vfl_tile = t
		assert_true(vfl_tile != null, "vfl tile must exist")

		var event := InputEventScreenTouch.new()
		event.pressed = true
		vfl_tile._on_gui_input(event)

		assert_eq(GameState.state["currentScreen"], "phone", "a locked vfl tap never navigates")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "a locked vfl tap never opens a PhoneNav app either")
		var notifications: Array = GameState.state["notifications"]
		assert_eq(notifications.size(), 1, "a toast notification is pushed instead of navigating")
		assert_eq(notifications[0]["text"], NavBar.LOCKED_MAP_LABEL, "the toast carries the same lock hint text the dock's Map slot shows")

		phone.free()
	)

	run_case("tapping_the_unlocked_vfl_tile_navigates_straight_to_map_without_touching_phoneNav", func():
		GameState.reset()
		GameState.state["flags"]["archiePartnerSeen"] = true
		GameState.state["currentScreen"] = "phone"

		var phone := PhoneScreen.new()
		phone._ready()

		var vfl_tile: AppTile = null
		for t in _find_tiles(phone):
			if t._app_id == "vfl":
				vfl_tile = t
		assert_true(vfl_tile != null, "vfl tile must exist")

		var event := InputEventScreenTouch.new()
		event.pressed = true
		vfl_tile._on_gui_input(event)

		assert_eq(GameState.state["currentScreen"], "map", "an unlocked vfl tap navigates straight to the Map screen")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "navigating to Map never routes through PhoneNav.open_app -- phoneNav.app is untouched")

		phone.free()
	)
