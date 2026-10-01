extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# R§3.1 "Network intel menu": the handler's priced intel products for the
# player, their relation pricing and gates, and the timers they set.


static func _fresh() -> void:
	GameState.reset()
	GameState.state["shares"] = Shares.new_state()
	GameState.state["world"]["sites"] = []
	GameState.state["player"]["veins"] = []
	GameState.state["player"]["cash"] = 100000


static func _market_fresh(day: int) -> void:
	_fresh()
	GameState.state["world"]["day"] = day
	GameState.state["market"] = Market.new_state(true)
	GameState.state["market"]["startedDay"] = 1


static func _network_relation(value: int) -> void:
	GameState.state["factions"]["network"]["relation"] = value


static func _product(product_id: String) -> Dictionary:
	return GameData.NETWORK_MENU["products"][product_id]


static func _line(key: String) -> String:
	return GameData.NETWORK_MENU["lines"][key]


static func _last_handler_text() -> String:
	var thread: Array = GameState.state["messages"].get(NetworkHandler.CONTACT_ID, [])
	return thread.back()["text"] if not thread.is_empty() else ""


static func _player_relation(faction_id: String) -> int:
	return int(GameState.state["factions"][faction_id]["relation"])


# A funded faction under pressure at `relation` with the player, already
# warned about that band, so its next escalation is a move.
static func _move_ready(faction_id: String, relation: int) -> void:
	GameState.state["factions"][faction_id]["resources"] = 10000
	Factions.adjust_player_relation(faction_id, relation - _player_relation(faction_id))
	var snapshots: Dictionary = GameState.state["factionPressure"]["snapshots"]
	if not snapshots.has(faction_id):
		snapshots[faction_id] = {}
	snapshots[faction_id]["player"] = { "threat": 2.0, "dependence": 0.0, "delta": -2.0 }
	FactionAI._target_entry(faction_id, "player")["warnedBand"] = FactionAI.band(faction_id, "player")


# Asserts the purchase went through at the price quoted beforehand.
func _assert_charged(result: Dictionary, price: int) -> void:
	assert_true(result["ok"], "purchase goes through: %s" % result.get("reason", ""))
	assert_eq(int(result["price"]), price)
	assert_eq(int(GameState.state["player"]["cash"]), 100000 - price, "cash charged")


