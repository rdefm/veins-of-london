extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")


static func _fresh() -> void:
	GameState.reset()
	GameState.state["shares"] = Shares.new_state()
	GameState.state["world"]["sites"] = []
	GameState.state["player"]["veins"] = []


static func _hostile_pair(a: String, b: String) -> void:
	Factions.adjust_relation(a, b, -60 - Factions.get_relation(a, b))
	GameState.state["factionStances"]["pairs"][FactionAI.pair_key(a, b)]["stance"] = FactionAI.HOSTILE


static func _hostile_player(faction_id: String) -> void:
	Factions.adjust_player_relation(faction_id, -60 - int(GameState.state["factions"][faction_id]["relation"]))
	GameState.state["factionStances"]["player"][faction_id]["stance"] = FactionAI.HOSTILE


# One day of the stance and war steps.
static func _war_day(day: int) -> void:
	GameState.state["world"]["day"] = day
	FactionAI.update_stances()
	FactionAI.update_wars()


static func _raid_on(day: int, attacker: String, defender: String) -> void:
	GameState.state["world"]["day"] = day
	FactionAI.report_pair_move(attacker, defender, FactionAI.MOVE_VEIN_RAID, "shoreditch", false)


static func _war_weariness(a: String, b: String, party: String) -> float:
	for war in FactionAI.wars_of(a):
		if FactionAI.war_enemy(war, a) == b:
			return float(war["weariness"][party])
	return -1.0


static func _texts(contact_id: String) -> Array:
	return GameState.state["messages"].get(contact_id, []).map(func(m: Dictionary) -> String: return m["text"])


static func _truce_cfg() -> Dictionary:
	return GameData.FACTION_WAR["truce"]


static func _just_above_hostile() -> int:
	return int(GameData.FACTION_STANCES["hostileAtOrBelow"]) + int(_truce_cfg()["relationAboveHostile"])


static func _nag(index: int) -> String:
	return GameData.FACTION_WAR["nags"][index]["text"]


