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

	run_case("save_mutate_load_round_trips_factionRelations_as_ints", func():
		GameState.reset()
		Factions.adjust_relation("collective", "firm", -12)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["factionRelations"]["collective"]["firm"] = 0

		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var restored: Variant = GameState.state["factionRelations"]["collective"]["firm"]
		assert_eq(restored, -12, "relation value should be restored")
		assert_eq(typeof(restored), TYPE_INT, "JSON round-trip should restore int, not float")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_sites_with_int_fields_intact", func():
		GameState.reset()
		GameState.state["world"]["sites"].append({
			"id": "s1", "district": "hampstead", "tier": "rich", "oreType": "life",
			"bonuses": ["yield"], "discoveredDay": 3, "claimed": false,
			"factionVein": { "id": "fv1", "factionId": "collective", "oreType": "life", "level": 1, "devBar": 0, "security": "none", "claimedOnDay": 5 },
			"hasNaturalVein": false,
		})
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["world"]["sites"] = []
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_eq(typeof(site["discoveredDay"]), TYPE_INT, "discoveredDay should be restored as int, not float")
		assert_eq(typeof(site["factionVein"]["claimedOnDay"]), TYPE_INT, "factionVein.claimedOnDay should be restored as int, not float")
		assert_eq(GameState.state, original, "the full state tree (including sites) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_stealth_skill_for_player_and_contact", func():
		GameState.reset()
		GameState.state["player"]["stealthSkill"] = 3
		GameState.state["player"]["stealthXP"] = 45
		GameState.state["contacts"]["archie"]["stealthSkill"] = 2
		GameState.state["contacts"]["archie"]["stealthXP"] = 30

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["player"]["stealthSkill"] = 1
		GameState.state["player"]["stealthXP"] = 0
		GameState.state["contacts"]["archie"]["stealthSkill"] = 1
		GameState.state["contacts"]["archie"]["stealthXP"] = 0

		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_eq(GameState.state["player"]["stealthSkill"], 3, "player.stealthSkill should be restored")
		assert_eq(GameState.state["player"]["stealthXP"], 45, "player.stealthXP should be restored")
		assert_eq(typeof(GameState.state["player"]["stealthXP"]), TYPE_INT, "player.stealthXP should be restored as int, not float")
		assert_eq(GameState.state["contacts"]["archie"]["stealthSkill"], 2, "contact.stealthSkill should be restored")
		assert_eq(GameState.state["contacts"]["archie"]["stealthXP"], 30, "contact.stealthXP should be restored")
		assert_eq(typeof(GameState.state["contacts"]["archie"]["stealthXP"]), TYPE_INT, "contact.stealthXP should be restored as int, not float")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_player_bench", func():
		GameState.reset()
		var bench: Dictionary = GameState.state["player"]["bench"]
		bench["surveyed"]["life+time"] = 3
		bench["cells"]["life+time|heat"] = { "state": "found", "misses": 2, "refine": 1 }
		bench["cells"]["life+time|compression"] = { "state": "hot", "misses": 3, "refine": 0 }
		bench["notes"]["life+time"] = [{ "day": 9, "approach": "heat", "outcome": "found" }]
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["player"]["bench"] = { "surveyed": {}, "cells": {}, "notes": {} }
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var restored: Dictionary = GameState.state["player"]["bench"]
		assert_eq(restored["surveyed"]["life+time"], 3, "surveyed count should be restored")
		assert_eq(typeof(restored["surveyed"]["life+time"]), TYPE_INT, "surveyed count should be restored as int, not float")
		assert_eq(restored["cells"]["life+time|heat"]["state"], "found", "found cell state should be restored")
		assert_eq(typeof(restored["cells"]["life+time|heat"]["misses"]), TYPE_INT, "cell misses should be restored as int, not float")
		assert_eq(typeof(restored["cells"]["life+time|heat"]["refine"]), TYPE_INT, "cell refine should be restored as int, not float")
		assert_eq(typeof(restored["notes"]["life+time"][0]["day"]), TYPE_INT, "note day should be restored as int, not float")
		assert_eq(GameState.state, original, "the full state tree (including player.bench) should deep-equal what was saved")

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

	run_case("slot_summary_is_non_destructive", func():
		SaveManager.delete_slot(TEST_SLOT)
		assert_eq(SaveManager.slot_summary(TEST_SLOT), {}, "empty dict for a slot that doesn't exist")

		GameState.reset()
		GameState.state["world"]["day"] = 7
		GameState.state["player"]["cash"] = 555
		SaveManager.save_to_slot(TEST_SLOT)

		GameState.state["world"]["day"] = 1
		GameState.state["player"]["cash"] = 1
		var summary := SaveManager.slot_summary(TEST_SLOT)

		assert_eq(summary, { "day": 7, "cash": 555 }, "summary reflects the saved slot, not live state")
		assert_eq(GameState.state["world"]["day"], 1, "slot_summary must not touch live GameState.state")
		assert_eq(GameState.state["player"]["cash"], 1, "slot_summary must not touch live GameState.state")

		SaveManager.delete_slot(TEST_SLOT)
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

	run_case("loading_a_save_with_a_retired_currentScreen_lands_on_phone_home", func():
		for retired_id in ["home", "you", "bag", "inventory"]:
			GameState.reset()
			GameState.state["currentScreen"] = retired_id
			GameState.state["phoneNav"]["app"] = "messages"
			GameState.state["phoneNav"]["selectedAxis"] = "economic"
			GameState.state["phoneNav"]["confirmingNewGame"] = true
			var save_result := SaveManager.save_to_slot(TEST_SLOT)
			assert_true(save_result["ok"], "save_to_slot should succeed")

			GameState.reset()
			var load_result := SaveManager.load_from_slot(TEST_SLOT)
			assert_true(load_result["ok"], "load_from_slot should succeed")

			assert_eq(GameState.state["currentScreen"], "phone", "%s should remap to phone on load" % retired_id)
			assert_eq(GameState.state["phoneNav"]["app"], "home", "phoneNav should reset to the grid, not whatever app was last open")
			assert_eq(GameState.state["phoneNav"]["selectedAxis"], null, "phoneNav.selectedAxis should reset")
			assert_eq(GameState.state["phoneNav"]["confirmingNewGame"], false, "phoneNav.confirmingNewGame should reset")

			SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("loading_a_save_with_a_live_currentScreen_leaves_it_untouched", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.reset()
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_eq(GameState.state["currentScreen"], "hq", "a non-retired screen id should pass through unchanged")

		SaveManager.delete_slot(TEST_SLOT)
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
