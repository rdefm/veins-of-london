extends "res://tests/test_base.gd"

const FACTION_IDS := ["collective", "firm", "guild", "network", "conclave"]


static func _days(n: int) -> void:
	for i in n:
		FactionAI.update_stances()


static func _set_pair(a: String, b: String, value: int) -> void:
	Factions.adjust_relation(a, b, value - Factions.get_relation(a, b))


static func _log_texts(faction_id: String) -> Array:
	return FactionAI.activity_log(faction_id).map(func(e: Dictionary) -> String: return e["text"])


func run() -> void:
	run_case("london_starts_with_the_canonical_stances_inside_their_bands", func():
		GameState.reset()
		assert_eq(FactionAI.pair_stance("collective", "firm"), FactionAI.HOSTILE)
		assert_eq(FactionAI.pair_stance("firm", "collective"), FactionAI.HOSTILE, "pairs are symmetric")
		assert_eq(FactionAI.pair_stance("guild", "conclave"), FactionAI.BUSINESS_RIVAL)
		assert_eq(FactionAI.pair_stance("network", "conclave"), FactionAI.BUSINESS_RIVAL)
		assert_eq(FactionAI.pair_stance("collective", "guild"), FactionAI.PARTNER)
		assert_eq(FactionAI.pair_stance("firm", "guild"), FactionAI.NEUTRAL)
		assert_eq(FactionAI.pair_stance("collective", "network"), FactionAI.NEUTRAL)
		for faction_id in FACTION_IDS:
			assert_eq(FactionAI.player_stance(faction_id), FactionAI.NEUTRAL, "%s player stance" % faction_id)
		_days(10)
		for i in FACTION_IDS.size():
			for j in range(i + 1, FACTION_IDS.size()):
				var a: String = FACTION_IDS[i]
				var b: String = FACTION_IDS[j]
				assert_eq(FactionAI.pair_stance(a, b), FactionAI.starting_pair_stance(a, b), "%s-%s holds its starting stance" % [a, b])
	)

	run_case("a_new_band_flips_the_stance_only_after_the_hysteresis_days", func():
		GameState.reset()
		_set_pair("firm", "guild", 60)
		_days(2)
		assert_eq(FactionAI.pair_stance("firm", "guild"), FactionAI.NEUTRAL, "two days in the band is not enough")
		_days(1)
		assert_eq(FactionAI.pair_stance("firm", "guild"), FactionAI.PARTNER, "third day flips")
		assert_true(_log_texts("firm").has("Now Partner with The Guild."), "logged on the Firm")
		assert_true(_log_texts("guild").has("Now Partner with Firm."), "logged on the Guild")
	)

	run_case("leaving_the_new_band_resets_the_hysteresis_count", func():
		GameState.reset()
		_set_pair("firm", "guild", 60)
		_days(2)
		_set_pair("firm", "guild", 0)
		_days(1)
		_set_pair("firm", "guild", 60)
		_days(2)
		assert_eq(FactionAI.pair_stance("firm", "guild"), FactionAI.NEUTRAL, "count restarted")
		_days(1)
		assert_eq(FactionAI.pair_stance("firm", "guild"), FactionAI.PARTNER)
	)

	run_case("business_rival_needs_an_overlap_else_neutral", func():
		GameState.reset()
		_set_pair("firm", "guild", -20)
		_set_pair("collective", "guild", -20)
		_days(3)
		assert_eq(FactionAI.pair_stance("firm", "guild"), FactionAI.BUSINESS_RIVAL, "Firm and Guild share physics")
		assert_eq(FactionAI.pair_stance("collective", "guild"), FactionAI.NEUTRAL, "Collective and Guild share nothing")
		_set_pair("collective", "guild", -45)
		_days(3)
		assert_eq(FactionAI.pair_stance("collective", "guild"), FactionAI.HOSTILE, "Hostile needs no overlap")
	)

	run_case("player_business_rival_needs_five_percent_share_in_a_faction_ore", func():
		GameState.reset()
		Factions.adjust_player_relation("firm", -20)
		Shares.record_ore("player", "physics", 1)
		Shares.record_ore("firm", "physics", 24)
		_days(3)
		assert_eq(FactionAI.player_stance("firm"), FactionAI.NEUTRAL, "4% of physics is below the bar")
		Shares.record_craft("player", { "life": 1 })
		Shares.record_craft("firm", { "life": 9 })
		_days(3)
		assert_eq(FactionAI.player_stance("firm"), FactionAI.BUSINESS_RIVAL, "10% of life crafting overlaps")
	)

	run_case("a_player_stance_change_sends_a_key_member_message_and_logs_it", func():
		GameState.reset()
		Factions.adjust_player_relation("firm", 60)
		_days(3)
		assert_eq(FactionAI.player_stance("firm"), FactionAI.PARTNER)
		var thread: Array = GameState.state["messages"].get("lusk", [])
		var line: String = GameData.FACTION_STANCES["lines"]["firm"]["partner"]
		assert_true(thread.any(func(m: Dictionary) -> bool: return m["text"] == line), "Lusk sends the partner line")
		assert_true(_log_texts("firm").has("Your standing: Partner."), "activity log entry")
	)

	run_case("the_collective_player_stance_holds_neutral_until_its_questline_ends", func():
		GameState.reset()
		Factions.adjust_player_relation("collective", 60)
		_days(5)
		assert_eq(FactionAI.player_stance("collective"), FactionAI.NEUTRAL, "held mid-questline")
		GameState.state["flags"]["colA2Complete"] = true
		_days(3)
		assert_eq(FactionAI.player_stance("collective"), FactionAI.PARTNER, "follows relation once done")
	)

	run_case("the_activity_log_is_bounded_oldest_first_out", func():
		GameState.reset()
		var cap: int = GameData.FACTION_STANCES["activityLogCap"]
		for i in cap + 5:
			FactionAI.log_activity("guild", "entry %d" % i)
		var texts := _log_texts("guild")
		assert_eq(texts.size(), cap)
		assert_eq(texts[0], "entry 5", "oldest dropped")
		assert_eq(texts[-1], "entry %d" % (cap + 4), "newest kept")
	)

	run_case("the_daily_rollover_runs_the_stance_update", func():
		GameState.reset()
		Factions.adjust_player_relation("guild", -60)
		for i in 3:
			TimeSystem.daily_tick()
		assert_eq(FactionAI.player_stance("guild"), FactionAI.HOSTILE)
	)

	run_case("a_high_player_share_of_the_firms_primary_ore_lowers_firm_relation_by_at_most_the_cap", func():
		_fresh()
		Shares.record_ore("player", "physics", 10)
		Shares.record_ore("firm", "physics", 10)
		_pressure_days(1)
		assert_eq(_player_relation("firm"), -3, "capped at dailyCap")
		_pressure_days(1)
		assert_eq(_player_relation("firm"), -6, "again the next day")
		var snapshot: Dictionary = GameState.state["factionPressure"]["snapshots"]["firm"]["player"]
		assert_almost_eq(snapshot["threat"], 4.5, 0.001, "primary 8 × 0.5 + size 1 × 0.5")
		assert_almost_eq(snapshot["dependence"], 0.0, 0.001)
		assert_almost_eq(snapshot["delta"], -3.0, 0.001)
	)

	run_case("an_active_supplier_contract_with_the_firm_offsets_the_drop", func():
		_fresh()
		Shares.record_ore("player", "physics", 10)
		Shares.record_ore("firm", "physics", 10)
		Shares.record_delivery("firm", 10)
		Shares.record_london_buy("firm", 20)
		GameState.state["sales"]["activeContracts"].append({ "counterparty": "firm" })
		_pressure_days(1)
		var snapshot: Dictionary = GameState.state["factionPressure"]["snapshots"]["firm"]["player"]
		assert_almost_eq(snapshot["dependence"], 8.0 / 3.0 + 1.0, 0.001, "supplier share 1/3 × 8 + one contract")
		assert_eq(_player_relation("firm"), -1, "round(1.69 × (3.67 − 4.5))")
	)

	run_case("supplying_the_collective_raises_the_firms_threat_from_the_player", func():
		_fresh()
		Shares.record_ore("player", "physics", 1)
		Shares.record_ore("firm", "physics", 9)
		var base := FactionAI.threat("firm", "player")
		_pressure_days(1)
		assert_eq(_player_relation("firm"), -2, "without supplying the Collective")
		_fresh()
		Shares.record_ore("player", "physics", 1)
		Shares.record_ore("firm", "physics", 9)
		Shares.record_delivery("collective", 10)
		assert_almost_eq(FactionAI.threat("firm", "player") - base, 6.0, 0.001, "jealousyHostile × supplier share 1.0")
		_pressure_days(1)
		assert_eq(_player_relation("firm"), -3, "falls faster")
	)

	run_case("being_partner_with_a_factions_partner_reduces_its_threat", func():
		_fresh()
		Shares.record_ore("player", "time", 10)
		Shares.record_ore("guild", "time", 10)
		assert_almost_eq(FactionAI.threat("guild", "player"), 4.5, 0.001)
		GameState.state["factionStances"]["player"]["collective"]["stance"] = FactionAI.PARTNER
		assert_almost_eq(FactionAI.threat("guild", "player"), 2.5, 0.001, "the Collective is the Guild's Partner")
	)

	run_case("faction_pairs_drift_under_the_same_model_scaled_by_personality", func():
		_fresh()
		assert_true(FactionAI.personality("firm") > FactionAI.personality("guild"), "the Firm is touchier")
		Shares.record_ore("conclave", "fate", 10)
		_pressure_days(1)
		var snapshots: Dictionary = GameState.state["factionPressure"]["snapshots"]
		assert_almost_eq(snapshots["firm"]["conclave"]["threat"], 1.0, 0.001, "size alone")
		assert_almost_eq(snapshots["guild"]["conclave"]["threat"], 1.0, 0.001, "same threat")
		assert_almost_eq(snapshots["firm"]["conclave"]["delta"], -FactionAI.personality("firm"), 0.001)
		assert_almost_eq(snapshots["guild"]["conclave"]["delta"], -FactionAI.personality("guild"), 0.001)
		assert_eq(Factions.get_relation("firm", "conclave"), -1, "mean of −1.69 and 0 rounds to −1")
		assert_eq(Factions.get_relation("guild", "conclave"), -20, "mean of −0.78 and 0 rounds to 0")
	)

	run_case("the_collective_firm_pair_holds_until_the_questline_completes_then_joins_hostile", func():
		_fresh()
		Shares.record_ore("collective", "physics", 10)
		Shares.record_ore("player", "life", 10)
		var collective_relation := _player_relation("collective")
		_pressure_days(3)
		assert_eq(Factions.get_relation("collective", "firm"), -50, "pair held")
		assert_eq(_player_relation("collective"), collective_relation, "player relation held with its stance")
		_set_pair("collective", "firm", 0)
		GameState.state["factionStances"]["pairs"][FactionAI.pair_key("collective", "firm")]["stance"] = FactionAI.NEUTRAL
		GameState.state["flags"]["colA2Complete"] = true
		_pressure_days(1)
		assert_eq(FactionAI.pair_stance("collective", "firm"), FactionAI.HOSTILE, "joins at Hostile")
		assert_eq(Factions.get_relation("collective", "firm"), -52, "Hostile start −50, then mean(−3, 0) → −2")
		assert_true(_player_relation("collective") < collective_relation, "player relation now drifts")
		_pressure_days(1)
		assert_eq(Factions.get_relation("collective", "firm"), -54, "drifts normally, no re-join")
	)

	run_case("the_pressure_label_reads_relation_and_last_drift", func():
		_fresh()
		assert_eq(FactionAI.pressure_label("guild"), "Calm", "no snapshot yet")
		GameState.state["factionPressure"]["snapshots"] = { "guild": { "player": { "threat": 2.0, "dependence": 0.0, "delta": -2.0 } } }
		Factions.adjust_player_relation("guild", 30)
		assert_eq(FactionAI.pressure_label("guild"), "Watching")
		Factions.adjust_player_relation("guild", -20)
		assert_eq(FactionAI.pressure_label("guild"), "Annoyed")
		Factions.adjust_player_relation("guild", -15)
		assert_eq(FactionAI.pressure_label("guild"), "Moving against you")
	)

	run_case("the_daily_rollover_stores_pressure_snapshots", func():
		GameState.reset()
		TimeSystem.daily_tick()
		var snapshots: Dictionary = GameState.state["factionPressure"]["snapshots"]
		for faction_id in FACTION_IDS:
			assert_true(snapshots[faction_id].has("player"), "%s → player" % faction_id)
			assert_eq(snapshots[faction_id].size(), FACTION_IDS.size(), "%s → player + 4 factions" % faction_id)
	)

	run_case("faction_vein_valuation_uses_the_market_quote", func():
		GameState.reset()
		var vein := { "oreType": "time", "growth": 50, "level": 1 }
		if Market.is_running():
			GameState.state["market"]["goods"]["ore"]["time"]["price"] = 999
		assert_almost_eq(Factions.vein_value(vein), float(Market.quote("ore", "time")) * Cultivating.combined_magnitude(vein), 0.001)
	)


static func _fresh() -> void:
	GameState.reset()
	GameState.state["shares"] = Shares.new_state()
	GameState.state["world"]["sites"] = []
	GameState.state["player"]["veins"] = []


static func _pressure_days(n: int) -> void:
	for i in n:
		FactionAI.apply_pressure()


static func _player_relation(faction_id: String) -> int:
	return GameState.state["factions"][faction_id]["relation"]
