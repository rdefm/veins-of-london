extends "res://tests/test_base.gd"

# col_a1_des_sites guaranteed finds: while the objective is active, the 2nd
# prospect finds a fate site and the 4th a physics site (fair+, unclaimed);
# the count lives in state.collective.desProspectCount.


func _start_thread() -> void:
	GameState.reset()
	GameState.state["flags"]["colA1DesThreadActive"] = true
	GameState.state["flags"]["colA1SkirmishSeen"] = true
	GameState.state["flags"]["colA1IntimidationSeen"] = true


func _prospect() -> Variant:
	GameState.state["event"] = null
	return Sites.prospect("city").get("site")


func run() -> void:
	run_case("second_prospect_finds_fair_plus_unclaimed_fate_and_fourth_physics", func():
		for seed in [1, 2, 3, 4, 5, 6, 7, 8]:
			_start_thread()
			Rng.set_seed(seed)
			_prospect()
			var second: Variant = _prospect()
			_prospect()
			var fourth: Variant = _prospect()
			for pair in [[second, "fate"], [fourth, "physics"]]:
				var site: Variant = pair[0]
				assert_true(site != null, "seed %d: forced find exists" % seed)
				assert_eq(site["oreType"], pair[1])
				assert_true(GameData.SITE_TIER_ORDER.find(site["tier"]) >= GameData.SITE_TIER_ORDER.find("fair"))
				assert_true(not site["claimed"] and site["factionVein"] == null)
			assert_eq(GameState.state["collective"]["desProspectCount"], 4)
	)

	run_case("first_and_third_prospects_are_not_forced", func():
		var seen_non_forced := false
		for seed in range(1, 40):
			_start_thread()
			Rng.set_seed(seed)
			var first: Variant = _prospect()
			_prospect()
			var third: Variant = _prospect()
			if first["oreType"] not in ["fate", "physics"] or third["oreType"] not in ["fate", "physics"] or first["tier"] in ["barren", "poor"]:
				seen_non_forced = true
				break
		assert_true(seen_non_forced, "1st/3rd keep the normal ore/tier rolls")
	)

	run_case("forced_find_skipped_when_that_ore_type_already_reported", func():
		_start_thread()
		GameState.state["objectives"]["col_a1_des_sites"] = { "active": true, "complete": false, "progress": { "reportedSiteIds": { "fate": "x" } } }
		Collective.next_des_forced_ore_type()
		assert_eq(Collective.next_des_forced_ore_type(), "", "2nd would force fate, already reported")
		Collective.next_des_forced_ore_type()
		assert_eq(Collective.next_des_forced_ore_type(), "physics", "4th still forces physics")
	)

	run_case("count_does_not_advance_when_thread_inactive_or_objective_complete", func():
		GameState.reset()
		assert_eq(Collective.next_des_forced_ore_type(), "")
		assert_eq(GameState.state["collective"]["desProspectCount"], 0)
		GameState.state["flags"]["colA1DesThreadActive"] = true
		GameState.state["flags"]["colA1DesSitesFound"] = true
		assert_eq(Collective.next_des_forced_ore_type(), "")
		assert_eq(GameState.state["collective"]["desProspectCount"], 0)
	)

	run_case("forced_find_at_siteCap_replaces_worst_unclaimed_site", func():
		_start_thread()
		var cap: int = GameData.DISTRICTS["city"]["siteCap"]
		for i in cap:
			Sites.spawn_unclaimed_site("city", "poor", "time")
		GameState.state["collective"]["desProspectCount"] = 1
		var site: Variant = _prospect()
		assert_true(site != null)
		assert_eq(site["oreType"], "fate")
		assert_eq(Sites.sites_in_district("city").size(), cap)
	)
