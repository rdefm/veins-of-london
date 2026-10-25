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
	_register_network_cases()
	_register_conclave_cases()

	run_case("data_has_three_tiers_and_seventeen_perks", func():
		assert_eq(GameData.validate_tables(GameData.snapshot()).size(), 0)
		var n := 0
		for fid in GameData.FACTIONS.keys():
			for tier in ["friendly", "partner", "sworn"]:
				n += GameData.FACTION_PERKS["factions"][fid][tier].size()
		assert_eq(n, 17)
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
		assert_eq(_ids(Perks.active_global()), ["guild_craft_xp", "guild_recipe_hints_1"])
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

	run_case("benefit_rows_requirements_scope_and_activity", func():
		GameState.reset()
		_clear_veins()
		GameState.state["turf"] = {}
		for fid in GameData.FACTIONS.keys():
			GameState.state["factions"][fid]["relation"] = 0
		var friendly: int = int(GameData.FACTION_PERKS["friendlyAtOrAbove"])
		var rows := Perks.benefit_rows("collective")
		assert_eq(rows.size(), 3)
		assert_eq(rows[0]["requirement"], "Relation ≥%d" % friendly)
		assert_eq(rows[1]["requirement"], "Partner stance")
		assert_eq(rows[2]["requirement"], "Joined")
		assert_eq(rows[0]["scope"], "turf")
		assert_eq(rows[2]["scope"], "global")
		for r in rows:
			assert_true(not r["unlocked"] and not r["active"] and r["districts"].is_empty())
		GameState.state["factions"]["collective"]["relation"] = friendly
		GameState.state["turf"]["soho"] = { "controller": "collective", "shares": {}, "tiers": { "collective": Turf.TIER_CONTROL } }
		GameState.state["turf"]["camden"] = { "controller": "", "shares": {}, "tiers": { "collective": Turf.TIER_FOOTHOLD } }
		rows = Perks.benefit_rows("collective")
		assert_true(rows[0]["unlocked"] and rows[0]["active"])
		assert_true(not rows[1]["unlocked"] and not rows[1]["active"])
		var by_district := {}
		for d in rows[0]["districts"]:
			by_district[d["district"]] = d["strength"]
		assert_eq(by_district, { "soho": "full", "camden": "reduced" })
		var soho := Perks.district_benefit_rows("collective", "soho")
		assert_eq(soho[0]["here"], "full")
		assert_eq(soho[1]["here"], "inactive")
		assert_eq(Perks.district_benefit_rows("collective", "camden")[0]["here"], "reduced")
		assert_eq(Perks.district_benefit_rows("collective", "hampstead")[0]["here"], "inactive")
		# Global perk: active wherever, once the tier is reached.
		GameState.state["factions"]["collective"]["joined"] = true
		rows = Perks.benefit_rows("collective")
		assert_true(rows[2]["active"] and rows[2]["districts"].is_empty())
		assert_eq(Perks.district_benefit_rows("collective", "hampstead")[2]["here"], "full")
		# Control without the tier: turf perk stays inactive.
		GameState.state["factions"]["collective"]["joined"] = false
		GameState.state["factions"]["collective"]["relation"] = 0
		assert_eq(Perks.district_benefit_rows("collective", "soho")[0]["here"], "inactive")
	)

	run_case("guild_benefits_list_recipe_hint_rows_at_friendly_and_partner", func():
		GameState.reset()
		var tiers := {}
		for row in Perks.benefit_rows("guild"):
			if row["perk"]["effect"] == "recipeHints":
				tiers[row["perk"]["label"]] = row["tier"]
		assert_eq(tiers, { "Recipe hints I": "friendly", "Recipe hints II": "partner" })
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
		GameState.state["event"] = { "eventId": "x", "context": { "muscle": true } }
		assert_eq(Perks.muscle_odds_bonus(), 0.1)
		assert_true(Raiding.raid_factor_mods(vein).any(func(m): return m["delta"] == 0.1), "muscle shows as a raid factor")
		GameState.state["event"] = { "eventId": "x", "context": {} }
		assert_eq(Perks.muscle_odds_bonus(), 0.0)
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

	run_case("guild_craft_xp_multiplier", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["relation"] = 0
		assert_eq(Perks.craft_xp_mult(), 1.0)
		var before: int = GameState.state["player"]["craftingXP"]
		Crafting.award_crafting_xp(20)
		assert_eq(GameState.state["player"]["craftingXP"] - before, 20)
		GameState.state["factions"]["guild"]["relation"] = 30
		before = GameState.state["player"]["craftingXP"]
		Crafting.award_crafting_xp(20)
		assert_eq(GameState.state["player"]["craftingXP"] - before, 25)
	)

	run_case("internship_free_cultivate_daily_and_craft_chance_bonus", func():
		GameState.reset()
		GameState.state["turf"]["soho"] = { "controller": "guild", "tiers": { "guild": Turf.TIER_CONTROL }, "shares": {} }
		GameState.state["factionStances"]["player"]["guild"]["stance"] = FactionAI.PARTNER
		var vein := _RAIDING._player_vein_of(30, "time", "none", "soho")
		vein["id"] = "pv_soho"
		GameState.state["player"]["veins"] = [vein]
		var blocks_before: int = GameState.state["world"]["timeBlock"]
		assert_true(Cultivating.cultivate(vein["id"])["ok"])
		assert_eq(GameState.state["world"]["timeBlock"], blocks_before, "free: no block")
		Cultivating.cultivate(vein["id"])
		assert_true(GameState.state["world"]["timeBlock"] != blocks_before, "second costs a block")
		GameState.state["world"]["day"] += 1
		var again: int = GameState.state["world"]["timeBlock"]
		Cultivating.cultivate(vein["id"])
		assert_eq(GameState.state["world"]["timeBlock"], again, "free again next day")
		assert_almost_eq(Perks.craft_chance_bonus(), 0.05, 0.0001)
		vein["district"] = "camden"
		assert_eq(Perks.craft_chance_bonus(), 0.0)
	)

	run_case("sworn_guild_commission_offer", func():
		GameState.reset()
		GameState.state["factions"]["guild"]["joined"] = true
		GameState.state["sales"]["pendingOffers"] = []
		for i in 40:
			Offers.daily_tick()
		var found := []
		for o in Offers.pending_offers():
			if o["source"] == "commission":
				found.append(o)
		assert_eq(found.size(), 1, "one at a time")
		assert_eq(found[0]["counterparty"], "guild")
		var plain: int = Offers.quote_for_request(found[0]["request"], Offers.sales_skill())["payment"]
		assert_true(found[0]["quote"]["payment"] > plain)
		GameState.state["factions"]["guild"]["joined"] = false
		GameState.state["sales"]["pendingOffers"] = []
		for i in 40:
			Offers.daily_tick()
		for o in Offers.pending_offers():
			assert_true(o["source"] != "commission")
	)


func _network_standing(tier: String) -> void:
	GameState.reset()
	for fid in GameData.FACTIONS.keys():
		GameState.state["factions"][fid]["relation"] = 0
	GameState.state["factions"]["network"]["relation"] = 30
	if tier == "sworn":
		GameState.state["factions"]["network"]["joined"] = true


func _register_network_cases() -> void:
	run_case("network_daily_intel_on_chosen_faction", func():
		_network_standing("friendly")
		assert_true(Perks.set_intel_target("firm")["ok"])
		var before := Intel.meter(Shares.PLAYER, "firm")
		Perks.daily_intel()
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), before + 1)
		Perks.set_intel_target("guild")
		var firm := Intel.meter(Shares.PLAYER, "firm")
		Perks.daily_intel()
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), firm)
		assert_eq(Intel.meter(Shares.PLAYER, "guild"), 1)
		GameState.state["factions"]["network"]["relation"] = 0
		Perks.daily_intel()
		assert_eq(Intel.meter(Shares.PLAYER, "guild"), 1)
		assert_true(not Perks.set_intel_target("firm")["ok"])
	)

	run_case("network_forewarning_texts_raids_for_partner_only", func():
		_network_standing("friendly")
		assert_true(not Perks.forewarning_active())
		GameState.state["factionStances"]["player"]["network"]["stance"] = FactionAI.PARTNER
		assert_true(Perks.forewarning_active())
		GameState.state["world"]["sites"].append({ "id": "s_fw", "district": "soho" })
		var site_id := "s_fw"
		var msgs: int = GameState.state["messages"].get(NetworkHandler.CONTACT_ID, []).size()
		NetworkHandler.warn_of_raid("firm", site_id)
		assert_eq(GameState.state["messages"][NetworkHandler.CONTACT_ID].size(), msgs + 1)
	)

	run_case("network_commissioned_move_costs_cash_and_cools_down", func():
		_network_standing("sworn")
		GameState.state["player"]["cash"] = 5000
		GameState.state["factions"]["collective"]["resources"] = 0
		var res := Perks.commission_market_move("priceGouge", "firm")
		assert_true(res["ok"])
		assert_eq(int(GameState.state["player"]["cash"]), 5000 - int(res["cost"]))
		assert_true(FactionAI.gouge_mult("firm") > 1.0)
		assert_true(not Perks.commission_market_move("priceGouge", "guild")["ok"])
		assert_true(Perks.commission_cooldown_left() > 0)
		GameState.state["world"]["day"] += 7
		assert_eq(Perks.commission_cooldown_left(), 0)
	)

	run_case("network_commission_rejects_bad_orders", func():
		_network_standing("friendly")
		assert_true(not Perks.commission_market_move("priceGouge", "firm")["ok"])
		_network_standing("sworn")
		GameState.state["player"]["cash"] = 0
		assert_true(not Perks.commission_market_move("priceGouge", "firm")["ok"])
		GameState.state["player"]["cash"] = 5000
		assert_true(not Perks.commission_market_move("flood", "firm")["ok"])
		assert_true(not Perks.commission_market_move("priceGouge", "network")["ok"])
	)



