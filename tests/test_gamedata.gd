extends "res://tests/test_base.gd"

# T01 acceptance: validation passes on real data; a deliberately corrupted
# fixture fails validation; spot-check representative values across tables.


func run() -> void:
	run_case("real_data_loads_and_validates", func():
		assert_true(GameData.loaded, "GameData should have loaded at boot")
		var ok := GameData.validate()
		assert_true(ok, "GameData.validate() should pass on the real data/*.json tables: %s" % str(GameData.get_errors()))
	)

	run_case("corrupt_fixture_missing_ore_type_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["ore_types"].erase("fate")
		var errors := GameData.validate_tables(corrupted)
		assert_true(not errors.is_empty(), "removing a canonical ore type should fail validation")
	)

	run_case("corrupt_fixture_bad_cross_reference_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["recipes"]["enhancementPowder"]["ingredients"] = { "energy": 6 }
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("energy"):
				found = true
		assert_true(found, "an old-roster ingredient ('energy') should be flagged as an unknown ore type")
	)

	run_case("corrupt_fixture_bad_room_min_tier_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["home_rooms"]["lab"]["minTier"] = "nonexistent_tier"
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("nonexistent_tier"):
				found = true
		assert_true(found, "a room minTier that doesn't exist in home tiers should be flagged")
	)

	run_case("corrupt_fixture_bad_faction_pref_state_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["faction_prefs"]["collective"][0]["state"] = "not_a_real_state"
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("not_a_real_state"):
				found = true
		assert_true(found, "a faction barometer pref pointing at a nonexistent state should be flagged")
	)

	# ── collective1-07: contacts.recruitable / data/collective_barks.json ──

	run_case("corrupt_fixture_contact_missing_recruitable_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["contacts_defaults"]["des"].erase("recruitable")
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("constants.contacts.des") and e.contains("recruitable"):
				found = true
		assert_true(found, "a contact missing recruitable should be flagged")
	)

	run_case("corrupt_fixture_missing_collective_bark_vendor_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["collective_barks"].erase("nadia")
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("collective_barks") and e.contains("nadia"):
				found = true
		assert_true(found, "removing a vendor's bark pool entirely should fail validation")
	)

	run_case("corrupt_fixture_collective_bark_pool_too_short_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["collective_barks"]["hakim"] = ["one line only"]
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("collective_barks.hakim") and e.contains("at least 6"):
				found = true
		assert_true(found, "a bark pool under 6 lines should fail validation")
	)

	run_case("corrupt_fixture_missing_faction_trade_lane_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["faction_trade"].erase("collective")
		var errors := GameData.validate_tables(corrupted)
		assert_true(not errors.is_empty(), "removing the collective's trade lane config should fail validation")
	)

	# ── dial-device ticket 03: capacityCost / dial.capacityByLevel ──────

	run_case("corrupt_fixture_recipe_missing_capacityCost_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["recipes"]["blast"].erase("capacityCost")
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("recipes.blast") and e.contains("capacityCost"):
				found = true
		assert_true(found, "a recipe missing capacityCost should be flagged")
	)

	run_case("corrupt_fixture_recipe_zero_capacityCost_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["recipes"]["blast"]["capacityCost"] = 0
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("recipes.blast") and e.contains("capacityCost"):
				found = true
		assert_true(found, "a recipe with capacityCost <= 0 should be flagged")
	)

	run_case("corrupt_fixture_dial_capacityByLevel_wrong_size_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["dial_capacity_by_level"] = [0, 1, 2]
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("dial.capacityByLevel"):
				found = true
		assert_true(found, "a capacityByLevel table with the wrong number of entries should be flagged")
	)

	# ── collective1-02: data/objectives.json ────────────────────────────

	run_case("corrupt_fixture_objective_unknown_type_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["objectives"]["_test"] = {
			"id": "_test", "title": "t", "detail": "d", "type": "not_a_real_type",
			"params": {}, "activateFlag": "f1", "completeFlag": "f2",
		}
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("not_a_real_type"):
				found = true
		assert_true(found, "an objective with an unknown evaluator type should be flagged")
	)

	run_case("corrupt_fixture_objective_missing_param_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["objectives"]["_test"] = {
			"id": "_test", "title": "t", "detail": "d", "type": "vein_growth_above",
			"params": {}, "activateFlag": "f1", "completeFlag": "f2",
		}
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("missing param 'threshold'"):
				found = true
		assert_true(found, "an objective missing a required param for its type should be flagged")
	)

	run_case("corrupt_fixture_objective_unknown_faction_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["objectives"]["_test"] = {
			"id": "_test", "title": "t", "detail": "d", "type": "traded_with_faction",
			"params": { "factionId": "not_a_real_faction", "oreType": "emotion", "qty": 1, "minTransactions": 1 },
			"activateFlag": "f1", "completeFlag": "f2",
		}
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("not_a_real_faction"):
				found = true
		assert_true(found, "an objective referencing an unknown faction should be flagged")
	)

	# ticket 79: questline groups Notes-app sections (systems/todo.gd) --
	# required on every objective, same as activateFlag/completeFlag.
	run_case("corrupt_fixture_objective_missing_questline_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["objectives"]["_test"] = {
			"id": "_test", "title": "t", "detail": "d", "type": "flag_true",
			"params": {}, "activateFlag": "f1", "completeFlag": "f2",
		}
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("_test") and e.contains("questline"):
				found = true
		assert_true(found, "an objective missing questline should be flagged")
	)

	run_case("corrupt_fixture_objective_null_activateFlag_is_allowed", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["objectives"]["_test"] = {
			"id": "_test", "title": "t", "detail": "d", "type": "flag_true",
			"params": {}, "activateFlag": null, "completeFlag": "f2", "questline": "tutorial",
		}
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("_test"):
				found = true
		assert_true(not found, "activateFlag: null (always active) should not be flagged as invalid")
	)

	run_case("corrupt_fixture_missing_district_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["districts"].erase("soho")
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("soho"):
				found = true
		assert_true(found, "removing a canonical district should fail validation")
	)

	run_case("corrupt_fixture_bad_district_oreBias_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["districts"]["camden"]["oreBias"] = { "energy": 0.6 }
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("energy"):
				found = true
		assert_true(found, "an old-roster oreBias type ('energy') should be flagged as an unknown ore type")
	)

	run_case("corrupt_fixture_bad_site_tier_order_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["site_tier_order"] = ["barren", "poor", "fair", "saturated", "rich"]
		var errors := GameData.validate_tables(corrupted)
		assert_true(not errors.is_empty(), "a reordered site tierOrder should fail validation")
	)

	run_case("corrupt_fixture_seedTierMod_with_barren_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["site_seed_tier_mod"]["barren"] = 0.0
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("barren"):
				found = true
		assert_true(found, "seedTierMod including barren should be flagged — barren sites can't be seeded")
	)

	run_case("corrupt_fixture_missing_map_layout_district_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["map_layout"]["districts"].erase("soho")
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("map_layout.districts") and e.contains("soho"):
				found = true
		assert_true(found, "removing a canonical district from map_layout should fail validation")
	)

	run_case("corrupt_fixture_map_layout_too_few_stop_slots_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["map_layout"]["districts"]["camden"]["stopSlots"] = [[0, 0], [1, 1]]
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("camden") and e.contains("stopSlots"):
				found = true
		assert_true(found, "camden siteCap 6 needs >= 8 stopSlots — 2 should fail validation")
	)

	run_case("corrupt_fixture_bad_event_pin_district_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["events"]["archie_cultivation"]["pin"]["district"] = "not_a_real_district"
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("archie_cultivation.pin") and e.contains("not_a_real_district"):
				found = true
		assert_true(found, "an event pin pointing at an unknown district should be flagged")
	)

	run_case("corrupt_fixture_vein_growth_band_gap_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		# Leave a gap between thinning (max 44) and dormant (min was 45).
		for band in corrupted["vein_growth"]["bands"]:
			if band["id"] == "dormant":
				band["min"] = 46
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("gap or overlap"):
				found = true
		assert_true(found, "a gap between bands should fail validation")
	)

	run_case("corrupt_fixture_vein_growth_bands_not_covering_100_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["vein_growth"]["bands"] = corrupted["vein_growth"]["bands"].filter(func(b): return b["id"] != "rampant")
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("cover through growth 100"):
				found = true
		assert_true(found, "bands that stop short of growth 100 should fail validation")
	)

	run_case("corrupt_fixture_vein_growth_no_dormant_band_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		for band in corrupted["vein_growth"]["bands"]:
			if band["id"] == "dormant":
				band["drift"] = 1  # no longer a resting band at all
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("exactly one drift:0 band straddling neutral"):
				found = true
		assert_true(found, "losing the one resting (drift:0) band straddling neutral should fail validation")
	)

	run_case("spot_check_values", func():
		assert_eq(GameData.ORE_TYPES["fate"]["basePrice"], 90, "fate basePrice")
		assert_eq(GameData.ORE_TYPES["emotion"]["symbol"], "❋", "emotion symbol")
		assert_eq(GameData.HOME_TIERS["townhouse"]["maxRooms"], 3, "townhouse maxRooms")
		assert_true(GameData.RECIPES["enhancementPowder"]["ingredients"].has("life"), "enhancementPowder ingredients")
		assert_eq(GameData.VEIN_GROWTH["neutral"], 50, "vein_growth neutral")
		assert_eq(GameData.VEIN_GROWTH["ceiling"], 100, "vein_growth ceiling")
		assert_eq(GameData.VEIN_GROWTH["seedGrowth"], 20, "vein_growth seedGrowth")
		assert_eq(GameData.VEIN_SECURITY["guarded"]["raidResist"], 55, "guarded raidResist")
		assert_eq(GameData.FACTIONS["conclave"]["joinRelation"], 60, "conclave joinRelation")
		assert_eq(GameData.FACTION_TRADE["collective"]["sellSpreadMax"], 0.45, "collective sellSpreadMax (§8.1)")
		assert_eq(GameData.FACTION_TRADE["collective"]["anchorRelation"], 0, "collective trade lane anchors at relation 0, not joinRelation")
		assert_eq(GameData.FACTION_TRADE["guild"]["anchorRelation"], 40, "guild trade lane still anchors at its joinRelation")
		assert_almost_eq(GameData.BAROMETER_STATES["economic"]["crisis"]["effects"]["fatePremium"], 0.5, 0.0001, "crisis fatePremium (migrated from void)")
		assert_eq(GameData.DIAL_MOVEMENTS["capacitor"]["windingCostPerCharge"][1], 5, "capacitor Movement tier-1 windingCostPerCharge")
		assert_eq(GameData.CONSUMABLE_PRICES["timePearl"], 120, "timePearl consumable price")
		assert_eq(GameData.SEED_ORE_COST, 40, "SEED_ORE_COST")
		assert_eq(GameData.ARCHIE_ORE_GOAL, 10, "ARCHIE_ORE_GOAL")
		assert_eq(GameData.DISTRICTS.size(), 9, "9 districts")
		assert_eq(GameData.DISTRICTS["camden"]["siteCap"], 6, "camden siteCap (base 4 + faction-starting-veins T01's day-1 bump of 2)")
		assert_eq(GameData.DISTRICTS["kingscross"]["oreBias"]["time"], 0.3, "kingscross oreBias.time")
		assert_almost_eq(GameData.DISTRICTS["city"]["priceMod"], 0.15, 0.0001, "city priceMod")
		assert_eq(GameData.DISTRICTS["soho"]["siteCap"], 0, "soho has no sites (marketplace, no prospecting)")
		assert_eq(GameData.SITE_TIER_WEIGHTS["fair"], 32, "site tier base weight: fair")
		assert_eq(GameData.SITE_AT_CAP_TIER_WEIGHTS["poor"], 45, "site at-cap tier weight: poor")
		assert_eq(GameData.SITE_PROSPECT_XP["saturated"], 40, "prospect XP: saturated")
		assert_almost_eq(GameData.SITE_SEED_TIER_MOD["rich"], 0.20, 0.0001, "seed tierMod: rich")
		assert_eq(GameData.SITE_DISCOVERY_BONUS_POOL.size(), 3, "3 discovery bonus types")
		assert_almost_eq(GameData.SITE_NATURAL_VEIN_CHANCE, 0.05, 0.0001, "natural vein chance")
		assert_eq(GameData.MAP_LAYOUT["mapSize"], [1170, 1560], "map_layout mapSize")
		assert_eq(GameData.MAP_LAYOUT["districts"].size(), 9, "map_layout has 9 districts")
		assert_eq(GameData.MAP_LAYOUT["districts"]["camden"]["stopSlots"].size(), 8, "camden siteCap 6 -> 8 stopSlots")
		assert_eq(GameData.MAP_LAYOUT["districts"]["soho"]["stopSlots"].size(), 2, "soho siteCap 0 -> 2 stopSlots")

		# collective1-07, spec §9.3/§9.5
		assert_true(GameData.CONTACTS_DEFAULTS["archie"]["recruitable"], "archie stays recruitable")
		assert_true(GameData.CONTACTS_DEFAULTS["james"]["recruitable"], "james stays recruitable")
		for key in ["des", "nadia", "hakim"]:
			assert_true(not GameData.CONTACTS_DEFAULTS[key]["recruitable"], "%s is never recruitable" % key)
			assert_eq(GameData.CONTACTS_DEFAULTS[key]["startRelation"], 0, "%s starts at relation 0" % key)
			assert_true(not GameData.CONTACTS_DEFAULTS[key]["unlocked"], "%s starts locked" % key)
			assert_true(GameData.COLLECTIVE_BARKS[key].size() >= 6, "%s has at least 6 bark lines" % key)
	)
