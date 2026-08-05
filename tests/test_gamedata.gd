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
		corrupted["recipes"]["enhancementPowder"]["ingredient"] = "energy"
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
		assert_true(found, "camden siteCap 4 needs >= 6 stopSlots — 2 should fail validation")
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

	run_case("spot_check_values", func():
		assert_eq(GameData.ORE_TYPES["fate"]["basePrice"], 90, "fate basePrice")
		assert_eq(GameData.ORE_TYPES["emotion"]["symbol"], "❋", "emotion symbol")
		assert_eq(GameData.HOME_TIERS["townhouse"]["maxRooms"], 3, "townhouse maxRooms")
		assert_eq(GameData.RECIPES["enhancementPowder"]["ingredient"], "life", "enhancementPowder ingredient")
		assert_eq(GameData.VEIN_LEVELS["5"]["devBarMax"], 9999, "Lode devBarMax")
		assert_eq(GameData.VEIN_SECURITY["guarded"]["raidResist"], 55, "guarded raidResist")
		assert_eq(GameData.FACTIONS["conclave"]["joinRelation"], 60, "conclave joinRelation")
		assert_almost_eq(GameData.BAROMETER_STATES["economic"]["crisis"]["effects"]["fatePremium"], 0.5, 0.0001, "crisis fatePremium (migrated from void)")
		assert_eq(GameData.DEVICES["enhancementDevice"]["recipeKey"], "enhancementPowder", "enhancementDevice recipeKey")
		assert_eq(GameData.CONSUMABLE_PRICES["timePearl"], 120, "timePearl consumable price")
		assert_eq(GameData.SEED_ORE_COST, 40, "SEED_ORE_COST")
		assert_eq(GameData.ARCHIE_ORE_GOAL, 10, "ARCHIE_ORE_GOAL")
		assert_eq(GameData.DISTRICTS.size(), 9, "9 districts")
		assert_eq(GameData.DISTRICTS["camden"]["siteCap"], 4, "camden siteCap")
		assert_eq(GameData.DISTRICTS["kingscross"]["oreBias"]["time"], 0.3, "kingscross oreBias.time")
		assert_almost_eq(GameData.DISTRICTS["city"]["priceMod"], 0.15, 0.0001, "city priceMod")
		assert_eq(GameData.DISTRICTS["soho"]["siteCap"], 0, "soho has no sites (marketplace, no prospecting)")
		assert_eq(GameData.SITE_TIER_WEIGHTS["fair"], 32, "site tier base weight: fair")
		assert_eq(GameData.SITE_PROSPECT_XP["saturated"], 40, "prospect XP: saturated")
		assert_almost_eq(GameData.SITE_SEED_TIER_MOD["rich"], 0.20, 0.0001, "seed tierMod: rich")
		assert_eq(GameData.SITE_DISCOVERY_BONUS_POOL.size(), 3, "3 discovery bonus types")
		assert_almost_eq(GameData.SITE_NATURAL_VEIN_CHANCE, 0.05, 0.0001, "natural vein chance")
		assert_eq(GameData.MAP_LAYOUT["mapSize"], [1170, 1560], "map_layout mapSize")
		assert_eq(GameData.MAP_LAYOUT["districts"].size(), 9, "map_layout has 9 districts")
		assert_eq(GameData.MAP_LAYOUT["districts"]["camden"]["stopSlots"].size(), 6, "camden siteCap 4 -> 6 stopSlots")
		assert_eq(GameData.MAP_LAYOUT["districts"]["soho"]["stopSlots"].size(), 2, "soho siteCap 0 -> 2 stopSlots")
	)
