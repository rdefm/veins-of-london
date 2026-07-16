extends "res://tests/test_base.gd"

# T02 acceptance: new_game_state matches R§2 defaults on ~20 representative
# fields; deep_copy independence (mutate copy, original unchanged).


func run() -> void:
	run_case("new_game_state_matches_schema_defaults", func():
		var s := GameState.new_game_state()

		assert_eq(s["meta"]["saveVersion"], 1, "meta.saveVersion")
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
		assert_eq(s["player"]["inventory"], { "timePearl": 0, "enhancementPowder": 0, "rewind": 0 }, "player.inventory")
		assert_eq(s["player"]["equipment"], { "weapon": null, "device": null }, "player.equipment")
		assert_eq(s["player"]["craftingSkill"], 1, "player.craftingSkill")
		assert_eq(s["player"]["cultivatingSkill"], 1, "player.cultivatingSkill")

		assert_eq(s["world"]["day"], 1, "world.day")
		assert_eq(s["world"]["timeBlock"], 0, "world.timeBlock")
		assert_eq(s["world"]["timeBlocksDone"], [], "world.timeBlocksDone")
		assert_eq(s["world"]["archieChatUnlockDay"], null, "world.archieChatUnlockDay")
		assert_eq(s["world"]["currentDistrict"], "shoreditch", "world.currentDistrict")

		assert_eq(s["home"]["tier"], "bedsit", "home.tier")
		assert_eq(s["home"]["lastRaidDay"], 0, "home.lastRaidDay")
		assert_eq(s["home"]["storedOre"], {}, "home.storedOre")

		for faction_id in ["collective", "firm", "guild", "network", "conclave"]:
			assert_eq(s["factions"][faction_id], { "relation": 0, "joined": false }, "factions.%s" % faction_id)

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
		assert_eq(s["flags"]["consSoldCount"], 0, "flags.consSoldCount")
	)

	run_case("get_path_reads_nested_values", func():
		GameState.reset()
		assert_eq(GameState.get_path("player.cash"), 40, "get_path player.cash")
		assert_eq(GameState.get_path("contacts.archie.relation"), 10, "get_path contacts.archie.relation")
		assert_eq(GameState.get_path("does.not.exist", "fallback"), "fallback", "get_path missing path returns default")
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

	run_case("reset_produces_a_fresh_independent_tree", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 12345
		GameState.reset()
		assert_eq(GameState.state["player"]["cash"], 40, "reset() should rebuild from scratch, not mutate in place")
	)
