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
	)
