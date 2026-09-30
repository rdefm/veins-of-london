extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

const FACTION_IDS := ["collective", "firm", "guild", "network", "conclave"]
const STABILISER_SAVE_SLOT := 86


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


	# ── Escalation ─────────────────────────────────────────────────────────

	run_case("a_key_member_warning_precedes_the_first_move_in_each_new_band", func():
		_fresh()
		_under_pressure("guild")
		Factions.adjust_player_relation("guild", 10)
		_escalate_on(1)
		assert_eq(_last_message("ingram"), _warning("crafter", "warning"))
		assert_eq(_target_entry("guild")["warnedBand"], FactionAI.BAND_WARNING, "flag stored guild → player")
		Factions.adjust_player_relation("guild", -20)
		_escalate_on(1 + _cooldown())
		assert_eq(_last_message("ingram"), _warning("crafter", "market"), "market band warned on entry")
		Factions.adjust_player_relation("guild", -30)
		_escalate_on(1 + 2 * _cooldown())
		assert_eq(_last_message("ingram"), _warning("crafter", "raid"), "below raidThreshold −30 → raid band")
		assert_eq(_target_entry("guild")["warnedBand"], FactionAI.BAND_RAID)
		assert_true(_log_texts("guild").has(GameData.FACTION_ESCALATION["log"]["warningPlayer"]))
	)

	run_case("no_warning_without_pressure_below_the_raid_band", func():
		_fresh()
		Factions.adjust_player_relation("guild", -10)
		_escalate_on(1)
		assert_true(not GameState.state["messages"].has("ingram"), "calm faction stays quiet")
	)

	run_case("recovering_a_band_rearms_its_warning", func():
		_fresh()
		_under_pressure("guild")
		Factions.adjust_player_relation("guild", -10)
		_escalate_on(1)
		Factions.adjust_player_relation("guild", 30)
		_escalate_on(2)
		assert_eq(_target_entry("guild")["warnedBand"], FactionAI.BAND_NONE)
		Factions.adjust_player_relation("guild", -30)
		_escalate_on(1 + _cooldown())
		assert_eq(_last_message("ingram"), _warning("crafter", "market"))
	)

	run_case("the_cooldown_stops_a_second_move_against_the_same_target", func():
		_fresh()
		_raid_ready("firm", -50)
		for day in range(1, 1 + _cooldown()):
			_escalate_on(day)
		assert_eq(_queued().size(), 0, "warning on day 1, then cooling")
		_escalate_on(1 + _cooldown())
		assert_eq(_queued().size(), 1, "first raid once the warning's cooldown ends")
		GameState.state["factionEscalation"]["queuedRaids"] = []
		for day in range(2 + _cooldown(), 1 + 2 * _cooldown()):
			_escalate_on(day)
		assert_eq(_queued().size(), 0, "no second move inside the cooldown")
		_escalate_on(1 + 2 * _cooldown())
		assert_eq(_queued().size(), 1)
	)

	run_case("the_raid_rung_opens_below_raid_threshold_or_at_hostile", func():
		_fresh()
		for faction_id in FACTION_IDS:
			var threshold: int = GameData.FACTIONS[faction_id]["raidThreshold"]
			Factions.adjust_player_relation(faction_id, threshold - _player_relation(faction_id))
			assert_true(FactionAI.band(faction_id, "player") != FactionAI.BAND_RAID, "%s at its raidThreshold" % faction_id)
			Factions.adjust_player_relation(faction_id, -1)
			assert_eq(FactionAI.band(faction_id, "player"), FactionAI.BAND_RAID, "%s just below" % faction_id)
		Factions.adjust_player_relation("guild", 20 - _player_relation("guild"))
		GameState.state["factionStances"]["player"]["guild"]["stance"] = FactionAI.HOSTILE
		assert_eq(FactionAI.band("guild", "player"), FactionAI.BAND_RAID, "Hostile stance opens it too")
	)

	run_case("only_the_raid_band_queues_a_vein_raid", func():
		_fresh()
		_raid_ready("collective", -20)
		_under_pressure("collective")
		_target_entry("collective")["warnedBand"] = FactionAI.BAND_MARKET
		for day in range(1, 30):
			_escalate_on(day)
		assert_eq(_queued().size(), 0, "market band: no raid")
		Factions.adjust_player_relation("collective", -30)
		_escalate_on(30)
		assert_eq(_queued().size(), 0, "raid band entered: warning first")
		_escalate_on(30 + _cooldown())
		assert_eq(_queued().size(), 1)
		assert_eq(_queued()[0]["attackerId"], "collective")
	)

	run_case("a_faction_that_cannot_afford_the_move_does_not_raid", func():
		_fresh()
		_raid_ready("firm", -50)
		_target_entry("firm")["warnedBand"] = FactionAI.BAND_RAID
		GameState.state["factions"]["firm"]["resources"] = int(GameData.FACTION_ESCALATION["moveCosts"]["veinRaid"]) - 1
		_escalate_on(1)
		assert_eq(_queued().size(), 0)
		GameState.state["factions"]["firm"]["resources"] = 10000
		_escalate_on(1)
		assert_eq(_queued().size(), 1)
		assert_eq(GameState.state["factions"]["firm"]["resources"], 10000 - int(GameData.FACTION_ESCALATION["moveCosts"]["veinRaid"]), "move cost paid")
	)

	run_case("a_queued_raid_resolves_on_the_next_rollover_and_is_reported", func():
		_fresh()
		_raid_ready("firm", -80)
		_target_entry("firm")["warnedBand"] = FactionAI.BAND_RAID
		TimeSystem.daily_tick()
		assert_eq(_queued().size(), 1, "decided today")
		assert_eq(_queued()[0]["targetId"], "player")
		assert_true(FactionAI.moves_against_player().is_empty(), "not resolved yet")
		TimeSystem.daily_tick()
		assert_eq(_queued().size(), 0, "drained by the raid step; the cooldown holds today's decision")
		var moves := FactionAI.moves_against_player()
		assert_eq(moves.size(), 1, "one move against you")
		assert_eq(moves[0]["factionId"], "firm", "actor named")
		assert_eq(moves[0]["move"], FactionAI.MOVE_VEIN_RAID)
		assert_true(GameState.state["messages"].has("lusk"), "key member sends it")
		assert_eq(_explainer_count(), 1, "Archie explains the first raid")
	)

	run_case("archies_explainer_fires_once_per_move_type", func():
		_fresh()
		var vein := Fixtures.seed_vein("pv", 60)
		for i in 2:
			FactionAI.report_player_move("firm", FactionAI.MOVE_VEIN_RAID, vein["district"], i == 0)
		assert_eq(_explainer_count(), 1)
		assert_eq(FactionAI.moves_against_player().size(), 2)
	)

	run_case("the_collective_firm_pair_makes_no_moves_until_the_questline_completes", func():
		_fresh()
		GameData.FACTION_RIVALRY = true
		Fixtures.seed_faction_vein("fv_c", 60, "collective")
		GameState.state["factions"]["firm"]["resources"] = 10000
		FactionAI._target_entry("firm", "collective")["warnedBand"] = FactionAI.BAND_RAID
		for day in range(1, 20):
			_escalate_on(day)
		assert_eq(_queued().size(), 0, "held pair")
		GameState.state["flags"]["colA2Complete"] = true
		_escalate_on(20)
		assert_eq(_queued().size(), 1, "joins once the questline ends")
		assert_eq(_queued()[0]["targetId"], "collective")
		GameData.FACTION_RIVALRY = false
	)

	run_case("faction_vs_faction_raids_stay_off_while_factionRivalry_is_off", func():
		_fresh()
		Fixtures.seed_faction_vein("fv_g", 60, "guild")
		_set_pair("firm", "guild", -60)
		GameState.state["factions"]["firm"]["resources"] = 10000
		FactionAI._target_entry("firm", "guild")["warnedBand"] = FactionAI.BAND_RAID
		_escalate_on(1)
		assert_eq(_queued().size(), 0)
	)

	run_case("a_firm_flood_records_supply_annotates_lowers_the_price_and_costs_the_firm", func():
		_market_fresh(5)
		Shares.record_ore("player", "time", 100)
		_move_ready("firm", -10)
		_holdings("firm")["time"] = 200
		var qty: int = int(GameData.FACTION_ESCALATION["flood"]["qty"])
		var value: int = Market.line_total("ore", Market.quote("ore", "time"), qty)
		var untouched: Dictionary = GameState.deep_copy(GameState.state["market"])
		Market.daily_reprice()
		var control_price := Market.quote("ore", "time")
		GameState.state["market"] = untouched
		FactionAI.apply_escalation()
		assert_eq(int(_holdings("firm")["time"]), 200 - qty, "ore sold off")
		assert_eq(int(GameState.state["market"]["supply"]["ore"]["time"]["firm"]), qty, "recorded as Firm supply")
		var gained: int = int(GameState.state["factions"]["firm"]["resources"]) - 10000
		assert_true(gained > 0 and gained < value, "sold below value: %d of %d" % [gained, value])
		Market.daily_reprice()
		assert_true(Market.quote("ore", "time") < control_price, "flood lowers the reprice")
		var floods: Array = Market.annotations_for("ore", "time").filter(func(n: Dictionary) -> bool: return n["kind"] == "flood")
		assert_eq(floods.size(), 1, "one flood annotation")
		assert_eq(floods[0]["source"], "firm", "named for the Firm")
		assert_eq(floods[0]["value"], qty)
		var moves := FactionAI.moves_against_player()
		assert_eq(moves[0]["move"], FactionAI.MOVE_FLOOD)
		assert_eq(_last_message("lusk"), GameData.FACTION_ESCALATION["moveLines"]["firm"]["flood"] % "time")
		assert_true(Barometer.headlines().is_empty(), "a flood on the player is no headline")
	)

	run_case("withhold_stops_the_faction_selling_that_ore_for_the_duration", func():
		_market_fresh(5)
		Shares.record_craft("player", { "life": 50 })
		_move_ready("firm", -10)
		_holdings("firm")["life"] = 5000
		FactionSim.trade()
		assert_true(_firm_sold("life"), "control: the Firm sells its surplus life")
		_market_fresh(5)
		Shares.record_craft("player", { "life": 50 })
		_move_ready("firm", -10)
		_holdings("firm")["life"] = 5000
		FactionAI.apply_escalation()
		assert_eq(FactionAI.moves_against_player()[0]["move"], FactionAI.MOVE_WITHHOLD)
		assert_eq(int(GameState.state["factions"]["firm"]["resources"]), 10000 - int(GameData.FACTION_ESCALATION["moveCosts"]["withhold"]), "cost paid")
		var days: int = int(GameData.FACTION_ESCALATION["withhold"]["days"])
		for day in range(6, 6 + days):
			GameState.state["world"]["day"] = day
			FactionSim.trade()
			assert_true(not _firm_sold("life"), "withheld on day %d" % day)
			GameState.state["market"]["supply"] = { "ore": {}, "consumable": {} }
		GameState.state["world"]["day"] = 6 + days
		FactionSim.trade()
		assert_true(_firm_sold("life"), "selling again once it lapses")
	)

	run_case("outbid_claims_a_site_the_player_found_and_tells_the_player", func():
		_market_fresh(5)
		var site := Fixtures.site("site_found", "life", "rich")
		GameState.state["world"]["sites"].append(site)
		_move_ready("firm", -10)
		FactionAI.apply_escalation()
		assert_true(site["factionVein"] != null, "site claimed")
		assert_eq(site["factionVein"]["factionId"], "firm")
		assert_eq(int(GameState.state["factions"]["firm"]["resources"]), 10000 - int(GameData.FACTION_ESCALATION["moveCosts"]["outbid"]))
		var district_name: String = GameData.DISTRICTS[site["district"]]["name"]
		assert_eq(_last_message("lusk"), GameData.FACTION_ESCALATION["moveLines"]["firm"]["outbid"] % district_name)
		assert_eq(FactionAI.moves_against_player()[0]["move"], FactionAI.MOVE_OUTBID)
		assert_eq(_explainer_count(FactionAI.MOVE_OUTBID), 1, "Archie explains the first outbid")
	)

	run_case("market_moves_wait_for_the_band_and_the_cash", func():
		_market_fresh(5)
		var site := Fixtures.site("site_found", "life", "rich")
		GameState.state["world"]["sites"].append(site)
		_move_ready("collective", 10)
		_target_entry("collective")["warnedBand"] = FactionAI.BAND_WARNING
		FactionAI.apply_escalation()
		assert_eq(site["factionVein"], null, "warning band: no market move")
		_move_ready("collective", -10)
		GameState.state["factions"]["collective"]["resources"] = int(GameData.FACTION_ESCALATION["moveCosts"]["outbid"]) - 1
		FactionAI.apply_escalation()
		assert_eq(site["factionVein"], null, "market band but can't afford it")
		GameState.state["factions"]["collective"]["resources"] = 10000
		FactionAI.apply_escalation()
		assert_eq(site["factionVein"]["factionId"], "collective", "market band and funded")
	)

	run_case("a_faction_flood_on_a_faction_is_a_headline_and_outbid_is_player_only", func():
		_market_fresh(5)
		Shares.record_ore("guild", "time", 100)
		GameState.state["world"]["sites"].append(Fixtures.site("site_found", "life", "rich"))
		_set_pair("firm", "guild", -60)
		GameState.state["factions"]["firm"]["resources"] = 10000
		FactionAI._target_entry("firm", "guild")["warnedBand"] = FactionAI.BAND_RAID
		_holdings("firm")["time"] = 200
		FactionAI.apply_escalation()
		var ore_name: String = GameData.ORE_TYPES["time"]["name"]
		var headline: String = GameData.FACTION_ESCALATION["headlines"]["flood"] % ["Firm", ore_name, "The Guild"]
		assert_eq(Barometer.headlines()[0]["text"], headline)
		assert_true(_log_texts("guild").has(GameData.FACTION_ESCALATION["log"]["flood"]["defender"] % ["Firm", ore_name]), "logged on the target")
		assert_eq(GameState.state["world"]["sites"][0]["factionVein"], null, "no outbid against a faction")
		assert_true(FactionAI.moves_against_player().is_empty())
	)

	run_case("a_conclave_undercut_hits_the_players_top_seller_of_the_week_and_lowers_its_price", func():
		_market_fresh(3)
		GameState.state["player"]["cash"] = 100000
		Market.record_supply("ore", "physics", 80, "player")
		Market.daily_reprice()
		GameState.state["world"]["day"] = 5
		Market.record_supply("ore", "time", 30, "player")
		_move_ready("conclave", -10)
		_holdings("conclave")["physics"] = 500
		_holdings("conclave")["time"] = 500
		var qty: int = int(GameData.FACTION_ESCALATION["undercut"]["qty"]["ore"])
		var value: int = Market.line_total("ore", Market.quote("ore", "physics"), qty)
		var untouched: Dictionary = GameState.deep_copy(GameState.state["market"])
		Market.daily_reprice()
		var control_price := Market.quote("ore", "physics")
		GameState.state["market"] = untouched
		FactionAI.apply_escalation()
		assert_eq(FactionAI.moves_against_player()[0]["move"], FactionAI.MOVE_UNDERCUT)
		assert_eq(int(_holdings("conclave")["physics"]), 500 - qty, "stock sold")
		assert_eq(int(GameState.state["market"]["supply"]["ore"]["physics"]["conclave"]), qty, "recorded as Conclave supply")
		var gained: int = int(GameState.state["factions"]["conclave"]["resources"]) - 10000
		assert_true(gained > 0 and gained < value, "sold under the price: %d of %d" % [gained, value])
		Market.daily_reprice()
		assert_true(Market.quote("ore", "physics") < control_price, "undercut lowers the reprice")
		var notes: Array = Market.annotations_for("ore", "physics")
		var undercuts: Array = notes.filter(func(n: Dictionary) -> bool: return n["kind"] == "undercut")
		assert_eq(undercuts.size(), 1, "one undercut annotation")
		assert_eq(undercuts[0]["source"], "conclave", "named for the Conclave")
		assert_eq(undercuts[0]["value"], qty)
		assert_true(notes.filter(func(n: Dictionary) -> bool: return n["kind"] == "dump" and n["source"] == "conclave").is_empty(), "not also a dump")
		var ore_name: String = GameData.ORE_TYPES["physics"]["name"]
		assert_eq(_last_message(KeyMembers.speaker_for("conclave")), GameData.FACTION_ESCALATION["moveLines"]["conclave"]["undercut"] % ore_name)
		assert_eq(_explainer_count(FactionAI.MOVE_UNDERCUT), 1)
	)

	run_case("a_conclave_deny_buys_up_what_the_player_needs_and_holds_it", func():
		_market_fresh(5)
		GameState.state["player"]["cash"] = 100000
		Shares.record_craft("player", { "life": 50 })
		_move_ready("conclave", -10)
		var held_before: int = FactionSim.ore_held("conclave", "life")
		var qty: int = mini(int(GameData.FACTION_ESCALATION["deny"]["qty"]["ore"]), Market.affordable_qty("ore", Market.quote("ore", "life"), 10000))
		var untouched: Dictionary = GameState.deep_copy(GameState.state["market"])
		Market.daily_reprice()
		var control_price := Market.quote("ore", "life")
		var control_stock := int(GameState.state["market"]["goods"]["ore"]["life"]["stock"])
		GameState.state["market"] = untouched
		FactionAI.apply_escalation()
		assert_eq(FactionAI.moves_against_player()[0]["move"], FactionAI.MOVE_DENY)
		assert_true(qty > 0, "the Conclave can afford some")
		assert_eq(FactionSim.ore_held("conclave", "life"), held_before + qty, "holdings rise")
		assert_eq(int(GameState.state["market"]["demand"]["ore"]["life"]["conclave"]), qty, "recorded as Conclave demand")
		assert_eq(int(GameState.state["factions"]["conclave"]["resources"]), 10000 - Market.line_total("ore", Market.quote("ore", "life"), qty), "paid at the quote")
		assert_true(FactionAI.is_withholding("conclave", "ore", "life"), "held, not resold")
		Market.daily_reprice()
		assert_true(Market.quote("ore", "life") > control_price, "deny raises the reprice")
		assert_true(int(GameState.state["market"]["goods"]["ore"]["life"]["stock"]) < control_stock, "and thins the stock")
		var notes: Array = Market.annotations_for("ore", "life")
		var denials: Array = notes.filter(func(n: Dictionary) -> bool: return n["kind"] == "deny")
		assert_eq(denials.size(), 1, "one deny annotation")
		assert_eq(denials[0]["source"], "conclave")
		assert_eq(denials[0]["value"], qty)
		assert_true(notes.filter(func(n: Dictionary) -> bool: return n["kind"] == "buy" and n["source"] == "conclave").is_empty(), "not also a buy")
		var ore_name: String = GameData.ORE_TYPES["life"]["name"]
		assert_eq(_last_message(KeyMembers.speaker_for("conclave")), GameData.FACTION_ESCALATION["moveLines"]["conclave"]["denyGoods"] % ore_name)
		GameState.state["world"]["day"] = 6
		FactionSim.trade()
		assert_true(not GameState.state["market"]["supply"]["ore"].get("life", {}).has("conclave"), "denied stock isn't sold back")
	)

	run_case("a_conclave_move_on_a_faction_is_logged_on_both_sides", func():
		_market_fresh(5)
		Shares.record_craft("guild", { "fate": 50 })
		_set_pair("conclave", "guild", -60)
		GameState.state["factions"]["conclave"]["resources"] = 10000
		FactionAI._target_entry("conclave", "guild")["warnedBand"] = FactionAI.BAND_RAID
		FactionAI.apply_escalation()
		var denied: Array = FactionAI._withholds().filter(func(e: Dictionary) -> bool: return e["factionId"] == "conclave" and e["targetId"] == "guild")
		assert_eq(denied.size(), 1, "the Conclave denies the Guild something")
		var entry: Dictionary = denied[0]
		var good_name: String = GameData.ORE_TYPES[entry["good"]]["name"] if entry["kind"] == "ore" else GameData.RECIPES[entry["good"]]["name"]
		var log_cfg: Dictionary = GameData.FACTION_ESCALATION["log"][FactionAI.MOVE_DENY]
		assert_true(_log_texts("guild").has(log_cfg["defender"] % [GameData.FACTIONS["conclave"]["shortName"], good_name]), "logged on the target")
		assert_true(_log_texts("conclave").has(log_cfg["attacker"] % [good_name, GameData.FACTIONS["guild"]["shortName"]]), "logged on the Conclave")
	)

	run_case("the_conclave_never_queues_a_raid", func():
		_market_fresh(5)
		GameData.FACTION_RIVALRY = true
		Fixtures.seed_vein("pv", 60)
		Fixtures.seed_faction_vein("fv_g", 60, "guild")
		Factions.adjust_player_relation("conclave", -100 - _player_relation("conclave"))
		_set_pair("conclave", "guild", -100)
		for day in range(5, 40):
			GameState.state["factions"]["conclave"]["resources"] = 100000
			_escalate_on(day)
		assert_true(_queued().filter(func(e: Dictionary) -> bool: return e["attackerId"] == "conclave").is_empty(), "no Conclave raids")
		assert_true(FactionAI._open_moves("conclave", FactionAI.BAND_RAID).filter(func(m: String) -> bool: return m in [FactionAI.MOVE_VEIN_RAID, "stockpileRaid"]).is_empty(), "no raid rung")
		GameData.FACTION_RIVALRY = false
	)

	run_case("a_poached_renewal_the_player_matches_stays_at_the_matched_price", func():
		_market_fresh(5)
		var offer := _renewal("firm")
		_move_ready("guild", -10)
		FactionAI.apply_escalation()
		assert_eq(FactionAI.moves_against_player()[0]["move"], FactionAI.MOVE_POACH)
		assert_eq(offer["poach"]["factionId"], "guild")
		var rival_price: int = int(offer["poach"]["payment"])
		assert_true(rival_price < int(offer["quote"]["payment"]), "the rival undercuts")
		assert_true(not Offers.accept_offer(offer["id"])["ok"], "can't accept at the old price")
		var result := Offers.match_poach(offer["id"])
		assert_true(result["ok"], "matched")
		assert_eq(int(result["contract"]["signedQuote"]["payment"]), rival_price, "signed at the matched price")
		assert_eq(result["contract"]["counterparty"], "firm", "the buyer stays")
	)

	run_case("an_unmatched_poached_renewal_lapses_to_the_rival", func():
		_market_fresh(5)
		var offer := _renewal("firm")
		_move_ready("guild", -10)
		FactionAI.apply_escalation()
		GameState.state["world"]["day"] = int(offer["expiresDay"])
		Offers.expire_pending_offers()
		assert_true(Offers.pending_offers().is_empty(), "the renewal is gone")
		assert_true(Offers.active_contracts().is_empty())
		var lapsed: String = GameData.FACTION_ESCALATION["log"]["poach"]["lapsed"] % "Firm"
		assert_true(_log_texts("guild").has(lapsed), "the Guild took the buyer")
	)

	run_case("poach_is_skipped_between_factions", func():
		_market_fresh(5)
		var offer := _renewal("collective")
		_set_pair("guild", "firm", -60)
		GameState.state["factions"]["guild"]["resources"] = 10000
		FactionAI._target_entry("guild", "firm")["warnedBand"] = FactionAI.BAND_RAID
		FactionAI.apply_escalation()
		assert_true(not offer.has("poach"), "no poach against a faction")
		assert_true(FactionAI.moves_against_player().is_empty())
	)

	run_case("withhold_items_removes_the_item_from_the_guild_for_sale_stock_for_the_duration", func():
		_market_fresh(5)
		_owe_item("timePearl")
		FactionSim.add_item("guild", "timePearl", 1, 10)
		var stock := FactionSim.for_sale("guild", "consumable", "timePearl")
		assert_true(stock >= 10, "control: on sale")
		_move_ready("guild", -10)
		FactionAI.apply_escalation()
		assert_eq(FactionAI.moves_against_player()[0]["move"], FactionAI.MOVE_WITHHOLD_ITEMS)
		var item_name: String = GameData.RECIPES["timePearl"]["name"]
		assert_eq(_last_message("ingram"), GameData.FACTION_ESCALATION["moveLines"]["guild"]["withholdItems"] % item_name)
		var days: int = int(GameData.FACTION_ESCALATION["withhold"]["days"])
		for day in range(5, 6 + days):
			GameState.state["world"]["day"] = day
			assert_eq(FactionSim.for_sale("guild", "consumable", "timePearl"), 0, "withheld on day %d" % day)
		GameState.state["world"]["day"] = 6 + days
		assert_eq(FactionSim.for_sale("guild", "consumable", "timePearl"), stock, "back on sale once it lapses")
	)

	run_case("a_lowball_buyout_is_below_the_quote_and_accepting_sells_the_vein", func():
		_market_fresh(5)
		var vein := Fixtures.seed_vein("pv", 60)
		GameState.state["player"]["cash"] = 100
		var quote := VeinTrade.quote(vein)
		_move_ready("guild", -10)
		GameState.state["factions"]["guild"]["resources"] = quote * 2
		FactionAI.apply_escalation()
		var pending := Messages.pending_for("ingram")
		assert_eq(pending.size(), 1, "an actionable message")
		assert_eq(pending[0]["kind"], FactionAI.LOWBALL_KIND)
		var price: int = int(pending[0]["payload"]["price"])
		assert_true(price > 0 and price < quote, "below the quote: %d of %d" % [price, quote])
		var result := FactionAI.accept_lowball(pending[0]["id"])
		assert_true(result["ok"], "sold")
		assert_true(GameState.state["player"]["veins"].is_empty(), "the vein is gone")
		assert_eq(Sites.find_site("site_pv")["factionVein"]["factionId"], "guild", "the Guild has it")
		assert_eq(int(GameState.state["player"]["cash"]), 100 + price, "paid")
		assert_eq(int(GameState.state["factions"]["guild"]["resources"]), quote * 2 - price, "from the Guild's cash")
		assert_true(Messages.pending_for("ingram").is_empty(), "resolved")
	)

	run_case("lowball_waits_for_a_squeeze_and_a_lost_vein_counts", func():
		_market_fresh(5)
		Fixtures.seed_vein("pv", 60)
		GameState.state["player"]["cash"] = 100000
		_move_ready("guild", -10)
		GameState.state["factions"]["guild"]["resources"] = 1000000
		FactionAI.apply_escalation()
		assert_true(Messages.pending_for("ingram").is_empty(), "flush player: no lowball")
		FactionAI.note_player_vein_lost()
		_target_entry("guild")["lastMoveDay"] = -1
		FactionAI.apply_escalation()
		assert_eq(Messages.pending_for("ingram").size(), 1, "just lost a vein: lowball")
		GameState.state["world"]["day"] = 5 + int(GameData.FACTION_ESCALATION["lowball"]["expiryDays"]) + 1
		_target_entry("guild")["lastMoveDay"] = GameState.state["world"]["day"]
		FactionAI.apply_escalation()
		assert_true(Messages.pending_for("ingram").is_empty(), "an unanswered lowball lapses")
	)

	run_case("a_spike_held_for_the_run_gets_a_conclave_sell_at_a_loss", func():
		_stabiliser_fresh()
		_holdings("conclave")["physics"] = 500
		_stock("ore", "physics", 180)
		GameState.state["factions"]["conclave"]["resources"] = 10000
		var price: int = _hold_quote("ore", "physics", 1.5)
		var qty: int = int(_stabiliser()["qty"]["ore"])
		_stabilise_days(_run_days() - 1)
		assert_eq(int(_holdings("conclave")["physics"]), 500, "no trade before the run completes")
		assert_eq(FactionAI.stabiliser_run("ore", "physics"), _run_days() - 1)
		_stabilise_days(1)
		assert_eq(int(_holdings("conclave")["physics"]), 500 - qty, "sold into the spike")
		assert_eq(FactionAI.stockpile_held("conclave", "ore", "physics"), 180 - qty, "sold from the stockpile")
		var gained: int = int(GameState.state["factions"]["conclave"]["resources"]) - 10000
		var value: int = Market.line_total("ore", price, qty)
		assert_true(gained > 0 and gained < value, "sold below value: %d of %d" % [gained, value])
		assert_eq(int(GameState.state["market"]["supply"]["ore"]["physics"]["conclave"]), qty, "recorded as Conclave supply")
		assert_eq(FactionAI.stabiliser_run("ore", "physics"), 0, "run restarts after the trade")
		Market.daily_reprice()
		var notes: Array = Market.annotations_for("ore", "physics").filter(func(n: Dictionary) -> bool: return n["kind"] == "stabiliseSell")
		assert_eq(notes.size(), 1, "one stabiliser annotation")
		assert_eq(notes[0]["source"], "conclave")
		assert_eq(notes[0]["value"], qty)
	)

	run_case("a_crash_held_for_the_run_gets_a_conclave_buy_at_a_loss", func():
		_stabiliser_fresh()
		var qty: int = int(_stabiliser()["qty"]["ore"])
		var start: int = _target("ore")
		_holdings("conclave")["life"] = start
		_stock("ore", "life", start)
		GameState.state["factions"]["conclave"]["resources"] = 100000
		var price: int = _hold_quote("ore", "life", 0.5)
		_stabilise_days(_run_days())
		assert_eq(int(_holdings("conclave")["life"]), start + qty, "bought the crash")
		assert_eq(FactionAI.stockpile_held("conclave", "ore", "life"), start + qty, "into the stockpile, past its target")
		var spent: int = 100000 - int(GameState.state["factions"]["conclave"]["resources"])
		var value: int = Market.line_total("ore", price, qty)
		assert_true(spent > value, "paid over value: %d for %d" % [spent, value])
		assert_eq(int(GameState.state["market"]["demand"]["ore"]["life"]["conclave"]), qty, "recorded as Conclave demand")
		Market.daily_reprice()
		var notes: Array = Market.annotations_for("ore", "life").filter(func(n: Dictionary) -> bool: return n["kind"] == "stabiliseBuy")
		assert_eq(notes.size(), 1, "one stabiliser annotation")
		assert_eq(notes[0]["source"], "conclave")
	)

	run_case("a_short_excursion_triggers_no_conclave_trade", func():
		_stabiliser_fresh()
		_holdings("conclave")["physics"] = 500
		_stock("ore", "physics", _target("ore"))
		GameState.state["factions"]["conclave"]["resources"] = 100000
		_hold_quote("ore", "physics", 1.5)
		_stabilise_days(_run_days() - 1)
		_hold_quote("ore", "physics", 1.1)
		_stabilise_days(1)
		assert_eq(FactionAI.stabiliser_run("ore", "physics"), 0, "back inside the band clears the run")
		_hold_quote("ore", "physics", 1.5)
		_stabilise_days(_run_days() - 1)
		_hold_quote("ore", "physics", 0.5)
		_stabilise_days(_run_days() - 1)
		assert_eq(FactionAI.stabiliser_run("ore", "physics"), 1 - _run_days(), "flipping sides restarts the run")
		assert_eq(int(_holdings("conclave")["physics"]), 500, "nothing sold")
		assert_eq(int(GameState.state["factions"]["conclave"]["resources"]), 100000, "nothing bought")
	)

	run_case("the_rollover_counts_stabiliser_runs_and_they_survive_a_save", func():
		_stabiliser_fresh()
		_hold_quote("ore", "fate", 1.6)
		TimeSystem.daily_tick()
		assert_eq(FactionAI.stabiliser_run("ore", "fate"), 1, "the rollover counts a day beyond the band")
		GameState.state["factionConclave"]["runs"]["ore:fate"] = 2
		assert_true(SaveManager.save_to_slot(STABILISER_SAVE_SLOT)["ok"])
		GameState.reset()
		assert_true(SaveManager.load_from_slot(STABILISER_SAVE_SLOT)["ok"])
		SaveManager.delete_slot(STABILISER_SAVE_SLOT)
		assert_eq(FactionAI.stabiliser_run("ore", "fate"), 2)
		assert_eq(typeof(GameState.state["factionConclave"]["runs"]["ore:fate"]), TYPE_INT)
	)

	run_case("conclave_trading_never_sells_its_stockpile", func():
		_stabiliser_fresh()
		var stock: int = _target("ore")
		_holdings("conclave")["physics"] = stock
		_stock("ore", "physics", stock)
		GameState.state["factions"]["conclave"]["resources"] = 0
		_hold_quote("ore", "physics", 2.0)
		assert_true(2.0 > float(GameData.FACTIONS["conclave"]["trading"]["arbSellMult"]), "above the arbitrage sell line")
		assert_eq(FactionSim.for_sale("conclave", "ore", "physics"), 0, "stockpile is off sale")
		FactionSim.trade()
		assert_eq(int(_holdings("conclave")["physics"]), stock, "surplus selling and arbitrage left it")
		assert_eq(FactionAI.stockpile_held("conclave", "ore", "physics"), stock)
		_holdings("conclave")["physics"] = stock + 40
		assert_eq(FactionSim.for_sale("conclave", "ore", "physics"), 40, "only units above it are for sale")
	)

	run_case("the_stockpile_tops_up_at_or_under_base_within_cap_and_floor", func():
		_stabiliser_fresh()
		var top_up: Dictionary = _stabiliser()["stockpile"]["topUp"]
		var cap: int = int(top_up["dailyCap"]["ore"])
		var floor_cash: int = int(top_up["cashFloor"])
		_holdings("conclave")["physics"] = 0
		GameState.state["factions"]["conclave"]["resources"] = 1000000
		_stabilise_days(1)
		assert_eq(FactionAI.stockpile_held("conclave", "ore", "physics"), 0, "no top-up above base")
		_hold_quote("ore", "physics", 1.0)
		_stabilise_days(1)
		assert_eq(FactionAI.stockpile_held("conclave", "ore", "physics"), cap, "one day's cap at base")
		assert_eq(int(_holdings("conclave")["physics"]), cap)
		assert_eq(int(GameState.state["market"]["demand"]["ore"]["physics"]["conclave"]), cap, "London demand")
		_stabilise_days(ceili(float(_target("ore")) / cap) + 2)
		assert_eq(FactionAI.stockpile_held("conclave", "ore", "physics"), _target("ore"), "stops at the target")
		_hold_quote("ore", "life", 0.9)
		_holdings("conclave")["life"] = 0
		GameState.state["factions"]["conclave"]["resources"] = floor_cash + Market.line_total("ore", Market.quote("ore", "life"), 5)
		_stabilise_days(2)
		assert_eq(FactionAI.stockpile_held("conclave", "ore", "life"), 5, "spends only cash above the floor")
		assert_true(int(GameState.state["factions"]["conclave"]["resources"]) >= floor_cash, "never below the floor")
	)

	run_case("the_stockpile_survives_a_save_and_an_old_save_gets_one", func():
		_stabiliser_fresh()
		_holdings("conclave")["fate"] = 30
		_stock("ore", "fate", 30)
		assert_true(SaveManager.save_to_slot(STABILISER_SAVE_SLOT)["ok"])
		GameState.reset()
		assert_true(SaveManager.load_from_slot(STABILISER_SAVE_SLOT)["ok"])
		SaveManager.delete_slot(STABILISER_SAVE_SLOT)
		assert_eq(typeof(GameState.state["factionConclave"]["stockpile"]["ore:fate"]), TYPE_INT)
		assert_eq(int(GameState.state["factionConclave"]["stockpile"]["ore:fate"]), 30)
		var old: Dictionary = GameState.deep_copy(GameState.state)
		old["factionConclave"].erase("stockpile")
		assert_eq(SaveManager.backfill_defaults(old)["factionConclave"]["stockpile"], {}, "old save backfilled")
	)