func run() -> void:
	run_case("hostile_plus_a_raid_starts_a_war_on_the_rollover_and_quiet_days_end_it", func():
		_fresh()
		_hostile_pair("firm", "guild")
		_raid_on(1, "firm", "guild")
		TimeSystem.daily_tick()
		assert_true(FactionAI.at_war("guild", "firm"), "Hostile + raid is war")
		assert_eq(int(FactionAI.wars()[0]["startDay"]), 1)
		assert_eq(Barometer.headlines()[0]["text"], GameData.FACTION_WAR["headlines"]["warDeclared"] % ["Firm", "The Guild"], "war declared on the wires")
		for day in range(2, 9):
			_war_day(day)
		assert_true(FactionAI.at_war("firm", "guild"), "still at war on the last day of the window")
		_war_day(9)
		assert_true(not FactionAI.at_war("firm", "guild"), "quiet past the window ends it")
		var ended: String = GameData.FACTION_WAR["log"]["endedPair"] % "The Guild"
		assert_true(FactionAI.activity_log("firm").any(func(e: Dictionary) -> bool: return e["text"] == ended), "logged")
	)

	run_case("a_raid_without_a_hostile_stance_is_no_war", func():
		_fresh()
		_raid_on(1, "firm", "network")
		_war_day(1)
		assert_true(FactionAI.wars().is_empty())
	)

	run_case("a_new_raid_keeps_the_war_going", func():
		_fresh()
		_hostile_pair("firm", "guild")
		_raid_on(1, "firm", "guild")
		_war_day(1)
		_raid_on(6, "guild", "firm")
		for day in range(6, 14):
			_war_day(day)
		assert_true(FactionAI.at_war("firm", "guild"))
		assert_eq(int(FactionAI.wars()[0]["lastHostileDay"]), 6)
	)

	run_case("losses_wear_a_side_down_faster_than_days_at_war", func():
		_fresh()
		_hostile_pair("firm", "guild")
		Fixtures.seed_faction_vein("fv_g", 60, "guild")
		_raid_on(1, "firm", "guild")
		Factions.resolve_rivalry_outcome({ "success": true, "attackerId": "firm", "defenderId": "guild", "veinSiteId": "site_fv_g" })
		_war_day(1)
		var days_only := float(GameData.FACTION_WAR["weights"]["dayAtWar"])
		assert_eq(FactionAI.weariness("firm"), days_only, "the winner only pays the day")
		assert_true(FactionAI.weariness("guild") > days_only * 5.0, "the loser pays for the vein")
	)

	run_case("a_second_war_multiplies_weariness", func():
		_fresh()
		_hostile_pair("firm", "guild")
		_hostile_pair("firm", "network")
		_raid_on(1, "firm", "guild")
		_raid_on(1, "firm", "network")
		for day in range(1, 4):
			_war_day(day)
		assert_eq(FactionAI.wars_of("firm").size(), 2)
		var firm := _war_weariness("firm", "guild", "firm")
		var guild := _war_weariness("firm", "guild", "guild")
		assert_true(firm > guild, "two fronts wear faster than one (%s vs %s)" % [firm, guild])
	)

	run_case("weariness_decays_out_of_war", func():
		_fresh()
		_hostile_pair("firm", "guild")
		_raid_on(1, "firm", "guild")
		FactionAI.note_loss("guild", "firm", 400.0)
		for day in range(1, 10):
			_war_day(day)
		assert_true(not FactionAI.at_war("firm", "guild"))
		var after_war := FactionAI.weariness("guild")
		assert_true(after_war > 0.0)
		_war_day(10)
		assert_almost_eq(FactionAI.weariness("guild"), after_war - float(GameData.FACTION_WAR["decayPerDay"]), 0.001, "eases a step a day")
	)

	run_case("spend_above_peacetime_wears_a_side_down", func():
		_fresh()
		_hostile_pair("firm", "guild")
		_raid_on(1, "firm", "guild")
		FactionAI.note_spend("guild", 500.0)
		_war_day(1)
		assert_true(FactionAI.weariness("guild") > FactionAI.weariness("firm"), "the spender tires")
	)

	run_case("the_players_weariness_crossing_nag_sends_escalating_messages", func():
		_fresh()
		GameState.state["contacts"]["james"]["unlocked"] = false
		_hostile_player("firm")
		GameState.state["world"]["day"] = 1
		FactionAI.note_hostile_act("firm", "player")
		FactionAI.note_loss("player", "firm", 800.0)
		_war_day(1)
		assert_true(FactionAI.at_war("player", "firm"))
		assert_true(Barometer.headlines().is_empty(), "the player's wars aren't on the wires")
		assert_true(_texts("archie").has(_nag(0)), "first nag")
		assert_true(not _texts("archie").has(_nag(1)))
		_war_day(2)
		assert_eq(_texts("archie").filter(func(t: String) -> bool: return t == _nag(0)).size(), 1, "no repeat at the same level")
		GameState.state["contacts"]["james"]["unlocked"] = true
		FactionAI.note_loss("player", "firm", 400.0)
		_war_day(3)
		assert_true(_texts("james").has(_nag(1)), "James takes the second")
		FactionAI.note_loss("player", "firm", 2000.0)
		_war_day(4)
		assert_true(FactionAI.player_extreme())
		assert_true(_texts("james").has(GameData.FACTION_WAR["extremeNag"]["text"]), "extreme")
	)

	run_case("two_weary_factions_sign_a_truce_on_the_rollover", func():
		_fresh()
		_hostile_pair("firm", "guild")
		_raid_on(1, "firm", "guild")
		_war_day(1)
		var war: Dictionary = FactionAI.wars()[0]
		war["weariness"]["firm"] = 86.0
		war["weariness"]["guild"] = 50.0
		GameState.state["world"]["day"] = 2
		TimeSystem.daily_tick()
		assert_true(not FactionAI.at_war("firm", "guild"), "the war ends")
		assert_true(FactionAI.in_truce("guild", "firm"))
		var signed: String = _truce_cfg()["headlines"]["signed"] % ["Firm", "The Guild"]
		assert_true(Barometer.headlines().any(func(h: Dictionary) -> bool: return h["text"] == signed), "truce on the wires")
		assert_eq(Factions.get_relation("firm", "guild"), _just_above_hostile(), "relation just above Hostile")
	)

	run_case("a_side_short_of_accept_peace_keeps_fighting", func():
		_fresh()
		_hostile_pair("firm", "guild")
		_raid_on(1, "firm", "guild")
		_war_day(1)
		FactionAI.wars()[0]["weariness"]["firm"] = 90.0
		FactionAI.wars()[0]["weariness"]["guild"] = 20.0
		_war_day(2)
		assert_true(FactionAI.at_war("firm", "guild"))
		assert_true(FactionAI.truces().is_empty())
	)

	run_case("the_weary_side_pays_to_lift_a_bare_truce_to_the_others_bar", func():
		_fresh()
		_hostile_pair("firm", "guild")
		_raid_on(1, "firm", "guild")
		_war_day(1)
		FactionAI.wars()[0]["weariness"]["firm"] = 90.0
		FactionAI.wars()[0]["weariness"]["guild"] = 36.0
		GameState.state["factions"]["firm"]["resources"] = 10000
		var guild_before := int(GameState.state["factions"]["guild"]["resources"])
		_war_day(2)
		assert_true(FactionAI.in_truce("firm", "guild"))
		var paid := int(GameState.state["factions"]["guild"]["resources"]) - guild_before
		assert_true(paid > 0, "the Guild is paid to sign")
		assert_eq(int(GameState.state["factions"]["firm"]["resources"]), 10000 - paid, "by the Firm")
	)

	run_case("the_less_weary_side_offers_when_only_it_is_at_offer_peace", func():
		_fresh()
		_hostile_pair("firm", "guild")
		_raid_on(1, "firm", "guild")
		_war_day(1)
		FactionAI.wars()[0]["weariness"]["firm"] = 80.0
		FactionAI.wars()[0]["weariness"]["guild"] = 70.0
		_war_day(2)
		assert_true(FactionAI.in_truce("firm", "guild"), "the Guild offers, the Firm accepts")
	)

	run_case("signing_drops_raids_queued_between_the_parties", func():
		_fresh()
		GameState.state["world"]["day"] = 1
		var queued: Array = GameState.state["factionEscalation"]["queuedRaids"]
		queued.append({ "attackerId": "guild", "targetId": "firm", "veinId": "v1", "siteId": "s1" })
		queued.append({ "attackerId": "guild", "targetId": "network", "veinId": "v2", "siteId": "s2" })
		FactionAI.sign_truce("firm", "guild", {})
		var left: Array = GameState.state["factionEscalation"]["queuedRaids"]
		assert_eq(left.size(), 1)
		assert_eq(left[0]["targetId"], "network", "other raids stand")
	)

	run_case("a_truce_blocks_moves_and_adds_its_daily_bonus_until_it_ends", func():
		_fresh()
		_hostile_pair("firm", "guild")
		GameState.state["world"]["day"] = 1
		FactionAI.sign_truce("firm", "guild", { "truceDays": 5 })
		TimeSystem.daily_tick()
		var warned_firm: String = GameData.FACTION_ESCALATION["log"]["warningPair"] % "The Guild"
		var warned_guild: String = GameData.FACTION_ESCALATION["log"]["warningPair"] % "Firm"
		assert_true(not FactionAI.activity_log("firm").any(func(e: Dictionary) -> bool: return e["text"] == warned_firm), "no move by the Firm")
		assert_true(not FactionAI.activity_log("guild").any(func(e: Dictionary) -> bool: return e["text"] == warned_guild), "no move by the Guild")
		var before := Factions.get_relation("firm", "guild")
		_war_day(3)
		assert_eq(Factions.get_relation("firm", "guild"), before + int(_truce_cfg()["dailyBonus"]), "daily bonus")
		_war_day(6)
		assert_true(not FactionAI.in_truce("firm", "guild"), "lapses at its end day")
	)

	run_case("without_a_truce_the_same_pair_warns", func():
		_fresh()
		_hostile_pair("firm", "guild")
		GameState.state["world"]["day"] = 1
		TimeSystem.daily_tick()
		var warned: String = GameData.FACTION_ESCALATION["log"]["warningPair"] % "The Guild"
		assert_true(FactionAI.activity_log("firm").any(func(e: Dictionary) -> bool: return e["text"] == warned))
	)

	run_case("a_faction_breaking_a_truce_loses_relation_with_every_faction", func():
		_fresh()
		_hostile_pair("firm", "guild")
		GameState.state["world"]["day"] = 1
		FactionAI.sign_truce("firm", "guild", {})
		var before := {}
		for faction_id in GameData.FACTIONS.keys():
			before[faction_id] = Factions.get_relation("firm", faction_id)
		_raid_on(2, "firm", "guild")
		assert_true(not FactionAI.in_truce("firm", "guild"), "broken")
		var penalty := int(_truce_cfg()["breakPenalty"])
		for faction_id in GameData.FACTIONS.keys():
			if faction_id != "firm":
				assert_eq(Factions.get_relation("firm", faction_id), before[faction_id] - penalty, faction_id)
		assert_eq(Factions.get_relation("guild", "network"), FactionAI.starting_pair_relation("guild", "network"), "bystander pairs untouched")
	)

	run_case("the_player_breaking_a_truce_loses_relation_with_every_faction", func():
		_fresh()
		GameState.state["world"]["day"] = 1
		FactionAI.sign_truce("player", "firm", {})
		var before := {}
		for faction_id in GameData.FACTIONS.keys():
			before[faction_id] = int(GameState.state["factions"][faction_id]["relation"])
		FactionAI.note_hostile_act("player", "firm")
		assert_true(not FactionAI.in_truce("firm", "player"))
		for faction_id in GameData.FACTIONS.keys():
			assert_eq(int(GameState.state["factions"][faction_id]["relation"]), before[faction_id] - int(_truce_cfg()["breakPenalty"]), faction_id)
	)
