extends "res://tests/test_base.gd"

const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")
const Fixtures := preload("res://tests/support/fixtures.gd")


func run() -> void:
	run_case("daily_tick_stores_resulting_day_and_actual_reynards_totals", func():
		GameState.reset()
		GameState.state["world"]["day"] = 2
		GameState.state["player"]["cash"] = 120
		TimeSystem.daily_tick()
		var account: Dictionary = MorningAccountsSystem.latest()
		assert_eq(account["day"], 2)
		assert_eq(account["openingBalance"], 120)
		assert_eq(account["closingBalance"], 70)
		assert_eq(account["income"], 0)
		assert_eq(account["expenses"], 50)
	)

	run_case("account_uses_actual_bank_entries_for_income_and_expense", func():
		GameState.reset()
		var context := MorningAccountsSystem.begin_rollover()
		GameState.state["player"]["cash"] += 120
		Bank.record(120, "Contract sale")
		GameState.state["player"]["cash"] -= 30
		Bank.record(-30, "Supplies")
		MorningAccountsSystem.record_sale(context, "time calc contract", 12)
		var account := MorningAccountsSystem.finish_rollover(context)
		assert_eq(account["income"], 120)
		assert_eq(account["expenses"], 30)
		assert_eq(account["closingBalance"], 130)
		assert_eq(account["sales"]["time calc contract"], 12)
	)

	run_case("room_processing_records_stock_production_and_shortfall", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "lab")
		GameState.state["flags"]["craftingUnlocked"] = true
		GameState.state["labThresholds"]["timePearl"] = 2
		GameState.state["player"]["orichalchum"]["time"] = 10000
		var context := MorningAccountsSystem.begin_rollover()
		Rng.set_seed(7)
		Rooms.process_lab()
		MorningAccountsSystem.capture_lab(context)
		var account := MorningAccountsSystem.finish_rollover(context)
		assert_eq(account["production"]["items"]["timePearl"], 2)
		assert_true(account["oreMovement"]["time"] < 0)
		assert_true(account["exceptions"].is_empty())

		GameState.state["labThresholds"]["timePearl"] = 5
		GameState.state["player"]["orichalchum"]["time"] = 0
		context = MorningAccountsSystem.begin_rollover()
		Rooms.process_lab()
		MorningAccountsSystem.capture_lab(context)
		account = MorningAccountsSystem.finish_rollover(context)
		assert_eq(account["exceptions"][0]["kind"], "productionShortfall")
	)

	run_case("vein_station_output_and_losses_are_recorded_separately", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "veinStation")
		var vein := {
			"id": "v1", "oreType": "time", "growth": 95, "security": "none",
			"alarmUpgrades": [], "location": "Test Alley", "claimedOnDay": 1,
			"district": "shoreditch", "siteId": null, "rampantDays": 0,
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		GameState.state["player"]["veins"] = [vein]
		GameState.state["veinStationVeins"] = ["v1"]
		GameState.state["veinStationTargets"] = { "v1": 70 }
		var context := MorningAccountsSystem.begin_rollover()
		Rooms.process_vein_station()
		MorningAccountsSystem.capture_vein_station(context)
		GameState.state["player"]["orichalchum"]["time"] -= 3
		GameState.state["player"]["veins"] = []
		MorningAccountsSystem.capture_losses(context, "Raid")
		var account := MorningAccountsSystem.finish_rollover(context)
		assert_eq(account["production"]["ore"]["time"], 9)
		assert_eq(account["losses"]["ore"]["time"], 3)
		assert_eq(account["losses"]["veins"], 1)
		assert_eq(account["oreMovement"]["time"], 6)
	)

	run_case("attention_is_current_unresolved_alarms_and_unread_messages", func():
		GameState.reset()
		GameState.state["home"]["pendingRaid"] = true
		Messages.append("archie", "them", "Call me.")
		var items := MorningAccountsSystem.attention_items()
		assert_eq(items.size(), 2)
		assert_eq(items[0]["kind"], "alarm")
		assert_eq(items[1]["kind"], "message")
		MorningAccountsSystem.open_bank()
		assert_eq(GameState.state["phoneNav"]["app"], "bank")
		MorningAccountsSystem.open_attention(items[0])
		assert_eq(GameState.state["phoneNav"]["app"], "alarms")
		MorningAccountsSystem.open_attention(items[1])
		assert_eq(GameState.state["phoneNav"]["app"], "messages")
		assert_eq(GameState.state["phoneNav"]["selectedContactId"], "archie")
	)

	run_case("attention_lists_live_development_eligible_veins_with_raid_exposure_but_never_capped_ones", func():
		GameState.reset()
		Fixtures.seed_vein("eligible", 95)  # fair cap 3, level 1: eligible
		var capped := Fixtures.seed_vein("capped", 95)
		capped["level"] = 3  # fair cap 3: already maxed, never listed
		var items := MorningAccountsSystem.attention_items()
		var development_items: Array = items.filter(func(i: Dictionary): return i["kind"] == "development")
		assert_eq(development_items.size(), 1)
		assert_eq(development_items[0]["veinId"], "eligible")

		var label := MorningAccountsSystem.attention_label(development_items[0])
		assert_true(label.find("ready to develop") != -1)
		assert_true(label.find("raid exposure %d" % Cultivating.combined_magnitude(GameState.state["player"]["veins"][0])) != -1)

		MorningAccountsSystem.open_attention(development_items[0])
		assert_eq(GameState.state["currentScreen"], "map")
		assert_eq(GameState.state["mapNav"]["selectedSiteId"], "site_eligible")

		# Harvesting below the threshold live drops the item immediately -- no stale snapshot.
		Cultivating.prune("eligible", GameData.VEIN_GROWTH["pruneHardDepth"])
		items = MorningAccountsSystem.attention_items()
		assert_true(items.filter(func(i: Dictionary): return i["kind"] == "development").is_empty())
	)

	run_case("quiet_operations_are_omitted", func():
		GameState.reset()
		var account := MorningAccountsSystem.finish_rollover(MorningAccountsSystem.begin_rollover())
		assert_true(not MorningAccountsSystem.has_operations(account))
	)

	run_case("auto_open_is_once_only_and_load_does_not_duplicate_or_misattribute", func():
		GameState.reset()
		GameState.state["world"]["day"] = 4
		var account := MorningAccountsSystem.finish_rollover(MorningAccountsSystem.begin_rollover())
		var saved := SaveManager.export_string()
		assert_true(MorningAccountsSystem.open_after_transition(4))
		assert_eq(GameState.state["phoneNav"]["app"], "bizbrief")
		assert_true(not MorningAccountsSystem.open_after_transition(4))
		assert_true(SaveManager.import_string(saved)["ok"])
		assert_eq(MorningAccountsSystem.latest()["day"], account["day"])
		assert_eq(GameState.state["phoneNav"]["app"], "home", "load itself never auto-opens")
		assert_true(not MorningAccountsSystem.open_after_transition(5), "another day cannot consume a stale account")
	)
