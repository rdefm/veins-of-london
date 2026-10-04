extends "res://tests/test_base.gd"

# Uses high slot/autosave indices (90+) to avoid colliding with any real
# save data, and cleans up after itself.

const TEST_SLOT := 91
const Fixtures := preload("res://tests/support/fixtures.gd")
const OffersSystem := preload("res://systems/offers.gd")
const ContractsSystem := preload("res://systems/contracts.gd")


# Shared by the mixed-offer round-trip case below, for both the pending
# offer's own quote and (after acceptance) the resulting contract's quote --
# same { lines: [{ unitValue, liveValue }] } shape either way.
func _assert_quote_lines_are_ints(quote: Dictionary, label: String) -> void:
	for line in quote["lines"]:
		assert_eq(typeof(line["unitValue"]), TYPE_INT, "%s quote.lines[].unitValue should be restored as int, not float" % label)
		assert_eq(typeof(line["liveValue"]), TYPE_INT, "%s quote.lines[].liveValue should be restored as int, not float" % label)


func run() -> void:
	run_case("ticker_recency_backfills_and_round_trips", func():
		GameState.reset()
		var old_save: Dictionary = GameState.deep_copy(GameState.state)
		old_save["barometer"].erase("changeSeq")
		old_save["barometer"].erase("changedAt")
		var filled: Dictionary = SaveManager.backfill_defaults(old_save)
		assert_eq(filled["barometer"]["changeSeq"], 0, "old saves start with no change sequence")
		assert_eq(filled["barometer"]["changedAt"], {}, "old saves use the base order")
		Barometer.ensure_progress()
		GameState.state["barometer"]["progress"]["political"]["war"] = 100
		Barometer._resolve_section("political")
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"], "recency save succeeds")
		GameState.state["barometer"]["changeSeq"] = 0
		GameState.state["barometer"]["changedAt"] = {}
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"], "recency load succeeds")
		assert_eq(GameState.state["barometer"]["changedAt"]["political"], 1, "recency survives save/load")
		assert_eq(typeof(GameState.state["barometer"]["changeSeq"]), TYPE_INT, "counter restores as int")
		assert_eq(typeof(GameState.state["barometer"]["changedAt"]["political"]), TYPE_INT, "stamp restores as int")
		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_exactly", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 12345
		GameState.state["player"]["veins"].append({
			"id": "v1", "oreType": "time", "growth": 65, "rampantDays": 2, "security": "basic",
			"alarmUpgrades": [], "location": "Brick Lane, near the off-licence", "claimedOnDay": 4,
			"district": "shoreditch", "siteId": "s1", "hospitability": { "tier": "fair", "bonuses": [] },
			"guardKit": {},
		})
		GameState.state["world"]["day"] = 9
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["player"]["cash"] = 1
		GameState.state["world"]["day"] = 1
		GameState.state["player"]["veins"] = []

		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_eq(GameState.state["player"]["cash"], 12345, "cash should be restored")
		assert_eq(GameState.state["world"]["day"], 9, "day should be restored")
		assert_eq(GameState.state["player"]["veins"].size(), 1, "veins should be restored")
		assert_eq(GameState.state, original, "the full state tree should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_a_scrappers_combat_variant", func():
		GameState.reset()
		Combat.start_raid("v1", 1, 3, Combat.SCRAPPER_TEMPLATE_KEY)
		var variants: Array = GameState.state["combat"]["enemies"].map(func(e: Dictionary) -> String: return e["variant"])

		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"], "save_to_slot should succeed")
		for enemy in GameState.state["combat"]["enemies"]:
			enemy["variant"] = "x"
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"], "load_from_slot should succeed")

		assert_eq(GameState.state["combat"]["enemies"].map(func(e: Dictionary) -> String: return e["variant"]), variants, "each scrapper's variant is restored")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_factionRelations_as_ints", func():
		GameState.reset()
		Factions.adjust_relation("collective", "firm", -12)
		var expected: int = Factions.get_relation("collective", "firm")

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["factionRelations"]["collective"]["firm"] = 0

		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var restored: Variant = GameState.state["factionRelations"]["collective"]["firm"]
		assert_eq(restored, expected, "relation value should be restored")
		assert_eq(typeof(restored), TYPE_INT, "JSON round-trip should restore int, not float")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("stances_pending_counters_and_activity_log_round_trip", func():
		GameState.reset()
		Factions.adjust_player_relation("firm", 60)
		FactionAI.update_stances()
		FactionAI.log_activity("firm", "A note.")
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"])
		GameState.reset()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"])
		var entry: Dictionary = GameState.state["factionStances"]["player"]["firm"]
		assert_eq(entry["pending"], FactionAI.PARTNER)
		assert_eq(typeof(entry["pendingDays"]), TYPE_INT)
		assert_eq(entry["pendingDays"], 1)
		assert_eq(FactionAI.activity_log("firm")[-1]["text"], "A note.")
		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("pressure_snapshots_round_trip_and_backfill", func():
		GameState.reset()
		FactionAI.apply_pressure()
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"])
		GameState.reset()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"])
		assert_true(GameState.state["factionPressure"]["snapshots"]["firm"].has("player"), "snapshots kept")
		SaveManager.delete_slot(TEST_SLOT)
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save.erase("factionPressure")
		assert_true(SaveManager.import_string(JSON.stringify(save))["ok"])
		assert_eq(GameState.state["factionPressure"], FactionAI.new_pressure_state(), "backfilled empty")
		assert_eq(FactionAI.pressure_label("firm"), "Calm")
	)

	run_case("escalation_state_and_headlines_round_trip_and_backfill", func():
		GameState.reset()
		FactionAI._target_entry("firm", "player")["lastMoveDay"] = 4
		GameState.state["factionEscalation"]["queuedRaids"].append({ "attackerId": "firm", "targetId": "player", "veinId": "v", "siteId": "s" })
		GameState.state["factionEscalation"]["withholds"].append({ "factionId": "firm", "targetId": "player", "kind": "ore", "good": "time", "untilDay": 9 })
		GameState.state["factionEscalation"]["lastVeinLostDay"] = 3
		Barometer.push_headline("Test headline.")
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"])
		GameState.reset()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"])
		assert_eq(typeof(GameState.state["factionEscalation"]["lastVeinLostDay"]), TYPE_INT, "lost-vein day restored as int")
		var entry: Dictionary = GameState.state["factionEscalation"]["targets"]["firm"]["player"]
		assert_eq(typeof(entry["lastMoveDay"]), TYPE_INT, "day restored as int")
		assert_eq(entry["lastMoveDay"], 4)
		assert_eq(GameState.state["factionEscalation"]["queuedRaids"].size(), 1, "queued raid kept")
		assert_eq(typeof(GameState.state["factionEscalation"]["withholds"][0]["untilDay"]), TYPE_INT, "withhold day restored as int")
		assert_eq(typeof(Barometer.headlines()[0]["day"]), TYPE_INT)
		SaveManager.delete_slot(TEST_SLOT)
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save.erase("factionEscalation")
		save["barometer"].erase("headlines")
		assert_true(SaveManager.import_string(JSON.stringify(save))["ok"])
		assert_eq(GameState.state["factionEscalation"], FactionAI.new_escalation_state(), "backfilled empty")
		assert_eq(Barometer.headlines(), [])
	)

	run_case("wars_and_player_weariness_round_trip_and_backfill", func():
		GameState.reset()
		var war: Dictionary = GameState.state["factionWar"]
		war["wars"].append({ "parties": ["player", "firm"], "startDay": 3, "lastHostileDay": 5, "weariness": { "player": 41.5, "firm": 12.25 } })
		war["lastHostile"]["player:firm"] = 5
		war["weariness"]["player"] = 41.5
		war["nagLevel"] = 1
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"])
		GameState.reset()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"])
		SaveManager.delete_slot(TEST_SLOT)
		var loaded: Dictionary = FactionAI.wars()[0]
		assert_eq(typeof(loaded["startDay"]), TYPE_INT, "start day restored as int")
		assert_eq(typeof(loaded["lastHostileDay"]), TYPE_INT, "last hostile day restored as int")
		assert_eq(typeof(GameState.state["factionWar"]["lastHostile"]["player:firm"]), TYPE_INT)
		assert_eq(typeof(GameState.state["factionWar"]["nagLevel"]), TYPE_INT)
		assert_eq(FactionAI.weariness("player"), 41.5, "player weariness kept")
		assert_eq(loaded["weariness"]["firm"], 12.25)
		assert_true(FactionAI.at_war("firm", "player"))
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save.erase("factionWar")
		assert_true(SaveManager.import_string(JSON.stringify(save))["ok"])
		assert_eq(GameState.state["factionWar"], FactionAI.new_war_state(), "backfilled empty")
	)

	run_case("truces_round_trip_and_backfill", func():
		GameState.reset()
		GameState.state["world"]["day"] = 4
		FactionAI.sign_truce("firm", "guild", { "truceDays": 10, "weekly": [{ "from": "firm", "to": "guild", "amount": 150 }] })
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"])
		GameState.reset()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"])
		SaveManager.delete_slot(TEST_SLOT)
		var truce: Dictionary = FactionAI.find_truce("guild", "firm")
		assert_eq(typeof(truce["endDay"]), TYPE_INT)
		assert_eq(truce["endDay"], 14)
		assert_eq(typeof(truce["weekly"][0]["amount"]), TYPE_INT)
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save["factionWar"].erase("truces")
		assert_true(SaveManager.import_string(JSON.stringify(save))["ok"])
		assert_eq(FactionAI.truces(), [], "backfilled empty")
	)

	run_case("negotiation_round_trips_and_backfills", func():
		GameState.reset()
		var war: Dictionary = GameState.state["factionWar"]
		var draft := FactionAI.default_terms()
		draft[FactionAI.TERM_CASH_TO_PLAYER] = 300
		war["negotiation"] = { "factionId": "firm", "round": 2, "binding": true, "final": false, "draft": draft, "counter": FactionAI.default_terms() }
		war["peaceCooldown"]["guild"] = 12
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"])
		GameState.reset()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"])
		SaveManager.delete_slot(TEST_SLOT)
		var talks := FactionAI.negotiation()
		assert_eq(typeof(talks["round"]), TYPE_INT)
		assert_eq(typeof(talks["draft"][FactionAI.TERM_CASH_TO_PLAYER]), TYPE_INT)
		assert_eq(talks["draft"][FactionAI.TERM_CASH_TO_PLAYER], 300)
		assert_eq(typeof(talks["counter"][FactionAI.TERM_TRUCE_DAYS]), TYPE_INT)
		assert_true(talks["binding"])
		assert_eq(typeof(GameState.state["factionWar"]["peaceCooldown"]["guild"]), TYPE_INT)
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save["factionWar"].erase("negotiation")
		save["factionWar"].erase("peaceCooldown")
		assert_true(SaveManager.import_string(JSON.stringify(save))["ok"])
		assert_eq(FactionAI.negotiation(), {}, "backfilled empty")
		assert_eq(GameState.state["factionWar"]["peaceCooldown"], {})
	)

	run_case("old_save_clamps_relations_symmetrises_pairs_and_backfills_stances", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save.erase("factionStances")
		for faction in save["factions"].values():
			faction.erase("activityLog")
		save["factions"]["firm"]["relation"] = 250
		save["factions"]["guild"]["relation"] = -60
		for a in save["factionRelations"]:
			for b in save["factionRelations"][a]:
				save["factionRelations"][a][b] = 0
		save["factionRelations"]["firm"]["guild"] = -30
		save["factionRelations"]["guild"]["firm"] = 20
		save["factionRelations"]["collective"]["firm"] = -500
		save["factionRelations"]["firm"]["collective"] = -500
		save["factionRelations"]["collective"]["guild"] = 0
		save["factionRelations"]["guild"]["collective"] = 0
		assert_true(SaveManager.import_string(JSON.stringify(save))["ok"])
		assert_eq(GameState.state["factions"]["firm"]["relation"], 100, "player relation clamped")
		assert_eq(Factions.get_relation("firm", "guild"), -5, "directions averaged")
		assert_eq(Factions.get_relation("guild", "firm"), -5)
		assert_eq(Factions.get_relation("collective", "firm"), -100, "pair relation clamped")
		assert_eq(FactionAI.pair_stance("collective", "firm"), FactionAI.HOSTILE, "starting stances backfilled")
		assert_eq(FactionAI.pair_stance("collective", "guild"), FactionAI.PARTNER)
		assert_eq(Factions.get_relation("collective", "guild"), FactionAI.starting_pair_relation("collective", "guild"), "moved into the Partner band")
		assert_eq(FactionAI.player_stance("firm"), FactionAI.PARTNER, "player stance read from relation")
		assert_eq(FactionAI.player_stance("guild"), FactionAI.HOSTILE)
		assert_eq(FactionAI.activity_log("firm"), [], "activity log backfilled")
	)

	run_case("save_mutate_load_round_trips_vein_level_as_an_int", func():
		GameState.reset()
		GameState.state["player"]["veins"].append(Cultivating.make_vein("time", 50, "shoreditch", "s1", { "tier": "rich", "bonuses": [] }))
		GameState.state["player"]["veins"][0]["level"] = 3

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["player"]["veins"][0]["level"] = 0

		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var restored: Variant = GameState.state["player"]["veins"][0]["level"]
		assert_eq(restored, 3, "vein level should be restored")
		assert_eq(typeof(restored), TYPE_INT, "JSON round-trip should restore int, not float")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_bankLog_with_int_fields_intact", func():
		GameState.reset()
		Bank.record(-50, "Living costs")
		Bank.record(300, "Archie sale")
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["bankLog"] = []
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var log: Array = GameState.state["bankLog"]
		assert_eq(log.size(), 2, "bankLog should be restored")
		assert_eq(typeof(log[0]["amount"]), TYPE_INT, "amount should be restored as int, not float")
		assert_eq(typeof(log[0]["day"]), TYPE_INT, "day should be restored as int, not float")
		assert_eq(GameState.state, original, "the full state tree (including bankLog) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("old_save_payroll_state_is_dropped_on_load", func():
		GameState.reset()
		GameState.state["payroll"] = { "paidToday": { "lab": 0.0 }, "hires": {}, "lastSummary": { "day": 1.0, "entries": [] } }
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_true(not GameState.state.has("payroll"))
	)

	run_case("old_save_recurring_contract_due_mid_week_migrates_to_the_next_monday", func():
		GameState.reset()
		GameState.state["world"]["day"] = 3
		var created: Dictionary = Offers.create_scripted_offer("scripted_physics_weekly")
		var contract: Dictionary = Offers.accept_offer(created["offer"]["id"])["contract"]
		var one_off: Dictionary = Offers.accept_offer(Offers.create_scripted_offer("scripted_life_order")["offer"]["id"])["contract"]
		# An old save: recurring due on a WED, weekday THU.
		contract["dueDay"] = 10
		contract["weekday"] = 3
		var one_off_due: int = one_off["dueDay"]
		var text := SaveManager.export_string()
		assert_true(SaveManager.import_string(text)["ok"])

		var loaded: Array = GameState.state["sales"]["activeContracts"]
		assert_eq(loaded[0]["dueDay"], 15, "WED day 10 moves to MON day 15")
		assert_eq(loaded[0]["weekday"], 0)
		assert_eq(loaded[1]["dueDay"], one_off_due, "a one-off keeps its deadline")

		var round_trip := SaveManager.export_string()
		assert_true(SaveManager.import_string(round_trip)["ok"])
		assert_eq(GameState.state["sales"]["activeContracts"][0]["dueDay"], 15, "a Monday due day is left alone")
	)

	run_case("old_save_drops_contract_delegation_fields", func():
		GameState.reset()
		var offer: Dictionary = OffersSystem.create_scripted_offer("scripted_life_order")["offer"]
		var contract: Dictionary = OffersSystem.accept_offer(offer["id"])["contract"]
		contract["delegated"] = true
		contract["delegatedWholePeriod"] = true
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		var loaded: Dictionary = GameState.state["sales"]["activeContracts"][0]
		assert_true(not loaded.has("delegated"))
		assert_true(not loaded.has("delegatedWholePeriod"))
	)

	run_case("old_save_between_beat_1_and_the_staff_tab_puts_archie_in_sales", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["flags"]["bizArchieSalesRole"] = true
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["contacts"]["archie"]["assignedRole"], "sales")
		GameState.state["contacts"]["archie"]["assignedRole"] = null
		GameState.state["flags"]["bizStaffTabOpen"] = true
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["contacts"]["archie"]["assignedRole"], null, "the player's own choice once the Staff tab is open")
	)

	run_case("faction_holdings_round_trip_with_int_counts", func():
		GameState.reset()
		FactionSim.add_item("guild", "timePearl", 3, 2)
		FactionSim.add_ore("firm", "fate", 7)
		var guild_pearls: Dictionary = GameState.state["factions"]["guild"]["holdings"]["items"]["timePearl"].duplicate()
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["factions"]["guild"]["holdings"]["items"]["timePearl"], guild_pearls)
		assert_eq(FactionSim.ore_held("firm", "fate"), 7)
		assert_eq(typeof(GameState.state["factions"]["firm"]["holdings"]["ore"]["fate"]), TYPE_INT)
		assert_eq(typeof(GameState.state["factions"]["guild"]["holdings"]["items"]["timePearl"]["3"]), TYPE_INT)
	)

	run_case("old_save_ore_stock_migrates_into_backfilled_holdings_and_keeps_cash", func():
		GameState.reset()
		for faction_id in GameState.state["factions"]:
			GameState.state["factions"][faction_id].erase("holdings")
			GameState.state["factions"][faction_id]["oreStock"] = {}
		GameState.state["factions"]["collective"]["oreStock"] = { "life": 5, "time": 9 }
		GameState.state["factions"]["collective"]["resources"] = 37
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		var collective: Dictionary = GameState.state["factions"]["collective"]
		assert_true(not collective.has("oreStock"), "oreStock is dropped")
		var start := FactionSim.starting_holdings("collective")
		assert_eq(FactionSim.ore_held("collective", "life"), int(start["ore"]["life"]) + 5, "old stock adds onto the backfill")
		assert_eq(FactionSim.ore_held("collective", "time"), 9)
		assert_eq(collective["holdings"]["items"], start["items"], "items backfilled at starting stock")
		assert_eq(collective["resources"], 37, "faction cash unchanged")
		assert_eq(GameState.state["factions"]["conclave"]["holdings"], FactionSim.starting_holdings("conclave"))
	)

	run_case("faction_stockpile_survives_save_load_unchanged", func():
		GameState.reset()
		GameState.state["factions"]["network"]["stockpile"]["revealedTo"].append("player")
		var before: Dictionary = GameState.state["factions"]["network"]["stockpile"].duplicate(true)
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["factions"]["network"]["stockpile"], before, "load keeps the picked stockpile and its reveals")
	)

	run_case("old_save_without_stockpile_gets_one_picked_on_load", func():
		GameState.reset()
		for faction_id in GameState.state["factions"]:
			GameState.state["factions"][faction_id].erase("stockpile")
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		for faction_id in GameState.state["factions"]:
			var stockpile: Dictionary = GameState.state["factions"][faction_id]["stockpile"]
			assert_true(FactionSim.home_districts(faction_id).has(stockpile["district"]), "%s backfilled in a home district" % faction_id)
			assert_true(GameData.FACTIONS[faction_id]["stockpilePlaces"].has(stockpile["place"]), "%s backfilled place from data" % faction_id)
			assert_eq(stockpile["revealedTo"], [], "%s backfilled unrevealed" % faction_id)
	)

	run_case("old_save_arrears_day_clock_migrates_to_whole_weeks", func():
		GameState.reset()
		GameState.state["home"]["arrears"] = 300
		GameState.state["home"].erase("arrearsWeeks")
		GameState.state["home"]["arrearsDays"] = 9
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		var home: Dictionary = GameState.state["home"]
		assert_eq(home["arrearsWeeks"], 2, "9 days rounds up to 2 weeks")
		assert_eq(typeof(home["arrearsWeeks"]), TYPE_INT)
		assert_true(not home.has("arrearsDays"), "the day clock is dropped")
	)


	run_case("save_mutate_load_round_trips_messages_with_day_int_intact", func():
		GameState.reset()
		# 21-contact-roles-sales-skill: mutate the default "des" contact in
		# place rather than replacing it with a hand-rolled partial dict --
		# contacts are now subject to the same full-shape backfill on load as
		# home/world/player (SaveManager._backfill_new_contact_keys), so a
		# stub missing most contact keys would no longer round-trip exactly.
		GameState.state["contacts"]["des"]["unlocked"] = true
		Messages.append("des", "them", "Hello.")
		Messages.queue_pending("des", "col_a1_des_report", "Something for you.")
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["messages"] = {}
		GameState.state["pendingMessages"] = []
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var thread: Array = GameState.state["messages"]["des"]
		assert_eq(thread.size(), 2, "messages should be restored")
		assert_eq(typeof(thread[0]["day"]), TYPE_INT, "message day should be restored as int, not float")
		assert_eq(GameState.state["pendingMessages"].size(), 1, "pendingMessages should be restored")
		assert_eq(GameState.state, original, "the full state tree (including messages/pendingMessages) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_sites_with_int_fields_intact", func():
		GameState.reset()
		GameState.state["world"]["sites"].append({
			"id": "s1", "district": "hampstead", "tier": "rich", "oreType": "life",
			"bonuses": ["yield"], "discoveredDay": 3, "claimed": false,
			"factionVein": { "id": "fv1", "factionId": "collective", "oreType": "life", "growth": 20, "rampantDays": 0, "security": "none", "claimedOnDay": 5, "kit": { "healingSalve": 1 } },
			"hasNaturalVein": false,
		})
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["world"]["sites"] = []
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var site: Dictionary = GameState.state["world"]["sites"][0]
		assert_eq(typeof(site["discoveredDay"]), TYPE_INT, "discoveredDay should be restored as int, not float")
		assert_eq(typeof(site["factionVein"]["claimedOnDay"]), TYPE_INT, "factionVein.claimedOnDay should be restored as int, not float")
		assert_eq(GameState.state, original, "the full state tree (including sites) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_mapSlotFreePool_with_int_fields_intact", func():
		GameState.reset()
		Sites.next_slot_index("hampstead")
		Sites.next_slot_index("hampstead")
		Sites.release_slot_index("hampstead", 0)
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["world"]["mapSlotFreePool"] = {}
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var freed: Array = GameState.state["world"]["mapSlotFreePool"]["hampstead"]
		assert_eq(typeof(freed[0]), TYPE_INT, "a freed slotIndex should be restored as int, not float")
		assert_eq(GameState.state, original, "the full state tree (including mapSlotFreePool) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	# Covers both a pending mixed-type offer and, after accepting it, the
	# resulting contract -- each carries its own quote.lines[] array (one
	# entry per requested ore/consumable type) alongside the offer's own
	# extraTypeDeadlineDays.
	run_case("save_mutate_load_round_trips_a_mixed_offer_quotes_lines_and_extraTypeDeadlineDays_as_ints", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		var created: Dictionary = OffersSystem.create_offer({
			"id": "t_mixed_savemanager", "source": "scripted", "contractType": "oneOff",
			"deadlineAfterDays": 5,
			"request": { "types": [{ "kind": "ore", "type": "fate", "qty": 3 }, { "kind": "consumable", "type": "timePearl", "qty": 2 }] },
		})
		assert_true(created["ok"])
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["sales"]["pendingOffers"] = []
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var offer: Dictionary = GameState.state["sales"]["pendingOffers"][0]
		assert_eq(typeof(offer["extraTypeDeadlineDays"]), TYPE_INT, "extraTypeDeadlineDays should be restored as int, not float")
		assert_eq(offer["quote"]["lines"].size(), 2)
		_assert_quote_lines_are_ints(offer["quote"], "offer")
		assert_eq(GameState.state, original, "the full state tree (including the mixed offer's quote.lines) should deep-equal what was saved")

		var accepted: Dictionary = OffersSystem.accept_offer(offer["id"])
		assert_true(accepted["ok"])
		var original_with_contract: Dictionary = GameState.deep_copy(GameState.state)

		save_result = SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["sales"]["activeContracts"] = []
		load_result = SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var contract: Dictionary = GameState.state["sales"]["activeContracts"][0]
		_assert_quote_lines_are_ints(contract["signedQuote"], "contract")
		assert_eq(GameState.state, original_with_contract, "the full state tree (including the accepted contract's quote.lines) should deep-equal what was saved")

		# A settled contract lands in sales.contractHistory as its own full
		# copy (systems/contracts.gd's settle()), not a reference into
		# activeContracts -- same nested quote/request/delivered shape, so it
		# needs the same round-trip proof.
		GameState.state["player"]["orichalchum"]["fate"] = 3
		Crafting.inventory_add("timePearl", 1, 2)
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["flags"]["bizArchieSalesRole"] = true
		Contacts.set_role("archie", "sales")
		ContractsSystem.process_sales_deliveries()
		assert_eq(GameState.state["sales"]["contractHistory"].size(), 1, "full delivery settles immediately")
		var original_with_history: Dictionary = GameState.deep_copy(GameState.state)

		save_result = SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["sales"]["contractHistory"] = []
		load_result = SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var history_entry: Dictionary = GameState.state["sales"]["contractHistory"][0]
		_assert_quote_lines_are_ints(history_entry["contract"]["signedQuote"], "contractHistory.contract")
		assert_eq(typeof(history_entry["contract"]["dueDay"]), TYPE_INT, "contractHistory.contract.dueDay should be restored as int, not float")
		assert_eq(typeof(history_entry["contract"]["delivered"]["fate"]), TYPE_INT, "contractHistory.contract.delivered[].qty should be restored as int, not float")
		assert_eq(typeof(history_entry["settlement"]["payment"]), TYPE_INT, "contractHistory.settlement.payment should be restored as int, not float")
		assert_eq(typeof(history_entry["settlement"]["delivered"]["fate"]), TYPE_INT, "contractHistory.settlement.delivered[].qty should be restored as int, not float")
		assert_eq(GameState.state, original_with_history, "the full state tree (including sales.contractHistory) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_stealth_skill_for_player_and_contact", func():
		GameState.reset()
		GameState.state["player"]["stealthSkill"] = 3
		GameState.state["player"]["stealthXP"] = 45
		GameState.state["contacts"]["archie"]["stealthSkill"] = 2
		GameState.state["contacts"]["archie"]["stealthXP"] = 30

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["player"]["stealthSkill"] = 1
		GameState.state["player"]["stealthXP"] = 0
		GameState.state["contacts"]["archie"]["stealthSkill"] = 1
		GameState.state["contacts"]["archie"]["stealthXP"] = 0

		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_eq(GameState.state["player"]["stealthSkill"], 3, "player.stealthSkill should be restored")
		assert_eq(GameState.state["player"]["stealthXP"], 45, "player.stealthXP should be restored")
		assert_eq(typeof(GameState.state["player"]["stealthXP"]), TYPE_INT, "player.stealthXP should be restored as int, not float")
		assert_eq(GameState.state["contacts"]["archie"]["stealthSkill"], 2, "contact.stealthSkill should be restored")
		assert_eq(GameState.state["contacts"]["archie"]["stealthXP"], 30, "contact.stealthXP should be restored")
		assert_eq(typeof(GameState.state["contacts"]["archie"]["stealthXP"]), TYPE_INT, "contact.stealthXP should be restored as int, not float")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_player_bench", func():
		GameState.reset()
		var bench: Dictionary = GameState.state["player"]["bench"]
		bench["surveyed"]["life+time"] = 3
		bench["cells"]["life+time|heat"] = { "state": "found", "misses": 2, "refine": 1 }
		bench["cells"]["life+time|compression"] = { "state": "hot", "misses": 3, "refine": 0 }
		bench["notes"]["life+time"] = [{ "day": 9, "approach": "heat", "outcome": "found" }]
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["player"]["bench"] = { "surveyed": {}, "cells": {}, "notes": {} }
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		var restored: Dictionary = GameState.state["player"]["bench"]
		assert_eq(restored["surveyed"]["life+time"], 3, "surveyed count should be restored")
		assert_eq(typeof(restored["surveyed"]["life+time"]), TYPE_INT, "surveyed count should be restored as int, not float")
		assert_eq(restored["cells"]["life+time|heat"]["state"], "found", "found cell state should be restored")
		assert_eq(typeof(restored["cells"]["life+time|heat"]["misses"]), TYPE_INT, "cell misses should be restored as int, not float")
		assert_eq(typeof(restored["cells"]["life+time|heat"]["refine"]), TYPE_INT, "cell refine should be restored as int, not float")
		assert_eq(typeof(restored["notes"]["life+time"][0]["day"]), TYPE_INT, "note day should be restored as int, not float")
		assert_eq(GameState.state, original, "the full state tree (including player.bench) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_mutate_load_round_trips_mapView_with_scroll_as_ints_and_zoom_as_float", func():
		GameState.reset()
		MapView.mark_opened()
		MapView.save_view(1.15, Vector2(345, 678))
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.reset()
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_true(MapView.has_opened_before(), "everOpened should be restored")
		assert_almost_eq(MapView.zoom(), 1.15, 0.0001, "zoom should be restored")
		assert_eq(MapView.scroll(), Vector2(345, 678), "scroll should be restored")
		assert_eq(typeof(GameState.state["mapView"]["scrollX"]), TYPE_INT, "scrollX should be restored as int, not float")
		assert_eq(typeof(GameState.state["mapView"]["scrollY"]), TYPE_INT, "scrollY should be restored as int, not float")
		assert_eq(typeof(GameState.state["mapView"]["zoom"]), TYPE_FLOAT, "zoom should stay a float, not get int-cast like scrollX/scrollY")
		assert_eq(GameState.state, original, "the full state tree (including mapView) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	# ── 107-hq-stackable-guards ────────────────────────────────────────

	run_case("save_mutate_load_round_trips_home_guardCount_as_int", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 100000
		GameState.state["home"]["tier"] = "compound"
		Home.add_security("guard")
		Home.add_security("guard")
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["home"]["guardCount"] = 0
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_eq(GameState.state["home"]["guardCount"], 2, "guardCount should be restored")
		assert_eq(typeof(GameState.state["home"]["guardCount"]), TYPE_INT, "guardCount should be restored as int, not float")
		assert_eq(GameState.state, original, "the full state tree (including home.guardCount) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("save_round_trip_keeps_the_market_with_int_prices", func():
		GameState.reset()
		Market.record_supply("ore", "time", 40, "player")
		Market.daily_reprice()
		Market.record_supply("ore", "life", 7, "player")
		var original: Dictionary = GameState.deep_copy(GameState.state["market"])
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["market"], original, "market survives save/load")
		var time_good: Dictionary = GameState.state["market"]["goods"]["ore"]["time"]
		assert_eq(typeof(time_good["price"]), TYPE_INT, "price restored as int")
		assert_eq(typeof(time_good["history"][0]), TYPE_INT, "history restored as ints")
		assert_eq(typeof(GameState.state["market"]["supply"]["ore"]["life"]["player"]), TYPE_INT, "tallies restored as ints")
	)

	run_case("loading_a_save_without_a_market_backfills_resting_prices", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy.erase("market")
		assert_true(SaveManager._load_save_dict(legacy)["ok"])
		var resting: int = Market.target_price("ore", "fate", GameState.round_epsilon(Market.resting_stock("ore", "fate")))
		assert_eq(Market.quote("ore", "fate"), resting, "an old save opens at the resting price")
		assert_true(resting > 90, "resting sits above base (idle premium)")
	)

	run_case("old_save_offers_and_contracts_backfill_a_counterparty", func():
		GameState.reset()
		Offers.create_scripted_offer("scripted_physics_weekly")
		Offers.accept_offer(Offers.create_scripted_offer("scripted_life_order")["offer"]["id"])
		Offers.create_offer({ "id": "", "source": "random", "contractType": "oneOff", "request": { "kind": "ore", "type": "time", "qty": 1 } })
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["factions"]["firm"]["relation"] = 50
		for entry in legacy["sales"]["pendingOffers"] + legacy["sales"]["activeContracts"]:
			entry.erase("counterparty")
		var filled := SaveManager.backfill_defaults(legacy)
		var offers: Array = filled["sales"]["pendingOffers"]
		assert_eq(offers[0]["counterparty"], "firm", "scripted: from data")
		assert_eq(offers[1]["counterparty"], "firm", "small, no fit: the save's better relation")
		assert_eq(filled["sales"]["activeContracts"][0]["counterparty"], "collective")
	)

	run_case("old_save_contract_quote_becomes_signed_quote", func():
		GameState.reset()
		var contract: Dictionary = Offers.accept_offer(Offers.create_scripted_offer("scripted_life_order")["offer"]["id"])["contract"]
		var payment: int = contract["signedQuote"]["payment"]
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		var old_contract: Dictionary = legacy["sales"]["activeContracts"][0]
		old_contract["quote"] = old_contract["signedQuote"]
		old_contract.erase("signedQuote")
		legacy["sales"]["contractHistory"].append({ "contract": old_contract.duplicate(true), "cancelledDay": 1 })
		var filled := SaveManager.backfill_defaults(legacy)
		for migrated in [filled["sales"]["activeContracts"][0], filled["sales"]["contractHistory"][0]["contract"]]:
			assert_true(not migrated.has("quote"))
			assert_eq(migrated["signedQuote"]["payment"], payment)
	)

	run_case("guard_cost_history_backfills_empty_and_round_trips_with_int_values", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy.erase("guardUpkeep")
		assert_eq(SaveManager.backfill_defaults(legacy)["guardUpkeep"], { "history": [], "pendingShortfall": null }, "old saves start with empty history")

		GameState.state["world"]["day"] = 3
		GuardUpkeep.record_payment("home", 71)
		GuardUpkeep.record_payment("v1", 357)
		var original: Dictionary = GameState.deep_copy(GameState.state)
		var parsed: Dictionary = JSON.parse_string(JSON.stringify(GameState.state))
		assert_true(SaveManager._load_save_dict(parsed)["ok"])
		var record: Dictionary = GameState.state["guardUpkeep"]["history"][0]
		assert_eq(typeof(record["day"]), TYPE_INT)
		assert_eq(typeof(record["places"]["v1"]), TYPE_INT)
		assert_eq(GameState.state["guardUpkeep"], original["guardUpkeep"])
	)

	run_case("rewind_restores_guard_cost_history", func():
		GameState.reset()
		GameState.state["world"]["day"] = 3
		GuardUpkeep.record_payment("home", 71)
		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		GameState.state["event"] = { "snapshots": [] }
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		GameState.state["event"]["snapshots"].append(snapshot)
		GuardUpkeep.record_payment("home", 500)
		assert_true(Events.rewind()["ok"])
		assert_eq(GameState.state["guardUpkeep"]["history"], [{ "day": 3, "places": { "home": 71 } }])
	)

	run_case("pending_guard_shortfall_backfills_null_round_trips_and_rewinds", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["guardUpkeep"].erase("pendingShortfall")
		assert_eq(SaveManager.backfill_defaults(legacy)["guardUpkeep"]["pendingShortfall"], null, "old saves have none pending")

		GameState.state["world"]["day"] = 8
		GuardUpkeep.start_shortfall({ "home": 1 }, 250, 500)
		var original: Dictionary = GameState.deep_copy(GameState.state)
		var parsed: Dictionary = JSON.parse_string(JSON.stringify(GameState.state))
		assert_true(SaveManager._load_save_dict(parsed)["ok"])
		var shortfall: Dictionary = GameState.state["guardUpkeep"]["pendingShortfall"]
		for key in ["day", "deadline", "reserve"]:
			assert_eq(typeof(shortfall[key]), TYPE_INT, key)
		assert_eq(typeof(shortfall["places"]["home"]), TYPE_INT)
		assert_eq(GameState.state["guardUpkeep"], original["guardUpkeep"])

		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		GameState.state["event"] = { "snapshots": [] }
		GameState.state["event"]["snapshots"].append(GameState.deep_copy(GameState.state))
		GameState.state["guardUpkeep"]["pendingShortfall"] = null
		assert_true(Events.rewind()["ok"])
		assert_eq(GameState.state["guardUpkeep"]["pendingShortfall"], original["guardUpkeep"]["pendingShortfall"])
	)

	run_case("business_float_backfills_0_round_trips_and_rewinds", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["business"].erase("float")
		assert_eq(SaveManager.backfill_defaults(legacy)["business"]["float"], 0, "old saves start with an empty float")

		Business.activate()
		GameState.state["player"]["cash"] = 300
		Business.donate(120)
		var parsed: Dictionary = JSON.parse_string(JSON.stringify(GameState.state))
		assert_true(SaveManager._load_save_dict(parsed)["ok"])
		assert_eq(GameState.state["business"]["float"], 120)
		assert_eq(typeof(GameState.state["business"]["float"]), TYPE_INT)

		GameState.state["player"]["inventory"]["rewind"] = { "1": 1 }
		GameState.state["event"] = { "snapshots": [] }
		GameState.state["event"]["snapshots"].append(GameState.deep_copy(GameState.state))
		Business.withdraw(120)
		assert_true(Events.rewind()["ok"])
		assert_eq(GameState.state["business"]["float"], 120)
	)

	run_case("loading_a_pre_107_save_backfills_home_guardCount_to_0", func():
		GameState.reset()
		# Pre-107 shape: state.home had no guardCount key at all.
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["home"].erase("guardCount")

		var filled := SaveManager.backfill_defaults(legacy)
		assert_eq(filled["home"]["guardCount"], 0, "a save from before guardCount existed should backfill it to 0")
	)

	run_case("loading_a_save_without_room_seats_backfills_one_per_room", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["home"].erase("roomSeats")
		var filled := SaveManager.backfill_defaults(legacy)
		for room_id in GameData.HOME_ROOMS.keys():
			assert_eq(filled["home"]["roomSeats"][room_id], 1, "%s backfilled to 1 seat" % room_id)
		var partial: Dictionary = GameState.deep_copy(GameState.state)
		partial["home"]["roomSeats"] = { "lab": 2 }
		filled = SaveManager.backfill_defaults(partial)
		assert_eq(filled["home"]["roomSeats"]["lab"], 2, "an upgraded room keeps its seats")
		assert_eq(filled["home"]["roomSeats"]["veinStation"], 1)
	)

	run_case("loading_a_save_without_faction_shop_flags_backfills_them_false", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		for flag in ["firmShopUnlocked", "networkShopUnlocked", "conclaveShopUnlocked"]:
			legacy["flags"].erase(flag)

		var filled := SaveManager.backfill_defaults(legacy)
		for flag in ["firmShopUnlocked", "networkShopUnlocked", "conclaveShopUnlocked"]:
			assert_eq(filled["flags"][flag], false, "%s backfills to its default" % flag)
	)

	run_case("loading_a_save_without_productionLog_starts_an_empty_log", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy.erase("productionLog")

		assert_true(SaveManager._load_save_dict(legacy)["ok"])
		assert_eq(GameState.state["productionLog"], [], "an old save loads with an empty production log")
	)

	run_case("loading_a_save_without_businessStats_starts_empty_and_round_trips_ints", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy.erase("businessStats")
		assert_true(SaveManager._load_save_dict(legacy)["ok"])
		assert_eq(GameState.state["businessStats"]["days"], [], "an old save loads with no stats history")

		GameState.state["businessStats"]["days"] = [{ "day": 4, "revenue": 90, "expenses": 10, "oreCultivator": 3, "orePlayer": 2, "items": 1 }]
		GameState.state["businessStats"]["today"]["revenue"] = 5
		var parsed: Dictionary = JSON.parse_string(JSON.stringify(GameState.state))
		assert_true(SaveManager._load_save_dict(parsed)["ok"])
		assert_eq(typeof(GameState.state["businessStats"]["days"][0]["revenue"]), TYPE_INT)
		assert_eq(typeof(GameState.state["businessStats"]["today"]["revenue"]), TYPE_INT)
	)

	run_case("loading_stats_without_expense_kinds_backfills_them_as_zero", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["businessStats"] = {
			"today": { "revenue": 0, "expenses": 30, "oreCultivator": 0, "orePlayer": 0 },
			"days": [{ "day": 4, "revenue": 90, "expenses": 10, "oreCultivator": 3, "orePlayer": 2, "items": 1 }],
		}
		assert_true(SaveManager._load_save_dict(legacy)["ok"])
		var stats: Dictionary = GameState.state["businessStats"]
		for record in [stats["today"], stats["days"][0]]:
			assert_eq(record["expensesStaff"], 0)
			assert_eq(record["expensesGuard"], 0)
			assert_eq(record["expensesCalc"], 0)
		assert_eq(stats["days"][0]["expenses"], 10, "the unsplit total is kept")
		BusinessStats.record_expense(5, BusinessStats.EXPENSE_GUARD)
		assert_eq(stats["today"]["expenses"], 35)
		assert_eq(stats["today"]["expensesGuard"], 5)
	)

	run_case("productionLog_round_trips_through_json_with_int_counts", func():
		GameState.reset()
		GameState.state["productionLog"] = [{ "day": 3, "blocks": [{ "block": 1, "entries": [{ "contactId": "james", "made": { "timePearl": { "2": 4 } }, "failed": { "timePearl": 1 }, "oreShort": { "recipeKey": "timePearl", "ore": ["time"] } }] }] }]
		var parsed: Dictionary = JSON.parse_string(JSON.stringify(GameState.state))
		assert_true(SaveManager._load_save_dict(parsed)["ok"])
		var entry: Dictionary = GameState.state["productionLog"][0]["blocks"][0]["entries"][0]
		assert_eq(typeof(GameState.state["productionLog"][0]["day"]), TYPE_INT)
		assert_eq(typeof(GameState.state["productionLog"][0]["blocks"][0]["block"]), TYPE_INT)
		assert_eq(typeof(entry["made"]["timePearl"]["2"]), TYPE_INT)
		assert_eq(typeof(entry["failed"]["timePearl"]), TYPE_INT)
	)

	run_case("loading_a_save_with_archie_in_a_room_converts_him_to_the_sales_role", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["contacts"]["archie"]["recruited"] = true
		legacy["contacts"]["archie"]["assignedRoom"] = "ops"
		legacy["contacts"]["archie"].erase("assignedRole")

		assert_true(SaveManager._load_save_dict(legacy)["ok"])
		var archie: Dictionary = GameState.state["contacts"]["archie"]
		assert_eq(archie["assignedRole"], "sales", "a founder's room becomes the matching role")
		assert_eq(archie["assignedRoom"], null, "the room assignment is cleared")
		assert_true(ContractsSystem.has_staffed_sales(), "Archie's founder role staffs Sales")
	)

	run_case("loading_an_old_save_past_the_home_raid_recruits_archie_and_drops_relation_recruitment", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["contacts"].erase("owen")
		legacy["contacts"]["archie"]["recruitable"] = true
		legacy["contacts"]["james"]["recruitable"] = true
		legacy["flags"]["homeRaidEventSeen"] = true

		assert_true(SaveManager._load_save_dict(legacy)["ok"])
		var contacts: Dictionary = GameState.state["contacts"]
		assert_true(contacts["archie"]["recruited"], "past the home raid means Archie is recruited")
		assert_true(not contacts["archie"]["recruitable"], "Archie recruits by story only")
		assert_true(not contacts["james"]["recruitable"], "James recruits by story only")
		assert_true(contacts.has("owen") and not contacts["owen"]["unlocked"], "Owen backfills hidden")
	)

	run_case("loading_clamps_production_targets_above_the_cap", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["labThresholds"] = { "timePearl": 80.0, "rewind": 10.0 }

		assert_true(SaveManager._load_save_dict(legacy)["ok"])
		assert_eq(GameState.state["labThresholds"], { "timePearl": GameData.PRODUCTION_TARGET_MAX, "rewind": 10 }, "over-cap target clamps; in-range one is kept")
	)

	run_case("loading_an_old_vein_station_list_moves_it_to_the_station_occupant", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy.erase("cultivatorVeins")
		legacy["veinStationVeins"] = ["v1", "v2"]
		legacy["player"]["veins"] = [Fixtures.player_vein_with(), Fixtures.player_vein_with({ "id": "v2" })]
		legacy["veinStationTargets"] = { "v1": 60.0, "v2": 80.0 }
		legacy["contacts"]["archie"]["recruited"] = true
		legacy["contacts"]["archie"]["assignedRoom"] = "veinStation"

		assert_true(SaveManager._load_save_dict(legacy)["ok"])
		assert_eq(GameState.state["cultivatorVeins"], { "archie": ["v1", "v2"] }, "occupant takes the list, even though founder fix-up clears the room")
		assert_eq(GameState.state["veinStationTargets"], { "v1": 60, "v2": 80 }, "targets stay keyed by vein id")
		assert_true(not GameState.state.has("veinStationVeins"), "old key removed")
	)

	run_case("loading_an_old_vein_station_list_goes_to_owen_when_he_is_the_only_cultivator", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy.erase("cultivatorVeins")
		legacy["veinStationVeins"] = ["v1"]
		legacy["player"]["veins"] = [Fixtures.player_vein_with()]
		legacy["contacts"]["owen"]["recruited"] = true
		legacy["contacts"]["owen"]["assignedRole"] = "cultivation"

		assert_true(SaveManager._load_save_dict(legacy)["ok"])
		assert_eq(GameState.state["cultivatorVeins"], { "owen": ["v1"] })
	)

	run_case("loading_an_old_vein_station_list_with_no_cultivator_drops_it", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy.erase("cultivatorVeins")
		legacy["veinStationVeins"] = ["v1"]

		assert_true(SaveManager._load_save_dict(legacy)["ok"])
		assert_eq(GameState.state["cultivatorVeins"], {})
		assert_true(not GameState.state.has("veinStationVeins"))
	)

	run_case("loading_strips_unowned_vein_ids_from_cultivator_lists", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["player"]["veins"] = [Fixtures.player_vein_with()]
		legacy["cultivatorVeins"] = { "owen": ["v1", "gone1", "gone2"], "archie": ["gone3"] }

		assert_true(SaveManager._load_save_dict(legacy)["ok"])
		assert_eq(GameState.state["cultivatorVeins"], { "owen": ["v1"], "archie": [] })
	)

	run_case("new_game_player_model_is_territorial3", func():
		GameState.reset()
		assert_eq(GameState.state["player"]["model"], "territorial3")
	)

	run_case("loading_a_protagonist2_save_migrates_player_model_to_territorial3", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["player"]["model"] = "protagonist2"
		assert_true(SaveManager.import_string(JSON.stringify(legacy))["ok"])
		assert_eq(GameState.state["player"]["model"], "territorial3")
	)

	run_case("loading_a_save_with_another_player_model_leaves_it_alone", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["player"]["model"] = "territorial1"
		assert_true(SaveManager.import_string(JSON.stringify(legacy))["ok"])
		assert_eq(GameState.state["player"]["model"], "territorial1")
	)

	run_case("loading_an_old_save_before_the_home_raid_leaves_archie_unrecruited", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(SaveManager._load_save_dict(legacy)["ok"])
		assert_true(not GameState.state["contacts"]["archie"]["recruited"])
	)

	run_case("new_game_starts_in_a_rented_bedsit_with_no_arrears", func():
		GameState.reset()
		var home: Dictionary = GameState.state["home"]
		assert_eq(home["tier"], "bedsit", "new game tier")
		assert_eq(home["tenure"], "rented", "new game tenure")
		assert_eq(home["arrears"], 0, "new game arrears")
		assert_eq(home["arrearsWeeks"], 0, "new game arrearsWeeks")
	)

	run_case("loading_a_pre_tenure_save_owns_its_tier_or_rents_the_bedsit", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		for key in ["tenure", "arrears", "arrearsWeeks"]:
			legacy["home"].erase(key)
		legacy["home"]["tier"] = "townhouse"

		var filled := SaveManager.backfill_defaults(legacy)
		assert_eq(filled["home"]["tenure"], "owned", "a pre-tenure townhouse save loads as owned")
		assert_eq(filled["home"]["arrears"], 0, "arrears backfills to 0")
		assert_eq(filled["home"]["arrearsWeeks"], 0, "arrearsWeeks backfills to 0")
		assert_eq(SaveManager.backfill_defaults(filled), filled, "re-migrating a migrated save is idempotent")

		legacy["home"]["tier"] = "bedsit"
		assert_eq(SaveManager.backfill_defaults(legacy)["home"]["tenure"], "rented", "a pre-tenure bedsit save loads as rented")
	)

	run_case("save_mutate_load_round_trips_home_tenure_and_arrears_as_ints", func():
		GameState.reset()
		GameState.state["home"]["tier"] = "flat"
		GameState.state["home"]["tenure"] = "owned"
		GameState.state["home"]["arrears"] = 120
		GameState.state["home"]["arrearsWeeks"] = 3
		var original: Dictionary = GameState.deep_copy(GameState.state)

		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"], "save_to_slot should succeed")
		GameState.state["home"]["arrears"] = 0
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"], "load_from_slot should succeed")

		assert_eq(typeof(GameState.state["home"]["arrears"]), TYPE_INT, "arrears restored as int")
		assert_eq(typeof(GameState.state["home"]["arrearsWeeks"]), TYPE_INT, "arrearsWeeks restored as int")
		assert_eq(GameState.state, original, "home tenure/arrears round-trip exactly")

		SaveManager.delete_slot(TEST_SLOT)
	)

	# ── combat-refining 10: combat.locationKey ────────────────────────────

	run_case("save_mutate_load_round_trips_combat_locationKey", func():
		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "camden"
		Combat.start_street_mugging()
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["combat"]["locationKey"] = "soho"
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_eq(GameState.state["combat"]["locationKey"], "camden", "locationKey should be restored")
		assert_eq(GameState.state, original, "the full state tree should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("loading_a_save_without_combat_locationKey_backfills_it_empty", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["combat"]["active"] = true
		legacy["combat"].erase("locationKey")

		var filled := SaveManager.backfill_defaults(legacy)
		assert_eq(filled["combat"]["locationKey"], "", "a save from before locationKey existed should backfill it empty (context-plate path)")
		assert_true(filled["combat"]["active"], "backfilling must not touch existing combat keys")
	)

	# ── combat-refining 12: mid-fight cursor/selection persistence ────────

	run_case("save_load_mid_fight_round_trips_cursor_selection_and_locationKey", func():
		GameState.reset()
		GameState.state["world"]["currentDistrict"] = "camden"
		Rng.set_seed(1)
		Combat.start_street_mugging()
		var combat: Dictionary = GameState.state["combat"]
		for enemy in combat["enemies"]:
			enemy["hp"] = 500
			enemy["hpMax"] = 500
		Combat.player_attack()
		Combat.set_selection("player", 0)
		var original: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"], "save_to_slot should succeed")

		GameState.state["combat"]["turnCursor"] = { "queue": [], "index": 0, "round": 0 }
		GameState.state["combat"]["selection"] = { "type": "enemy", "index": 0 }
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"], "load_from_slot should succeed")

		var loaded: Dictionary = GameState.state["combat"]
		assert_eq(loaded["turnCursor"], original["combat"]["turnCursor"], "the turn cursor is restored")
		assert_eq(typeof(loaded["turnCursor"]["index"]), TYPE_INT, "cursor index comes back an int")
		assert_eq(loaded["selection"], { "type": "player", "index": 0 }, "selection is restored")
		assert_eq(loaded["locationKey"], "camden", "locationKey is restored")
		assert_eq(Combat.project_queue(loaded), Combat.project_queue(original["combat"]), "the projection is the same after load")
		Combat.set_selection("enemy", 0)
		assert_true(Combat.player_attack()["ok"], "the fight resumes from the loaded decision point")
		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("a_mid_fight_save_without_selection_or_cursor_loads_safe_defaults", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["combat"]["active"] = true
		legacy["combat"]["enemies"] = [Fixtures.enemy("Down", 0, 20, true), Fixtures.enemy("Up")]
		legacy["combat"].erase("selection")
		legacy["combat"].erase("turnCursor")
		legacy["combat"].erase("locationKey")

		assert_true(SaveManager.import_string(JSON.stringify(legacy))["ok"], "the legacy save loads")

		var combat: Dictionary = GameState.state["combat"]
		assert_eq(combat["selection"], { "type": "enemy", "index": 1 }, "the backfilled selection clamps off the KO'd enemy")
		assert_eq(combat["turnCursor"], { "queue": [], "index": 0, "round": 0 }, "cursor backfills fresh")
		assert_eq(combat["locationKey"], "", "locationKey backfills empty")
		var projected: Array = Combat.project_queue(combat)
		assert_eq(projected.map(func(o): return o["type"]), ["player", "enemy"], "a valid projection of the living combatants")
	)

	run_case("an_old_save_without_key_member_contacts_backfills_them_and_round_trips", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		for contact_id in ["lusk", "ingram", "fairweather"]:
			legacy["contacts"].erase(contact_id)
		assert_true(SaveManager.import_string(JSON.stringify(legacy))["ok"], "the old save loads")
		for contact_id in ["lusk", "ingram", "fairweather"]:
			assert_true(GameState.state["contacts"].has(contact_id), "%s backfilled" % contact_id)
			assert_true(not GameState.state["contacts"][contact_id]["unlocked"], "%s backfills locked" % contact_id)

		KeyMembers.send("guild", "Noted.")
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"], "save_to_slot should succeed")
		GameState.reset()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"], "load_from_slot should succeed")
		assert_true(GameState.state["contacts"]["ingram"]["unlocked"], "unlock survives the round trip")
		assert_eq(GameState.state["messages"]["ingram"].size(), 2, "intro + message survive the round trip")
	)

	# ── 21-contact-roles-sales-skill ──────────────────────────────────────

	run_case("loading_a_pre_21_save_backfills_salesSkill_and_salesXP_on_an_existing_contact", func():
		GameState.reset()
		# Pre-21 shape: an existing contact's dict had no salesSkill/salesXP
		# keys at all, unlike a wholly-new contact id (covered by
		# _backfill_new_contacts already).
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["contacts"]["archie"]["craftingSkill"] = 3
		legacy["contacts"]["archie"].erase("salesSkill")
		legacy["contacts"]["archie"].erase("salesXP")

		var filled := SaveManager.backfill_defaults(legacy)
		assert_eq(filled["contacts"]["archie"]["salesSkill"], 1, "a save from before salesSkill existed should backfill it to 1")
		assert_eq(filled["contacts"]["archie"]["salesXP"], 0, "a save from before salesXP existed should backfill it to 0")
		assert_eq(filled["contacts"]["archie"]["craftingSkill"], 3, "backfilling the new keys must not touch existing progress")
	)

	run_case("save_mutate_load_round_trips_contact_salesSkill_and_salesXP_as_int", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.award_contact_xp("archie", "sales", 80)
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.state["contacts"]["archie"]["salesSkill"] = 1
		GameState.state["contacts"]["archie"]["salesXP"] = 0
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_eq(GameState.state["contacts"]["archie"]["salesSkill"], 2, "salesSkill should be restored")
		assert_eq(typeof(GameState.state["contacts"]["archie"]["salesSkill"]), TYPE_INT, "salesSkill should be restored as int, not float")
		assert_eq(typeof(GameState.state["contacts"]["archie"]["salesXP"]), TYPE_INT, "salesXP should be restored as int, not float")
		assert_eq(GameState.state, original, "the full state tree (including contacts.archie.salesSkill/salesXP) should deep-equal what was saved")

		SaveManager.delete_slot(TEST_SLOT)
	)

	# ── ticket 64: legacy flat-int inventory migration ───────────────────

	run_case("loading_a_pre_ticket_64_save_migrates_flat_int_inventory_into_the_0_bucket", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		# Pre-ticket-64 shape: player.inventory[recipeKey] was a bare count,
		# not a { tier: count } dict. JSON round-trips every number as a
		# float, same as every other int field this suite exercises.
		legacy["player"]["inventory"] = { "timePearl": 5.0, "enhancementPowder": 0.0, "rewind": 2.0 }

		var result := SaveManager.import_string(JSON.stringify(legacy))
		assert_true(result["ok"], "a legacy flat-int inventory should load without crashing")

		var inventory: Dictionary = GameState.state["player"]["inventory"]
		assert_eq(inventory["timePearl"], { "1": 5 }, "a legacy count migrates into the tier-1 bucket, as an int not a float")
		assert_eq(inventory["enhancementPowder"], { "1": 0 }, "a zero legacy count still migrates to a (empty-valued) '1' bucket rather than being dropped")
		assert_eq(inventory["rewind"], { "1": 2 }, "each recipe key migrates independently")
		assert_eq(Crafting.inventory_qty("timePearl"), 5, "the migrated stock is usable through the normal inventory_qty API")
	)

	run_case("loading_a_save_already_in_the_tiered_inventory_shape_leaves_it_untouched_besides_int_ifying", func():
		GameState.reset()
		var current: Dictionary = GameState.deep_copy(GameState.state)
		current["player"]["inventory"] = { "timePearl": { "1": 3.0, "3": 2.0 }, "enhancementPowder": {}, "rewind": {} }

		var result := SaveManager.import_string(JSON.stringify(current))
		assert_true(result["ok"], "a save already in the tier-bucketed shape should load normally")

		var inventory: Dictionary = GameState.state["player"]["inventory"]
		assert_eq(inventory["timePearl"], { "1": 3, "3": 2 }, "bucket counts restore as ints, tiers untouched")
		assert_eq(Crafting.inventory_qty("timePearl"), 5, "inventory_qty sums both buckets")
	)

	run_case("slot_exists_and_delete_slot", func():
		SaveManager.delete_slot(TEST_SLOT)
		assert_true(not SaveManager.slot_exists(TEST_SLOT), "should not exist before saving")
		GameState.reset()
		SaveManager.save_to_slot(TEST_SLOT)
		assert_true(SaveManager.slot_exists(TEST_SLOT), "should exist after saving")
		SaveManager.delete_slot(TEST_SLOT)
		assert_true(not SaveManager.slot_exists(TEST_SLOT), "should not exist after deleting")
	)

	run_case("slot_summary_is_non_destructive", func():
		SaveManager.delete_slot(TEST_SLOT)
		assert_eq(SaveManager.slot_summary(TEST_SLOT), {}, "empty dict for a slot that doesn't exist")

		GameState.reset()
		GameState.state["world"]["day"] = 7
		GameState.state["player"]["cash"] = 555
		SaveManager.save_to_slot(TEST_SLOT)

		GameState.state["world"]["day"] = 1
		GameState.state["player"]["cash"] = 1
		var summary := SaveManager.slot_summary(TEST_SLOT)

		assert_eq(summary, { "day": 7, "cash": 555 }, "summary reflects the saved slot, not live state")
		assert_eq(GameState.state["world"]["day"], 1, "slot_summary must not touch live GameState.state")
		assert_eq(GameState.state["player"]["cash"], 1, "slot_summary must not touch live GameState.state")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("load_from_empty_slot_fails_cleanly", func():
		SaveManager.delete_slot(TEST_SLOT)
		var result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(not result["ok"], "loading a slot that was never saved should fail, not crash")
	)

	run_case("export_string_reimports_to_an_equal_state", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 777
		GameState.state["flags"]["metArchie"] = true
		GameState.state["barometer"]["economic"] = "crisis"
		var original: Dictionary = GameState.deep_copy(GameState.state)

		var exported := SaveManager.export_string()
		assert_true(exported.length() > 0, "export should produce a non-empty JSON string")

		GameState.reset()
		var result := SaveManager.import_string(exported)

		assert_true(result["ok"], "import should succeed on a just-exported string")
		assert_eq(GameState.state, original, "reimported state should deep-equal the exported state")
	)

	run_case("import_string_rejects_garbage", func():
		var result := SaveManager.import_string("not valid json {{{")
		assert_true(not result["ok"], "garbage input should fail cleanly, not crash")
	)

	run_case("loading_a_v1_save_is_rejected_with_a_clear_message", func():
		var save := { "meta": { "saveVersion": 1 }, "player": { "cash": 55 } }
		var result := SaveManager.import_string(JSON.stringify(save))
		assert_true(not result["ok"], "a v1 save must not half-load under the growth-model schema")
		assert_true(result["reason"].contains("incompatible version"), "the rejection reason should be clear about why")
	)

	run_case("loading_a_save_with_no_meta_saveVersion_is_treated_as_current_and_succeeds", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save.erase("meta")
		var result := SaveManager.import_string(JSON.stringify(save))
		assert_true(result["ok"], "a save with no meta.saveVersion at all should be treated as the current version")
	)

	run_case("loading_a_v4_save_drops_crowbars_and_the_equipped_weapon", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save["meta"]["saveVersion"] = 4
		save["player"]["items"] = [{ "id": "item1", "type": "crowbar" }]
		save["player"]["equipment"] = { "weapon": "item1" }
		var result := SaveManager.import_string(JSON.stringify(save))
		assert_true(result["ok"], "a v4 save should load")
		var player: Dictionary = GameState.state["player"]
		assert_true(not player.has("items"), "held crowbars removed")
		assert_true(not player.get("equipment", {}).has("weapon"), "equipped weapon removed")
		assert_eq(GameState.state["meta"]["saveVersion"], SaveManager.SAVE_VERSION, "stamped current")
	)

	run_case("loading_a_v8_save_returns_hq_kit_overflow_to_inventory", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save["meta"]["saveVersion"] = 8
		save["home"]["guardCount"] = 1
		save["home"]["guardKit"] = { "blast": { "1": 2 }, "shield": { "3": 1 } }
		save["player"]["inventory"] = { "blast": { "1": 1 } }
		var result := SaveManager.import_string(JSON.stringify(save))
		assert_true(result["ok"], "a v8 save should load")
		assert_eq(GameState.state["home"]["guardKit"], { "blast": { "1": 1 }, "shield": { "3": 1 } })
		assert_eq(GameState.state["player"]["inventory"]["blast"]["1"], 2, "overflow unit back in inventory")
	)

	run_case("loading_a_v7_save_grants_a_recruited_james_his_dial_and_leaves_stock_alone", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save["meta"]["saveVersion"] = 7
		save["contacts"]["james"]["recruited"] = true
		save["contacts"]["james"].erase("dial")
		save["contacts"]["james"]["dialCharges"] = 1
		save["player"]["inventory"] = { "timePearl": { "2": 3 } }
		var result := SaveManager.import_string(JSON.stringify(save))
		assert_true(result["ok"], "a v7 save should load")
		var james: Dictionary = GameState.state["contacts"]["james"]
		assert_true(not james.has("dialCharges"), "per-day counter retired")
		assert_eq(james["dial"]["level"], 2)
		assert_eq(james["dial"]["movement"]["archetype"], "recharge")
		assert_eq(james["dial"]["loadedComplications"].size(), 2)
		assert_eq(james["dial"]["currentCharge"], float(james["dial"]["maxCharge"]))
		assert_eq(GameState.state["player"]["inventory"], { "timePearl": { "2": 3 } })
		assert_eq(GameState.state["contacts"]["archie"]["dial"], null)
	)

	run_case("loading_a_v6_save_drops_the_contact_stash_and_gives_combat_recruits_slots", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save["meta"]["saveVersion"] = 6
		save["contacts"]["archie"].erase("loadout")
		save["contacts"]["archie"]["combatStash"] = 2
		save["contacts"]["archie"]["combatStashMax"] = 2
		save["contacts"]["archie"]["combatHealAmount"] = 15
		var result := SaveManager.import_string(JSON.stringify(save))
		assert_true(result["ok"], "a v6 save should load")
		var archie: Dictionary = GameState.state["contacts"]["archie"]
		assert_true(not archie.has("combatStash") and not archie.has("combatHealAmount"), "stash retired")
		assert_eq(archie["loadout"]["slots"], [null, null])
		assert_true(not GameState.state["contacts"]["des"].has("loadout"), "noncombat contacts have no slots")
	)

	run_case("loading_a_v5_save_raises_stock_unarmed_attack_to_7_15", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save["meta"]["saveVersion"] = 5
		save["player"]["attackMin"] = 3
		save["player"]["attackMax"] = 7
		var result := SaveManager.import_string(JSON.stringify(save))
		assert_true(result["ok"], "a v5 save should load")
		assert_eq(GameState.state["player"]["attackMin"], 7, "attackMin raised")
		assert_eq(GameState.state["player"]["attackMax"], 15, "attackMax raised")
	)

	run_case("loading_a_save_at_the_current_version_succeeds", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		assert_eq(save["meta"]["saveVersion"], SaveManager.SAVE_VERSION, "a fresh game state should stamp the current save version")
		var result := SaveManager.import_string(JSON.stringify(save))
		assert_true(result["ok"], "a save at the current version should load")
	)

	run_case("backfill_fills_missing_top_level_keys_from_defaults", func():
		var incomplete := {
			"player": { "cash": 999 },  # customised, should survive
			"world": { "day": 42 },
		}
		var filled := SaveManager.backfill_defaults(incomplete)
		var defaults := GameState.new_game_state()

		assert_eq(filled["player"]["cash"], 999, "an existing top-level key should be kept as-is")
		assert_eq(filled["world"]["day"], 42, "an existing top-level key should be kept as-is")
		assert_eq(filled["flags"], defaults["flags"], "a missing top-level key should be backfilled from defaults")
		assert_eq(filled["combat"], defaults["combat"], "a missing top-level key should be backfilled from defaults")
		assert_true(filled.has("factions") and filled.has("contacts"), "all top-level keys should be present after backfill")
		# collective1-03
		assert_eq(filled["messages"], {}, "an old save missing 'messages' should backfill to {}")
		assert_eq(filled["pendingMessages"], [], "an old save missing 'pendingMessages' should backfill to []")
	)

	# collective1-07: "contacts" is a top-level key that has existed since
	# M0, so a save from before des/nadia/hakim existed has it present but
	# missing the three new ids -- the shallow top-level fill above never
	# fires for it, so this needs its own per-id backfill.
	run_case("backfill_seeds_new_contact_ids_into_an_old_saves_existing_contacts_dict", func():
		var incomplete := {
			"contacts": { "archie": { "relation": 55, "recruited": true } },  # pre-collective1-07 save
		}
		var filled := SaveManager.backfill_defaults(incomplete)
		var defaults := GameState.new_game_state()

		# 21-contact-roles-sales-skill's _backfill_new_contact_keys now fills
		# every OTHER missing key on an existing contact from defaults too
		# (salesSkill/salesXP among them) -- relation/recruited (the keys
		# this legacy fixture actually carries) must still survive untouched.
		var expected_archie: Dictionary = defaults["contacts"]["archie"].duplicate()
		expected_archie["relation"] = 55
		expected_archie["recruited"] = true
		assert_eq(filled["contacts"]["archie"], expected_archie, "an existing contact's own data must survive untouched; every other key backfills from defaults")
		for contact_id in ["des", "nadia", "hakim"]:
			assert_eq(filled["contacts"][contact_id], defaults["contacts"][contact_id], "%s should be seeded from defaults, same as a missing top-level key" % contact_id)
	)

	run_case("backfill_seeds_crafter_specialities_into_an_old_saves_contacts", func():
		var incomplete := {
			"contacts": { "james": { "recruited": true }, "owen": { "recruited": true } },
		}
		var filled := SaveManager.backfill_defaults(incomplete)
		assert_eq(filled["contacts"]["james"]["specialities"], ["time", "life"])
		assert_eq(filled["contacts"]["owen"]["specialities"], ["life"])
		assert_eq(filled["contacts"]["archie"]["specialities"], [])
	)

	# 87-map-slot-index-recycling: "world" is a top-level key that has
	# existed since M0, so a pre-ticket-87 save has it present but missing
	# the new mapSlotFreePool key -- the shallow top-level fill above never
	# fires for it, so this needs its own per-key backfill.
	run_case("backfill_seeds_mapSlotFreePool_into_an_old_saves_existing_world_dict", func():
		var incomplete := {
			"world": { "day": 42, "mapSlotCounters": { "camden": 3 } },  # pre-ticket-87 save
		}
		var filled := SaveManager.backfill_defaults(incomplete)

		assert_eq(filled["world"]["day"], 42, "existing world data must survive untouched")
		assert_eq(filled["world"]["mapSlotCounters"], { "camden": 3 }, "existing world data must survive untouched")
		assert_eq(filled["world"]["mapSlotFreePool"], {}, "the new key should be seeded from defaults, same as a missing top-level key")
	)

	# dial-device ticket 01: "player" is a top-level key that has existed
	# since M0, so a pre-Dial save has it present but missing the new dial
	# key -- the shallow top-level fill above never fires for it, same
	# reasoning as the mapSlotFreePool case above.
	run_case("backfill_seeds_dial_into_an_old_saves_existing_player_dict", func():
		var incomplete := {
			"player": {
				"cash": 999,
				"devicesInProgress": [{ "id": "d1", "type": "timeDevice", "progress": 40.0 }],
				"devicesCompleted": [{ "id": "d2", "type": "rewindDevice", "level": 2, "xp": 60, "chargesPerDay": 2, "chargesUsedToday": 0, "lastResetDay": 3 }],
				"equipment": { "weapon": "crowbar", "device": "d2" },
			},
			"flags": { "craftingUnlocked": true, "enhancementUnlocked": true },
		}
		var filled := SaveManager.backfill_defaults(incomplete)

		assert_eq(filled["player"]["cash"], 999, "existing player data must survive untouched")
		assert_eq(filled["player"]["dial"], null, "the new key should be seeded from defaults, same as a missing top-level key")
		assert_eq(filled["player"]["devicesInProgress"], [{ "id": "d1", "type": "timeDevice", "progress": 40.0 }], "pre-Dial device progress must be left untouched, not converted")
		assert_eq(filled["player"]["devicesCompleted"], [{ "id": "d2", "type": "rewindDevice", "level": 2, "xp": 60, "chargesPerDay": 2, "chargesUsedToday": 0, "lastResetDay": 3 }], "pre-Dial completed devices must be left untouched, not converted")
		assert_eq(filled["player"]["equipment"], { "weapon": "crowbar", "device": "d2" }, "pre-Dial equipment.device must be left untouched, not converted")
		assert_eq(filled["flags"]["craftingUnlocked"], true, "craftingUnlocked must survive the dial backfill untouched")
		assert_eq(filled["flags"]["enhancementUnlocked"], true, "enhancementUnlocked must survive the dial backfill untouched")
	)

	# dial-device ticket 01, acceptance: a save with populated
	# devicesInProgress/devicesCompleted/equipment.device and no player.dial
	# loads without error into a null-Dial state, craftingUnlocked/
	# enhancementUnlocked intact. Full import_string round trip (not just
	# backfill_defaults) to exercise the real load path.
	run_case("loading_a_pre_dial_save_migrates_into_a_null_dial_state_with_old_unlocks_intact", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["player"].erase("dial")
		legacy["player"]["devicesInProgress"] = [{ "id": "d1", "type": "timeDevice", "progress": 40.0 }]
		legacy["player"]["devicesCompleted"] = [{ "id": "d2", "type": "rewindDevice", "level": 2, "xp": 60, "chargesPerDay": 2, "chargesUsedToday": 0, "lastResetDay": 3 }]
		legacy["player"]["equipment"] = { "weapon": "crowbar", "device": "d2" }
		legacy["flags"]["craftingUnlocked"] = true
		legacy["flags"]["enhancementUnlocked"] = true

		var result := SaveManager.import_string(JSON.stringify(legacy))
		assert_true(result["ok"], "a pre-Dial save should load without error")

		var player: Dictionary = GameState.state["player"]
		assert_eq(player["dial"], null, "a pre-Dial save should load into a null-Dial state")
		assert_eq(player["devicesInProgress"], [{ "id": "d1", "type": "timeDevice", "progress": 40.0 }], "old device progress should survive the migration untouched")
		assert_eq(player["devicesCompleted"][0]["id"], "d2", "old completed devices should survive the migration untouched")
		assert_eq(player["equipment"], { "weapon": "crowbar", "device": "d2" }, "old equipment.device should survive the migration untouched")
		assert_true(GameState.state["flags"]["craftingUnlocked"], "craftingUnlocked should stay true across the migration")
		assert_true(GameState.state["flags"]["enhancementUnlocked"], "enhancementUnlocked should stay true across the migration")
	)

	# ticket 22: "player" has existed since M0, so a pre-stash save has it
	# present but missing the new stash key -- same shallow-fill gap the
	# dial cases above cover.
	run_case("backfill_seeds_an_empty_stash_into_an_old_saves_existing_player_dict", func():
		var incomplete := {
			"player": {
				"cash": 999,
				"orichalchum": { "time": 40 },
			},
		}
		var filled := SaveManager.backfill_defaults(incomplete)

		assert_eq(filled["player"]["cash"], 999, "existing player data must survive untouched")
		assert_eq(filled["player"]["orichalchum"], { "time": 40 }, "existing player data must survive untouched")
		assert_eq(filled["player"]["stash"], { "orichalchum": {}, "inventory": {} }, "the new key should be seeded from defaults, same as a missing top-level key")
	)

	run_case("loading_a_pre_stash_save_migrates_into_an_empty_stash_with_existing_pools_intact", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["player"].erase("stash")
		legacy["player"]["orichalchum"]["time"] = 40
		legacy["player"]["inventory"]["timePearl"] = { "3": 2 }

		var result := SaveManager.import_string(JSON.stringify(legacy))
		assert_true(result["ok"], "a pre-stash save should load without error")

		var player: Dictionary = GameState.state["player"]
		assert_eq(player["stash"], { "orichalchum": {}, "inventory": {} }, "a pre-stash save should load into an empty stash")
		assert_eq(player["orichalchum"]["time"], 40, "the shared ore pool should survive the migration untouched")
		assert_eq(player["inventory"]["timePearl"], { "3": 2 }, "the shared crafted-item pool should survive the migration untouched")
	)

	run_case("loading_a_save_with_stash_stock_restores_ints_and_migrates_legacy_tier_shape", func():
		GameState.reset()
		var legacy: Dictionary = GameState.deep_copy(GameState.state)
		legacy["player"]["stash"]["orichalchum"] = { "time": 7.0 }
		# A stash JSON round trip int-restores/tier-migrates the same way
		# player.inventory itself does -- exercised directly here since a
		# pre-stash save can never actually contain stash.inventory in the
		# legacy bare-number shape (the key didn't exist yet to migrate).
		legacy["player"]["stash"]["inventory"] = { "timePearl": 3.0 }

		var result := SaveManager.import_string(JSON.stringify(legacy))
		assert_true(result["ok"], "a save with stash stock should load without error")

		var stash: Dictionary = GameState.state["player"]["stash"]
		assert_eq(stash["orichalchum"]["time"], 7, "stash ore qty comes back as an int, not a float")
		assert_eq(stash["inventory"]["timePearl"], { "1": 3 }, "a bare-number stash inventory entry migrates into the tier-1 bucket, same as player.inventory")
	)

	run_case("loading_a_save_with_a_retired_currentScreen_lands_on_phone_home", func():
		for retired_id in ["home", "you", "bag", "inventory"]:
			GameState.reset()
			GameState.state["currentScreen"] = retired_id
			GameState.state["phoneNav"]["app"] = "messages"
			GameState.state["phoneNav"]["selectedAxis"] = "economic"
			GameState.state["phoneNav"]["confirmingNewGame"] = true
			var save_result := SaveManager.save_to_slot(TEST_SLOT)
			assert_true(save_result["ok"], "save_to_slot should succeed")

			GameState.reset()
			var load_result := SaveManager.load_from_slot(TEST_SLOT)
			assert_true(load_result["ok"], "load_from_slot should succeed")

			assert_eq(GameState.state["currentScreen"], "phone", "%s should remap to phone on load" % retired_id)
			assert_eq(GameState.state["phoneNav"]["app"], "home", "phoneNav should reset to the grid, not whatever app was last open")
			assert_eq(GameState.state["phoneNav"]["selectedAxis"], null, "phoneNav.selectedAxis should reset")
			assert_eq(GameState.state["phoneNav"]["confirmingNewGame"], false, "phoneNav.confirmingNewGame should reset")

			SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("loading_a_save_with_a_live_currentScreen_leaves_it_untouched", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.reset()
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_eq(GameState.state["currentScreen"], "hq", "a non-retired screen id should pass through unchanged")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("loading_a_save_open_on_the_retired_notes_app_reopens_todo", func():
		GameState.reset()
		GameState.state["currentScreen"] = "phone"
		GameState.state["phoneNav"]["app"] = "notes"
		var save_result := SaveManager.save_to_slot(TEST_SLOT)
		assert_true(save_result["ok"], "save_to_slot should succeed")

		GameState.reset()
		var load_result := SaveManager.load_from_slot(TEST_SLOT)
		assert_true(load_result["ok"], "load_from_slot should succeed")

		assert_eq(GameState.state["phoneNav"]["app"], "todo", "the old notes id should remap to todo")
		assert_true(PhoneAppRegistry.REGISTRY.has(GameState.state["phoneNav"]["app"]), "the remapped id must be a live app")

		SaveManager.delete_slot(TEST_SLOT)
	)

	run_case("autosave_rotates_across_3_slots_then_overwrites_the_oldest", func():
		for i in range(SaveManager.AUTOSAVE_COUNT):
			if FileAccess.file_exists(SaveManager.autosave_path(i)):
				DirAccess.remove_absolute(SaveManager.autosave_path(i))

		GameState.reset()
		GameState.state["world"]["day"] = 1
		SaveManager.autosave()
		GameState.state["world"]["day"] = 2
		SaveManager.autosave()
		GameState.state["world"]["day"] = 3
		SaveManager.autosave()

		for i in range(SaveManager.AUTOSAVE_COUNT):
			assert_true(FileAccess.file_exists(SaveManager.autosave_path(i)), "slot %d should be filled after 3 autosaves" % i)

		# 4th autosave must land in one of the 3 rotation files (overwriting
		# the oldest), not create a 4th file.
		GameState.state["world"]["day"] = 4
		SaveManager.autosave()
		var day_4_count := 0
		for i in range(SaveManager.AUTOSAVE_COUNT):
			var file := FileAccess.open(SaveManager.autosave_path(i), FileAccess.READ)
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed["world"]["day"] == 4:
				day_4_count += 1
		assert_eq(day_4_count, 1, "exactly one of the 3 rotation slots should now hold the 4th autosave")

		for i in range(SaveManager.AUTOSAVE_COUNT):
			if FileAccess.file_exists(SaveManager.autosave_path(i)):
				DirAccess.remove_absolute(SaveManager.autosave_path(i))
	)
