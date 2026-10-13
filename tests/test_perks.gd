extends "res://tests/test_base.gd"

# Perks: tier mapping, global/turf queries, preview, and the panel's benefit rows.


func _claim(site_idx: int, district: String, faction: String) -> void:
	var site: Dictionary = GameState.state["world"]["sites"][site_idx]
	site["district"] = district
	site["factionVein"] = { "id": "v%d" % site_idx, "factionId": faction }


func _clear_veins() -> void:
	for site in GameState.state["world"]["sites"]:
		site["factionVein"] = null


func _ids(entries: Array) -> Array:
	var ids := []
	for e in entries:
		ids.append(e["perk"]["id"])
	return ids


func run() -> void:
	run_case("data_has_three_tiers_and_fifteen_perks", func():
		assert_eq(GameData.validate_tables(GameData.snapshot()).size(), 0)
		var n := 0
		for fid in GameData.FACTIONS.keys():
			for tier in ["friendly", "partner", "sworn"]:
				n += GameData.FACTION_PERKS["factions"][fid][tier].size()
		assert_eq(n, 15)
	)

	run_case("tier_mapping", func():
		GameState.reset()
		var fid := "collective"
		GameState.state["factions"][fid]["relation"] = 0
		GameState.state["factionStances"]["player"][fid]["stance"] = FactionAI.NEUTRAL
		assert_eq(Perks.player_tier(fid), "none")
		GameState.state["factions"][fid]["relation"] = int(GameData.FACTION_PERKS["friendlyAtOrAbove"])
		assert_eq(Perks.player_tier(fid), "friendly")
		GameState.state["factionStances"]["player"][fid]["stance"] = FactionAI.PARTNER
		assert_eq(Perks.player_tier(fid), "partner")
		GameState.state["factions"][fid]["joined"] = true
		assert_eq(Perks.player_tier(fid), "sworn")
	)

	run_case("global_perks_cumulative_by_tier", func():
		GameState.reset()
		for fid in GameData.FACTIONS.keys():
			GameState.state["factions"][fid]["relation"] = 0
		assert_eq(Perks.active_global().size(), 0)
		GameState.state["factions"]["guild"]["relation"] = 30
		assert_eq(_ids(Perks.active_global()), ["guild_craft_xp"])
		GameState.state["factions"]["guild"]["joined"] = true
		assert_true(_ids(Perks.active_global()).has("guild_commissions"))
		assert_true(_ids(Perks.active_global()).has("guild_craft_xp"))
	)

	run_case("turf_perks_scale_with_control_and_foothold", func():
		GameState.reset()
		_clear_veins()
		for fid in GameData.FACTIONS.keys():
			GameState.state["factions"][fid]["relation"] = 0
		GameState.state["factions"]["collective"]["relation"] = 30
		var sites: Array = GameState.state["world"]["sites"]
		if sites.size() < 4:
			return
		for i in 3:
			_claim(i, "soho", "collective")
		GameState.state["turf"] = Turf.compute(GameState.state)
		var perks := Perks.active_turf("soho")
		assert_eq(_ids(perks), ["collective_neighbourhood_watch"])
		assert_eq(perks[0]["scale"], 1.0)
		assert_eq(Perks.active_turf("camden").size(), 0)
		GameState.state["turf"]["soho"]["tiers"]["collective"] = Turf.TIER_FOOTHOLD
		GameState.state["turf"]["soho"]["controller"] = ""
		assert_eq(Perks.active_turf("soho")[0]["scale"], float(GameData.TURF["footholdFactor"]))
	)

	run_case("preview_lists_all_tiers_and_marks_turf", func():
		GameState.reset()
		GameState.state["factions"]["conclave"]["relation"] = 0
		var panel := TurfPanel.faction_preview("conclave")
		assert_eq(panel["perks"].size(), 3)
		assert_eq(panel["tier"], "none")
		assert_true(panel["perks"][0]["turf"])
		assert_true(not panel["perks"][1]["turf"])
		for p in panel["perks"]:
			assert_true(not p["unlocked"])
	)

	run_case("panel_benefit_rows_carry_source_faction", func():
		GameState.reset()
		_clear_veins()
		for fid in GameData.FACTIONS.keys():
			GameState.state["factions"][fid]["relation"] = 0
		var sites: Array = GameState.state["world"]["sites"]
		if sites.size() < 3:
			return
		GameState.state["factions"]["conclave"]["relation"] = 30
		for i in 3:
			_claim(i, "soho", "conclave")
		GameState.state["turf"] = Turf.compute(GameState.state)
		var rows: Array = TurfPanel.build("soho")["sections"]["benefits"]
		assert_eq(rows.size(), 1)
		assert_eq(rows[0]["source"], "conclave")
		assert_eq(rows[0]["perk_id"], "conclave_legal_cover")
	)
