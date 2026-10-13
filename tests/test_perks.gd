extends "res://tests/test_base.gd"

# Perks: tier mapping, global/turf queries, preview, and the panel's benefit rows.

const _RAIDING := preload("res://tests/test_raiding.gd")


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

	run_case("watch_lowers_raid_odds_full_in_control_reduced_at_foothold_none_elsewhere", func():
		GameState.reset()
		GameState.state["factions"]["firm"]["relation"] = -100
		var friendly: int = int(GameData.FACTION_PERKS["friendlyAtOrAbove"])
		GameState.state["factions"]["collective"]["relation"] = friendly
		var vein := _RAIDING._player_vein_of(30, "time", "none", "soho")
		var other := _RAIDING._player_vein_of(30, "time", "none", "camden")
		GameState.state["turf"]["soho"] = { "controller": "collective", "shares": {}, "tiers": { "collective": Turf.TIER_CONTROL } }
		GameData.FACTION_PERKS["friendlyAtOrAbove"] = 101  # same turf danger band, perk locked
		var base := Raiding.raid_success_chance("firm", vein)
		GameData.FACTION_PERKS["friendlyAtOrAbove"] = friendly
		var full := Raiding.raid_success_chance("firm", vein)
		assert_almost_eq(full, base - 0.1, 0.0001)
		GameState.state["turf"]["soho"]["tiers"]["collective"] = Turf.TIER_FOOTHOLD
		GameData.FACTION_PERKS["friendlyAtOrAbove"] = 101
		var foot_base := Raiding.raid_success_chance("firm", vein)
		GameData.FACTION_PERKS["friendlyAtOrAbove"] = friendly
		var part := Raiding.raid_success_chance("firm", vein)
		assert_almost_eq(part, foot_base - 0.1 * float(GameData.TURF["footholdFactor"]), 0.0001)
		GameState.state["factions"]["collective"]["relation"] = 0
		var other_base := Raiding.raid_success_chance("firm", other)
		GameState.state["factions"]["collective"]["relation"] = int(GameData.FACTION_PERKS["friendlyAtOrAbove"])
		assert_almost_eq(Raiding.raid_success_chance("firm", other), other_base, 0.0001)
	)

	run_case("partner_tending_tends_only_skipped_turf_veins_once", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 0
		GameState.state["factionStances"]["player"]["collective"]["stance"] = FactionAI.PARTNER
		GameState.state["turf"]["soho"] = { "controller": "collective", "shares": {}, "tiers": { "collective": Turf.TIER_CONTROL } }
		var a := _RAIDING._player_vein_of(30, "time", "none", "soho")
		a["id"] = "va"
		var b := _RAIDING._player_vein_of(30, "time", "none", "soho")
		b["id"] = "vb"
		var c := _RAIDING._player_vein_of(30, "time", "none", "camden")
		c["id"] = "vc"
		GameState.state["player"]["veins"] = [a, b, c]
		GameState.state["world"]["day"] = 5
		GameState.state["player"]["cultivatingSkill"] = 5
		GameState.state["world"]["day"] = 4
		Perks.note_player_tended("va")
		GameState.state["world"]["day"] = 5
		Perks.daily_tend()
		assert_eq(a["growth"], 30, "player-tended vein left alone")
		assert_true(b["growth"] > 30, "skipped turf vein tended")
		assert_eq(c["growth"], 30, "non-turf vein untouched")
	)

	run_case("whip_round_fires_once_before_forced_downgrade", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["joined"] = true
		var home: Dictionary = GameState.state["home"]
		home["tier"] = "flat"
		home["tenure"] = Home.TENURE_RENTED
		var day := 7
		while not Calendar.is_monday(day):
			day += 1
		GameState.state["world"]["day"] = day
		GameState.state["player"]["cash"] = 0
		home["arrears"] = 500
		home["arrearsWeeks"] = int(GameData.HOME_BILLS["downgradeThresholdWeeks"]) - 1
		var first: Dictionary = TimeSystem._apply_living_costs()
		assert_true(first["downgrade"].is_empty(), "bailout stops downgrade")
		assert_eq(home["tier"], "flat")
		assert_eq(home["arrears"], 0)
		assert_true(GameState.state["perks"]["whipRoundUsed"])
		home["arrears"] = 500
		home["arrearsWeeks"] = int(GameData.HOME_BILLS["downgradeThresholdWeeks"]) - 1
		var second: Dictionary = TimeSystem._apply_living_costs()
		assert_true(not second["downgrade"].is_empty(), "second time downgrades")
	)

	run_case("racket_fee_charged_on_monday_and_ends_when_unpaid", func():
		GameState.reset()
		GameState.state["factions"]["firm"]["relation"] = 30
		assert_true(Perks.set_racket(true)["ok"])
		var day := 7
		while not Calendar.is_monday(day):
			day += 1
		GameState.state["world"]["day"] = day
		GameState.state["player"]["cash"] = 1000
		assert_eq(Perks.pay_racket_fee(), 150)
		assert_eq(GameState.state["player"]["cash"], 850)
		GameState.state["player"]["cash"] = 10
		assert_eq(Perks.pay_racket_fee(), 0)
		assert_true(not Perks.racket_active(), "missed fee ends racket")
		GameState.state["factions"]["firm"]["relation"] = 0
		assert_true(not Perks.set_racket(true)["ok"], "needs Friendly")
	)

	run_case("racket_blocks_firm_raids_and_deters_others", func():
		GameState.reset()
		GameState.state["factions"]["firm"]["relation"] = 30
		var vein := _RAIDING._player_vein_of(30, "time", "none", "soho")
		var base := Raiding.raid_success_chance("collective", vein)
		assert_true(not Perks.racket_blocks("firm", Shares.PLAYER, "veinRaid"))
		Perks.set_racket(true)
		assert_true(Perks.racket_blocks("firm", Shares.PLAYER, "veinRaid"))
		assert_true(not Perks.racket_blocks("firm", Shares.PLAYER, "flood"), "market moves stay")
		assert_true(not Perks.racket_blocks("guild", Shares.PLAYER, "veinRaid"))
		assert_true(Raiding.raid_success_chance("collective", vein) < base, "deterrence")
	)

	run_case("muscle_adds_odds_and_combat_ally", func():
		GameState.reset()
		GameState.state["factionStances"]["player"]["firm"]["stance"] = FactionAI.PARTNER
		var vein := _RAIDING._player_vein_of(30, "time", "none", "soho")
		var plain := Raiding.stealth_success_chance(1, vein, 0.0)
		GameState.state["event"] = { "eventId": "x", "context": { "muscle": true } }
		assert_eq(Perks.muscle_odds_bonus(), 0.1)
		GameState.state["event"] = { "eventId": "x", "context": {} }
		assert_eq(Perks.muscle_odds_bonus(), 0.0)
		assert_true(plain > 0.0)
		Raiding.prepare_raid(vein)
		GameState.state["combatPrep"] = { "kind": CombatPrep.KIND_VEIN_RAID, "args": {}, "forced": false, "returnScreen": "map" }
		assert_true(CombatPrep.toggle_muscle())
		assert_true(bool(GameState.state["combatPrep"]["args"]["muscle"]))
		var rows := CombatPrep.participants(GameState.state["combatPrep"])
		assert_eq(rows[1]["name"], "Firm muscle")
		GameState.state["factionStances"]["player"]["firm"]["stance"] = FactionAI.NEUTRAL
		assert_true(not CombatPrep.toggle_muscle(), "needs Partner")
	)

	run_case("sworn_firm_districts_count_as_player_for_danger", func():
		GameState.reset()
		GameState.state["turf"]["soho"] = { "controller": "firm", "tiers": { "firm": Turf.TIER_CONTROL }, "shares": {} }
		var before := Turf.danger_mod("soho")
		GameState.state["factions"]["firm"]["joined"] = true
		assert_true(Turf.danger_mod("soho") < before)
		assert_true(not Perks.counts_as_player_for_danger("camden"))
	)