static func _stabiliser() -> Dictionary:
	return GameData.FACTION_CONCLAVE["stabiliser"]


static func _target(kind: String) -> int:
	return int(_stabiliser()["stockpile"]["target"][kind])


static func _stock(kind: String, good_type: String, units: int) -> void:
	GameState.state["factionConclave"]["stockpile"][kind + ":" + good_type] = units


static func _run_days() -> int:
	return int(_stabiliser()["runDays"])


# Pins a good's quote at mult × base; returns the quote.
static func _hold_quote(kind: String, good_type: String, mult: float) -> int:
	var price: int = roundi(Market.base_price(kind, good_type) * mult)
	GameState.state["market"]["goods"][kind][good_type]["price"] = price
	return price


# _market_fresh(5) with every good quoted at 1.1 × base: inside the band,
# above the stockpile top-up's price ceiling.
static func _stabiliser_fresh() -> void:
	_market_fresh(5)
	for kind in Market.KINDS:
		for good_type in GameState.state["market"]["goods"][kind]:
			_hold_quote(kind, good_type, 1.1)


static func _stabilise_days(n: int) -> void:
	for i in n:
		FactionAI.stabilise()


static func _cooldown() -> int:
	return int(GameData.FACTION_ESCALATION["cooldownDays"])


static func _warning(archetype: String, band_id: String) -> String:
	return GameData.FACTION_ESCALATION["warnings"][archetype][band_id]


