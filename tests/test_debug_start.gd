extends "res://tests/test_base.gd"


func run() -> void:
	run_case("debug_start_matches_R5", func():
		DebugStart.apply()
		var s: Dictionary = GameState.state
		var p: Dictionary = s["player"]

		assert_eq(p["cash"], 1000000, "cash")
		assert_eq(p["craftingSkill"], 3, "crafting skill")
		assert_eq(p["cultivatingSkill"], 2, "cultivating skill")

		for ore_type in GameData.ORE_TYPES.keys():
			assert_eq(p["orichalchum"][ore_type], 20, "20 units of %s" % ore_type)

		assert_eq(p["inventory"], { "timePearl": 5, "enhancementPowder": 3, "rewind": 1 }, "consumables")

		assert_eq(p["items"].size(), 1, "one item (the crowbar)")
		assert_eq(p["items"][0]["type"], "crowbar", "item is a crowbar")
		assert_eq(p["equipment"]["weapon"], p["items"][0]["id"], "crowbar equipped")

		assert_eq(p["veins"].size(), 3, "3 debug veins")
		var by_type := {}
		for v in p["veins"]:
			by_type[v["oreType"]] = v
		assert_eq(by_type["time"]["level"], 3, "time vein Lv3")
		assert_eq(by_type["physics"]["level"], 1, "physics vein Lv1")
		assert_eq(by_type["life"]["level"], 5, "life vein Lv5")
		for ore_type in ["time", "physics", "life"]:
			var v: Dictionary = by_type[ore_type]
			assert_true(v["charged"], "%s vein should be charged" % ore_type)
			var level_data: Dictionary = GameData.VEIN_LEVELS[str(v["level"])]
			assert_eq(v["devBar"], GameState.round_epsilon(level_data["devBarMax"] * 0.5), "%s vein devBar at 50%% of level max" % ore_type)

		var flags: Dictionary = s["flags"]
		assert_eq(flags["tutorialStage"], "free", "tutorialStage")
		assert_eq(flags["consSoldCount"], 5, "consSoldCount")
		assert_eq(flags["homeRaidEventPending"], true, "homeRaidEventPending true")
		assert_eq(flags["homeRaidEventSeen"], false, "homeRaidEventSeen must stay false or the pending flag can never trigger anything")
		for key in flags.keys():
			if key in ["tutorialStage", "consSoldCount", "homeRaidEventSeen"]:
				continue
			assert_true(flags[key] == true, "flag '%s' should be true under debug start" % key)

		assert_eq(s["home"]["tier"], "townhouse", "home tier")
		assert_eq(s["home"]["rooms"], ["workshop", "homeGym"], "home rooms")
		assert_eq(s["home"]["security"], ["lock", "cameras"], "home security")

		assert_eq(s["contacts"]["archie"]["relation"], 60, "archie relation")
		assert_eq(s["contacts"]["archie"]["unlocked"], true, "archie unlocked")
		assert_eq(s["contacts"]["james"]["relation"], 40, "james relation")
		assert_eq(s["contacts"]["james"]["unlocked"], true, "james unlocked")

		assert_eq(s["factions"]["guild"]["joined"], true, "guild joined")
		assert_eq(s["factions"]["collective"]["relation"], 25, "collective relation")
		assert_eq(s["factions"]["firm"]["relation"], 15, "firm relation")

		assert_eq(s["barometer"]["economic"], "boom", "barometer economic")
		assert_eq(s["barometer"]["social"], "stable", "barometer social")
		assert_eq(s["barometer"]["political"], "war", "barometer political")
		assert_eq(s["barometer"]["progress"]["economic"]["boom"], 100, "progress should be initialised to match the forced active state")

		assert_eq(s["currentScreen"], "home", "debug start should land on the home screen")

		var sites: Array = s["world"]["sites"]
		assert_eq(sites.size(), 2, "exactly 2 discovered sites")
		var by_district := {}
		for site in sites:
			by_district[site["district"]] = site
		assert_eq(by_district["greenwich"]["tier"], "rich", "greenwich site is rich")
		assert_eq(by_district["whitechapel"]["tier"], "saturated", "whitechapel site is saturated")
		for site in sites:
			assert_true(not site["claimed"], "debug sites start unclaimed")
			assert_eq(site["factionVein"], null, "debug sites start unclaimed by any faction")
	)
