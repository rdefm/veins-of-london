extends "res://tests/test_base.gd"

# 11-phone-os-shell ticket 07: PhoneApps registry + build_tile_configs()
# tested standalone against a synthetic roster, same reasoning
# tests/test_app_tile.gd documents for AppTile -- proves the locked-tile
# mechanism even though today's real apps() roster is all-unlocked.


func run() -> void:
	run_case("apps_lists_the_ten_existing_apps_in_a_fixed_order", func():
		var ids: Array[String] = []
		for app in PhoneApps.apps():
			ids.append(app["id"])
		assert_eq(ids, ["messages", "notes", "factions", "ticker", "profile", "saveload", "notifications", "bank", "contacts", "vfl"], "grid slot order comes straight from the registry order")
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
		var configs := PhoneApps.build_tile_configs(synthetic, func(_id): return false)

		assert_eq(configs[0]["locked"], false, "alpha's own predicate says unlocked")
		assert_eq(configs[1]["locked"], true, "beta's own predicate says locked")
	)

	run_case("build_tile_configs_wires_the_injected_badge_predicate_per_app_id", func():
		var synthetic: Array[Dictionary] = [
			{ "id": "messages", "label": "Messages", "locked": func(): return false },
			{ "id": "notes", "label": "Notes", "locked": func(): return false },
		]
		var configs := PhoneApps.build_tile_configs(synthetic, func(id): return id == "messages")

		assert_eq(configs[0]["badge"], true, "messages gets a badge when the predicate says so")
		assert_eq(configs[1]["badge"], false, "notes gets no badge when the predicate says no")
	)

	run_case("fixed_slot_order_and_count_survive_a_lock_state_change", func():
		var state := { "beta_locked": true }
		var synthetic: Array[Dictionary] = [
			{ "id": "alpha", "label": "Alpha", "locked": func(): return false },
			{ "id": "beta", "label": "Beta", "locked": func(): return state["beta_locked"] },
			{ "id": "gamma", "label": "Gamma", "locked": func(): return false },
		]
		var badge_for := func(_id): return false

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
