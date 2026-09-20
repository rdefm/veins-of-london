extends "res://tests/test_base.gd"

# MapNav — Map tab drill-down state (M1-LONDON.md D4: district list ->
# district panel -> site/vein sheet).


func run() -> void:
	run_case("select_district_sets_selectedDistrict_and_emits", func():
		GameState.reset()
		var received := [false]
		var on_changed := func(): received[0] = true
		EventBus.state_changed.connect(on_changed)
		MapNav.select_district("camden")
		EventBus.state_changed.disconnect(on_changed)

		assert_eq(GameState.state["mapNav"]["selectedDistrict"], "camden", "selectedDistrict should update")
		assert_true(received[0], "state_changed should fire")
	)

	run_case("select_site_sets_selectedSiteId", func():
		GameState.reset()
		MapNav.select_district("camden")
		MapNav.select_site("s1")
		assert_eq(GameState.state["mapNav"]["selectedSiteId"], "s1", "selectedSiteId should update")
		assert_eq(GameState.state["mapNav"]["selectedDistrict"], "camden", "selecting a site should not disturb the selected district")
	)

	run_case("close_site_sheet_clears_only_the_site", func():
		GameState.reset()
		MapNav.select_district("camden")
		MapNav.select_site("s1")
		MapNav.close_site_sheet()
		assert_eq(GameState.state["mapNav"]["selectedSiteId"], null, "selectedSiteId should clear")
		assert_eq(GameState.state["mapNav"]["selectedDistrict"], "camden", "district selection should survive closing the site sheet")
	)

	run_case("back_to_list_clears_both_district_and_site", func():
		GameState.reset()
		MapNav.select_district("camden")
		MapNav.select_site("s1")
		MapNav.back_to_list()
		assert_eq(GameState.state["mapNav"]["selectedDistrict"], null, "selectedDistrict should clear")
		assert_eq(GameState.state["mapNav"]["selectedSiteId"], null, "selectedSiteId should also clear — no site sheet without a district panel")
	)

	# 11-detail-panel-ui: the vein detail panel's own drill-down slot.

	run_case("select_vein_detail_sets_selectedVeinId_and_clears_selectedSiteId", func():
		GameState.reset()
		MapNav.select_district("camden")
		MapNav.select_site("s1")
		MapNav.select_vein_detail("v1")
		assert_eq(GameState.state["mapNav"]["selectedVeinId"], "v1")
		assert_eq(GameState.state["mapNav"]["selectedSiteId"], null, "the site sheet and the vein detail panel are mutually exclusive")
		assert_eq(GameState.state["mapNav"]["selectedDistrict"], "camden", "selecting a vein detail should not disturb the selected district")
	)

	run_case("select_site_clears_selectedVeinId", func():
		GameState.reset()
		MapNav.select_vein_detail("v1")
		MapNav.select_site("s1")
		assert_eq(GameState.state["mapNav"]["selectedSiteId"], "s1")
		assert_eq(GameState.state["mapNav"]["selectedVeinId"], null, "opening the site sheet closes any open vein detail panel")
	)

	run_case("close_vein_detail_clears_only_the_vein", func():
		GameState.reset()
		MapNav.select_district("camden")
		MapNav.select_vein_detail("v1")
		MapNav.close_vein_detail()
		assert_eq(GameState.state["mapNav"]["selectedVeinId"], null)
		assert_eq(GameState.state["mapNav"]["selectedDistrict"], "camden", "district selection should survive closing the vein detail panel")
	)

	run_case("back_to_list_also_clears_the_vein_detail_panel", func():
		GameState.reset()
		MapNav.select_district("camden")
		MapNav.select_vein_detail("v1")
		MapNav.back_to_list()
		assert_eq(GameState.state["mapNav"]["selectedVeinId"], null, "no vein detail panel without a district panel")
	)