static func _last_message(contact_id: String) -> String:
	var thread: Array = GameState.state["messages"].get(contact_id, [])
	return thread.back()["text"] if not thread.is_empty() else ""


static func _target_entry(faction_id: String) -> Dictionary:
	return FactionAI._target_entry(faction_id, "player")


# A negative last drift toward the player, as the pressure step would store.
static func _under_pressure(faction_id: String) -> void:
	var snapshots: Dictionary = GameState.state["factionPressure"]["snapshots"]
	if not snapshots.has(faction_id):
		snapshots[faction_id] = {}
	snapshots[faction_id]["player"] = { "threat": 2.0, "dependence": 0.0, "delta": -2.0 }


static func _escalate_on(day: int) -> void:
	GameState.state["world"]["day"] = day
	FactionAI.apply_escalation()


static func _queued() -> Array:
	return GameState.state["factionEscalation"]["queuedRaids"]


# A player vein to hit, a funded faction, and its player relation.
static func _raid_ready(faction_id: String, relation: int) -> void:
	Fixtures.seed_vein("pv", 60)
	GameState.state["factions"][faction_id]["resources"] = 10000
	Factions.adjust_player_relation(faction_id, relation - _player_relation(faction_id))


static func _explainer_count(move_id: String = FactionAI.MOVE_VEIN_RAID) -> int:
	var text: String = GameData.FACTION_ESCALATION["explainers"][move_id]
	return GameState.state["messages"].get("archie", []).filter(func(m: Dictionary) -> bool: return m["text"] == text).size()


