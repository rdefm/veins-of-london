extends "res://tests/test_base.gd"

# Turf core: control margin, foothold share, daily recompute + flips, backfill.

const Fixtures := preload("res://tests/support/fixtures.gd")


func _clear() -> void:
	GameState.reset()
	GameState.state["world"]["sites"] = []
	GameState.state["player"]["veins"] = []


func _put_faction_veins(district: String, faction_id: String, n: int) -> void:
	var existing: int = GameState.state["world"]["sites"].size()
	for i in n:
		Fixtures.seed_faction_vein("%s_%s_%d" % [district, faction_id, existing + i], 50, faction_id)
		GameState.state["world"]["sites"][-1]["district"] = district


func _put_player_veins(district: String, n: int) -> void:
	for i in n:
		var id := "pv_%s_%d" % [district, i]
		GameState.state["player"]["veins"].append(
			Fixtures.player_vein(id, "s_" + id, district, "life", 50, "low"))


func run() -> void:
	run_case("margin_of_two_controls_margin_of_one_is_contested", func():
		_clear()
		_put_faction_veins("shoreditch", "firm", 3)
		_put_faction_veins("shoreditch", "guild", 1)
		Turf.recompute()
		assert_eq(Turf.controller("shoreditch"), "firm")
		assert_eq(Turf.tier("shoreditch", "firm"), "control")
		_put_faction_veins("shoreditch", "guild", 1)
		Turf.recompute()
		assert_eq(Turf.controller("shoreditch"), "")
		assert_true(Turf.is_contested("shoreditch"))
	)

	run_case("player_counts_as_contender_and_foothold_needs_share", func():
		_clear()
		_put_faction_veins("shoreditch", "firm", 5)
		_put_player_veins("shoreditch", 2)
		_put_faction_veins("shoreditch", "network", 1)
		Turf.recompute()
		assert_eq(Turf.controller("shoreditch"), "firm")
		assert_eq(Turf.tier("shoreditch", "player"), "foothold")
		assert_eq(Turf.tier("shoreditch", "network"), "none")
		assert_true(absf(float(Turf.shares("shoreditch")["player"]) - 0.25) < 0.001)
	)

	run_case("player_can_control", func():
		_clear()
		_put_player_veins("shoreditch", 2)
		Turf.recompute()
		assert_eq(Turf.controller("shoreditch"), "player")
	)

	run_case("seeded_turf_follows_presence_and_first_recompute_is_silent", func():
		GameState.reset()
		var presence: String = GameData.DISTRICTS["shoreditch"].get("factionPresence", "")
		assert_eq(Turf.controller("shoreditch"), presence)
		GameState.state["world"]["sites"] = []
		GameState.state["player"]["veins"] = []
		GameState.state["mapEvents"]["queue"] = []
		Turf.recompute()
		assert_eq(GameState.state["mapEvents"]["queue"].size(), 0, "seed -> computed is not a flip")
		assert_true(not (GameState.state["turf"]["shoreditch"].has("seeded")))
	)

	run_case("flip_queues_headline_and_map_event_no_flip_none", func():
		_clear()
		Turf.recompute()
		GameState.state["mapEvents"]["queue"] = []
		GameState.state["barometer"]["headlines"] = []
		Turf.recompute()
		assert_eq(GameState.state["mapEvents"]["queue"].size(), 0)
		assert_eq(GameState.state["barometer"]["headlines"].size(), 0)
		_put_faction_veins("shoreditch", "guild", 2)
		Turf.recompute()
		assert_eq(GameState.state["barometer"]["headlines"].size(), 1)
		var ev: Dictionary = GameState.state["mapEvents"]["queue"][0]
		assert_eq(ev["type"], "turf_flip")
		assert_eq(ev["to"], "guild")
		Turf.recompute()
		assert_eq(GameState.state["barometer"]["headlines"].size(), 1, "stable value, no repeat")
	)

	run_case("stored_value_is_stable_between_recomputes", func():
		_clear()
		Turf.recompute()
		_put_faction_veins("shoreditch", "guild", 3)
		assert_eq(Turf.controller("shoreditch"), "", "not recomputed until the daily tick")
	)

	run_case("backfill_computes_turf_for_an_old_save", func():
		GameState.reset()
		var save: Dictionary = GameState.state.duplicate(true)
		save.erase("turf")
		var out: Dictionary = SaveManager.backfill_defaults(save)
		assert_true(out.has("turf"))
	)

	
	run_case("friendly_controller_lowers_danger_and_raises_price", func():
		_clear()
		_put_faction_veins("shoreditch", "firm", 3)
		GameState.state["factions"]["firm"]["relation"] = 60
		Turf.recompute()
		var base: Dictionary = GameData.DISTRICTS["shoreditch"]
		assert_almost_eq(Turf.danger_mod("shoreditch"), float(base["dangerMod"]) - 0.03, 0.0001)
		assert_almost_eq(Turf.price_mod("shoreditch"), float(base["priceMod"]) + 0.03, 0.0001)
	)

	run_case("hostile_controller_raises_danger_and_lowers_price", func():
		_clear()
		_put_faction_veins("shoreditch", "firm", 3)
		GameState.state["factions"]["firm"]["relation"] = -60
		Turf.recompute()
		var base: Dictionary = GameData.DISTRICTS["shoreditch"]
		assert_almost_eq(Turf.danger_mod("shoreditch"), float(base["dangerMod"]) + 0.04, 0.0001)
		assert_almost_eq(Turf.price_mod("shoreditch"), float(base["priceMod"]) - 0.04, 0.0001)
	)

	run_case("foothold_faction_gets_half_the_shift", func():
		_clear()
		_put_faction_veins("shoreditch", "firm", 5)
		_put_faction_veins("shoreditch", "guild", 2)
		GameState.state["factions"]["firm"]["relation"] = 0
		GameState.state["factions"]["guild"]["relation"] = -60
		Turf.recompute()
		assert_eq(Turf.tier("shoreditch", "guild"), "foothold")
		var base: Dictionary = GameData.DISTRICTS["shoreditch"]
		assert_almost_eq(Turf.danger_mod("shoreditch"), float(base["dangerMod"]) + 0.02, 0.0001)
	)

	run_case("player_control_cuts_danger_and_raid_odds", func():
		_clear()
		_put_player_veins("shoreditch", 2)
		Turf.recompute()
		var base: Dictionary = GameData.DISTRICTS["shoreditch"]
		assert_almost_eq(Turf.danger_mod("shoreditch"), float(base["dangerMod"]) - 0.03, 0.0001)
		assert_almost_eq(Turf.raid_odds_adj("shoreditch"), -0.05, 0.0001)
		assert_eq(Turf.player_controlled_count(), 1)
		assert_almost_eq(Turf.raid_odds_adj("camden"), 0.0, 0.0001)
	)

	run_case("player_districts_add_threat_toward_player_for_every_faction", func():
		_clear()
		_put_player_veins("shoreditch", 2)
		Turf.recompute()
		var weights: Dictionary = GameData.FACTION_PRESSURE["weights"]
		var saved: float = float(weights["playerDistricts"])
		for faction_id in GameData.FACTIONS:
			weights["playerDistricts"] = 0
			var without: float = FactionAI.threat(faction_id, "player")
			weights["playerDistricts"] = 3
			var with_term: float = FactionAI.threat(faction_id, "player")
			assert_almost_eq(with_term - without, 3.0, 0.0001, faction_id)
		weights["playerDistricts"] = saved
	)
