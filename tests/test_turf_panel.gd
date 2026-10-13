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
