extends "res://tests/test_base.gd"

# Uses high slot/autosave indices (90+) to avoid colliding with any real
# save data, and cleans up after itself.

const TEST_SLOT := 91


func run() -> void:
	run_case("save_mutate_load_round_trips_exactly", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 12345
		GameState.state["player"]["veins"].append({
			"id": "v1", "oreType": "time", "growth": 65, "rampantDays": 2, "security": "basic",
			"alarmUpgrades": [], "location": "Brick Lane, near the off-licence", "claimedOnDay": 4,
			"district": "shoreditch", "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
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

	run_case("save_mutate_load_round_trips_bankLog_with_int_fields_intact", func():
		GameState.reset()
		Bank.record(-50, "Living costs")
		Bank.record(300, "Archie sale")
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["bankLog"] = []
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var log: Array = GameState.state["bankLog"]
		assert_eq(log.size(), 2, "bankLog should be restored")
		assert_eq(typeof(log[0]["amount"]), TYPE_INT, "amount should be restored as int, not float")
		assert_eq(typeof(log[0]["day"]), TYPE_INT, "day should be restored as int, not float")
		assert_eq(GameState.state, original, "the full state tree (including bankLog) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_messages_with_day_int_intact", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		Messages.append("des", "them", "Hello.")
		Messages.queue_pending("des", "col_a1_des_report", "Something for you.")
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["messages"] = {}
		GameState.state["pendingMessages"] = []
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var thread: Array = GameState.state["messages"]["des"]
		assert_eq(thread.size(), 2, "messages should be restored")
		assert_eq(typeof(thread[0]["day"]), TYPE_INT, "message day should be restored as int, not float")
		assert_eq(GameState.state["pendingMessages"].size(), 1, "pendingMessages should be restored")
		assert_eq(GameState.state, original, "the full state tree (including messages/pendingMessages) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_sites_with_int_fields_intact", func():
		GameState.reset()
		GameState.state["world"]["sites"].append({
			"id": "s1", "district": "hampstead", "tier": "rich", "oreType": "life",
			"bonuses": ["yield"], "discoveredDay": 3, "claimed": false,
			"factionVein": { "id": "fv1", "factionId": "collective", "oreType": "life", "growth": 20, "rampantDays": 0, "security": "none", "claimedOnDay": 5 },
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

	run_case("save_mutate_load_round_trips_mapSlotFreePool_with_int_fields_intact", func():
		GameState.reset()
		Sites.next_slot_index("hampstead")
		Sites.next_slot_index("hampstead")
		Sites.release_slot_index("hampstead", 0)
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["world"]["mapSlotFreePool"] = {}
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var freed: Array = GameState.state["world"]["mapSlotFreePool"]["hampstead"]
		assert_eq(typeof(freed[0]), TYPE_INT, "a freed slotIndex should be restored as int, not float")
		assert_eq(GameState.state, original, "the full state tree (including mapSlotFreePool) should deep-equal what was saved")

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

	run_case("save_mutate_load_round_trips_mapView_with_scroll_as_ints_and_zoom_as_float", func():
		GameState.reset()
		MapView.mark_opened()
		MapView.save_view(1.15, Vector2(345, 678))
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.reset()
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_true(MapView.has_opened_before(), "everOpened should be restored")
		assert_almost_eq(MapView.zoom(), 1.15, 0.0001, "zoom should be restored")
		assert_eq(MapView.scroll(), Vector2(345, 678), "scroll should be restored")
		assert_eq(typeof(GameState.state["mapView"]["scrollX"]), TYPE_INT, "scrollX should be restored as int, not float")
		assert_eq(typeof(GameState.state["mapView"]["scrollY"]), TYPE_INT, "scrollY should be restored as int, not float")
		assert_eq(typeof(GameState.state["mapView"]["zoom"]), TYPE_FLOAT, "zoom should stay a float, not get int-cast like scrollX/scrollY")
		assert_eq(GameState.state, original, "the full state tree (including mapView) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	# ── 107-hq-stackable-guards ────────────────────────────────────────

	run_case("save_mutate_load_round_trips_home_guardCount_as_int", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "compound"
		Home.add_security("guard")
		Home.add_security("guard")
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["home"]["guardCount"] = 0
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_eq(GameState.state["home"]["guardCount"], 2, "guardCount should be restored")
		assert_eq(typeof(GameState.state["home"]["guardCount"]), TYPE_INT, "guardCount should be restored as int, not float")
		assert_eq(GameState.state, original, "the full state tree (including home.guardCount) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("loading_a_pre_107_save_backfills_home_guardCount_to_0", func():
		GameState.reset()
		# Pre-107 shape: state.home had no guardCount key at all.
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["home"].erase("guardCount")

		var filled := SaveManager.backfill_defaults(legacy)
		assert_eq(filled["home"]["guardCount"], 0, "a save from before guardCount existed should backfill it to 0")
	)

	# ── ticket 64: legacy flat-int inventory migration ───────────────────

	run_case("loading_a_pre_ticket_64_save_migrates_flat_int_inventory_into_the_0_bucket", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		# Pre-ticket-64 shape: player.inventory[recipeKey] was a bare count,
		# not a { tier: count } dict. JSON round-trips every number as a
		# float, same as every other int field this suite exercises.
		legacy["player"]["inventory"] = { "timePearl": 5.0, "enhancementPowder": 0.0, "rewind": 2.0 }

		var result := SaveManager.import_string(JSON.stringify(legacy))
		assert_true(result["ok"], "a legacy flat-int inventory should load without crashing")

		var inventory: Dictionary = GameState.state["player"]["inventory"]
		assert_eq(inventory["timePearl"], { "0": 5 }, "a legacy count migrates into the untiered '0' bucket, as an int not a float")
		assert_eq(inventory["enhancementPowder"], { "0": 0 }, "a zero legacy count still migrates to a (empty-valued) '0' bucket rather than being dropped")
		assert_eq(inventory["rewind"], { "0": 2 }, "each recipe key migrates independently")
		assert_eq(Crafting.inventory_qty("timePearl"), 5, "the migrated stock is usable through the normal inventory_qty API")
	)

	run_case("loading_a_save_already_in_the_tiered_inventory_shape_leaves_it_untouched_besides_int_ifying", func():
		GameState.reset()
		var current: Dictionary = GameState.deep_copy(GameState.state)
		current["player"]["inventory"] = { "timePearl": { "1": 3.0, "3": 2.0 }, "enhancementPowder": {}, "rewind": {} }

		var result := SaveManager.import_string(JSON.stringify(current))
		assert_true(result["ok"], "a save already in the tier-bucketed shape should load normally")

		var inventory: Dictionary = GameState.state["player"]["inventory"]
		assert_eq(inventory["timePearl"], { "1": 3, "3": 2 }, "bucket counts restore as ints, tiers untouched")
		assert_eq(Crafting.inventory_qty("timePearl"), 5, "inventory_qty sums both buckets")
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

	run_case("loading_a_v1_save_is_rejected_with_a_clear_message", func():
		var save := { "meta": { "saveVersion": 1 }, "player": { "cash": 55 } }
		var result := SaveManager.import_string(JSON.stringify(save))
		assert_true(not result["ok"], "a v1 save must not half-load under the growth-model schema")
		assert_true(result["reason"].contains("older version"), "the rejection reason should be clear about why")
	)

	run_case("loading_a_save_with_no_meta_saveVersion_is_treated_as_current_and_succeeds", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save.erase("meta")
		var result := SaveManager.import_string(JSON.stringify(save))
		assert_true(result["ok"], "a save with no meta.saveVersion at all should be treated as the current version")
	)

	run_case("loading_a_save_at_the_current_version_succeeds", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		assert_eq(save["meta"]["saveVersion"], SaveManager.SAVE_VERSION, "a fresh game state should stamp the current save version")
		var result := SaveManager.import_string(JSON.stringify(save))
		assert_true(result["ok"], "a save at the current version should load")
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
		# collective1-03
		assert_eq(filled["messages"], {}, "an old save missing 'messages' should backfill to {}")
		assert_eq(filled["pendingMessages"], [], "an old save missing 'pendingMessages' should backfill to []")
	)

	# collective1-07: "contacts" is a top-level key that has existed since
	# M0, so a save from before des/nadia/hakim existed has it present but
	# missing the three new ids -- the shallow top-level fill above never
	# fires for it, so this needs its own per-id backfill.
	run_case("backfill_seeds_new_contact_ids_into_an_old_saves_existing_contacts_dict", func():
		var incomplete := {
			"contacts": { "archie": { "relation": 55, "recruited": true } },  # pre-collective1-07 save
		}
		var filled := SaveManager.backfill_defaults(incomplete)
		var defaults := GameState.new_game_state()

		assert_eq(filled["contacts"]["archie"], { "relation": 55, "recruited": true }, "an existing contact's data must survive untouched")
		for contact_id in ["des", "nadia", "hakim"]:
			assert_eq(filled["contacts"][contact_id], defaults["contacts"][contact_id], "%s should be seeded from defaults, same as a missing top-level key" % contact_id)
	)

	# 87-map-slot-index-recycling: "world" is a top-level key that has
	# existed since M0, so a pre-ticket-87 save has it present but missing
	# the new mapSlotFreePool key -- the shallow top-level fill above never
	# fires for it, so this needs its own per-key backfill.
	run_case("backfill_seeds_mapSlotFreePool_into_an_old_saves_existing_world_dict", func():
		var incomplete := {
			"world": { "day": 42, "mapSlotCounters": { "camden": 3 } },  # pre-ticket-87 save
		}
		var filled := SaveManager.backfill_defaults(incomplete)

		assert_eq(filled["world"]["day"], 42, "existing world data must survive untouched")
		assert_eq(filled["world"]["mapSlotCounters"], { "camden": 3 }, "existing world data must survive untouched")
		assert_eq(filled["world"]["mapSlotFreePool"], {}, "the new key should be seeded from defaults, same as a missing top-level key")
	)

	# dial-device ticket 01: "player" is a top-level key that has existed
	# since M0, so a pre-Dial save has it present but missing the new dial
	# key -- the shallow top-level fill above never fires for it, same
	# reasoning as the mapSlotFreePool case above.
	run_case("backfill_seeds_dial_into_an_old_saves_existing_player_dict", func():
		var incomplete := {
			"player": {
				"cash": 999,
				"devicesInProgress": [{ "id": "d1", "type": "timeDevice", "progress": 40.0 }],
				"devicesCompleted": [{ "id": "d2", "type": "rewindDevice", "level": 2, "xp": 60, "chargesPerDay": 2, "chargesUsedToday": 0, "lastResetDay": 3 }],
				"equipment": { "weapon": "crowbar", "device": "d2" },
			},
			"flags": { "craftingUnlocked": true, "enhancementUnlocked": true },
		}
		var filled := SaveManager.backfill_defaults(incomplete)

		assert_eq(filled["player"]["cash"], 999, "existing player data must survive untouched")
		assert_eq(filled["player"]["dial"], null, "the new key should be seeded from defaults, same as a missing top-level key")
		assert_eq(filled["player"]["devicesInProgress"], [{ "id": "d1", "type": "timeDevice", "progress": 40.0 }], "pre-Dial device progress must be left untouched, not converted")
		assert_eq(filled["player"]["devicesCompleted"], [{ "id": "d2", "type": "rewindDevice", "level": 2, "xp": 60, "chargesPerDay": 2, "chargesUsedToday": 0, "lastResetDay": 3 }], "pre-Dial completed devices must be left untouched, not converted")
		assert_eq(filled["player"]["equipment"], { "weapon": "crowbar", "device": "d2" }, "pre-Dial equipment.device must be left untouched, not converted")
		assert_eq(filled["flags"]["craftingUnlocked"], true, "craftingUnlocked must survive the dial backfill untouched")
		assert_eq(filled["flags"]["enhancementUnlocked"], true, "enhancementUnlocked must survive the dial backfill untouched")
	)

	# dial-device ticket 01, acceptance: a save with populated
	# devicesInProgress/devicesCompleted/equipment.device and no player.dial
	# loads without error into a null-Dial state, craftingUnlocked/
	# enhancementUnlocked intact. Full import_string round trip (not just
	# backfill_defaults) to exercise the real load path.
	run_case("loading_a_pre_dial_save_migrates_into_a_null_dial_state_with_old_unlocks_intact", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["player"].erase("dial")
		legacy["player"]["devicesInProgress"] = [{ "id": "d1", "type": "timeDevice", "progress": 40.0 }]
		legacy["player"]["devicesCompleted"] = [{ "id": "d2", "type": "rewindDevice", "level": 2, "xp": 60, "chargesPerDay": 2, "chargesUsedToday": 0, "lastResetDay": 3 }]
		legacy["player"]["equipment"] = { "weapon": "crowbar", "device": "d2" }
		legacy["flags"]["craftingUnlocked"] = true
		legacy["flags"]["enhancementUnlocked"] = true

		var result := SaveManager.import_string(JSON.stringify(legacy))
		assert_true(result["ok"], "a pre-Dial save should load without error")

		var player: Dictionary = GameState.state["player"]
		assert_eq(player["dial"], null, "a pre-Dial save should load into a null-Dial state")
		assert_eq(player["devicesInProgress"], [{ "id": "d1", "type": "timeDevice", "progress": 40.0 }], "old device progress should survive the migration untouched")
		assert_eq(player["devicesCompleted"][0]["id"], "d2", "old completed devices should survive the migration untouched")
		assert_eq(player["equipment"], { "weapon": "crowbar", "device": "d2" }, "old equipment.device should survive the migration untouched")
		assert_true(GameState.state["flags"]["craftingUnlocked"], "craftingUnlocked should stay true across the migration")
		assert_true(GameState.state["flags"]["enhancementUnlocked"], "enhancementUnlocked should stay true across the migration")
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
