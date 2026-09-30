extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")


static func _cfg() -> Dictionary:
	return GameData.FACTION_FAVOURS


static func _relation(faction_id: String) -> int:
	return int(GameState.state["factions"][faction_id]["relation"])


static func _staff_sales() -> void:
	GameState.state["contacts"]["archie"]["recruited"] = true
	Contacts.assign_to_room("archie", "ops")


# Queues faction_id's favour_id as a pending request, as issue_favours does.
static func _ask(faction_id: String, favour_id: String) -> Dictionary:
	var favour := Diplomacy.favour_def(faction_id, favour_id)
	var payload := { "factionId": faction_id, "favourId": favour_id, "expiresDay": int(GameState.state["world"]["day"]) + int(_cfg()["expiryDays"]) }
	KeyMembers.send(faction_id, favour["text"], Diplomacy.FAVOUR_KIND, payload)
	return Diplomacy.pending_for(faction_id)[0]


static func _accept(faction_id: String, favour_id: String) -> Dictionary:
	return Diplomacy.accept(_ask(faction_id, favour_id)["id"])


static func _tick_on(day: int) -> void:
	GameState.state["world"]["day"] = day
	var chance: float = _cfg()["issueChance"]
	_cfg()["issueChance"] = 0.0
	Diplomacy.daily_tick()
	_cfg()["issueChance"] = chance


static func _set_pair(faction_a: String, faction_b: String, stance: String) -> void:
	GameState.state["factionStances"]["pairs"][FactionAI.pair_key(faction_a, faction_b)]["stance"] = stance


