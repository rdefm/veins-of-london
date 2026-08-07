extends "res://tests/test_base.gd"

# Districts — derived indicators + ownership summary for the Map tab's
# district list/panel (M1-LONDON.md D4).


func run() -> void:
	run_case("price_indicator_matches_the_D4_worked_example", func():
		# city priceMod = +0.15
		assert_eq(Districts.price_indicator("city"), "Prices +15%", "positive priceMod formats with an explicit +")
	)

	run_case("price_indicator_negative_mod_keeps_the_minus_sign_only", func():
		# camden priceMod = -0.05
		assert_eq(Districts.price_indicator("camden"), "Prices -5%", "negative priceMod should not double up on sign")
	)

	run_case("price_indicator_empty_at_zero_mod", func():
		# shoreditch priceMod = 0.00
		assert_eq(Districts.price_indicator("shoreditch"), "", "zero priceMod produces no indicator")
	)

	run_case("danger_indicator_rough_for_positive_dangerMod", func():
		# camden dangerMod = +0.10
		assert_eq(Districts.danger_indicator("camden"), "Rough", "positive dangerMod is labelled Rough per D4's example")
	)

	run_case("danger_indicator_safe_for_negative_dangerMod", func():
		# city dangerMod = -0.05
		assert_eq(Districts.danger_indicator("city"), "Safe", "negative dangerMod is labelled Safe")
	)

	run_case("danger_indicator_empty_at_zero_mod", func():
		# shoreditch dangerMod = 0.00
		assert_eq(Districts.danger_indicator("shoreditch"), "", "zero dangerMod produces no indicator")
	)

	run_case("derived_indicators_combines_both_and_skips_empties", func():
		assert_eq(Districts.derived_indicators("camden"), ["Prices -5%", "Rough"], "camden should show both a price and a danger indicator")
		assert_eq(Districts.derived_indicators("shoreditch"), [], "shoreditch has zero mods on both axes -> no indicators")
	)

	run_case("ownership_summary_no_sites_discovered_yet", func():
		GameState.reset()
		assert_eq(Districts.ownership_summary("camden"), "No sites discovered yet.", "a district with no sites in state.world.sites")
	)

	run_case("ownership_summary_counts_claimed_against_all_discovered_sites", func():
		GameState.reset()
		var unclaimed := { "id": "s1", "district": "camden", "tier": "poor", "oreType": "physics", "bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null, "hasNaturalVein": false }
		var yours := { "id": "s2", "district": "camden", "tier": "fair", "oreType": "physics", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false }
		var npc := { "id": "s3", "district": "camden", "tier": "rich", "oreType": "physics", "bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": { "id": "fv1", "factionId": "collective", "oreType": "physics", "level": 1, "devBar": 0, "security": "none", "claimedOnDay": 2 }, "hasNaturalVein": false }
		GameState.state["world"]["sites"] = [unclaimed, yours, npc]
		assert_eq(Districts.ownership_summary("camden"), "1 of 3 sites yours", "denominator counts all three claim states, numerator only player-claimed")
	)
