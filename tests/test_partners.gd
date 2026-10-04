extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")


static func _cfg() -> Dictionary:
	return GameData.PARTNERS


static func _relation(faction_id: String) -> int:
	return int(GameState.state["factions"][faction_id]["relation"])


static func _make_player_partner(faction_id: String, relation: int) -> void:
	GameState.state["factions"][faction_id]["relation"] = relation
	GameState.state["factionStances"]["player"][faction_id]["stance"] = FactionAI.PARTNER


static func _set_pair(faction_a: String, faction_b: String, stance: String, relation: int) -> void:
	GameState.state["factionStances"]["pairs"][FactionAI.pair_key(faction_a, faction_b)]["stance"] = stance
	GameState.state["factionRelations"][faction_a][faction_b] = relation
	GameState.state["factionRelations"][faction_b][faction_a] = relation


static func _queue_ask(payload: Dictionary) -> Dictionary:
	payload["expiresDay"] = int(GameState.state["world"]["day"]) + int(_cfg()["trouble"]["expiryDays"])
	KeyMembers.send(payload["factionId"], Partners.trouble_text(payload), Partners.TROUBLE_KIND, payload)
	return Partners.pending_for(payload["factionId"])[0]


# Hands the player what an ask needs: cash, or the goods it wants.
static func _equip_player(payload: Dictionary) -> void:
	GameState.state["player"]["cash"] = 1000000
	if payload["ask"] != Partners.ASK_GOODS:
		return
	if payload["kind"] == "ore":
		GameState.state["player"]["orichalchum"][payload["type"]] = int(payload["qty"])
	else:
		Crafting.inventory_add(payload["type"], 1, int(payload["qty"]))


# The Firm Hostile to the player with a vein to aim at, past its first
# warning, so its next move is a real one.
static func _firm_bears_down() -> void:
	Fixtures.seed_vein("v1", 40, "physics")
	GameState.state["factions"]["firm"]["relation"] = -80
	GameState.state["factions"]["firm"]["resources"] = 100000
	GameState.state["factionStances"]["player"]["firm"]["stance"] = FactionAI.HOSTILE
	GameState.state["factionEscalation"]["targets"]["firm"] = { "player": { "warnedBand": FactionAI.BAND_RAID, "lastMoveDay": -1 } }


static func _with_trouble_chance(chance: float, fn: Callable) -> void:
	var cfg: Dictionary = _cfg()["trouble"]
	var saved: float = cfg["issueChance"]
	var saved_cash: int = cfg["cashBelow"]
	cfg["issueChance"] = chance
	cfg["cashBelow"] = 1000000000
	fn.call()
	cfg["issueChance"] = saved
	cfg["cashBelow"] = saved_cash