func run() -> void:
	run_case("raid_intel_texts_the_raid_a_faction_plans_on_the_player", func():
		_fresh()
		Fixtures.seed_vein("pv", 60)
		_move_ready("firm", -50)
		var day: int = GameState.state["world"]["day"]
		var price := NetworkHandler.product_price(NetworkHandler.PRODUCT_RAID_INTEL)
		var result := NetworkHandler.buy_raid_intel()
		_assert_charged(result, price)
		var raids: Array = result["plans"].filter(func(p: Dictionary) -> bool: return p["factionId"] == "firm" and p["move"] == FactionAI.MOVE_VEIN_RAID)
		assert_eq(raids.size(), 1, "the Firm's raid is listed")
		assert_eq(int(raids[0]["day"]), day + 1)
		var text := _last_handler_text()
		assert_true(text.begins_with(_line("raidIntel")), text)
		var label: String = GameData.NETWORK_MENU["moveLabels"]["veinRaid"] % GameData.DISTRICTS["shoreditch"]["name"]
		assert_true(text.contains(_line("planLine") % [GameData.FACTIONS["firm"]["name"], label, _line("tomorrow")]), text)
		GameState.state["world"]["day"] = day + 1
		FactionAI.apply_escalation()
		assert_eq(GameState.state["factionEscalation"]["queuedRaids"].size(), 1, "the forecast move is the one made")
	)

	run_case("raid_intel_forecasts_a_warning_before_a_new_band", func():
		_fresh()
		Fixtures.seed_vein("pv", 60)
		_move_ready("firm", -50)
		FactionAI._target_entry("firm", "player")["warnedBand"] = FactionAI.BAND_MARKET
		var plans: Array = NetworkHandler.buy_raid_intel()["plans"]
		assert_eq(plans.size(), 1)
		assert_eq(plans[0]["move"], FactionAI.PLAN_WARNING)
	)

	run_case("raid_intel_with_nothing_planned_says_so", func():
		_fresh()
		var result := NetworkHandler.buy_raid_intel()
		assert_true(result["ok"])
		assert_eq(result["plans"], [])
		assert_eq(_last_handler_text(), _line("raidIntelNone"))
	)

	run_case("a_move_on_cooldown_is_forecast_for_the_day_the_cooldown_ends", func():
		_fresh()
		Fixtures.seed_vein("pv", 60)
		_move_ready("firm", -50)
		var day: int = GameState.state["world"]["day"]
		FactionAI._target_entry("firm", "player")["lastMoveDay"] = day
		var plans := FactionAI.planned_moves(7).filter(func(p: Dictionary) -> bool: return p["targetId"] == Shares.PLAYER)
		assert_eq(int(plans[0]["day"]), day + int(GameData.FACTION_ESCALATION["cooldownDays"]))
		assert_true(FactionAI.planned_moves(0).is_empty(), "outside the horizon")
	)

	run_case("market_intel_texts_a_planned_flood", func():
		_market_fresh(5)
		Shares.record_ore("player", "time", 100)
		_move_ready("firm", -35)
		GameState.state["factions"]["firm"]["holdings"]["ore"]["time"] = 200
		var price := NetworkHandler.product_price(NetworkHandler.PRODUCT_MARKET_INTEL)
		var result := NetworkHandler.buy_market_intel()
		_assert_charged(result, price)
		var floods: Array = result["plans"].filter(func(p: Dictionary) -> bool: return p["factionId"] == "firm" and p["move"] == FactionAI.MOVE_FLOOD)
		assert_eq(floods.size(), 1, "the Firm's flood is listed")
		var label: String = GameData.NETWORK_MENU["moveLabels"]["flood"] % GameData.ORE_TYPES["time"]["name"]
		var line := _line("marketLine") % [GameData.FACTIONS["firm"]["name"], label, _line("you"), _line("tomorrow")]
		assert_true(_last_handler_text().contains(line), _last_handler_text())
		for plan in result["plans"]:
			assert_true(GameData.NETWORK_MENU["marketMoves"].has(plan["move"]), "only buys and dumps: %s" % plan["move"])
	)

	run_case("raid_warnings_run_for_their_days_and_text_when_a_raid_is_queued", func():
		_fresh()
		Fixtures.seed_vein("pv", 60)
		var day: int = GameState.state["world"]["day"]
		var price := NetworkHandler.product_price(NetworkHandler.PRODUCT_RAID_WARNINGS)
		_assert_charged(NetworkHandler.buy_raid_warnings(), price)
		var days := int(_product(NetworkHandler.PRODUCT_RAID_WARNINGS)["days"])
		assert_eq(Intel.raid_warnings_until(Shares.PLAYER), day + days)
		_move_ready("firm", -50)
		FactionAI.apply_escalation()
		assert_eq(_last_handler_text(), _line("raidWarning") % [GameData.FACTIONS["firm"]["name"], GameData.DISTRICTS["shoreditch"]["name"]])
	)

	run_case("no_raid_warning_once_the_subscription_lapses", func():
		_fresh()
		Fixtures.seed_vein("pv", 60)
		NetworkHandler.buy_raid_warnings()
		GameState.state["world"]["day"] = Intel.raid_warnings_until(Shares.PLAYER) + 1
		var before := _last_handler_text()
		_move_ready("firm", -50)
		FactionAI.apply_escalation()
		assert_eq(GameState.state["factionEscalation"]["queuedRaids"].size(), 1)
		assert_eq(_last_handler_text(), before, "no warning text")
	)

	run_case("an_intel_boost_raises_the_players_meter_on_the_target", func():
		_fresh()
		var price := NetworkHandler.product_price(NetworkHandler.PRODUCT_BOOST)
		_assert_charged(NetworkHandler.buy_intel_boost("firm"), price)
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), int(_product(NetworkHandler.PRODUCT_BOOST)["amount"]))
		assert_eq(_last_handler_text(), _line("boost") % GameData.FACTIONS["firm"]["name"])
		assert_true(not NetworkHandler.buy_intel_boost("network")["ok"], "not on the Network itself")
	)

	run_case("privacy_runs_for_its_days_and_extends_when_rebought", func():
		_fresh()
		_network_relation(50)
		var day: int = GameState.state["world"]["day"]
		var days := int(_product(NetworkHandler.PRODUCT_PRIVACY)["days"])
		var price := NetworkHandler.product_price(NetworkHandler.PRODUCT_PRIVACY)
		_assert_charged(NetworkHandler.buy_privacy(), price)
		assert_true(Intel.privacy_active(Shares.PLAYER))
		assert_eq(Intel.privacy_until(Shares.PLAYER), day + days)
		NetworkHandler.buy_privacy()
		assert_eq(Intel.privacy_until(Shares.PLAYER), day + 2 * days, "extends the running timer")
		GameState.state["world"]["day"] = day + 2 * days + 1
		assert_true(not Intel.privacy_active(Shares.PLAYER), "lapsed")
	)

	run_case("disinformation_sets_the_mode_on_the_rival_for_its_days", func():
		_fresh()
		_network_relation(50)
		var day: int = GameState.state["world"]["day"]
		var days := int(_product(NetworkHandler.PRODUCT_DISINFORMATION)["days"])
		var price := NetworkHandler.product_price(NetworkHandler.PRODUCT_DISINFORMATION)
		_assert_charged(NetworkHandler.buy_disinformation("firm", Intel.DISINFO_INVERTED), price)
		assert_eq(Intel.disinformation("firm", Shares.PLAYER), Intel.DISINFO_INVERTED)
		assert_eq(Intel.disinformation("guild", Shares.PLAYER), "", "only the named rival")
		assert_eq(_last_handler_text(), _line("inverted") % [GameData.FACTIONS["firm"]["name"], days])
		NetworkHandler.buy_disinformation("firm", Intel.DISINFO_OVERESTIMATE)
		assert_eq(Intel.disinformation("firm", Shares.PLAYER), Intel.DISINFO_OVERESTIMATE, "a new mode replaces the old")
		assert_eq(Intel.disinformation_until("firm", Shares.PLAYER), day + days, "from today")
		GameState.state["world"]["day"] = day + days + 1
		assert_eq(Intel.disinformation("firm", Shares.PLAYER), "", "lapsed")
		assert_true(not NetworkHandler.buy_disinformation("firm", "bogus")["ok"])
	)

	run_case("intel_reduction_lowers_the_rivals_meter_on_the_player", func():
		_fresh()
		GameState.state["intel"]["guild"][Shares.PLAYER] = 50
		var price := NetworkHandler.product_price(NetworkHandler.PRODUCT_REDUCTION)
		_assert_charged(NetworkHandler.buy_intel_reduction("guild"), price)
		assert_eq(Intel.meter("guild", Shares.PLAYER), 50 - int(_product(NetworkHandler.PRODUCT_REDUCTION)["amount"]))
		NetworkHandler.buy_intel_reduction("guild")
		NetworkHandler.buy_intel_reduction("guild")
		assert_eq(Intel.meter("guild", Shares.PLAYER), 0, "floored at 0")
	)

	run_case("prices_fall_with_network_relation_and_rise_below_zero", func():
		_fresh()
		var base := int(_product(NetworkHandler.PRODUCT_RAID_INTEL)["price"])
		_network_relation(0)
		assert_eq(NetworkHandler.product_price(NetworkHandler.PRODUCT_RAID_INTEL), base)
		_network_relation(60)
		var friendly := NetworkHandler.product_price(NetworkHandler.PRODUCT_RAID_INTEL)
		_network_relation(-60)
		var hostile := NetworkHandler.product_price(NetworkHandler.PRODUCT_RAID_INTEL)
		assert_true(friendly < base and base < hostile, "%d < %d < %d" % [friendly, base, hostile])
		var mod := float(GameData.NETWORK_MENU["relationPriceMod"])
		assert_eq(friendly, roundi(base * (1.0 - 60 * mod)))
	)

	run_case("a_gated_product_is_refused_below_its_relation_and_charges_nothing", func():
		_fresh()
		var gate := NetworkHandler.product_min_relation(NetworkHandler.PRODUCT_DISINFORMATION)
		_network_relation(gate - 1)
		assert_true(not NetworkHandler.product_open(NetworkHandler.PRODUCT_DISINFORMATION))
		var result := NetworkHandler.buy_disinformation("firm", Intel.DISINFO_INVERTED)
		assert_true(not result["ok"])
		assert_eq(result["reason"], GameData.NETWORK_MENU["gatedReason"])
		assert_eq(int(GameState.state["player"]["cash"]), 100000, "nothing charged")
		assert_eq(Intel.disinformation("firm", Shares.PLAYER), "")
		_network_relation(gate)
		assert_true(NetworkHandler.buy_disinformation("firm", Intel.DISINFO_INVERTED)["ok"], "open at the gate")
	)

	run_case("a_purchase_without_the_cash_is_refused", func():
		_fresh()
		GameState.state["player"]["cash"] = NetworkHandler.product_price(NetworkHandler.PRODUCT_BOOST) - 1
		assert_true(not NetworkHandler.buy_intel_boost("firm")["ok"])
		assert_eq(Intel.meter(Shares.PLAYER, "firm"), 0)
	)

	run_case("timers_survive_save_load_and_an_old_save_backfills_them", func():
		_fresh()
		_network_relation(50)
		NetworkHandler.buy_privacy()
		NetworkHandler.buy_raid_warnings()
		NetworkHandler.buy_disinformation("firm", Intel.DISINFO_OVERESTIMATE)
		var saved: Dictionary = GameState.deep_copy(GameState.state["intelTimers"])
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["intelTimers"], saved)
		assert_true(GameState.state["intelTimers"]["privacy"][Shares.PLAYER] is int, "loaded as int")
		assert_true(GameState.state["intelTimers"]["disinformation"][0]["untilDay"] is int, "loaded as int")
		GameState.state.erase("intelTimers")
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["intelTimers"], Intel.new_timers())
	)

	run_case("the_rollover_drops_lapsed_timers", func():
		_fresh()
		_network_relation(50)
		NetworkHandler.buy_privacy()
		NetworkHandler.buy_disinformation("firm", Intel.DISINFO_INVERTED)
		GameState.state["world"]["day"] = Intel.privacy_until(Shares.PLAYER) + 1
		Intel.expire_timers()
		assert_eq(GameState.state["intelTimers"], Intel.new_timers())
	)