func run() -> void:
	run_case("the_rollover_issues_favour_requests_as_actionable_key_member_messages_that_expire", func():
		GameState.reset()
		var chance: float = _cfg()["issueChance"]
		_cfg()["issueChance"] = 1.0
		TimeSystem.daily_tick()
		_cfg()["issueChance"] = chance
		var day: int = GameState.state["world"]["day"]
		var pending := Messages.pending_for("lusk")
		assert_eq(pending.size(), 1, "the Firm's key member asks")
		assert_eq(pending[0]["kind"], Diplomacy.FAVOUR_KIND)
		assert_eq(pending[0]["payload"]["favourId"], "firm_sit_out", "no Sales staff: only the sit-out is doable")
		assert_eq(int(pending[0]["payload"]["expiresDay"]), day + int(_cfg()["expiryDays"]))
		assert_true(Diplomacy.pending_for("collective").is_empty(), "a quest-locked key member can't ask")
		_tick_on(day + int(_cfg()["expiryDays"]))
		assert_eq(Diplomacy.pending_for("firm").size(), 1, "still open on its last day")
		_tick_on(day + int(_cfg()["expiryDays"]) + 1)
		assert_true(Diplomacy.pending_for("firm").is_empty(), "withdrawn once lapsed")
	)

	run_case("a_faction_waits_out_its_cooldown_and_asks_one_at_a_time", func():
		GameState.reset()
		GameState.state["world"]["day"] = 10
		var chance: float = _cfg()["issueChance"]
		_cfg()["issueChance"] = 1.0
		Diplomacy.issue_favours()
		Diplomacy.decline(Diplomacy.pending_for("firm")[0]["id"])
		GameState.state["world"]["day"] = 10 + int(_cfg()["cooldownDays"]) - 1
		Diplomacy.issue_favours()
		assert_true(Diplomacy.pending_for("firm").is_empty(), "cooling")
		GameState.state["world"]["day"] = 10 + int(_cfg()["cooldownDays"])
		Diplomacy.issue_favours()
		assert_eq(Diplomacy.pending_for("firm").size(), 1, "asks again")
		Diplomacy.accept(Diplomacy.pending_for("firm")[0]["id"])
		GameState.state["world"]["day"] += int(_cfg()["cooldownDays"])
		Diplomacy.issue_favours()
		assert_true(Diplomacy.pending_for("firm").is_empty(), "not while one is owed")
		_cfg()["issueChance"] = chance
	)

	run_case("ignoring_a_favour_costs_nothing", func():
		GameState.reset()
		var before := _relation("firm")
		_ask("firm", "firm_sit_out")
		_tick_on(int(GameState.state["world"]["day"]) + int(_cfg()["expiryDays"]) + 1)
		assert_true(Diplomacy.pending_for("firm").is_empty())
		assert_eq(_relation("firm"), before)
		var declined := _ask("guild", "guild_time_supply")
		before = _relation("guild")
		Diplomacy.decline(declined["id"])
		assert_eq(_relation("guild"), before, "declining costs nothing either")
	)

	run_case("keeping_a_sit_out_raises_relation", func():
		GameState.reset()
		var before := _relation("firm")
		var result := _accept("firm", "firm_sit_out")
		assert_true(result["ok"])
		assert_true(Diplomacy.pending_for("firm").is_empty(), "answered")
		_tick_on(int(result["favour"]["dueDay"]) - 1)
		assert_eq(_relation("firm"), before, "not yet due")
		_tick_on(int(result["favour"]["dueDay"]))
		assert_eq(_relation("firm"), before + int(_cfg()["relationGain"]))
		assert_true(Diplomacy.accepted().is_empty())
		assert_eq(Messages.latest_preview("lusk"), _cfg()["lines"]["firm"]["done"])
	)

	run_case("a_hostile_act_on_the_sit_out_target_fails_it_a_little", func():
		GameState.reset()
		var before := _relation("firm")
		_accept("firm", "firm_sit_out")
		FactionAI.note_hostile_act(Shares.PLAYER, "guild")
		assert_eq(Diplomacy.accepted().size(), 1, "another faction doesn't count")
		FactionAI.note_hostile_act(Shares.PLAYER, "collective")
		assert_eq(_relation("firm"), before - int(_cfg()["failRelationLoss"]))
		assert_true(Diplomacy.accepted().is_empty())
		assert_eq(Messages.latest_preview("lusk"), _cfg()["lines"]["firm"]["failed"])
	)

	run_case("a_guard_favour_fails_when_a_vein_is_lost_and_is_kept_when_held", func():
		GameState.reset()
		Fixtures.seed_vein("pv", 60)
		var before := _relation("conclave")
		var result := _accept("conclave", "conclave_hold_ground")
		GameState.state["player"]["veins"].clear()
		_tick_on(int(GameState.state["world"]["day"]) + 1)
		assert_eq(_relation("conclave"), before - int(_cfg()["failRelationLoss"]), "lost a vein")
		Fixtures.seed_vein("pv2", 60)
		before = _relation("conclave")
		result = _accept("conclave", "conclave_hold_ground")
		_tick_on(int(result["favour"]["dueDay"]))
		assert_eq(_relation("conclave"), before + int(_cfg()["relationGain"]), "held")
	)

	run_case("a_guard_favour_needs_a_vein", func():
		GameState.reset()
		var result := _accept("conclave", "conclave_hold_ground")
		assert_true(not result["ok"])
		assert_true(Diplomacy.accepted().is_empty())
	)

	run_case("a_deliver_favour_signs_a_contract_and_filling_it_raises_relation", func():
		GameState.reset()
		_staff_sales()
		var before := _relation("guild")
		var day: int = GameState.state["world"]["day"]
		var result := _accept("guild", "guild_time_supply")
		assert_true(result["ok"], str(result))
		var contract: Dictionary = Contracts.active_contracts()[0]
		assert_eq(contract["counterparty"], "guild")
		assert_eq(int(contract["dueDay"]), day + 6)
		assert_eq(int(contract["request"]["qty"]), 15)
		var live: int = Offers.quote_for_request(contract["request"], 1)["liveValue"]
		assert_eq(int(contract["signedQuote"]["payment"]), GameState.round_epsilon(float(live) * float(_cfg()["deliverPriceMult"])))
		GameState.state["player"]["orichalchum"]["time"] = 15
		Contracts.process_sales_deliveries()
		assert_true(Contracts.active_contracts().is_empty(), "settled")
		assert_eq(_relation("guild"), before + int(_cfg()["relationGain"]))
		assert_true(Diplomacy.accepted().is_empty())
	)

	run_case("a_deliver_favour_unfilled_by_its_day_fails_a_little", func():
		GameState.reset()
		_staff_sales()
		var before := _relation("guild")
		var result := _accept("guild", "guild_time_supply")
		GameState.state["world"]["day"] = int(result["favour"]["dueDay"])
		Contracts.daily_tick()
		assert_eq(_relation("guild"), before - int(_cfg()["failRelationLoss"]))
		assert_true(Diplomacy.accepted().is_empty())
	)

	run_case("a_sell_below_favour_is_priced_under_london_value", func():
		GameState.reset()
		_staff_sales()
		var result := _accept("firm", "firm_cheap_life")
		assert_true(result["ok"], str(result))
		var contract: Dictionary = Contracts.active_contracts()[0]
		var live: int = Offers.quote_for_request(contract["request"], 1)["liveValue"]
		assert_eq(int(contract["signedQuote"]["payment"]), GameState.round_epsilon(float(live) * 0.8))
		assert_eq(int(contract["dueDay"]), int(GameState.state["world"]["day"]) + int(_cfg()["sellBelowDays"]))
	)

	run_case("goods_favours_need_sales_staff", func():
		GameState.reset()
		var result := _accept("guild", "guild_time_supply")
		assert_true(not result["ok"])
		assert_eq(Diplomacy.pending_for("guild").size(), 1, "still open")
	)

	run_case("a_kept_favour_raises_intel_on_the_askers_enemies", func():
		GameState.reset()
		_set_pair("firm", "collective", FactionAI.HOSTILE)
		_set_pair("firm", "guild", FactionAI.NEUTRAL)
		var result := _accept("firm", "firm_sit_out")
		_tick_on(int(result["favour"]["dueDay"]))
		assert_eq(Intel.meter(Shares.PLAYER, "collective"), int(GameData.INTEL["gain"]["favour"]))
		assert_eq(Intel.meter(Shares.PLAYER, "guild"), 0, "not an enemy")
	)

	run_case("pending_and_accepted_favours_survive_save_load", func():
		GameState.reset()
		GameState.state["world"]["day"] = 4
		_ask("firm", "firm_sit_out")
		Fixtures.seed_vein("pv", 60)
		assert_true(_accept("conclave", "conclave_hold_ground")["ok"])
		GameState.state["favours"]["lastIssued"]["firm"] = 4
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(Diplomacy.pending_for("firm").size(), 1)
		assert_true(Diplomacy.pending_for("firm")[0]["payload"]["expiresDay"] is int, "request expiry loaded as int")
		assert_true(Diplomacy.accepted_for("conclave")["params"]["days"] is int)
		assert_eq(Diplomacy.accepted_for("conclave")["veinIds"], ["pv"])
		assert_true(Diplomacy.accepted_for("conclave")["dueDay"] is int, "loaded as int")
		assert_true(GameState.state["favours"]["lastIssued"]["firm"] is int)
	)

	run_case("an_old_save_without_favours_gets_the_empty_state", func():
		GameState.reset()
		GameState.state.erase("favours")
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["favours"], Diplomacy.new_state())
	)
