extends "res://tests/test_base.gd"

# T02 acceptance: new_game_state matches R§2 defaults on ~20 representative
# fields; deep_copy independence (mutate copy, original unchanged).


func run() -> void:
	run_case("new_game_state_matches_schema_defaults", func():
		var s := GameState.new_game_state()

		assert_eq(s["meta"]["saveVersion"], SaveManager.SAVE_VERSION, "meta.saveVersion")
		assert_eq(s["currentScreen"], "title", "currentScreen")
		assert_eq(s["modal"], null, "modal")
		assert_eq(s["inventoryTab"], "ore", "inventoryTab")
		assert_eq(s["notifications"], [], "notifications")
		assert_eq(s["event"], null, "event")

		assert_eq(s["player"]["cash"], 40, "player.cash")
		assert_eq(s["player"]["hp"], 100, "player.hp")
		assert_eq(s["player"]["hpMax"], 100, "player.hpMax")
		assert_eq(s["player"]["attackMin"], 5, "player.attackMin")
		assert_eq(s["player"]["attackMax"], 12, "player.attackMax")
		assert_eq(s["player"]["orichalchum"], {}, "player.orichalchum")
		assert_eq(s["player"]["veins"], [], "player.veins")
		assert_eq(s["player"]["inventory"], { "timePearl": {}, "enhancementPowder": {}, "rewind": {} }, "player.inventory")
		assert_eq(s["player"]["equipment"], { "weapon": null }, "player.equipment")
		assert_eq(s["player"]["dial"], null, "player.dial")
		assert_eq(s["player"]["craftingSkill"], 1, "player.craftingSkill")
		assert_eq(s["player"]["cultivatingSkill"], 1, "player.cultivatingSkill")
		assert_eq(s["player"]["stealthSkill"], 1, "player.stealthSkill")
		assert_eq(s["player"]["stealthXP"], 0, "player.stealthXP")
		assert_eq(s["player"]["bench"], { "surveyed": {}, "cells": {}, "notes": {} }, "player.bench starts empty")
		assert_eq(s["benchNav"], { "view": "home", "types": [], "approach": null, "result": null }, "benchNav")

		assert_eq(s["world"]["day"], 1, "world.day")
		assert_eq(s["world"]["timeBlock"], 0, "world.timeBlock")
		assert_eq(s["world"]["timeBlocksDone"], [], "world.timeBlocksDone")
		assert_eq(s["world"]["archieChatUnlockDay"], null, "world.archieChatUnlockDay")
		assert_eq(s["world"]["currentDistrict"], "shoreditch", "world.currentDistrict")

		assert_eq(s["home"]["tier"], "bedsit", "home.tier")
		assert_eq(s["home"]["lastRaidDay"], 0, "home.lastRaidDay")

		for faction_id in ["collective", "firm", "guild", "network", "conclave"]:
			assert_eq(s["factions"][faction_id]["relation"], 0, "factions.%s.relation" % faction_id)
			assert_eq(s["factions"][faction_id]["joined"], false, "factions.%s.joined" % faction_id)
			assert_eq(s["factions"][faction_id]["resources"], GameData.FACTIONS[faction_id]["startingResources"], "factions.%s.resources seeded from data/factions.json" % faction_id)

		assert_eq(s["barometer"]["economic"], "stable", "barometer.economic")
		assert_eq(s["barometer"]["social"], "stable", "barometer.social")
		assert_eq(s["barometer"]["political"], "stable", "barometer.political")

		assert_eq(s["contacts"]["archie"]["relation"], 10, "contacts.archie.relation")
		assert_eq(s["contacts"]["archie"]["unlocked"], true, "contacts.archie.unlocked")
		assert_eq(s["contacts"]["archie"]["recruitThreshold"], 80, "contacts.archie.recruitThreshold")
		assert_eq(s["contacts"]["james"]["relation"], 0, "contacts.james.relation")
		assert_eq(s["contacts"]["james"]["unlocked"], false, "contacts.james.unlocked")
		assert_eq(s["contacts"]["james"]["recruitThreshold"], 100, "contacts.james.recruitThreshold")

		assert_eq(s["combat"]["active"], false, "combat.active")
		assert_eq(s["combat"]["context"], "raid", "combat.context")
		assert_almost_eq(s["combat"]["evadeChance"], 0.0, 0.0001, "combat.evadeChance")

		assert_eq(s["jamesJob"], null, "jamesJob")
		assert_eq(s["pendingSaleCut"], 0, "pendingSaleCut")
		assert_eq(s["veinStationVeins"], [], "veinStationVeins")

		assert_eq(s["flags"]["tutorialStage"], "intro", "flags.tutorialStage")
		assert_eq(s["flags"]["metArchie"], false, "flags.metArchie")
		assert_eq(s["flags"]["homeRaidEventPending"], false, "flags.homeRaidEventPending")
		assert_eq(s["flags"]["debugStartUsed"], false, "flags.debugStartUsed defaults false on a normal New Game")
		assert_eq(s["flags"]["consSoldCount"], 0, "flags.consSoldCount")
	)

	run_case("read_path_reads_nested_values", func():
		GameState.reset()
		assert_eq(GameState.read_path("player.cash"), 40, "read_path player.cash")
		assert_eq(GameState.read_path("contacts.archie.relation"), 10, "read_path contacts.archie.relation")
		assert_eq(GameState.read_path("does.not.exist", "fallback"), "fallback", "read_path missing path returns default")
	)

	run_case("deep_copy_is_independent_of_original", func():
		var original := { "a": 1, "nested": { "b": [1, 2, 3] } }
		var copy: Dictionary = GameState.deep_copy(original)

		copy["a"] = 999
		copy["nested"]["b"].append(4)
		copy["nested"]["c"] = "new"

		assert_eq(original["a"], 1, "original top-level field unchanged")
		assert_eq(original["nested"]["b"], [1, 2, 3], "original nested array unchanged")
		assert_true(not original["nested"].has("c"), "original nested dict did not gain the copy's new key")
	)

	run_case("round_epsilon_guards_against_float_boundary_error", func():
		# 90 * (1 - 0.35 + 0.5) is exactly 103.5 in real-number math, but
		# IEEE-754 double precision evaluates it as 103.49999999999999.
		# round_epsilon must still land on 104, matching REFERENCE.md.
		var computed: float = 90.0 * (1.0 - 0.35 + 0.5)
		assert_true(computed < 103.5, "sanity: this is the exact float precision case we're guarding against")
		assert_eq(GameState.round_epsilon(computed), 104, "round_epsilon should round 103.4999...9 up to 104")
		assert_eq(GameState.round_epsilon(10.0), 10, "round_epsilon should not perturb a clean integer value")
		assert_eq(GameState.round_epsilon(10.4), 10, "round_epsilon should still round down when nowhere near a boundary")
	)

	# ── faction-resource-economy T01: state.factions[id].resources ──

	run_case("faction_resources_seed_with_differentiated_baselines_per_flavour_text", func():
		GameState.reset()
		var f: Dictionary = GameState.state["factions"]

		assert_eq(f["collective"]["resources"], 200, "Collective seeds scrappiest")
		assert_eq(f["firm"]["resources"], 500, "Firm seeds mid-tier")
		assert_eq(f["network"]["resources"], 500, "Network seeds mid-tier")
		assert_eq(f["guild"]["resources"], 900, "Guild seeds rich, above Firm/Network")
		assert_eq(f["conclave"]["resources"], 1200, "Conclave seeds richest")

		assert_true(f["collective"]["resources"] < f["firm"]["resources"], "Collective reads scrappier than Firm")
		assert_true(f["firm"]["resources"] < f["guild"]["resources"], "Guild reads richer than Firm (unlike resourceLevel, which ties them at 2)")
		assert_true(f["guild"]["resources"] <= f["conclave"]["resources"], "Guild and Conclave are both in the rich tier")

		for faction_id in f.keys():
			assert_eq(typeof(f[faction_id]["resources"]), TYPE_INT, "resources.%s is a plain int primitive" % faction_id)
	)

	run_case("faction_resources_round_trip_through_save_load", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["resources"] = 1337
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(92)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["factions"]["guild"]["resources"] = 0
		var load_result := SaveManager.load_from_slot(92)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_eq(GameState.state["factions"]["guild"]["resources"], 1337, "resources should be restored")
		assert_eq(GameState.state, original, "the full state tree should deep-equal what was saved")

		SaveManager.delete_slot(92)
	)

	run_case("faction_resources_round_trip_through_snapshot_restore", func():
		GameState.reset()
		GameState.state["factions"]["conclave"]["resources"] = 4242
		var stack: Array = []
		Snapshots.push("event", stack, GameState.state)

		GameState.state["factions"]["conclave"]["resources"] = 0
		var restored: Dictionary = Snapshots.oldest(stack)
		assert_eq(restored["factions"]["conclave"]["resources"], 4242, "snapshot retains the resources value taken at push time")
		assert_eq(GameState.state["factions"]["conclave"]["resources"], 0, "restoring from the snapshot copy must not be aliased to live state")
	)

	run_case("reset_produces_a_fresh_independent_tree", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 12345
		GameState.reset()
		assert_eq(GameState.state["player"]["cash"], 40, "reset() should rebuild from scratch, not mutate in place")
	)