func _conclave_standing(tier: String) -> void:
	GameState.reset()
	for fid in GameData.FACTIONS.keys():
		GameState.state["factions"][fid]["relation"] = 0
	GameState.state["factions"]["conclave"]["relation"] = 30
	if tier == "sworn":
		GameState.state["factions"]["conclave"]["joined"] = true


# A player vein raided away by `attacker`, the way the raid resolver does it.
func _raid_lost_vein(attacker: String) -> void:
	var vein := _RAIDING._player_vein_of(50, "physics", "none", "camden")
	GameState.state["player"]["veins"] = [vein]
	GameState.state["world"]["sites"] = [_RAIDING._player_site_with_vein("s_player", vein)]
	Raiding.resolve_raid_outcome({ "attackerId": attacker, "veinId": "pv_test", "siteId": "s_player", "success": true })


func _register_conclave_cases() -> void:
	run_case("conclave_legal_cover_lowers_danger_in_conclave_turf", func():
		_conclave_standing("none")
		GameState.state["factions"]["conclave"]["relation"] = 0
		var sites: Array = GameState.state["world"]["sites"]
		for i in 3:
			var vein := _RAIDING._player_vein_of(30, "time", "none", "soho", "s_c%d" % i)
			sites.append(_RAIDING._player_site_with_vein("s_c%d" % i, vein))
		_clear_veins()
		for i in 3:
			_claim(sites.size() - 3 + i, "soho", "conclave")
		GameState.state["turf"] = Turf.compute(GameState.state)
		assert_eq(Perks.danger_adj("soho"), 0.0)
		GameState.state["factions"]["conclave"]["relation"] = 30
		var base: float = GameData.DISTRICTS["soho"].get("dangerMod", 0.0)
		assert_true(Perks.danger_adj("soho") < 0.0)
		assert_eq(Turf.danger_mod("soho"), base + Turf._relation_adj("soho", "dangerAdj") + Perks.danger_adj("soho"))
		assert_eq(Perks.danger_adj("camden"), 0.0)
	)

	run_case("conclave_recovery_returns_raid_lost_vein_once", func():
		_conclave_standing("friendly")
		_raid_lost_vein("firm")
		assert_true(Perks.recoverable_veins().is_empty())
		GameState.state["factions"]["conclave"]["relation"] = 80
		GameState.state["factions"]["conclave"]["joined"] = false
		GameState.state["factionStances"]["player"]["conclave"]["stance"] = FactionAI.PARTNER
		assert_eq(Perks.recoverable_veins().size(), 1)
		assert_true(Perks.recover_vein("pv_test")["ok"])
		assert_eq(GameState.state["player"]["veins"].size(), 1)
		assert_true(Perks.recovery_used())
		assert_true(not Perks.recover_vein("pv_test")["ok"])
	)

	run_case("conclave_recovery_refuses_without_perk_or_when_vein_gone", func():
		_conclave_standing("friendly")
		_raid_lost_vein("firm")
		assert_true(not Perks.recover_vein("pv_test")["ok"])
		_conclave_standing("sworn")
		_raid_lost_vein("firm")
		Sites.find_site("s_player")["factionVein"] = null
		assert_true(not Perks.recover_vein("pv_test")["ok"])
		assert_true(not Perks.recovery_used())
	)

	run_case("conclave_sworn_nudge_moves_barometer_and_sets_lore", func():
		_conclave_standing("friendly")
		assert_true(not Perks.conclave_nudge("economic", "boom", "push")["ok"])
		_conclave_standing("sworn")
		Perks.sync_lore()
		assert_true(GameState.state["flags"]["deepVeinRoute"])
		GameState.state["player"]["cash"] = 5000
		Barometer.ensure_progress()
		var before: int = GameState.state["barometer"]["progress"]["economic"]["boom"]
		var target := "boom" if GameState.state["barometer"]["economic"] != "boom" else "recession"
		before = GameState.state["barometer"]["progress"]["economic"][target]
		var res := Perks.conclave_nudge("economic", target, "push")
		assert_true(res["ok"])
		assert_eq(int(GameState.state["player"]["cash"]), 5000 - int(res["cost"]))
		assert_true(GameState.state["barometer"]["economic"] == target or GameState.state["barometer"]["progress"]["economic"][target] > before)
		assert_true(not Perks.conclave_nudge("economic", target, "pull")["ok"])
		GameState.state["world"]["day"] += 7
		assert_eq(Perks.nudge_cooldown_left(), 0)
	)
