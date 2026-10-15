extends "res://tests/test_base.gd"

# TurfPanel: pure rows for the district panel's Turf section.


func _claim(site_idx: int, district: String, faction: String) -> void:
	var site: Dictionary = GameState.state["world"]["sites"][site_idx]
	site["district"] = district
	site["factionVein"] = { "id": "v%d" % site_idx, "factionId": faction }


func run() -> void:
	run_case("empty_district_has_no_rows", func():
		GameState.reset()
		for site in GameState.state["world"]["sites"]:
			site["factionVein"] = null
		GameState.state["turf"] = Turf.compute(GameState.state)
		var panel: Dictionary = TurfPanel.build("soho")
		assert_eq(panel["sections"]["contenders"].size(), 0)
		assert_eq(panel["sections"]["flip"].size(), 0)
		assert_eq(panel["status"], "unclaimed")
	)

	run_case("shares_tier_and_flip_margin_for_a_faction_controlled_district", func():
		GameState.reset()
		var sites: Array = GameState.state["world"]["sites"]
		for site in sites:
			site["factionVein"] = null
		var fid: String = GameData.FACTIONS.keys()[0]
		if sites.size() < 3:
			return
		for i in 3:
			_claim(i, "soho", fid)
		GameState.state["turf"] = Turf.compute(GameState.state)
		var panel: Dictionary = TurfPanel.build("soho")
		var rows: Array = panel["sections"]["contenders"]
		assert_eq(rows[0]["share_pct"], 100)
		assert_eq(rows[0]["tier"], "control")
		assert_eq(panel["sections"]["flip"][0]["kind"], "need")
		assert_eq(panel["sections"]["flip"][0]["veins"], 3 + int(GameData.TURF["controlMargin"]))
	)

	run_case("modifier_rows_carry_source_faction", func():
		GameState.reset()
		var sites: Array = GameState.state["world"]["sites"]
		for site in sites:
			site["factionVein"] = null
		if sites.size() < 3:
			return
		var fid: String = GameData.FACTIONS.keys()[0]
		for i in 3:
			_claim(i, "soho", fid)
		GameState.state["factions"][fid]["relation"] = 60
		GameState.state["turf"] = Turf.compute(GameState.state)
		var mods: Array = TurfPanel.build("soho")["sections"]["modifiers"]
		assert_true(mods.size() >= 2, "danger + price from relation band")
		for m in mods:
			assert_eq(m["source"], fid)
	)

	run_case("later_sections_exist_as_empty_slots", func():
		GameState.reset()
		var panel: Dictionary = TurfPanel.build("soho")
		assert_eq(panel["sections"]["benefits"].size(), 0)
		assert_eq(panel["sections"]["harassment"].size(), 0)
	)

	run_case("perk_groups_list_every_faction_with_no_veins", func():
		GameState.reset()
		for site in GameState.state["world"]["sites"]:
			site["factionVein"] = null
		GameState.state["turf"] = Turf.compute(GameState.state)
		var g: Dictionary = TurfPanel.perk_groups("soho")
		var ids := []
		for card in g["here"]:
			ids.append(card["faction"])
			assert_eq(card["presence"], "none")
			assert_eq(card["presence_label"], "No ground here")
		assert_eq(ids, ["collective", "firm", "guild", "conclave"])
		assert_eq(g["everywhere"].size() + g["locked_hidden"], 10)
		assert_true(g["locked_hidden"] > 0)
		for row in g["here"][0]["perks"]:
			assert_eq(row["status"], "locked")
			assert_true(row["note"].contains("No ground held here yet."))
	)

	run_case("perk_groups_controller_first_foothold_second_and_idle_when_sworn", func():
		GameState.reset()
		var sites: Array = GameState.state["world"]["sites"]
		for site in sites:
			site["factionVein"] = null
		if sites.size() < 5:
			return
		for i in 3:
			_claim(i, "soho", "guild")
		_claim(3, "soho", "collective")
		GameState.state["turf"] = Turf.compute(GameState.state)
		var tiers: Dictionary = GameState.state["turf"]["soho"]["tiers"]
		GameState.state["factions"]["guild"]["relation"] = 30
		GameState.state["factions"]["firm"]["joined"] = true
		var g: Dictionary = TurfPanel.perk_groups("soho")
		var first: Dictionary = g["here"][0]
		assert_eq(first["faction"], "guild")
		assert_eq(first["presence"], tiers["guild"])
		assert_eq(first["perks"][0]["status"], "locked")
		assert_true(first["perks"][0]["note"].begins_with("Needs Partner stance"))
		var firm: Dictionary = {}
		for card in g["here"]:
			if card["faction"] == "firm":
				firm = card
		assert_eq(firm["presence"], "none")
		assert_eq(firm["perks"][0]["status"], "idle")
		assert_eq(firm["perks"][0]["note"], "No ground held here yet.")
	)

	run_case("perk_groups_active_full_and_half", func():
		GameState.reset()
		var sites: Array = GameState.state["world"]["sites"]
		for site in sites:
			site["factionVein"] = null
		if sites.size() < 5:
			return
		for i in 4:
			_claim(i, "soho", "collective")
		_claim(4, "soho", "guild")
		GameState.state["turf"] = Turf.compute(GameState.state)
		GameState.state["factions"]["collective"]["relation"] = 60
		GameState.state["factions"]["guild"]["joined"] = true
		var g: Dictionary = TurfPanel.perk_groups("soho")
		var by_id := {}
		for card in g["here"]:
			by_id[card["faction"]] = card
		var ct: String = Turf.tier("soho", "collective")
		var gt: String = Turf.tier("soho", "guild")
		assert_eq(by_id["collective"]["perks"][0]["status"], "active" if ct == "control" else "half")
		if gt == "foothold":
			assert_eq(by_id["guild"]["perks"][0]["status"], "half")
			assert_eq(by_id["guild"]["presence_label"], "Foothold · half")
	)
