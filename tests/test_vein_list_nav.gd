extends "res://tests/test_base.gd"

# VeinListNav — transient nav state for the vein list screen (state.
# veinListNav, vein-growth-state ticket 09), same convention as
# tests/test_map_nav.gd/test_phone_nav.gd cover for their own nav systems.


func run() -> void:
	run_case("open_for_district_scopes_to_the_district_clears_the_band_filter_and_remembers_map_as_origin", func():
		GameState.reset()
		VeinListNav.set_band_filter("wild")  # a stale filter from a previous visit

		VeinListNav.open_for_district("shoreditch")

		assert_eq(GameState.state["veinListNav"]["districtId"], "shoreditch")
		assert_eq(GameState.state["veinListNav"]["bandFilter"], null, "opening scoped to a district must not carry over a stale filter")
		assert_eq(GameState.state["veinListNav"]["originScreen"], "map", "the district bubble's entry point is the Map tab")
	)

	run_case("open_all_scopes_to_every_district_and_remembers_hq_as_origin", func():
		GameState.reset()
		VeinListNav.open_for_district("camden")  # a stale scope from a previous visit

		VeinListNav.open_all()

		assert_eq(GameState.state["veinListNav"]["districtId"], null, "HQ's entry point is unfiltered -- every district")
		assert_eq(GameState.state["veinListNav"]["bandFilter"], null)
		assert_eq(GameState.state["veinListNav"]["originScreen"], "hq", "HQ's Vein Station room is the entry point")
	)

	run_case("set_band_filter_updates_only_the_band_filter", func():
		GameState.reset()
		VeinListNav.open_for_district("greenwich")

		VeinListNav.set_band_filter("collapsed")

		assert_eq(GameState.state["veinListNav"]["bandFilter"], "collapsed")
		assert_eq(GameState.state["veinListNav"]["districtId"], "greenwich", "changing the filter must not disturb the scope")
		assert_eq(GameState.state["veinListNav"]["originScreen"], "map")
	)

	run_case("set_band_filter_to_null_clears_it", func():
		GameState.reset()
		VeinListNav.open_for_district("greenwich")
		VeinListNav.set_band_filter("wild")

		VeinListNav.set_band_filter(null)

		assert_eq(GameState.state["veinListNav"]["bandFilter"], null)
	)

	run_case("nav_functions_emit_state_changed", func():
		GameState.reset()
		var received := [false]
		var on_changed := func(): received[0] = true
		EventBus.state_changed.connect(on_changed)
		VeinListNav.open_all()
		EventBus.state_changed.disconnect(on_changed)

		assert_true(received[0])
	)
