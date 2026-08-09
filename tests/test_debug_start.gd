extends "res://tests/test_base.gd"


func run() -> void:
	run_case("debug_start_matches_R5", func():
		DebugStart.apply()
		var s: Dictionary = GameState.state
		var p: Dictionary = s["player"]

		assert_eq(p["cash"], 1000000, "cash")
		assert_eq(p["craftingSkill"], 3, "crafting skill")
		assert_eq(p["cultivatingSkill"], 5, "cultivating skill maxed so debug prospecting sits at the seed_success_chance ceiling")

		for ore_type in GameData.ORE_TYPES.keys():
			assert_eq(p["orichalchum"][ore_type], 50, "50 units of %s -- enough for one seed attempt (40/type)" % ore_type)

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
		assert_eq(sites.size(), 9, "3 claimed shoreditch sites + 2 discovered unclaimed sites + 4 faction-owned sites")

		var unclaimed_by_district := {}
		var claimed_sites: Array = []
		var faction_sites: Array = []
		for site in sites:
			if site["claimed"]:
				claimed_sites.append(site)
			elif site["factionVein"] != null:
				faction_sites.append(site)
			else:
				unclaimed_by_district[site["district"]] = site
		assert_eq(unclaimed_by_district["greenwich"]["tier"], "rich", "greenwich site is rich")
		assert_eq(unclaimed_by_district["whitechapel"]["tier"], "saturated", "whitechapel site is saturated")
		for site in unclaimed_by_district.values():
			assert_eq(site["factionVein"], null, "debug sites start unclaimed by any faction")

		# multi-faction-line-routing (Chunk 2, ticket 03): faction-owned debug
		# fixtures so a debug-started game already shows real routed faction
		# lines on the Map tab (camden's 2 firm sites -> a multi-stop line;
		# kingscross/city each cover one more faction -> single-stop stubs).
		assert_eq(faction_sites.size(), 4, "4 faction-owned debug sites")
		var faction_site_ids_by_faction := {}
		for site in faction_sites:
			assert_eq(site["claimed"], false, "faction-owned sites are never also player-claimed")
			var faction_id: String = site["factionVein"]["factionId"]
			if not faction_site_ids_by_faction.has(faction_id):
				faction_site_ids_by_faction[faction_id] = []
			faction_site_ids_by_faction[faction_id].append(site["id"])
		assert_eq(faction_site_ids_by_faction.keys().size(), 3, "3 factions represented across the debug faction sites")
		assert_eq(faction_site_ids_by_faction["firm"].size(), 2, "firm has 2 stops -- a real multi-stop elbow-routed line")
		assert_eq(faction_site_ids_by_faction["network"].size(), 1, "network gets a single-stop stub")
		assert_eq(faction_site_ids_by_faction["conclave"].size(), 1, "conclave gets a single-stop stub")

		var visible_stops: Array = []
		for site in faction_sites:
			visible_stops.append_array(MapLayout.build_stop_items([site], []))
		var grouped := MapLayout.group_by_faction(visible_stops)
		assert_eq(grouped.keys().size(), 3, "the debug faction sites resolve into 3 real routable faction groups")
		assert_eq(grouped["firm"].size(), 2)

		# map-animations ticket 04 follow-up: each debug vein is linked to
		# its own claimed shoreditch site via siteId -- otherwise MapLayout.
		# build_stop_items never turns it into a Map stop (see debug_start.gd's
		# own comment), so it could never be tapped, harvested from the Map,
		# or targeted by a queued map event (charge/drain).
		assert_eq(claimed_sites.size(), 3, "one claimed site per debug vein")
		var claimed_site_ids := {}
		for site in claimed_sites:
			assert_eq(site["district"], "shoreditch", "claimed debug sites live in shoreditch")
			assert_eq(site["factionVein"], null, "claimed debug sites aren't faction-owned")
			claimed_site_ids[site["id"]] = site
		for v in p["veins"]:
			assert_true(claimed_site_ids.has(v["siteId"]), "%s vein's siteId resolves to one of the claimed sites" % v["oreType"])
			assert_eq(claimed_site_ids[v["siteId"]]["oreType"], v["oreType"], "linked site's oreType matches the vein's own oreType")

		var stops := MapLayout.build_stop_items(Sites.sites_in_district("shoreditch"), p["veins"])
		var vein_stop_ids := []
		for stop in stops:
			if stop["kind"] == "vein":
				vein_stop_ids.append(stop["vein"]["id"])
		for v in p["veins"]:
			assert_true(vein_stop_ids.has(v["id"]), "%s debug vein renders as a Map stop" % v["oreType"])
	)
