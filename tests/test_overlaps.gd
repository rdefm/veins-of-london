extends "res://tests/test_base.gd"

# Overlap detector (one test per kind), the Partner ladder it gates, the
# faction_relation_at_least tiers, and the rival-move / Partner spine beats.

const Fixtures := preload("res://tests/support/fixtures.gd")


func _clear() -> void:
	GameState.reset()
	GameState.state["world"]["day"] = 10
	GameState.state["world"]["sites"] = []
	GameState.state["player"]["veins"] = []
	GameState.state["boardMeetings"]["enabled"] = true
	GameState.state["boardMeetings"]["week"] = 1


# `player` of 100 units of `ore` over the prior days, the rest independents.
func _ore_share(ore_type: String, player: int) -> void:
	var today: int = GameState.state["world"]["day"]
	GameState.state["world"]["day"] = today - 1
	Shares.record_ore("player", ore_type, player)
	Shares.record_ore("independents", ore_type, 100 - player)
	GameState.state["world"]["day"] = today


func _kinds(faction_id: String) -> Array:
	var kinds: Array = []
	for entry in Overlaps.detect_for(faction_id):
		kinds.append(entry["kind"])
	return kinds


func _partner_cards() -> Array:
	var cards: Array = []
	for card in BoardMeetings.eligible_cards():
		if card["ladder"] == "partner":
			cards.append(card)
	return cards


func _set_relation(faction_id: String, value: int) -> void:
	GameState.state["factions"][faction_id]["relation"] = value


func run() -> void:
	run_act2_endgame()
	run_case("no_overlap_on_a_bare_state", func():
		_clear()
		assert_true(Overlaps.detect().is_empty())
		assert_true(not Overlaps.exists())
	)

	run_case("district_overlap_needs_both_in_one_district", func():
		_clear()
		Fixtures.seed_faction_vein("v_firm", 50, "firm")
		GameState.state["world"]["sites"][-1]["district"] = "shoreditch"
		assert_true(not _kinds("firm").has(Overlaps.KIND_DISTRICT))
		GameState.state["player"]["veins"].append(Fixtures.player_vein("pv", "s_pv", "camden", "life", 50, "low"))
		assert_true(not _kinds("firm").has(Overlaps.KIND_DISTRICT), "other district")
		GameState.state["player"]["veins"].append(Fixtures.player_vein("pv2", "s_pv2", "shoreditch", "life", 50, "low"))
		assert_true(_kinds("firm").has(Overlaps.KIND_DISTRICT))
	)

	run_case("crafting_overlap_at_ten_percent_of_their_ore", func():
		_clear()
		var ore_type: String = GameData.FACTIONS["collective"]["primaryOre"]
		var today: int = GameState.state["world"]["day"]
		GameState.state["world"]["day"] = today - 1
		Shares.record_craft("player", { ore_type: 9 })
		Shares.record_craft("guild", { ore_type: 91 })
		GameState.state["world"]["day"] = today
		assert_true(not _kinds("collective").has(Overlaps.KIND_CRAFTING), "9% is below")
		GameState.state["world"]["day"] = today - 1
		Shares.record_craft("player", { ore_type: 2 })
		GameState.state["world"]["day"] = today
		assert_true(_kinds("collective").has(Overlaps.KIND_CRAFTING), "10%+ counts")
	)

	run_case("producing_overlap_when_player_mines_what_they_consume", func():
		_clear()
		_ore_share("life", 9)
		assert_true(not _kinds("collective").has(Overlaps.KIND_PRODUCING), "9% is below")
		_clear()
		_ore_share("life", 12)
		assert_true(_kinds("collective").has(Overlaps.KIND_PRODUCING))
		assert_true(not _kinds("collective").has(Overlaps.KIND_PROVOCATION), "12% is not near provocation")
	)

	run_case("provocation_overlap_when_share_nears_the_trigger", func():
		_clear()
		_ore_share("life", 16)
		assert_true(_kinds("collective").has(Overlaps.KIND_PROVOCATION))
		assert_true(Overlaps.factions().has("collective"))
	)

	run_case("partner_card_needs_an_overlap", func():
		_clear()
		assert_true(_partner_cards().is_empty(), "no overlap, no card")
		_ore_share("life", 16)
		var cards := _partner_cards()
		assert_eq(cards.size(), 1)
		assert_eq(cards[0]["rung"], "partner_1")
		assert_eq(cards[0]["faction"], "collective")
		assert_eq(cards[0]["goal"]["params"]["factionId"], "collective")
		assert_eq(BoardMeetings.card_label(cards[0]), "Get on with Collective")
	)

	run_case("partner_card_skipped_when_target_relation_already_met", func():
		_clear()
		_ore_share("life", 16)
		_set_relation("collective", 30)
		var cards := _partner_cards()
		assert_eq(BoardMeetings.rung_status("partner", "partner_1"), "skipped")
		assert_eq(cards.size(), 1)
		assert_eq(cards[0]["rung"], "partner_2")
	)

	run_case("relation_tiers_at_the_edges", func():
		_clear()
		var goal := { "id": "g", "type": "faction_relation_at_least", "params": { "factionId": "guild" },
			"tiers": { "base": { "minRelation": 15 }, "target": { "minRelation": 30 }, "stretch": { "minRelation": 45 } } }
		_set_relation("guild", 14)
		assert_eq(Objectives.tier_met(goal), Objectives.TIER_NONE)
		_set_relation("guild", 15)
		assert_eq(Objectives.tier_met(goal), "base")
		_set_relation("guild", 30)
		assert_eq(Objectives.tier_met(goal), "target")
		_set_relation("guild", 45)
		assert_eq(Objectives.tier_met(goal), "stretch")
	)

	run_case("partner_2_follows_partner_1_and_keeps_the_faction", func():
		_clear()
		_ore_share("life", 16)
		var board: Dictionary = GameState.state["boardMeetings"]
		board["rungs"]["partner"] = { "partner_1": { "status": "done", "day": 5, "faction": "collective" } }
		var cards := _partner_cards()
		assert_eq(cards.size(), 1)
		assert_eq(cards[0]["rung"], "partner_2")
		assert_eq(cards[0]["faction"], "collective")
	)

	run_case("rival_move_queues_then_plays_once_in_the_next_meeting", func():
		_clear()
		_ore_share("life", 30)
		var board: Dictionary = GameState.state["boardMeetings"]
		board["rungs"]["market_share"] = { "share_first": { "status": "done", "day": 5, "ore": "life" } }
		Overlaps.update_spine()
		assert_true(board["rivalMove"] == null, "share target not done yet")
		BoardMeetings.mark_spine_done("share_target")
		Overlaps.update_spine()
		assert_eq(board["rivalMove"]["ore"], "life")
		assert_true(not BoardMeetings.spine_done("rival_move"), "waits for the meeting")
		assert_eq(GameState.state["messages"].get("archie", []).size(), 0, "no live text")
		var context := BoardMeetings.meeting_context(1)
		assert_true(context["rivalMove"].size() >= 1, "plays in the meeting")
		assert_true(BoardMeetings.spine_done("rival_move"))
		assert_true(BoardMeetings.meeting_context(2)["rivalMove"].is_empty(), "only once")
	)

	run_case("partner_beat_completes_in_any_order", func():
		_clear()
		Overlaps.update_spine()
		assert_true(not BoardMeetings.spine_done("partner"))
		GameState.state["factionStances"]["player"]["guild"]["stance"] = FactionAI.PARTNER
		Overlaps.update_spine()
		assert_true(BoardMeetings.spine_done("partner"))
		assert_true(not BoardMeetings.spine_done("share_target"))
	)


