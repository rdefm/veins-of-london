extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")


static func _gain(source: String) -> int:
	return int(GameData.INTEL["gain"][source])


static func _set_meter(observer: String, target: String, value: int) -> void:
	GameState.state["intel"][observer][target] = value


func run() -> void:
	run_case("a_new_game_starts_every_observer_at_zero_on_every_other_actor", func():
		GameState.reset()
		var actors := Intel.actors()
		assert_true(actors.has(Shares.PLAYER))
		for observer in actors:
			for target in actors:
				if target != observer:
					assert_eq(Intel.meter(observer, target), 0, "%s on %s" % [observer, target])
		assert_true(not GameState.state["intel"][Shares.PLAYER].has(Shares.PLAYER), "no self intel")
	)

	run_case("an_old_save_without_intel_gets_the_matrix_on_load", func():
		GameState.reset()
		GameState.state.erase("intel")
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["intel"], Intel.new_state())
	)

	run_case("meters_survive_save_load", func():
		GameState.reset()
		_set_meter(Shares.PLAYER, "firm", 47)
		_set_meter("guild", Shares.PLAYER, 12)
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), 47)
		assert_eq(Intel.meter("guild", Shares.PLAYER), 12)
		assert_true(GameState.state["intel"][Shares.PLAYER]["firm"] is int, "loaded as int")
	)

	run_case("levels_unlock_in_order_at_their_thresholds", func():
		GameState.reset()
		assert_eq(Intel.level(Shares.PLAYER, "firm"), {})
		_set_meter(Shares.PLAYER, "firm", 45)
		assert_eq(Intel.level(Shares.PLAYER, "firm")["id"], Intel.HOLDINGS)
		assert_true(Intel.knows(Shares.PLAYER, "firm", Intel.VEIN_SECURITY))
		assert_true(not Intel.knows(Shares.PLAYER, "firm", Intel.STOCKPILE_LOCATION), "location hidden below its level")
		_set_meter(Shares.PLAYER, "firm", 100)
		assert_eq(Intel.level(Shares.PLAYER, "firm")["id"], Intel.STASH)
	)

	run_case("meters_decay_each_rollover_and_stop_at_zero", func():
		GameState.reset()
		_set_meter(Shares.PLAYER, "firm", 30)
		_set_meter(Shares.PLAYER, "guild", 0)
		TimeSystem.daily_tick()
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), 30 - int(GameData.INTEL["dailyDecay"]))
		assert_eq(Intel.meter(Shares.PLAYER, "guild"), 0)
	)

	run_case("scouting_a_faction_vein_raises_the_players_meter", func():
		GameState.reset()
		var vein := Fixtures.seed_faction_vein("fv_s", 60, "firm")
		Raiding.resolve_stealth_check(vein, 0.0)
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), _gain(Intel.SOURCE_SCOUT))
	)

	run_case("raiding_a_faction_vein_raises_the_players_meter", func():
		GameState.reset()
		Fixtures.seed_faction_vein("fv_l", 60, "firm")
		Raiding.loot_vein("site_fv_l", false)
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), _gain(Intel.SOURCE_RAID))
		Fixtures.seed_faction_vein("fv_c", 60, "guild")
		Raiding.claim_vein("site_fv_c")
		assert_eq(Intel.meter(Shares.PLAYER, "guild"), _gain(Intel.SOURCE_RAID))
	)

	run_case("a_faction_raid_on_another_raises_the_attackers_meter", func():
		GameState.reset()
		Fixtures.seed_faction_vein("fv_g", 60, "guild")
		Factions.resolve_rivalry_outcome({ "success": true, "attackerId": "firm", "defenderId": "guild", "veinSiteId": "site_fv_g" })
		assert_eq(Intel.meter("firm", "guild"), _gain(Intel.SOURCE_RAID))
		assert_eq(Intel.meter("guild", "firm"), 0, "the defender learns nothing")
	)

	run_case("a_faction_raid_on_the_player_raises_its_meter_on_the_player", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [Fixtures.player_vein("pv", "site_pv", "camden", "physics", 50, "fair")]
		GameState.state["world"]["sites"] = [Fixtures.site("site_pv", "physics", "fair", true, null, "camden")]
		Raiding.resolve_raid_outcome({ "attackerId": "firm", "veinId": "pv", "siteId": "site_pv", "success": true })
		assert_eq(Intel.meter("firm", Shares.PLAYER), _gain(Intel.SOURCE_RAID))
	)

	run_case("meters_cap_at_max", func():
		GameState.reset()
		_set_meter(Shares.PLAYER, "firm", 99)
		Intel.gain(Shares.PLAYER, "firm", Intel.SOURCE_RAID)
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), int(GameData.INTEL["max"]))
	)

	run_case("relocating_a_stockpile_drops_observers_below_the_location_level", func():
		GameState.reset()
		_set_meter(Shares.PLAYER, "firm", 90)
		_set_meter("guild", "firm", 60)
		_set_meter("network", "firm", 30)
		Intel.relocate_stockpile("firm")
		for observer in [Shares.PLAYER, "guild"]:
			assert_true(not Intel.knows(observer, "firm", Intel.STOCKPILE_LOCATION), "%s lost the location" % observer)
			assert_true(Intel.knows(observer, "firm", Intel.HOLDINGS), "%s keeps holdings" % observer)
		assert_eq(Intel.meter("network", "firm"), 30, "an observer already below is untouched")
		assert_true(GameData.DISTRICTS.has(GameState.state["factions"]["firm"]["stockpile"]["district"]), "a fresh stockpile is picked")
	)
