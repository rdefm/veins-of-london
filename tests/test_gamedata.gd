extends "res://tests/test_base.gd"

# T01 acceptance: validation passes on real data; a deliberately corrupted
# fixture fails validation; spot-check representative values across tables.


func run() -> void:
	run_case("real_data_loads_and_validates", func():
		assert_true(GameData.loaded, "GameData should have loaded at boot")
		var ok := GameData.validate()
		assert_true(ok, "GameData.validate() should pass on the real data/*.json tables: %s" % str(GameData.get_errors()))
	)

	# ── load manifest: field values, load-error naming ──────────────────

	# tests/fixtures/gamedata_pre_manifest_snapshot.gdvar is a var_to_str()
	# dump of every GameData public loader field. var_to_str/str_to_var (not
	# JSON) round-trips int vs. float exactly -- Dictionary/Array equality
	# in Godot compares element types, not just numeric value, so a JSON
	# round-trip (which reads every number back as float) would falsely
	# flag fields that are legitimately int.
	#
	# DAILY_CYCLE is the one deliberate exception: it loads through the same
	# _load_json/_normalize_numbers pipeline every other table does, which
	# turns its whole-number fields (e.g. frameCount) into int. Every reader
	# of those fields already casts with int()/float() (scenes/components/
	# time_transition.gd etc.), so this is safe. Compared here against the
	# fixture's own value passed through _normalize_numbers, to prove that's
	# the *only* difference from the fixture.
	run_case("public_fields_match_pre_manifest_load_snapshot", func():
		var f := FileAccess.open("res://tests/fixtures/gamedata_pre_manifest_snapshot.gdvar", FileAccess.READ)
		assert_true(f != null, "pre-manifest snapshot fixture should be readable")
		var expected: Dictionary = str_to_var(f.get_as_text())
		f.close()
		for field in expected.keys():
			if field == "DAILY_CYCLE":
				continue
			assert_eq(GameData.get(field), expected[field], "%s should match the load manifest's snapshot fixture" % field)
		assert_eq(GameData.DAILY_CYCLE, GameData._normalize_numbers(expected["DAILY_CYCLE"]), "DAILY_CYCLE should match the fixture once normalized the same way every other table already is")
	)

	run_case("manifest_missing_file_reports_a_load_error_naming_the_table", func():
		var before := GameData._load_errors.size()
		var result := GameData._load_json("res://data/__manifest_test_missing__.json", "some_table")
		assert_eq(result, {}, "a missing manifest file should load as an empty dict, same as any other _load_json failure")
		var found := false
		for e in GameData._load_errors.slice(before):
			if e.contains("some_table") and e.contains("Missing data file"):
				found = true
		assert_true(found, "a missing manifest file should report a load error naming its table")
	)

	run_case("manifest_wrong_type_value_reports_table_and_field", func():
		var errors: Array[String] = []
		var value: Variant = GameData._resolve_manifest_value({"movements": "not_a_dict"}, {"field": "DIAL_MOVEMENTS", "key": "movements", "type": TYPE_DICTIONARY}, "dial", errors)
		assert_eq(value, {}, "a wrong-type manifest value should fall back to the type's default")
		var found := false
		for e in errors:
			if e.contains("dial") and e.contains("DIAL_MOVEMENTS"):
				found = true
		assert_true(found, "a wrong-type manifest value should report a load error naming its table and field")
	)

	run_case("manifest_int_value_for_a_float_field_is_widened_not_flagged", func():
		# _normalize_numbers() turns a whole-number JSON float (e.g. dial.json's
		# "baseRechargeRate": 2.0) into an int -- a float-typed field reading
		# one back out is the same int->float widening a plain assignment did
		# before this manifest existed, not a data error.
		var errors: Array[String] = []
		var value = GameData._resolve_manifest_value({"rate": 2}, {"field": "SOME_FLOAT_FIELD", "key": "rate", "type": TYPE_FLOAT}, "some_table", errors)
		assert_eq(value, 2.0, "an int value for a float-typed field should widen to float")
		assert_true(errors.is_empty(), "widening int to float should not report an error")
	)

	# No id-list const drives events loading -- whatever files live under
	# data/events/ at boot is the loaded roster.
	run_case("loaded_events_match_data_events_directory", func():
		var dir := DirAccess.open("res://data/events/")
		assert_true(dir != null, "res://data/events/ should be listable")
		var files_on_disk: Array[String] = []
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				files_on_disk.append(file_name.get_basename())
			file_name = dir.get_next()
		dir.list_dir_end()
		files_on_disk.sort()

		var loaded_ids: Array = GameData.EVENTS.keys()
		loaded_ids.sort()
		assert_eq(loaded_ids, files_on_disk, "GameData.EVENTS should be exactly the event files on disk")
	)

	run_case("corrupt_fixture_event_id_mismatched_with_filename_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["events"]["intro"]["id"] = "not_intro"
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("events.intro") and e.contains("does not match filename"):
				found = true
		assert_true(found, "an event whose id field disagrees with its filename should fail validation")
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

	# ── dial-device ticket 03: dial.capacityByLevel ──────────────────────

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

	# ticket 79: questline groups ToDo-app sections (systems/todo.gd) --
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

	run_case("corrupt_fixture_objective_faction_vein_seeded_count_unknown_faction_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["objectives"]["_test"] = {
			"id": "_test", "title": "t", "detail": "d", "type": "faction_vein_seeded_count",
			"params": { "factionId": "not_a_real_faction", "minCount": 1 },
			"activateFlag": "f1", "completeFlag": "f2", "questline": "collective",
		}
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("not_a_real_faction"):
				found = true
		assert_true(found, "faction_vein_seeded_count referencing an unknown faction should be flagged")
	)

	run_case("corrupt_fixture_objective_items_crafted_set_unknown_recipe_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["objectives"]["_test"] = {
			"id": "_test", "title": "t", "detail": "d", "type": "items_crafted_set",
			"params": { "recipeKeys": ["not_a_real_recipe"], "minEach": 1 },
			"activateFlag": "f1", "completeFlag": "f2", "questline": "collective",
		}
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("not_a_real_recipe"):
				found = true
		assert_true(found, "items_crafted_set referencing an unknown recipe should be flagged")
	)

	run_case("corrupt_fixture_objective_items_crafted_set_empty_recipeKeys_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["objectives"]["_test"] = {
			"id": "_test", "title": "t", "detail": "d", "type": "items_crafted_set",
			"params": { "recipeKeys": [], "minEach": 1 },
			"activateFlag": "f1", "completeFlag": "f2", "questline": "collective",
		}
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("_test") and e.contains("recipeKeys"):
				found = true
		assert_true(found, "items_crafted_set with an empty recipeKeys array should be flagged")
	)

	run_case("corrupt_fixture_objective_alarm_defend_wins_missing_minCount_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["objectives"]["_test"] = {
			"id": "_test", "title": "t", "detail": "d", "type": "alarm_defend_wins",
			"params": {}, "activateFlag": "f1", "completeFlag": "f2", "questline": "collective",
		}
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("missing param 'minCount'"):
				found = true
		assert_true(found, "alarm_defend_wins missing minCount should be flagged")
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
		assert_true(found, "camden siteCap 6 needs >= 12 stopSlots — 2 should fail validation")
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

	# ── day-rhythm-business-and-combat ticket 14: data/combat_prototype.json ──

	run_case("corrupt_fixture_combat_prototype_missing_encounter_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["combat_prototype"]["encounters"].erase("brawler")
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("brawler"):
				found = true
		assert_true(found, "an encounterOrder id missing its encounters entry should be flagged")
	)

	run_case("corrupt_fixture_combat_prototype_unknown_script_action_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["combat_prototype"]["encounters"]["brawler"]["script"] = ["stomp"]
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("stomp"):
				found = true
		assert_true(found, "a script entry naming an action outside CombatPrototype.SCRIPTABLE_ACTIONS should be flagged")
	)

	# ── combat-presentation ticket 08: data/combat_visuals.json ──

	run_case("corrupt_fixture_combat_visuals_missing_canonical_context_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["combat_visuals"]["backdrops"].erase("defend_vein")
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("defend_vein"):
				found = true
		assert_true(found, "a canonical context missing its backdrop entry should be flagged -- is_canonical_context() staying the single source of truth means a new context is caught here too")
	)

	run_case("corrupt_fixture_combat_visuals_location_backdrop_without_image_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["combat_visuals"]["locationBackdrops"] = { "camden": { "image": "" } }
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("locationBackdrops.camden"):
				found = true
		assert_true(found, "an empty location plate entry would mask the context tier and must be flagged")
	)

	run_case("corrupt_fixture_combat_visuals_no_image_and_no_fallback_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["combat_visuals"]["backdrops"]["defend_vein"]["fallbackColor"] = ""
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("defend_vein") and e.contains("render nothing"):
				found = true
		assert_true(found, "a context with neither an image nor a fallbackColor should be flagged -- the stage would render nothing")
	)

	run_case("corrupt_fixture_combat_visuals_unknown_fallback_color_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["combat_visuals"]["backdrops"]["raid"]["fallbackColor"] = "not_a_real_colour"
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("not_a_real_colour"):
				found = true
		assert_true(found, "a fallbackColor that isn't a data/palette.json colour id should be flagged")
	)

	run_case("corrupt_fixture_combat_visuals_archie_deal_mugging_diverging_from_mugging_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["combat_visuals"]["backdrops"]["archie_deal_mugging"]["fallbackColor"] = "brick_shadow"
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("archie_deal_mugging") and e.contains("must exactly match backdrops.mugging"):
				found = true
		assert_true(found, "archie_deal_mugging is a permanent alias of mugging's backdrop -- any divergence between the two entries should fail validation, not just a test convention")
	)

	# ── hq-diorama ticket 01: data/hq_visuals.json ──

	run_case("corrupt_fixture_hq_visuals_no_image_and_no_fallback_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		# hq-diorama ticket 10 gave bedsit a real "image", so this fixture must
		# null that out too -- otherwise it's no longer the "neither set" case
		# this test means to cover.
		corrupted["hq_visuals"]["rooms"]["bedsit"]["image"] = ""
		corrupted["hq_visuals"]["rooms"]["bedsit"]["fallbackColor"] = ""
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("bedsit") and e.contains("render nothing"):
				found = true
		assert_true(found, "a room with neither an image nor a fallbackColor should be flagged -- the room would render nothing")
	)

	run_case("corrupt_fixture_hq_visuals_unknown_fallback_color_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["hq_visuals"]["rooms"]["bedsit"]["fallbackColor"] = "not_a_real_colour"
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("not_a_real_colour"):
				found = true
		assert_true(found, "a fallbackColor that isn't a data/palette.json colour id should be flagged")
	)

	run_case("corrupt_fixture_hq_visuals_undersized_region_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["hq_visuals"]["rooms"]["bedsit"]["regions"]["dial"]["width"] = 20
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("dial") and e.contains("44x44"):
				found = true
		assert_true(found, "a region smaller than 44x44 logical px should be flagged (docs/hq-diorama-vision.md §3.2)")
	)

	run_case("corrupt_fixture_hq_visuals_overlapping_regions_fail", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		var dial: Dictionary = corrupted["hq_visuals"]["rooms"]["bedsit"]["regions"]["dial"]
		var lab: Dictionary = corrupted["hq_visuals"]["rooms"]["bedsit"]["regions"]["lab"]
		lab["x"] = dial["x"]
		lab["y"] = dial["y"]
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("overlaps region"):
				found = true
		assert_true(found, "two regions in the same room must not overlap (docs/hq-diorama-vision.md §3.2)")
	)

	run_case("corrupt_fixture_hq_visuals_missing_region_key_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["hq_visuals"]["rooms"]["bedsit"]["regions"]["dial"].erase("label")
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("hq_visuals.rooms.bedsit.regions.dial") and e.contains("label"):
				found = true
		assert_true(found, "a region missing a required key should be flagged")
	)

	run_case("real_hq_visuals_bedsit_room_has_every_v1_zone", func():
		var regions: Dictionary = GameData.HQ_VISUALS["rooms"]["bedsit"]["regions"]
		# hq-diorama ticket 02: "gym" is here too despite §3.1's own table
		# putting its first tier at "flat" -- a deliberate, human-approved
		# deviation (data/hq_visuals.json's own "gymDeviation" meta note).
		for zone_id in ["dial", "lab", "security", "rest", "rooms", "oreStore", "gym"]:
			assert_true(regions.has(zone_id), "bedsit room should have a '%s' zone (docs/hq-diorama-vision.md §3.1)" % zone_id)
	)

	# ── hq-diorama ticket 06: data/hq_visuals.json's "labBench" plate ──

	run_case("real_hq_visuals_lab_bench_has_both_notebook_regions", func():
		var regions: Dictionary = GameData.HQ_VISUALS["labBench"]["regions"]
		for zone_id in ["notebookRecipes", "notebookExperiments"]:
			assert_true(regions.has(zone_id), "the labBench plate should have a '%s' zone (docs/hq-diorama-vision.md §5.2)" % zone_id)
	)

	run_case("corrupt_fixture_hq_visuals_lab_bench_no_image_and_no_fallback_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		# hq-diorama ticket 12 gave labBench a real "image" too, so this
		# fixture must null that out as well -- otherwise it's no longer the
		# "neither set" case this test means to cover (same reasoning as the
		# bedsit room's own version of this test, above).
		corrupted["hq_visuals"]["labBench"]["image"] = ""
		corrupted["hq_visuals"]["labBench"]["fallbackColor"] = ""
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("labBench") and e.contains("render nothing"):
				found = true
		assert_true(found, "the labBench plate with neither an image nor a fallbackColor should be flagged, same as any room plate")
	)

	run_case("corrupt_fixture_hq_visuals_lab_bench_overlapping_notebook_regions_fail", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		var recipes: Dictionary = corrupted["hq_visuals"]["labBench"]["regions"]["notebookRecipes"]
		var experiments: Dictionary = corrupted["hq_visuals"]["labBench"]["regions"]["notebookExperiments"]
		experiments["x"] = recipes["x"]
		experiments["y"] = recipes["y"]
		var errors := GameData.validate_tables(corrupted)
		var found := false
		for e in errors:
			if e.contains("overlaps region"):
				found = true
		assert_true(found, "the two notebook regions must not overlap, same rule any room's regions follow (docs/hq-diorama-vision.md §3.2)")
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
		assert_eq(GameData.MAP_LAYOUT["districts"]["camden"]["stopSlots"].size(), 12, "camden siteCap 6 -> 12 stopSlots (siteCap*2, bugfixes-98)")
		assert_eq(GameData.MAP_LAYOUT["districts"]["soho"]["stopSlots"].size(), 2, "soho siteCap 0 -> 2 stopSlots")

		# collective1-07, spec §9.3/§9.5
		for key in ["archie", "james", "owen"]:
			assert_true(not GameData.CONTACTS_DEFAULTS[key]["recruitable"], "%s recruits by story only" % key)
			assert_true(GameData.CONTACTS_DEFAULTS[key]["roomFreeRoles"], "%s is a founder" % key)
		for key in ["des", "nadia", "hakim"]:
			assert_true(not GameData.CONTACTS_DEFAULTS[key]["recruitable"], "%s is never recruitable" % key)
			assert_eq(GameData.CONTACTS_DEFAULTS[key]["startRelation"], 0, "%s starts at relation 0" % key)
			assert_true(not GameData.CONTACTS_DEFAULTS[key]["unlocked"], "%s starts locked" % key)
			assert_true(GameData.COLLECTIVE_BARKS[key].size() >= 6, "%s has at least 6 bark lines" % key)

		# combat-presentation ticket 08
		for context in Combat.CANONICAL_CONTEXTS:
			assert_true(GameData.COMBAT_VISUALS["backdrops"].has(context), "combat_visuals.backdrops missing '%s'" % context)
		assert_eq(GameData.COMBAT_VISUALS["backdrops"]["archie_deal_mugging"]["fallbackColor"], GameData.COMBAT_VISUALS["backdrops"]["mugging"]["fallbackColor"], "archie_deal_mugging is a permanent alias of mugging's backdrop, not its own 7th plate")
		assert_eq(GameData.PALETTE["brick_shadow"], Color("#7c3a2f"), "PALETTE resolves a palette.json colour id to its hex Color")
	)
