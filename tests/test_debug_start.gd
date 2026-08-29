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

		# ticket 64: seeded at tier == craftingSkill (3, above) via
		# Crafting.inventory_add -- tier-bucketed, not a flat count.
		assert_eq(p["inventory"], {
			"timePearl": { "3": 5 }, "enhancementPowder": { "3": 3 }, "rewind": { "3": 1 },
			"healingSalve": { "3": 2 }, "blast": { "3": 3 }, "shield": { "3": 2 }, "blackHole": { "3": 2 }, "healingBurst": { "3": 3 },
		}, "consumables")

		assert_eq(p["items"].size(), 1, "one item (the crowbar)")
		assert_eq(p["items"][0]["type"], "crowbar", "item is a crowbar")
		assert_eq(p["equipment"]["weapon"], p["items"][0]["id"], "crowbar equipped")

		assert_eq(p["veins"].size(), 3, "3 debug veins")
		var by_type := {}
		for v in p["veins"]:
			by_type[v["oreType"]] = v
		assert_eq(by_type["time"]["growth"], 0, "time vein is collapsed (growth 0)")
		assert_eq(by_type["physics"]["growth"], 50, "physics vein is dormant (growth 50)")
		assert_eq(by_type["life"]["growth"], 100, "life vein is rampant (growth 100)")
		assert_eq(Cultivating.growth_band(by_type["time"])["id"], "collapsed", "time vein reads as the collapsed band")
		assert_eq(Cultivating.growth_band(by_type["physics"])["id"], "dormant", "physics vein reads as the dormant band")
		assert_eq(Cultivating.growth_band(by_type["life"])["id"], "rampant", "life vein reads as the rampant band")

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

		assert_eq(s["currentScreen"], "phone", "debug start should land on the phone app grid")
		assert_eq(s["phoneNav"]["app"], "home", "should land on the grid itself, not whatever app was last open")

		var sites: Array = s["world"]["sites"]
		# ticket 18: DebugStart.apply() now also calls Factions.seed_day_one_veins()
		# after its own hand-built fixture, so a debug-started game carries the
		# same 30 real day-one faction sites (collective 8, firm 4, guild 7,
		# network 4, conclave 7) a real New Game gets, on top of the 9
		# hand-built fixture sites.
		assert_eq(sites.size(), 9 + 30, "3 claimed shoreditch sites + 2 discovered unclaimed sites + 4 hand-built faction sites + 30 real day-one faction sites")

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
		# ticket 18: plus the real day-one roster from Factions.seed_day_one_veins()
		# (collective 8, firm 4, guild 7, network 4, conclave 7 = 30 more).
		assert_eq(faction_sites.size(), 4 + 30, "4 hand-built faction sites + 30 real day-one faction sites")
		var faction_site_ids_by_faction := {}
		for site in faction_sites:
			assert_eq(site["claimed"], false, "faction-owned sites are never also player-claimed")
			var faction_id: String = site["factionVein"]["factionId"]
			if not faction_site_ids_by_faction.has(faction_id):
				faction_site_ids_by_faction[faction_id] = []
			faction_site_ids_by_faction[faction_id].append(site["id"])
		assert_eq(faction_site_ids_by_faction.keys().size(), 5, "all 5 factions represented once the real day-one roster is included")
		assert_eq(faction_site_ids_by_faction["firm"].size(), 2 + 4, "firm: 2 hand-built (multi-stop elbow-routed line) + 4 real day-one")
		assert_eq(faction_site_ids_by_faction["network"].size(), 1 + 4, "network: 1 hand-built stub + 4 real day-one")
		assert_eq(faction_site_ids_by_faction["conclave"].size(), 1 + 7, "conclave: 1 hand-built stub + 7 real day-one")
		assert_eq(faction_site_ids_by_faction["collective"].size(), 8, "collective: real day-one roster only, no hand-built fixture")
		assert_eq(faction_site_ids_by_faction["guild"].size(), 7, "guild: real day-one roster only, no hand-built fixture")

		var visible_stops: Array = []
		for site in faction_sites:
			visible_stops.append_array(MapLayout.build_stop_items([site], []))
		var grouped := MapLayout.group_by_faction(visible_stops)
		assert_eq(grouped.keys().size(), 5, "the faction sites resolve into 5 real routable faction groups")
		assert_eq(grouped["firm"].size(), 6)

		# ticket 18: the hand-built fixture's districts (shoreditch, greenwich,
		# whitechapel, camden, kingscross, city) all overlap with districts the
		# real day-one roster also seeds -- verify the combined site count
		# never overflows the district's siteCap (which already accounts for
		# the real roster's own placement count, per Factions.seed_day_one_veins's
		# own "siteCap is bumped, not spent" comment).
		for district_id in ["shoreditch", "whitechapel", "camden", "kingscross", "city", "greenwich", "battersea"]:
			var site_cap: int = GameData.DISTRICTS[district_id]["siteCap"]
			var actual: int = Sites.sites_in_district(district_id).size()
			assert_true(actual <= site_cap, "%s: %d sites must not exceed siteCap %d" % [district_id, actual, site_cap])

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

		# ticket 96: debug start hands over an already-seeded Dial,
		# bypassing the gift-gate/cost/roll -- bare, matching
		# Dial.new_dial()'s exact inert shape.
		var dial: Dictionary = p["dial"]
		assert_true(dial != null, "debug start grants a Dial")
		assert_eq(dial["level"], 1, "seeded Dial is level 1")
		assert_eq(dial["movement"], null, "seeded Dial has no Movement seated")
		assert_eq(dial["loadedComplications"], [], "seeded Dial has no loaded Complications")
		assert_true(GameData.DIAL_HAFTS.has(dial["haftId"]), "seeded Dial has a valid haftId")
		assert_eq(dial["currentCharge"], 0, "seeded Dial has no charge")
		assert_eq(dial["capacityMax"], Dial.capacity_max(1), "seeded Dial's capacity matches the level-1 lookup")
	)