static func _fresh() -> void:
	GameState.reset()
	GameState.state["shares"] = Shares.new_state()
	GameState.state["world"]["sites"] = []
	GameState.state["player"]["veins"] = []


# _fresh() on day `day` with the London market running at rest.
static func _market_fresh(day: int) -> void:
	_fresh()
	GameState.state["world"]["day"] = day
	GameState.state["market"] = Market.new_state(true)
	GameState.state["market"]["startedDay"] = 1


# A funded faction under pressure at `relation` with the player, already
# warned about that band, so its next escalation is a move.
static func _move_ready(faction_id: String, relation: int) -> void:
	GameState.state["factions"][faction_id]["resources"] = 10000
	Factions.adjust_player_relation(faction_id, relation - _player_relation(faction_id))
	_under_pressure(faction_id)
	_target_entry(faction_id)["warnedBand"] = FactionAI.band(faction_id, "player")


static func _holdings(faction_id: String) -> Dictionary:
	return GameState.state["factions"][faction_id]["holdings"]["ore"]


static func _firm_sold(ore_type: String) -> bool:
	return GameState.state["market"]["supply"]["ore"].get(ore_type, {}).has("firm")


static func _pressure_days(n: int) -> void:
	for i in n:
		FactionAI.apply_pressure()


# A pending renewal offer for 5 time ore from counterparty.
static func _renewal(counterparty: String) -> Dictionary:
	return Offers.create_renewal_offer({ "templateId": "", "request": { "kind": "ore", "type": "time", "qty": 5 }, "counterparty": counterparty })


# An active one-off contract still owing 5 of recipe_key.
static func _owe_item(recipe_key: String) -> void:
	var template := { "id": "", "source": "scripted", "contractType": "oneOff", "request": { "kind": "consumable", "type": recipe_key, "qty": 5 } }
	var offer: Dictionary = Offers.create_offer(template)["offer"]
	Offers.accept_offer(offer["id"])


static func _player_relation(faction_id: String) -> int:
	return GameState.state["factions"][faction_id]["relation"]
