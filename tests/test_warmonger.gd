extends "res://tests/test_base.gd"

# Warmonger meter: weighted log, window roll-off, non-violent moves not logged,
# coalition pressure/drift, coordinated intel and joint-raid bonus, save/Rewind.

const Fixtures := preload("res://tests/support/fixtures.gd")


static func _cfg() -> Dictionary:
	return GameData.WARMONGER


static func _set_score(value: float) -> void:
	GameState.state["warmonger"] = { "score": value, "log": [{ "day": 1, "act": "raidClaim", "weight": value }] }


func run() -> void:
	run_case("record_logs_weights_and_sums", func():
		GameState.reset()
		Warmonger.record(Warmonger.ACT_RAID_CLAIM)
		Warmonger.record(Warmonger.ACT_RAID_LOOT)
		var expected: float = float(_cfg()["weights"]["raidClaim"]) + float(_cfg()["weights"]["raidLoot"])
		assert_eq(Warmonger.score(), expected)
		assert_eq(GameState.state["warmonger"]["log"].size(), 2)
	)

	run_case("acts_older_than_the_window_drop_off", func():
		GameState.reset()
		Warmonger.record(Warmonger.ACT_RAID_CLAIM)
		GameState.state["world"]["day"] = int(GameState.state["world"]["day"]) + int(_cfg()["windowDays"]) - 1
		Warmonger.daily_tick()
		assert_true(Warmonger.score() > 0.0, "still inside the window")
		GameState.state["world"]["day"] = int(GameState.state["world"]["day"]) + 1
		Warmonger.daily_tick()
		assert_eq(Warmonger.score(), 0.0)
		assert_true(GameState.state["warmonger"]["log"].is_empty())
	)

	run_case("non_violent_moves_are_not_logged", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["intel"] = { Shares.PLAYER: { "firm": 100 } }
		Fixtures.seed_faction_vein("fv", 40, "firm")
		for move_id in [PlayerMoves.MOVE_COMPLAINT, PlayerMoves.MOVE_POLICE, PlayerMoves.MOVE_LEAK]:
			PlayerMoves.perform(move_id, "firm", "site_fv" if move_id == PlayerMoves.MOVE_COMPLAINT else "")
		assert_eq(Warmonger.score(), 0.0)
		assert_true(GameState.state["warmonger"]["log"].is_empty())
	)

	run_case("coalition_adds_pressure_to_player_threat_only_above_the_line", func():
		GameState.reset()
		var base := FactionAI.threat("firm", Shares.PLAYER)
		_set_score(float(_cfg()["coalitionAt"]) - 1.0)
		assert_eq(FactionAI.threat("firm", Shares.PLAYER), base)
		_set_score(float(_cfg()["coalitionAt"]))
		assert_almost_eq(FactionAI.threat("firm", Shares.PLAYER), base + float(_cfg()["coalitionThreat"]), 0.0001)
	)

	run_case("coalition_drifts_pairs_not_at_war_with_the_player", func():
		GameState.reset()
		_set_score(float(_cfg()["coalitionAt"]))
		GameState.state["world"]["day"] = 1
		Factions.adjust_relation("firm", "guild", -30 - Factions.get_relation("firm", "guild"))
		var before := Factions.get_relation("firm", "guild")
		Warmonger.daily_tick()
		assert_eq(Factions.get_relation("firm", "guild"), before + int(_cfg()["pairDrift"]))
	)

	run_case("below_the_line_nothing_drifts", func():
		GameState.reset()
		_set_score(float(_cfg()["coalitionAt"]) - 1.0)
		GameState.state["world"]["day"] = 1
		var before := Factions.get_relation("firm", "guild")
		Warmonger.daily_tick()
		assert_eq(Factions.get_relation("firm", "guild"), before)
	)

	run_case("coordination_shares_intel_toward_the_best_informed", func():
		GameState.reset()
		GameState.state["world"]["day"] = 1
		_set_score(float(_cfg()["coordinateAt"]))
		GameState.state["intel"]["guild"][Shares.PLAYER] = 60
		Warmonger.daily_tick()
		assert_eq(Intel.meter("firm", Shares.PLAYER), int(_cfg()["shareIntelPerDay"]))
		_set_score(float(_cfg()["coordinateAt"]) - 1.0)
		GameState.state["warmonger"]["log"][0]["day"] = 1
		var firm := Intel.meter("firm", Shares.PLAYER)
		Warmonger.daily_tick()
		assert_eq(Intel.meter("firm", Shares.PLAYER), firm, "no sharing below coordinateAt")
	)

	run_case("joint_bonus_needs_coordination_and_two_attackers", func():
		GameState.reset()
		_set_score(float(_cfg()["coordinateAt"]))
		assert_eq(Warmonger.joint_raid_bonus(1), 0.0)
		assert_eq(Warmonger.joint_raid_bonus(2), float(_cfg()["jointRaidOddsBonus"]))
		_set_score(float(_cfg()["coordinateAt"]) - 1.0)
		assert_eq(Warmonger.joint_raid_bonus(2), 0.0)
	)

	run_case("queued_raids_from_two_factions_carry_the_joint_bonus", func():
		GameState.reset()
		_set_score(float(_cfg()["coordinateAt"]))
		Fixtures.seed_vein("v1", 40)
		var vein: Dictionary = GameState.state["player"]["veins"][0]
		for attacker in ["firm", "guild"]:
			GameState.state["factionEscalation"]["queuedRaids"].append({ "attackerId": attacker, "targetId": Shares.PLAYER, "veinId": vein["id"], "siteId": vein["siteId"] })
		var attempts := Raiding.queued_raid_attempts()
		assert_eq(attempts.size(), 2)
		for attempt in attempts:
			assert_eq(attempt["jointBonus"], float(_cfg()["jointRaidOddsBonus"]))
	)

	run_case("survives_save_load_and_snapshot", func():
		GameState.reset()
		Warmonger.record(Warmonger.ACT_STOCKPILE_RAID)
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(Warmonger.score(), float(_cfg()["weights"]["stockpileRaid"]))
		assert_true(GameState.state["warmonger"]["log"][0]["day"] is int, "day loaded as int")
		GameState.state.erase("warmonger")
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["warmonger"], Warmonger.new_state(), "old save backfills")
	)

	run_case("clean_loot_does_not_log_but_caught_loot_does", func():
		GameState.reset()
		Fixtures.seed_faction_vein("fv", 40, "firm")
		Raiding.loot_vein("site_fv", false)
		assert_eq(Warmonger.score(), 0.0)
		Raiding.loot_vein("site_fv", true)
		assert_eq(Warmonger.score(), float(_cfg()["weights"]["raidLoot"]))
	)
