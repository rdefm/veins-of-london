extends "res://tests/test_base.gd"

# Uses high slot/autosave indices (90+) to avoid colliding with any real
# save data, and cleans up after itself.

const TEST_SLOT := 91


func run() -> void:
	run_case("save_mutate_load_round_trips_exactly", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 12345
		GameState.state["player"]["veins"].append({
			"id": "v1", "oreType": "time", "level": 3, "levelLabel": "Moderate",
			"devBar": 7, "charged": true, "chargeBlocks": 2, "security": "basic",
			"location": "Brick Lane, near the off-licence", "claimedOnDay": 4,
			"district": "shoreditch", "hospitability": { "tier": "fair", "bonuses": [] },
		})
		GameState.state["world"]["day"] = 9
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["player"]["cash"] = 1
		GameState.state["world"]["day"] = 1
		GameState.state["player"]["veins"] = []

		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_eq(GameState.state["player"]["cash"], 12345, "cash should be restored")
		assert_eq(GameState.state["world"]["day"], 9, "day should be restored")
		assert_eq(GameState.state["player"]["veins"].size(), 1, "veins should be restored")
		assert_eq(GameState.state, original, "the full state tree should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("slot_exists_and_delete_slot", func():
		SaveManager.delete_slot(TEST_SLOT)
		assert_true(not SaveManager.slot_exists(TEST_SLOT), "should not exist before saving")
		GameState.reset()
		SaveManager.save_to_slot(TEST_SLOT)
		assert_true(SaveManager.slot_exists(TEST_SLOT), "should exist after saving")
		SaveManager.delete_slot(TEST_SLOT)
		assert_true(not SaveManager.slot_exists(TEST_SLOT), "should not exist after deleting")
	)

	run_case("load_from_empty_slot_fails_cleanly", func():
		SaveManager.delete_slot(TEST_SLOT)
		var result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(not result["ok"], "loading a slot that was never saved should fail, not crash")
	)

	run_case("export_string_reimports_to_an_equal_state", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 777
		GameState.state["flags"]["metArchie"] = true
		GameState.state["barometer"]["economic"] = "crisis"
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var exported := SaveManager.export_string()
		assert_true(exported.length() > 0, "export should produce a non-empty JSON string")

		GameState.reset()
		var result := SaveManager.import_string(exported)

		assert_true(result["ok"], "import should succeed on a just-exported string")
		assert_eq(GameState.state, original, "reimported state should deep-equal the exported state")
	)

	run_case("import_string_rejects_garbage", func():
		var result := SaveManager.import_string("not valid json {{{")
		assert_true(not result["ok"], "garbage input should fail cleanly, not crash")
	)

	run_case("migrate_is_identity_for_v1", func():
		var save := { "meta": { "saveVersion": 1 }, "player": { "cash": 55 } }
		var migrated := SaveManager.migrate(save)
		assert_eq(migrated, save, "v1 migration should be a no-op")
	)

	run_case("migrate_defaults_to_current_version_when_meta_missing", func():
		var save := { "player": { "cash": 55 } }
		var migrated := SaveManager.migrate(save)
		assert_eq(migrated, save, "a save with no meta.saveVersion should be treated as the current version and pass through unchanged")
	)

	run_case("backfill_fills_missing_top_level_keys_from_defaults", func():
		var incomplete := {
			"player": { "cash": 999 },  # customised, should survive
			"world": { "day": 42 },
		}
		var filled := SaveManager.backfill_defaults(incomplete)
		var defaults := GameState.new_game_state()

		assert_eq(filled["player"]["cash"], 999, "an existing top-level key should be kept as-is")
		assert_eq(filled["world"]["day"], 42, "an existing top-level key should be kept as-is")
		assert_eq(filled["flags"], defaults["flags"], "a missing top-level key should be backfilled from defaults")
		assert_eq(filled["combat"], defaults["combat"], "a missing top-level key should be backfilled from defaults")
		assert_true(filled.has("factions") and filled.has("contacts"), "all top-level keys should be present after backfill")
	)

	run_case("autosave_rotates_across_3_slots_then_overwrites_the_oldest", func():
		for i in range(SaveManager.AUTOSAVE_COUNT):
			if FileAccess.file_exists(SaveManager.autosave_path(i)):
				DirAccess.remove_absolute(SaveManager.autosave_path(i))

		GameState.reset()
		GameState.state["world"]["day"] = 1
		SaveManager.autosave()
		GameState.state["world"]["day"] = 2
		SaveManager.autosave()
		GameState.state["world"]["day"] = 3
		SaveManager.autosave()

		for i in range(SaveManager.AUTOSAVE_COUNT):
			assert_true(FileAccess.file_exists(SaveManager.autosave_path(i)), "slot %d should be filled after 3 autosaves" % i)

		# 4th autosave must land in one of the 3 rotation files (overwriting
		# the oldest), not create a 4th file.
		GameState.state["world"]["day"] = 4
		SaveManager.autosave()
		var day_4_count := 0
		for i in range(SaveManager.AUTOSAVE_COUNT):
			var file := FileAccess.open(SaveManager.autosave_path(i), FileAccess.READ)
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed["world"]["day"] == 4:
				day_4_count += 1
		assert_eq(day_4_count, 1, "exactly one of the 3 rotation slots should now hold the 4th autosave")

		for i in range(SaveManager.AUTOSAVE_COUNT):
			if FileAccess.file_exists(SaveManager.autosave_path(i)):
				DirAccess.remove_absolute(SaveManager.autosave_path(i))
	)