func run() -> void:
	run_case("a_price_favour_discounts_the_partner_shop_and_costs_relation", func():
		GameState.reset()
		_make_player_partner("guild", 60)
		var cfg: Dictionary = _cfg()["priceFavour"]
		var result := Partners.ask_price_favour("guild")
		assert_true(result["ok"], "a partner grants it")
		assert_eq(_relation("guild"), 60 - int(cfg["relationCost"]), "it costs relation")
		var discounted := Economy.get_faction_buy_price("guild", "ore", "time")
		var favours: Dictionary = GameState.state["partners"]["priceFavours"]
		var until: int = favours["guild"]
		favours["guild"] = -1
		var full := Economy.get_faction_buy_price("guild", "ore", "time")
		favours["guild"] = until
		assert_almost_eq(float(discounted), full * (1.0 - float(cfg["discount"])), 1.0, "the shop price drops by the discount")
		assert_true(discounted < full)
		assert_true(not Partners.ask_price_favour("guild")["ok"], "one at a time")
		GameState.state["world"]["day"] += int(cfg["days"]) + 1
		assert_eq(Economy.get_faction_buy_price("guild", "ore", "time"), full, "the partner rate lapses")
		assert_true(not Partners.ask_price_favour("guild")["ok"], "still cooling down")
		GameState.state["world"]["day"] += int(cfg["cooldownDays"])
		assert_true(Partners.ask_price_favour("guild")["ok"], "askable again after the cooldown")
		assert_true(not Partners.ask_price_favour("firm")["ok"], "a non-partner refuses")
	)

	run_case("the_rollover_sends_a_trouble_ask_and_accepting_raises_relation", func():
		GameState.reset()
		_make_player_partner("guild", 60)
		_with_trouble_chance(1.0, func(): TimeSystem.daily_tick())
		var pending := Partners.pending_for("guild")
		assert_eq(pending.size(), 1, "a partner in trouble asks")
		var entry: Dictionary = pending[0]
		var payload: Dictionary = entry["payload"]
		assert_eq(entry["contactId"], "ingram", "from its key member")
		assert_eq(int(payload["expiresDay"]), int(GameState.state["world"]["day"]) + int(_cfg()["trouble"]["expiryDays"]))
		_equip_player(payload)
		var before := _relation("guild")
		var result := Partners.accept_trouble(entry["id"], Partners.trouble_options(payload)[0])
		assert_true(result["ok"], "accepted")
		assert_true(_relation("guild") >= before + int(_cfg()["trouble"]["relationGain"]), "accepting raises relation")
		assert_true(Partners.pending_for("guild").is_empty(), "answered")
	)

	run_case("a_trouble_ask_stays_open_through_its_last_day_then_lapses", func():
		GameState.reset()
		_make_player_partner("guild", 60)
		var entry := _queue_ask({ "factionId": "guild", "ask": Partners.ASK_CASH, "amount": 300 })
		var last := int(entry["payload"]["expiresDay"])
		assert_true(last > int(GameState.state["world"]["day"]), "lasts past today")
		_with_trouble_chance(0.0, func():
			GameState.state["world"]["day"] = last
			Partners.daily_tick()
			assert_eq(Partners.pending_for("guild").size(), 1, "still open on its last day")
			GameState.state["world"]["day"] = last + 1
			Partners.daily_tick()
			assert_true(Partners.pending_for("guild").is_empty(), "withdrawn once lapsed"))
		assert_true(not Partners.accept_trouble(entry["id"], Partners.OPTION_SEND)["ok"], "a lapsed ask can't be taken")
	)

	run_case("each_trouble_answer_moves_cash_and_goods_at_the_ask_price", func():
		GameState.reset()
		_make_player_partner("guild", 60)
		var gain := int(_cfg()["trouble"]["relationGain"])
		var guild: Dictionary = GameState.state["factions"]["guild"]
		var player: Dictionary = GameState.state["player"]

		player["cash"] = 1000
		guild["resources"] = 0
		var cash_ask := _queue_ask({ "factionId": "guild", "ask": Partners.ASK_CASH, "amount": 300 })
		assert_true(not Partners.accept_trouble(cash_ask["id"], Partners.OPTION_SELL)["ok"], "only the ask's own answers")
		assert_true(Partners.accept_trouble(cash_ask["id"], Partners.OPTION_SEND)["ok"])
		assert_eq(int(player["cash"]), 700)
		assert_eq(int(guild["resources"]), 300)
		assert_eq(_relation("guild"), 60 + gain)

		guild["resources"] = 5000
		player["orichalchum"]["time"] = 4
		var goods_ask := _queue_ask({ "factionId": "guild", "ask": Partners.ASK_GOODS, "kind": "ore", "type": "time", "qty": 10, "unitPrice": 50 })
		var held := FactionSim.ore_held("guild", "time")
		var cash := int(player["cash"])
		assert_true(Partners.accept_trouble(goods_ask["id"], Partners.OPTION_SELL)["ok"], "sells what the player has")
		assert_eq(int(player["orichalchum"]["time"]), 0)
		assert_eq(FactionSim.ore_held("guild", "time"), held + 4)
		assert_eq(int(player["cash"]), cash + Market.line_total("ore", 50, 4), "at the ask's price")

		var contract_ask := _queue_ask({ "factionId": "guild", "ask": Partners.ASK_GOODS, "kind": "ore", "type": "time", "qty": 10, "unitPrice": 50 })
		assert_true(not Partners.accept_trouble(contract_ask["id"], Partners.OPTION_CONTRACT)["ok"], "a contract needs Sales")
		assert_eq(Partners.pending_for("guild").size(), 1, "a refusal leaves the ask open")
		Partners.decline_trouble(contract_ask["id"])
		assert_true(Partners.pending_for("guild").is_empty())
	)

	run_case("a_partner_warning_needs_high_relation_and_terms_with_the_aggressor", func():
		for setup in [
			{ "player": 85, "pair": 0, "warned": true, "why": "close partner on terms with the Firm warns" },
			{ "player": 85, "pair": -60, "warned": false, "why": "no warning while Hostile with the Firm" },
			{ "player": 70, "pair": 0, "warned": false, "why": "no warning below the relation bar" },
		]:
			GameState.reset()
			_make_player_partner("guild", int(setup["player"]))
			_set_pair("guild", "firm", FactionAI.NEUTRAL if int(setup["pair"]) > -40 else FactionAI.HOSTILE, int(setup["pair"]))
			_firm_bears_down()
			_with_trouble_chance(0.0, func(): TimeSystem.daily_tick())
			var plans := FactionAI.planned_moves(int(_cfg()["warnings"]["horizonDays"])).filter(func(p: Dictionary) -> bool:
				return p["factionId"] == "firm" and p["targetId"] == Shares.PLAYER)
			assert_true(not plans.is_empty(), "the Firm has a move planned")
			var warned: bool = GameState.state["partners"]["warned"].get("guild", {}).has("firm")
			assert_eq(warned, setup["warned"], setup["why"])
			var said: bool = GameState.state["messages"].get("ingram", []).any(func(m: Dictionary) -> bool: return str(m["text"]).contains(_cfg()["lines"]["guild"]["how"]))
			assert_eq(said, setup["warned"], "the warning explains how it knows")
	)

	run_case("seeded_defence_help_adds_the_partner_to_a_vein_defence_fight", func():
		GameState.reset()
		Rng.set_seed(21)
		_make_player_partner("guild", 85)
		var help: Dictionary = _cfg()["defenceHelp"]
		var saved: float = help["chance"]
		help["chance"] = 1.0
		var vein := Fixtures.seed_vein("v1", 40, "physics")
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": vein["id"], "siteId": vein["siteId"], "success": true, "notificationId": "n1" }]
		assert_true(Raiding.maybe_trigger_defend(vein["district"]), "the defend fight starts")
		help["chance"] = saved
		var allies: Array = GameState.state["combat"]["allies"]
		var partner_allies := allies.filter(func(a: Dictionary) -> bool: return a.get("partnerFactionId", "") == "guild")
		assert_eq(partner_allies.size(), 1, "the Guild sends a fighter")
		assert_eq(partner_allies[0]["name"], help["names"]["guild"])
		assert_true(not partner_allies[0].has("contactId") and not partner_allies[0].has("guardAlly"))
		assert_true(Partners.defence_helpers("guild").is_empty(), "a partner never helps against itself")
	)

	run_case("partner_factions_warn_and_help_each_other_in_faction_raids", func():
		GameState.reset()
		_set_pair("guild", "collective", FactionAI.PARTNER, 85)
		_set_pair("guild", "firm", FactionAI.NEUTRAL, 0)
		var help: Dictionary = _cfg()["raidHelp"]
		var vein := Fixtures.seed_faction_vein("fv1", 40, "collective", "life")
		GameState.state["factionEscalation"]["queuedRaids"].append({ "attackerId": "firm", "targetId": "collective", "veinId": vein["id"], "siteId": "site_fv1" })
		Partners.warn_factions()
		assert_eq(GameState.state["factionEscalation"]["queuedRaids"][0]["warnedBy"], "guild", "the Guild tips off its partner")
		var saved: float = help["chance"]
		help["chance"] = 1.0
		var cut := Partners.faction_defence_cut("firm", "collective", "guild")
		help["chance"] = 0.0
		var warned_only := Partners.faction_defence_cut("firm", "collective", "guild")
		help["chance"] = saved
		assert_almost_eq(cut, float(help["warnedOddsCut"]) + float(help["oddsCut"]), 0.0001, "warning plus help")
		assert_almost_eq(warned_only, float(help["warnedOddsCut"]), 0.0001)
		var attempt := { "attackerId": "firm", "defenderId": "collective", "veinSiteId": "site_fv1" }
		var base := Factions.rivalry_success_chance(attempt)
		attempt["oddsCut"] = cut
		assert_almost_eq(Factions.rivalry_success_chance(attempt), maxf(0.0, base - cut), 0.0001, "the cut lowers the raid odds")
		assert_true(FactionAI.activity_log("guild").any(func(e: Dictionary) -> bool: return str(e["text"]).contains("Sent help")), "logged on the helper")
	)

	run_case("partner_factions_sell_short_goods_and_leak_intel_to_each_other", func():
		GameState.reset()
		_set_pair("guild", "collective", FactionAI.PARTNER, 60)
		var need := Partners.needed_good("guild")
		assert_true(not need.is_empty(), "the Guild needs something")
		var holdings: Dictionary = GameState.state["factions"]["guild"]["holdings"]
		if need["kind"] == "ore":
			holdings["ore"][need["type"]] = 0
			FactionSim.add_ore("collective", need["type"], 1000)
		else:
			holdings["items"].erase(need["type"])
			FactionSim.add_item("collective", need["type"], 0, 1000)
		GameState.state["factions"]["guild"]["resources"] = 100000
		var before := FactionSim.held("guild", need["kind"], need["type"])
		var leaks: Dictionary = _cfg()["leaks"]
		var saved_leak: float = leaks["chance"]
		leaks["chance"] = 1.0
		Intel.raise("collective", "firm", 40)
		_with_trouble_chance(1.0, func(): Partners.daily_tick())
		leaks["chance"] = saved_leak
		assert_true(FactionSim.held("guild", need["kind"], need["type"]) > before, "the Collective sells to its partner")
		assert_eq(Intel.meter("guild", "firm"), int(leaks["amount"]), "the Collective leaks its file on the Firm")
	)
