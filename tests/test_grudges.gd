extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# Grudges: recorded by a successful faction raid, answered by a player raid or
# a security upgrade in the district, expiring into a decaying soft mark.


static func _fresh() -> void:
	GameState.reset()
	GameState.state["shares"] = Shares.new_state()
	GameState.state["world"]["sites"] = []
	GameState.state["player"]["veins"] = []


# A raided player vein "pv" on site "site_pv" in Shoreditch.
static func _raided(outcome_type: String) -> void:
	_fresh()
	Fixtures.seed_vein("pv", 60)
	Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv", "siteId": "site_pv", "success": true, "outcomeType": outcome_type })


func run() -> void:
	run_case("claim_raid_records_a_grudge_with_the_lost_site", func():
		_raided("claim")
		var grudge: Dictionary = GameState.state["grudges"]["firm"]
		assert_eq(grudge["district"], "shoreditch")
		assert_eq(grudge["siteId"], "site_pv")
	)

	run_case("loot_raid_records_a_grudge_without_a_site", func():
		_raided("loot")
		assert_true(Grudges.has_grudge("firm"))
		assert_true(not GameState.state["grudges"]["firm"].has("siteId"))
	)

	run_case("failed_raid_records_nothing", func():
		_fresh()
		Fixtures.seed_vein("pv", 60)
		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv", "siteId": "site_pv", "success": false })
		assert_true(not Grudges.has_grudge("firm"))
	)

	run_case("repeat_raid_refreshes_the_grudge", func():
		_raided("loot")
		GameState.state["world"]["day"] = 4
		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv", "siteId": "site_pv", "success": true, "outcomeType": "loot" })
		assert_eq(int(GameState.state["grudges"]["firm"]["sinceDay"]), 4)
	)

	run_case("player_raid_on_the_faction_answers_with_relation_gain_and_revenge_bonus", func():
		_raided("claim")
		var before := int(GameState.state["factions"]["firm"]["relation"])
		Grudges.answer("firm")
		assert_true(not Grudges.has_grudge("firm"))
		assert_eq(int(GameState.state["factions"]["firm"]["relation"]), before + int(GameData.FACTION_GRUDGE["answerRelationGain"]))
		assert_eq(Grudges.raid_odds_bonus("site_pv"), float(GameData.FACTION_GRUDGE["revengeOddsBonus"]))
		assert_eq(Grudges.raid_odds_bonus("elsewhere"), 0.0)
	)

	run_case("loot_vein_on_the_faction_answers_it", func():
		_raided("loot")
		Fixtures.seed_faction_vein("fv", 40, "firm")
		Raiding.loot_vein("site_fv", false)
		assert_true(not Grudges.has_grudge("firm"))
	)

	run_case("security_upgrade_in_the_district_answers_it", func():
		_raided("loot")
		GameState.state["player"]["cash"] = 100000
		var result := Cultivating.upgrade_vein_security("pv")
		assert_true(result["ok"])
		assert_true(not Grudges.has_grudge("firm"))
	)

	run_case("security_upgrade_elsewhere_leaves_it", func():
		_raided("loot")
		GameState.state["grudges"]["firm"]["district"] = "camden"
		GameState.state["player"]["cash"] = 100000
		Cultivating.upgrade_vein_security("pv")
		assert_true(Grudges.has_grudge("firm"))
	)

	run_case("answering_without_a_grudge_is_a_no_op", func():
		_fresh()
		var before: Dictionary = GameState.deep_copy(GameState.state)
		Grudges.answer("firm")
		assert_eq(GameState.state, before)
	)

	run_case("unanswered_grudge_expires_into_a_decaying_soft_pressure_on_every_faction", func():
		_raided("loot")
		GameState.state["grudges"]["firm"]["sinceDay"] = 0
		var window := int(GameData.FACTION_GRUDGE["windowDays"])
		GameState.state["world"]["day"] = window
		Grudges.daily_tick()
		assert_true(Grudges.has_grudge("firm"), "still inside the window")
		assert_eq(Grudges.soft_pressure(), 0.0)
		GameState.state["world"]["day"] = window + 1
		Grudges.daily_tick()
		assert_true(not Grudges.has_grudge("firm"))
		var full := Grudges.soft_pressure()
		assert_eq(full, float(GameData.FACTION_GRUDGE["softThreat"]))
		for faction_id in GameData.FACTIONS.keys():
			var with_mark := FactionAI.threat(faction_id, Shares.PLAYER)
			var marks: Array = GameState.state["grudgeEffects"]["soft"]
			GameState.state["grudgeEffects"]["soft"] = []
			assert_true(is_equal_approx(with_mark - FactionAI.threat(faction_id, Shares.PLAYER), full), "%s threat carries the mark" % faction_id)
			GameState.state["grudgeEffects"]["soft"] = marks
		GameState.state["world"]["day"] = window + 1 + 5
		assert_true(Grudges.soft_pressure() < full and Grudges.soft_pressure() > 0.0, "decays")
		GameState.state["world"]["day"] = window + 1 + int(GameData.FACTION_GRUDGE["softDecayDays"])
		Grudges.daily_tick()
		assert_eq(GameState.state["grudgeEffects"]["soft"].size(), 0, "mark dropped once decayed")
	)

	run_case("revenge_bonus_lifts_player_raid_factor_on_the_lost_site_then_lapses", func():
		_fresh()
		var vein := Fixtures.seed_faction_vein("fv", 40, "firm")
		var plain: float = Raiding.raid_factor_mods(vein).reduce(func(sum, m): return sum + m["delta"], 0.0)
		GameState.state["grudgeEffects"]["revenge"]["site_fv"] = 10
		assert_true(Raiding.raid_factor_mods(vein).reduce(func(sum, m): return sum + m["delta"], 0.0) > plain)
		GameState.state["world"]["day"] = 11
		Grudges.daily_tick()
		assert_eq(Raiding.raid_factor_mods(vein).reduce(func(sum, m): return sum + m["delta"], 0.0), plain)
	)

	run_case("grudge_state_survives_rewind_snapshot_and_backfills", func():
		_raided("claim")
		var copy: Dictionary = GameState.deep_copy(GameState.state)
		Grudges.answer("firm")
		GameState.state = copy
		assert_true(Grudges.has_grudge("firm"))
		var old: Dictionary = GameState.deep_copy(GameState.state)
		old.erase("grudges")
		old.erase("grudgeEffects")
		var filled: Dictionary = SaveManager.backfill_defaults(old)
		assert_eq(filled["grudges"], {})
		assert_eq(filled["grudgeEffects"], Grudges.new_effects())
	)

	run_case("district_rows_list_open_grudges_with_days_left", func():
		_raided("loot")
		var rows := Grudges.rows_for_district("shoreditch")
		assert_eq(rows.size(), 1)
		assert_eq(rows[0]["daysLeft"], int(GameData.FACTION_GRUDGE["windowDays"]))
		assert_eq(Grudges.rows_for_district("camden").size(), 0)
	)