func _rival_played(faction_id: String = "firm") -> void:
	var board: Dictionary = GameState.state["boardMeetings"]
	board["rivalMove"] = { "faction": faction_id, "ore": "life" }
	BoardMeetings.mark_spine_done("share_target")
	BoardMeetings.meeting_context(1)


func run_act2_endgame() -> void:
	run_case("weather_completes_after_quiet_days", func():
		_clear()
		_rival_played()
		Overlaps.update_spine()
		assert_true(not BoardMeetings.spine_done("weather_or_soften"), "too soon")
		GameState.state["world"]["day"] += 6
		Overlaps.update_spine()
		assert_true(not BoardMeetings.spine_done("weather_or_soften"), "just short")
		GameState.state["world"]["day"] += 1
		Overlaps.update_spine()
		assert_true(BoardMeetings.spine_done("weather_or_soften"))
	)

	run_case("a_lost_vein_or_walked_guard_blocks_weather", func():
		_clear()
		_rival_played()
		GameState.state["world"]["day"] += 8
		GameState.state["factionEscalation"]["lastVeinLostDay"] = 12
		Overlaps.update_spine()
		assert_true(not BoardMeetings.spine_done("weather_or_soften"), "vein lost")
		GameState.state["factionEscalation"]["lastVeinLostDay"] = -1
		GameState.state["guardUpkeep"]["lastWalkDay"] = 13
		Overlaps.update_spine()
		assert_true(not BoardMeetings.spine_done("weather_or_soften"), "guard walked")
	)

	run_case("soften_completes_on_relation_gain", func():
		_clear()
		_set_relation("firm", 0)
		_rival_played()
		_set_relation("firm", 9)
		Overlaps.update_spine()
		assert_true(not BoardMeetings.spine_done("weather_or_soften"))
		_set_relation("firm", 10)
		Overlaps.update_spine()
		assert_true(BoardMeetings.spine_done("weather_or_soften"))
	)

	run_case("debrief_fires_once_when_every_other_beat_is_done", func():
		_clear()
		for beat in ["share_target", "supplier_contract", "rival_move", "partner"]:
			BoardMeetings.mark_spine_done(beat)
		Overlaps.update_spine()
		assert_true(not GameState.state["boardMeetings"]["debriefPending"], "weather_or_soften outstanding")
		BoardMeetings.mark_spine_done("weather_or_soften")
		Overlaps.update_spine()
		assert_true(GameState.state["boardMeetings"]["debriefPending"])
		assert_true(not BoardMeetings.spine_done("debrief"), "waits for the meeting")
		assert_true(BoardMeetings.meeting_context(2)["debrief"].size() >= 1)
		assert_true(BoardMeetings.spine_done("debrief"))
		assert_true(BoardMeetings.meeting_context(3)["debrief"].is_empty(), "only once")
		assert_true(Todo.get_act2_section()["status"] == "done", "Act 2 complete")
	)

	run_case("meetings_continue_after_act2", func():
		_clear()
		BoardMeetings.mark_spine_done("debrief")
		GameState.state["flags"][GameData.BOARD_MEETING["enableFlag"]] = true
		GameState.state["world"]["day"] = Calendar.next_weekday_after(10, 0)
		BoardMeetings.monday_rollover()
		assert_true(BoardMeetings.meeting_pending())
	)

	run_case("defuse_card_reads_clash_kinds_only", func():
		_clear()
		_ore_share("life", 30)
		var cards := BoardMeetings.eligible_cards().filter(func(c: Dictionary) -> bool: return c["ladder"] == "defuse")
		assert_true(not cards.is_empty(), "provocation overlap offers Defuse")
		assert_eq(cards[0]["voice"], "james")
		_clear()
		assert_true(BoardMeetings.eligible_cards().filter(func(c: Dictionary) -> bool: return c["ladder"] == "defuse").is_empty())
	)
