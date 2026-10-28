extends "res://tests/test_base.gd"


func _set_levels(mind: int, soul: int) -> void:
	GameState.state["player"]["mindSkill"] = mind
	GameState.state["player"]["soulSkill"] = soul


# Seed so the first roll for this bucket/block hits (true) or misses (false).
func _find_seed(bucket: String, hit: bool) -> void:
	for s in 500:
		GameState.state["world"]["rollSeed"] = s
		var w: Dictionary = GameState.state["world"]
		var key := "%d|freeAction|%d|%d|%s|0" % [s, w["day"], w["timeBlock"], bucket]
		if (Rng.stable_unit(key) < GameData.FREE_ACTION["chance"]) == hit:
			return


func run() -> void:
	run_case("l3_roll_hit_keeps_block_miss_advances", func():
		GameState.reset()
		_set_levels(1, 3)
		_find_seed("soul", true)
		var r := FreeAction.spend("soul")
		assert_true(r["ok"] and r["free"], "hit is free")
		assert_eq(r["rule"], "roll")
		assert_eq(GameState.state["world"]["timeBlock"], 0, "block unchanged")
		assert_true(String(r["line"]).contains("Soul Level 3 perk (25% chance)"), r["line"])
		GameState.reset()
		_set_levels(1, 3)
		_find_seed("soul", false)
		r = FreeAction.spend("soul")
		assert_true(not r["free"], "miss not free")
		assert_eq(GameState.state["world"]["timeBlock"], 1, "block advanced")
	)

	run_case("below_l3_never_free", func():
		GameState.reset()
		_set_levels(2, 2)
		assert_true(not FreeAction.spend("mind")["free"])
	)

	run_case("l5_first_free_then_roll_then_resets_on_block", func():
		GameState.reset()
		_set_levels(1, 5)
		_find_seed("soul", false)
		var r := FreeAction.spend("soul")
		assert_eq(r["rule"], "guaranteed")
		assert_eq(GameState.state["world"]["timeBlock"], 0)
		r = FreeAction.spend("soul")
		assert_true(not r["free"], "second rolls L3 and misses")
		assert_eq(GameState.state["world"]["timeBlock"], 1)
		assert_eq(FreeAction.spend("soul")["rule"], "guaranteed", "freebie returns on block change")
	)

	run_case("mind_and_soul_independent", func():
		GameState.reset()
		_set_levels(5, 5)
		assert_eq(FreeAction.spend("mind")["rule"], "guaranteed")
		assert_eq(FreeAction.spend("soul")["rule"], "guaranteed")
		assert_eq(GameState.state["world"]["timeBlock"], 0)
	)

	run_case("internship_first_leaves_soul_freebie", func():
		GameState.reset()
		_set_levels(1, 5)
		GameState.state["turf"]["soho"] = { "controller": "guild", "tiers": { "guild": Turf.TIER_CONTROL }, "shares": {} }
		GameState.state["factionStances"]["player"]["guild"]["stance"] = FactionAI.PARTNER
		var r := FreeAction.spend("soul", "soho")
		assert_eq(r["rule"], "internship")
		assert_true(not GameState.state["player"]["freeAction"]["soulUsed"], "freebie untouched")
	)

	run_case("refused_when_time_exhausted", func():
		GameState.reset()
		_set_levels(5, 5)
		GameState.state["world"]["timeBlocksDone"] = GameData.TIME_BLOCKS.duplicate()
		assert_true(not FreeAction.spend("soul")["ok"])
		assert_true(not GameState.state["player"]["freeAction"]["soulUsed"])
	)

	run_case("old_save_backfills_free_action_state", func():
		GameState.reset()
		var raw: Dictionary = GameState.deep_copy(GameState.state)
		raw["player"].erase("freeAction")
		var loaded: Dictionary = SaveManager.backfill_defaults(raw)
		assert_true(loaded["player"].has("freeAction"))
	)

	run_case("rewind_replays_same_roll", func():
		GameState.reset()
		_set_levels(1, 3)
		var seed_val := 7
		GameState.state["world"]["rollSeed"] = seed_val
		var first: Array = []
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		for i in 3:
			first.append(FreeAction.spend("soul")["free"])
			GameState.state["world"]["timeBlock"] = 0
			GameState.state["world"]["timeBlocksDone"] = []
		GameState.state = snapshot
		var again: Array = []
		for i in 3:
			again.append(FreeAction.spend("soul")["free"])
			GameState.state["world"]["timeBlock"] = 0
			GameState.state["world"]["timeBlocksDone"] = []
		assert_eq(first, again)
	)


	run_case("prune_free_keeps_block_nonfree_advances_exhausted_refused", func():
		var vein := {
			"id": "v1", "oreType": "time", "growth": 60, "security": "none",
			"alarmUpgrades": [], "location": "Test St", "claimedOnDay": 1,
			"district": "shoreditch", "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
			"rampantDays": 0, "level": 1, "developmentStreak": 0,
		}
		var depth: int = GameData.VEIN_GROWTH["pruneLightDepth"]
		GameState.reset()
		GameState.state["player"]["veins"] = [vein.duplicate(true)]
		_set_levels(1, 5)
		var r := Cultivating.prune("v1", depth)
		assert_true(r["ok"] and r["freeAction"]["free"], "L5 freebie")
		assert_eq(GameState.state["world"]["timeBlock"], 0, "block unchanged")
		GameState.reset()
		GameState.state["player"]["veins"] = [vein.duplicate(true)]
		_set_levels(1, 1)
		r = Cultivating.prune("v1", depth)
		assert_true(not r["freeAction"]["free"])
		assert_eq(GameState.state["world"]["timeBlock"], 1, "block advanced")
		GameState.state["world"]["timeBlocksDone"] = GameData.TIME_BLOCKS.duplicate()
		assert_true(not Cultivating.prune("v1", depth)["ok"], "exhausted refused")
	)

	run_case("prospect_free_keeps_block_nonfree_advances", func():
		GameState.reset()
		_set_levels(5, 1)
		var r := Sites.prospect("city")
		assert_true(r["ok"] and r["freeAction"]["free"], "Mind L5 freebie")
		assert_eq(GameState.state["world"]["timeBlock"], 0)
		GameState.reset()
		_set_levels(1, 1)
		assert_eq(Sites.prospect("city")["freeAction"]["free"], false)
		assert_eq(GameState.state["world"]["timeBlock"], 1)
		GameState.state["world"]["timeBlocksDone"] = GameData.TIME_BLOCKS.duplicate()
		assert_true(not Sites.prospect("city")["ok"], "exhausted refused")
	)

	run_case("seed_free_keeps_block_nonfree_advances", func():
		var site := {
			"id": "s1", "district": "shoreditch", "tier": "fair", "oreType": "time",
			"bonuses": [], "discoveredDay": 1, "claimed": false, "factionVein": null,
			"hasNaturalVein": false,
		}
		GameState.reset()
		GameState.state["world"]["sites"] = [site.duplicate(true)]
		GameState.state["player"]["orichalchum"]["time"] = 500
		_set_levels(1, 5)
		var r := Sites.attempt_seed("s1")
		assert_true(r["ok"], str(r)); assert_true(r["freeAction"]["free"], "Soul L5 freebie")
		assert_eq(GameState.state["world"]["timeBlock"], 0)
		GameState.reset()
		GameState.state["world"]["sites"] = [site.duplicate(true)]
		GameState.state["player"]["orichalchum"]["time"] = 500
		_set_levels(1, 1)
		assert_eq(Sites.attempt_seed("s1")["freeAction"]["free"], false)
		assert_eq(GameState.state["world"]["timeBlock"], 1)
	)
