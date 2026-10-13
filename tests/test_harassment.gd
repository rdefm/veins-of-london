extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# Harassment rung: FactionAI harass band, Harassment queue/state/tick, panel rows.


static func _fresh() -> void:
	GameState.reset()
	GameState.state["shares"] = Shares.new_state()
	GameState.state["world"]["sites"] = []
	GameState.state["player"]["veins"] = []


# A player vein in Shoreditch under Firm turf, Firm funded and sore with the player.
static func _firm_ready(relation: int) -> void:
	_fresh()
	Fixtures.seed_vein("pv", 60)
	GameState.state["turf"]["shoreditch"] = { "controller": "firm", "shares": { "firm": 1.0 }, "tiers": { "firm": "control" } }
	GameState.state["factions"]["firm"]["resources"] = 10000
	Factions.adjust_player_relation("firm", relation - int(GameState.state["factions"]["firm"]["relation"]))
	GameState.state["factionPressure"]["snapshots"]["firm"] = { "player": { "threat": 2.0, "dependence": 0.0, "delta": -2.0 } }
	GameState.state["factionEscalation"]["targets"] = { "firm": { "player": { "warnedBand": FactionAI.BAND_HARASS, "lastMoveDay": -1 } } }


static func _escalate_on(day: int) -> void:
	GameState.state["world"]["day"] = day
	FactionAI.apply_escalation()


func run() -> void:
	run_case("harass_band_sits_between_warning_and_market", func():
		_fresh()
		for faction_id in GameData.FACTIONS.keys():
			assert_true(FactionAI.warning_line(faction_id) > FactionAI.harass_line(faction_id), "%s warning above harass" % faction_id)
			assert_true(FactionAI.harass_line(faction_id) > FactionAI.market_line(faction_id), "%s harass above market" % faction_id)
			Factions.adjust_player_relation(faction_id, FactionAI.harass_line(faction_id) - 1 - int(GameState.state["factions"][faction_id]["relation"]))
			assert_eq(FactionAI.band(faction_id, "player"), FactionAI.BAND_HARASS, "%s just below its harass line" % faction_id)
	)

	run_case("collective_and_guild_raid_thresholds_are_much_lower", func():
		assert_eq(int(GameData.FACTIONS["collective"]["raidThreshold"]), -60)
		assert_eq(int(GameData.FACTIONS["guild"]["raidThreshold"]), -50)
	)

	run_case("harass_rung_queues_the_authored_event_against_a_turf_vein", func():
		_firm_ready(FactionAI.harass_line("firm") - 1)
		_escalate_on(1)
		var queued: Array = Harassment.queued()
		assert_eq(queued.size(), 1)
		assert_eq(queued[0]["veinId"], "pv")
		assert_eq(queued[0]["eventId"], "harass_placeholder")
		assert_eq(int(GameState.state["factions"]["firm"]["resources"]), 10000 - 100, "cost paid")
	)

	run_case("harass_respects_cooldown_and_one_move_per_target", func():
		_firm_ready(FactionAI.harass_line("firm") - 1)
		_escalate_on(1)
		_escalate_on(2)
		assert_eq(Harassment.queued().size(), 1, "cooling down")
		_escalate_on(1 + int(GameData.FACTION_ESCALATION["cooldownDays"]))
		assert_eq(Harassment.queued().size(), 1, "the vein is already being harassed")
	)

	run_case("harass_warns_first_when_the_band_is_new", func():
		_firm_ready(FactionAI.harass_line("firm") - 1)
		GameState.state["factionEscalation"]["targets"]["firm"]["player"]["warnedBand"] = FactionAI.BAND_WARNING
		_escalate_on(1)
		assert_true(Harassment.queued().is_empty())
		assert_eq(GameState.state["factionEscalation"]["targets"]["firm"]["player"]["warnedBand"], FactionAI.BAND_HARASS)
	)

	run_case("harass_is_skipped_with_no_eligible_vein", func():
		_firm_ready(FactionAI.harass_line("firm") - 1)
		GameState.state["turf"]["shoreditch"]["tiers"] = { "firm": "none" }
		_escalate_on(1)
		assert_true(Harassment.queued().is_empty())
		assert_eq(int(GameState.state["factions"]["firm"]["resources"]), 10000, "nothing spent")
	)

	run_case("event_ops_add_and_clear_effects_and_escalation_follows_cadence", func():
		_firm_ready(0)
		GameState.state["world"]["day"] = 10
		GameState.state["event"] = { "eventId": "harass_placeholder", "context": { "faction_id": "firm", "vein_id": "pv" } }
		Events.apply_effects([{ "op": "harassment_add", "kind": "placeholder", "params": {} }])
		var row: Dictionary = Harassment.active()[0]
		assert_eq(row["veinId"], "pv")
		assert_eq(row["factionId"], "firm")
		assert_eq(int(row["escalation"]), 0)
		var cadence: Dictionary = GameData.FACTION_HARASSMENT["escalation"]
		GameState.state["world"]["day"] = 10 + int(cadence["everyDays"]) * 2
		Harassment.tick()
		assert_eq(int(Harassment.active()[0]["escalation"]), 2)
		GameState.state["world"]["day"] = 10 + int(cadence["everyDays"]) * 50
		Harassment.tick()
		assert_eq(int(Harassment.active()[0]["escalation"]), int(cadence["max"]), "capped")
		Events.apply_effects([{ "op": "harassment_clear", "kind": "placeholder" }])
		assert_true(Harassment.active().is_empty())
		GameState.state["event"] = null
	)

	run_case("state_is_pure_data_backfilled_and_rewound", func():
		_firm_ready(0)
		Harassment.add("firm", "placeholder", "pv", {})
		var snapshot: Dictionary = GameState.deep_copy(GameState.state["harassment"])
		Harassment.clear(Harassment.active()[0]["id"])
		GameState.state["harassment"] = snapshot
		assert_eq(Harassment.active().size(), 1, "restores with the snapshot")
		assert_eq(typeof(JSON.parse_string(JSON.stringify(snapshot))), TYPE_DICTIONARY, "round-trips as JSON")
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save.erase("harassment")
		var loaded: Dictionary = SaveManager.backfill_defaults(save)
		assert_eq(loaded["harassment"]["active"], [], "old save gets an empty harassment state")
	)

	run_case("panel_lists_active_harassment_for_the_district", func():
		_firm_ready(0)
		Harassment.add("firm", "placeholder", "pv", {})
		var rows: Array = TurfPanel.build("shoreditch")["sections"]["harassment"]
		assert_eq(rows.size(), 1)
		assert_eq(rows[0]["source_name"], GameData.FACTIONS["firm"]["shortName"])
		assert_true(TurfPanel.build("soho")["sections"]["harassment"].is_empty())
	)

	run_case("placeholder_entries_point_at_real_events_and_factions", func():
		for id in GameData.FACTION_HARASSMENT["entries"]:
			var row: Dictionary = GameData.FACTION_HARASSMENT["entries"][id]
			assert_true(GameData.EVENTS.has(row["eventId"]), "%s event exists" % id)
			assert_true(GameData.FACTIONS.has(row["factionId"]), "%s faction exists" % id)
		for menu in GameData.FACTION_ESCALATION["menus"].values():
			for id in menu["harass"]:
				assert_true(GameData.FACTION_HARASSMENT["entries"].has(id), "menu id %s defined" % id)
	)
