extends "res://tests/test_base.gd"

# Board meetings (R§3.15, .scratch/board-meetings/spec.md §"Testing
# Decisions" seam 1): eligibility, seeded agenda, choose/skip, stretch lock,
# judgement, state purity; plus the reserve_weeks_at_least condition.

const WEEKLY_EXPENSES := 100


# Puts `total` of expenses into the last completed day's snapshot, so
# BusinessStats.weekly_expenses() reads it.
func _set_expenses(total: int) -> void:
	var day: int = GameState.state["world"]["day"]
	GameState.state["businessStats"]["days"] = [{ "day": day - 1, "expenses": total }]


func _set_float(amount: int) -> void:
	GameState.state["business"]["float"] = amount


func _enabled_game() -> void:
	GameState.reset()
	GameState.state["world"]["day"] = 10
	GameState.state["boardMeetings"]["enabled"] = true
	GameState.state["boardMeetings"]["week"] = 1
	_set_expenses(WEEKLY_EXPENSES)
	_set_float(0)


func _rung(id: String, rewards: Dictionary = {}) -> Dictionary:
	return {
		"id": id, "premise": { "kind": "weekly_expenses_above", "amount": 0 },
		"goal": { "type": "reserve_weeks_at_least", "params": {} },
		"tiers": { "base": { "minWeeks": 2 }, "target": { "minWeeks": 3 }, "stretch": { "minWeeks": 4 } },
		"lengthWeeks": 1, "rewards": rewards, "pinned": false, "spine": null, "permanent": false,
	}


# Synthetic ladders: two for Archie, one each for James and Owen.
func _install_ladders() -> Dictionary:
	var original: Dictionary = GameData.BOARD_LADDERS
	GameData.BOARD_LADDERS = {
		"a1": { "voice": "archie", "rungs": [_rung("a1_r")] },
		"a2": { "voice": "archie", "rungs": [_rung("a2_r")] },
		"j1": { "voice": "james", "rungs": [_rung("j1_r")] },
		"o1": { "voice": "owen", "rungs": [_rung("o1_r")] },
	}
	return original


func _set_owen_rarity(value: float) -> float:
	var original := float(GameData.BOARD_VOICES["owen"]["pitchRarity"])
	GameData.BOARD_VOICES["owen"]["pitchRarity"] = value
	return original


func _voices(cards: Array) -> Array:
	var out: Array = []
	for card in cards:
		out.append(card["voice"])
	return out


func _choose_financial() -> void:
	var cards := BoardMeetings.agenda(1)
	assert_eq(cards.size(), 1, "sanity: only the Financial card is live")
	assert_true(BoardMeetings.choose(cards[0]["id"])["ok"])


func _pearls() -> int:
	return int(GameState.state["player"]["inventory"]["timePearl"].get("1", 0))


func _relation(contact_id: String) -> int:
	return int(GameState.state["contacts"][contact_id]["relation"])


# Player harvest of `amount` per day for the `days` days before today.
func _harvest(amount: int, days: int) -> void:
	var today: int = GameState.state["world"]["day"]
	for offset in range(1, days + 1):
		GameState.state["world"]["day"] = today - offset
		Shares.record_ore("player", "life", amount)
	GameState.state["world"]["day"] = today


func _mark_done(rung_id: String) -> void:
	var board: Dictionary = GameState.state["boardMeetings"]
	if not board["rungs"].has("cultivation"):
		board["rungs"]["cultivation"] = {}
	board["rungs"]["cultivation"][rung_id] = { "status": "done", "day": 1 }


# Offers the week-1 agenda with Owen certain to pitch, asserts the named
# cultivation rung is among the cards, and chooses it.
func _pick_cultivation_card(rung_id: String) -> void:
	var rarity := _set_owen_rarity(1.0)
	var cards := BoardMeetings.agenda(1)
	_set_owen_rarity(rarity)
	var picked := ""
	for card in cards:
		if card["ladder"] == "cultivation":
			picked = card["id"]
			assert_eq(card["rung"], rung_id)
	assert_true(BoardMeetings.choose(picked)["ok"], "cultivation card %s offered" % rung_id)


# A player with a vein and a 10-day harvest history, so Owen's first rung
# is live next to James's financial rung.
func _cultivation_ready() -> void:
	GameState.state["player"]["veins"].append(Cultivating.make_vein("life", 50, "", null, {}))
	_harvest(5, 10)


# Continues the live event until it awaits a pick or ends; capped.
func _advance_to_choice() -> void:
	for i in 10:
		if GameState.state["event"] == null or Events.is_awaiting_choice():
			return
		Events.advance()


# Continues the live event to its end; capped.
func _finish_event() -> void:
	for i in 10:
		if GameState.state["event"] == null:
			return
		Events.advance()


# Opens week 1 with the synthetic ladders and starts its meeting at the hub.
func _meeting_at_hub() -> Dictionary:
	_enabled_game()
	GameState.state["boardMeetings"]["week"] = 0
	var original := _install_ladders()
	BoardMeetings.open_week()
	assert_true(BoardMeetings.maybe_start_meeting(), "the pending meeting starts")
	_advance_to_choice()
	return original


func run() -> void:
	# ── data ─────────────────────────────────────────────────────────────

	run_case("financial_placeholder_tiers_are_2_3_4_weeks", func():
		var rung: Dictionary = GameData.BOARD_LADDERS["financial"]["rungs"][0]
		assert_eq(GameData.BOARD_LADDERS["financial"]["voice"], "james")
		assert_eq(rung["goal"]["type"], Objectives.TYPE_RESERVE_WEEKS_AT_LEAST)
		assert_eq(int(rung["tiers"]["base"]["minWeeks"]), 2)
		assert_eq(int(rung["tiers"]["target"]["minWeeks"]), 3)
		assert_eq(int(rung["tiers"]["stretch"]["minWeeks"]), 4)
	)

	run_case("no_tier_rewards_a_rewind", func():
		for ladder_id in GameData.BOARD_LADDERS:
			for rung in GameData.BOARD_LADDERS[ladder_id]["rungs"]:
				for tier in rung["rewards"]:
					for reward in rung["rewards"][tier]:
						assert_true(reward.get("id", "") != "rewind", "%s/%s" % [rung["id"], tier])
	)

	# ── reserve_weeks_at_least ───────────────────────────────────────────

	var reserve_def := { "id": "t", "type": Objectives.TYPE_RESERVE_WEEKS_AT_LEAST, "params": { "minWeeks": 2 } }
	var expected := { 199: false, 200: true, 201: true }
	for float_amount in expected.keys():
		run_case("reserve_2_weeks_of_100_with_float_%d_is_%s" % [float_amount, expected[float_amount]], func():
			_enabled_game()
			_set_float(float_amount)
			assert_eq(Objectives.evaluate(reserve_def), expected[float_amount])
		)

	run_case("reserve_never_met_with_no_expenses", func():
		_enabled_game()
		_set_expenses(0)
		_set_float(10000)
		assert_eq(Objectives.evaluate(reserve_def), false)
	)

	run_case("weekly_expenses_sum_only_the_last_7_completed_days", func():
		GameState.reset()
		GameState.state["world"]["day"] = 20
		GameState.state["businessStats"]["days"] = [
			{ "day": 12, "expenses": 1000 }, { "day": 13, "expenses": 30 }, { "day": 19, "expenses": 70 },
		]
		assert_eq(BusinessStats.weekly_expenses(), 100, "day 12 is outside days 13-19")
	)

	run_case("reserve_counts_the_business_float_not_player_cash", func():
		_enabled_game()
		GameState.state["player"]["cash"] = 100000
		GameState.state["business"]["pot"] = 100000
		assert_eq(Objectives.evaluate(reserve_def), false)
	)

	run_case("financial_card_prose_fills_live_reserve_tokens", func():
		_enabled_game()
		_set_float(250)
		var template: Dictionary = GameData.BOARD_TEMPLATES["fin_reserve"]
		assert_true(template["pitch"] is Array and template["why"] is Array, "variant lists")
		for i in template["why"].size():
			var card := { "id": "c%d" % i, "template": "fin_reserve" }
			var why: String = BoardMeetings.card_tokens_prose(template, "why", card)
			assert_true(not why.contains("{"), "tokens filled: " + why)
			assert_eq(BoardMeetings.card_tokens_prose(template, "why", card), why, "stable per card")
		var text: String = BoardMeetings.card_tokens_prose({ "why": "{expenses} {float} {weeks}" }, "why", { "id": "x" })
		assert_eq(text, "£100 £250 2.5")
	)

	# ── eligibility ──────────────────────────────────────────────────────

	run_case("financial_rung_absent_while_its_premise_is_false", func():
		_enabled_game()
		_set_expenses(0)
		assert_eq(BoardMeetings.eligible_cards(), [])
	)

	run_case("financial_rung_offered_when_premise_true_and_target_unmet", func():
		_enabled_game()
		_set_float(250)
		var cards := BoardMeetings.eligible_cards()
		assert_eq(cards.size(), 1)
		assert_eq(cards[0]["id"], "financial:fin_reserve")
		assert_eq(cards[0]["voice"], "james")
		assert_eq(cards[0]["preview"]["base"], "£100")
	)

	run_case("a_rung_already_met_is_recorded_skipped_and_not_offered", func():
		_enabled_game()
		_set_float(300)
		assert_eq(BoardMeetings.eligible_cards(), [])
		assert_eq(BoardMeetings.rung_status("financial", "fin_reserve"), BoardMeetings.RUNG_SKIPPED)
		_set_float(0)
		assert_eq(BoardMeetings.eligible_cards(), [], "a skipped rung stays skipped")
	)

	run_case("disabled_board_offers_no_agenda", func():
		_enabled_game()
		GameState.state["boardMeetings"]["enabled"] = false
		assert_eq(BoardMeetings.agenda(1), [])
	)

	# ── agenda ───────────────────────────────────────────────────────────

	run_case("agenda_is_three_distinct_voices", func():
		_enabled_game()
		var original := _install_ladders()
		var rarity := _set_owen_rarity(1.0)
		var voices := _voices(BoardMeetings.agenda(1))
		voices.sort()
		assert_eq(voices, ["archie", "james", "owen"])
		GameData.BOARD_LADDERS = original
		_set_owen_rarity(rarity)
	)

	run_case("archie_fills_owens_slot_when_owen_has_no_card", func():
		_enabled_game()
		var original := _install_ladders()
		var rarity := _set_owen_rarity(0.0)
		var voices := _voices(BoardMeetings.agenda(1))
		voices.sort()
		assert_eq(voices, ["archie", "archie", "james"])
		GameData.BOARD_LADDERS = original
		_set_owen_rarity(rarity)
	)

	run_case("same_seed_and_week_give_the_same_agenda", func():
		_enabled_game()
		var original := _install_ladders()
		GameState.state["world"]["rollSeed"] = 12345
		var first: Array = GameState.deep_copy(BoardMeetings.agenda(4))
		GameState.state["boardMeetings"]["agenda"] = []
		GameState.state["boardMeetings"]["agendaWeek"] = 0
		GameState.state["boardMeetings"]["lastCompeting"] = 0
		assert_eq(BoardMeetings.agenda(4), first)
		GameData.BOARD_LADDERS = original
	)

	run_case("competing_beat_links_same_ore_cards_without_changing_rewards", func():
		_enabled_game()
		var original_chance: float = GameData.BOARD_TUNING["competingChance"]
		GameData.BOARD_TUNING["competingChance"] = 1.0
		var cards: Array = [
			{ "id": "a", "ore": "time", "rewards": { "base": [] } },
			{ "id": "b", "ore": "time", "rewards": { "base": [] } },
			{ "id": "c", "ore": "life", "rewards": { "base": [] } },
		]
		var before: Array = GameState.deep_copy(cards)
		BoardMeetings._mark_competing(cards, 3)
		assert_eq(cards[0]["competesWith"], "b")
		assert_eq(cards[1]["competesWith"], "a")
		assert_true(not cards[2].has("competesWith"))
		assert_eq(cards[0]["rewards"], before[0]["rewards"])
		assert_eq(int(GameState.state["boardMeetings"]["lastCompeting"]), 3)
		GameData.BOARD_TUNING["competingChance"] = original_chance
	)

	run_case("competing_beat_respects_the_cap_window", func():
		_enabled_game()
		var original_chance: float = GameData.BOARD_TUNING["competingChance"]
		GameData.BOARD_TUNING["competingChance"] = 1.0
		var cap := int(GameData.BOARD_TUNING["competingCapWeeks"])
		var fired: Array = []
		for week in range(1, 40):
			var cards: Array = [{ "id": "a", "ore": "time" }, { "id": "b", "ore": "time" }]
			BoardMeetings._mark_competing(cards, week)
			if cards[0].has("competesWith"):
				fired.append(week)
		for i in range(1, fired.size()):
			assert_true(fired[i] - fired[i - 1] >= cap, "gap %d" % (fired[i] - fired[i - 1]))
		assert_true(fired.size() >= 2)
		GameData.BOARD_TUNING["competingChance"] = original_chance
	)

	run_case("a_different_card_can_be_chosen_after_a_snapshot_restore", func():
		_enabled_game()
		var original := _install_ladders()
		var rarity := _set_owen_rarity(1.0)
		var cards := BoardMeetings.agenda(1)
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		assert_true(BoardMeetings.choose(cards[0]["id"])["ok"])
		GameState.state = GameState.deep_copy(snapshot)
		assert_eq(BoardMeetings.agenda(1), cards, "restored agenda is what was shown")
		assert_true(BoardMeetings.choose(cards[1]["id"])["ok"])
		assert_eq(GameState.state["boardMeetings"]["active"]["cardId"], cards[1]["id"])
		GameData.BOARD_LADDERS = original
		_set_owen_rarity(rarity)
	)

	# ── choose / skip ────────────────────────────────────────────────────

	run_case("choose_writes_the_goal_warms_the_pitcher_and_bumps_unpicked_voices", func():
		_enabled_game()
		var original := _install_ladders()
		var rarity := _set_owen_rarity(1.0)
		var contacts: Dictionary = GameState.state["contacts"]
		var archie_before := int(contacts["archie"]["relation"])
		var james_before := int(contacts["james"]["relation"])
		var owen_before := int(contacts["owen"]["relation"])
		var james_card: Dictionary = {}
		for card in BoardMeetings.agenda(1):
			if card["voice"] == "james":
				james_card = card
		assert_true(BoardMeetings.choose(james_card["id"])["ok"])
		var board: Dictionary = GameState.state["boardMeetings"]
		assert_eq(board["active"]["cardId"], james_card["id"])
		assert_eq(board["active"]["goal"]["type"], Objectives.TYPE_RESERVE_WEEKS_AT_LEAST)
		assert_eq(board["active"]["lockedTier"], Objectives.TIER_NONE)
		assert_eq(board["active"]["skip"], false)
		assert_eq(int(contacts["james"]["relation"]), james_before + int(GameData.BOARD_VOICES["james"]["warmth"]))
		assert_eq(int(contacts["archie"]["relation"]), archie_before)
		assert_eq(int(contacts["owen"]["relation"]), owen_before)
		assert_almost_eq(board["voiceWeights"]["archie"], 1.5, 0.001)
		assert_almost_eq(board["voiceWeights"]["owen"], 1.5, 0.001)
		assert_almost_eq(board["voiceWeights"]["james"], 1.0, 0.001)
		assert_eq(BoardMeetings.choose(james_card["id"])["ok"], false, "one goal at a time")
		GameData.BOARD_LADDERS = original
		_set_owen_rarity(rarity)
	)

	run_case("a_voice_with_two_offered_cards_is_bumped_once", func():
		_enabled_game()
		var original := _install_ladders()
		var rarity := _set_owen_rarity(0.0)
		for card in BoardMeetings.agenda(1):
			if card["voice"] == "james":
				BoardMeetings.choose(card["id"])
		assert_almost_eq(GameState.state["boardMeetings"]["voiceWeights"]["archie"], 1.5, 0.001)
		GameData.BOARD_LADDERS = original
		_set_owen_rarity(rarity)
	)

	run_case("skip_takes_archies_card_and_flags_the_skip", func():
		_enabled_game()
		var original := _install_ladders()
		var archie_before := int(GameState.state["contacts"]["archie"]["relation"])
		BoardMeetings.agenda(1)
		assert_true(BoardMeetings.skip()["ok"])
		var active: Dictionary = GameState.state["boardMeetings"]["active"]
		assert_eq(active["voice"], "archie")
		assert_eq(active["skip"], true)
		assert_eq(int(GameState.state["contacts"]["archie"]["relation"]), archie_before, "a skip warms nobody")
		GameData.BOARD_LADDERS = original
	)

	run_case("skip_fails_without_an_archie_card", func():
		_enabled_game()
		BoardMeetings.agenda(1)
		assert_eq(BoardMeetings.skip()["ok"], false)
		assert_eq(GameState.state["boardMeetings"]["active"], null)
	)

	# ── stretch lock and judgement ───────────────────────────────────────

	run_case("stretch_locks_mid_week_and_survives_a_dip", func():
		_enabled_game()
		_choose_financial()
		_set_float(400)
		Objectives.refresh()
		assert_eq(GameState.state["boardMeetings"]["active"]["lockedTier"], "stretch")
		_set_float(0)
		var cash_before: int = GameState.state["player"]["cash"]
		var entry := BoardMeetings.judge_week()
		assert_eq(entry["result"], "stretch")
		assert_eq(int(GameState.state["player"]["cash"]), cash_before + 400)
	)

	var judged := {
		0: { "result": "missed", "cash": 0, "pearls": 0 },
		200: { "result": "base", "cash": 100, "pearls": 0 },
		300: { "result": "target", "cash": 250, "pearls": 1 },
		400: { "result": "stretch", "cash": 400, "pearls": 1 },
	}
	for float_amount in judged.keys():
		run_case("judge_with_float_%d_is_%s" % [float_amount, judged[float_amount]["result"]], func():
			_enabled_game()
			_choose_financial()
			_set_float(float_amount)
			var cash_before: int = GameState.state["player"]["cash"]
			var entry := BoardMeetings.judge_week()
			var want: Dictionary = judged[float_amount]
			assert_eq(entry["result"], want["result"])
			assert_eq(int(GameState.state["player"]["cash"]) - cash_before, want["cash"])
			assert_eq(_pearls(), want["pearls"])
			var board: Dictionary = GameState.state["boardMeetings"]
			assert_eq(board["active"], null)
			assert_eq(board["history"].size(), 1)
			assert_eq(board["history"][0]["rung"], "fin_reserve")
			assert_eq(board["history"][0]["voice"], "james")
			assert_eq(board["history"][0]["week"], 1)
		)

	run_case("a_missed_goal_costs_nothing_and_leaves_the_rung_open", func():
		_enabled_game()
		_choose_financial()
		var relation_before := int(GameState.state["contacts"]["james"]["relation"])
		BoardMeetings.judge_week()
		assert_eq(int(GameState.state["contacts"]["james"]["relation"]), relation_before)
		assert_eq(GameState.state["boardMeetings"]["history"][0]["reward"], [])
		assert_eq(BoardMeetings.rung_status("financial", "fin_reserve"), "")
	)

	run_case("a_target_result_marks_the_rung_done", func():
		_enabled_game()
		_choose_financial()
		_set_float(300)
		BoardMeetings.judge_week()
		assert_eq(BoardMeetings.rung_status("financial", "fin_reserve"), BoardMeetings.RUNG_DONE)
	)

	run_case("history_is_capped", func():
		_enabled_game()
		var original_cap: int = GameData.BOARD_TUNING["historyLength"]
		GameData.BOARD_TUNING["historyLength"] = 2
		for week in [1, 2, 3]:
			GameState.state["boardMeetings"]["week"] = week
			GameState.state["boardMeetings"]["agenda"] = []
			_choose_financial()
			BoardMeetings.judge_week()
		var history: Array = GameState.state["boardMeetings"]["history"]
		assert_eq(history.size(), 2)
		assert_eq(history[0]["week"], 2)
		GameData.BOARD_TUNING["historyLength"] = original_cap
	)

	run_case("judge_with_no_active_goal_does_nothing", func():
		_enabled_game()
		assert_eq(BoardMeetings.judge_week(), {})
		assert_eq(GameState.state["boardMeetings"]["history"], [])
	)

	# ── meeting event + rollover ─────────────────────────────────────────

	run_case("act_1_closing_enables_meetings_and_the_next_monday_is_week_1", func():
		GameState.reset()
		var monday := Calendar.monday_on_or_after(10)
		GameState.state["world"]["day"] = monday - 3
		TimeSystem.do_rest()
		assert_true(not GameState.state["boardMeetings"]["enabled"], "no closing, no meetings")
		GameState.state["flags"]["bizA1Complete"] = true
		TimeSystem.do_rest()
		var board: Dictionary = GameState.state["boardMeetings"]
		assert_true(board["enabled"], "the closing flag enables meetings at rollover")
		assert_eq(board["week"], 0, "no meeting off a Monday")
		TimeSystem.do_rest()
		assert_eq(int(GameState.state["world"]["day"]), monday)
		assert_eq(board["week"], 1, "first Monday on or after the flag is Week 1")
		assert_eq(board["firstMeetingDay"], monday)
		assert_true(BoardMeetings.meeting_pending())
		assert_true(BoardMeetings.maybe_start_meeting())
		assert_eq(GameState.state["event"]["eventId"], "board_meeting_week1", "Week 1 is the scripted meeting")
		assert_true(not BoardMeetings.meeting_pending(), "starting clears the pending meeting")
	)

	run_case("monday_rollover_judges_the_goal_after_payday_then_queues_the_meeting", func():
		_enabled_game()
		var monday := Calendar.monday_on_or_after(10)
		GameState.state["world"]["day"] = monday - 1
		_set_expenses(WEEKLY_EXPENSES)
		Business.activate()
		_choose_financial()
		_set_float(350)
		assert_eq(BoardMeetings.current_tier(), "target", "sanity: before payday the float covers 3.5 weeks")
		var goal: Dictionary = GameState.deep_copy(GameState.state["boardMeetings"]["active"]["goal"])
		var ledger_before: int = GameState.state["business"]["ledger"].size()
		TimeSystem.do_rest()
		assert_eq(GameState.state["business"]["ledger"].size(), ledger_before + 1, "payday ran")
		var board: Dictionary = GameState.state["boardMeetings"]
		var entry: Dictionary = board["history"].back()
		var after := Objectives.tier_met(goal)
		assert_eq(entry["result"], BoardMeetings.RESULT_MISSED if after == Objectives.TIER_NONE else after, "judged on the post-payday books")
		assert_true(entry["result"] != "target", "payday's wage draw counted")
		assert_eq(entry["week"], 1)
		assert_eq(board["active"], null)
		assert_eq(board["week"], 2)
		assert_true(BoardMeetings.meeting_pending(), "the meeting is queued")
		var block: int = GameState.state["world"]["timeBlock"]
		assert_true(BoardMeetings.maybe_start_meeting())
		assert_eq(GameState.state["event"]["eventId"], "board_meeting")
		assert_true(String(Events.revealed_cards()[0]["text"]).contains(BoardMeetings.card_label(entry)), "minutes read last week's result")
		_advance_to_choice()
		Events.choose(Events.hub_exit_index())
		_finish_event()
		assert_eq(GameState.state["event"], null)
		assert_eq(GameState.state["world"]["timeBlock"], block, "the meeting spends no time block")
	)

	run_case("a_live_event_holds_the_meeting_until_it_ends", func():
		_enabled_game()
		GameState.state["boardMeetings"]["pendingWeek"] = 2
		GameState.state["event"] = { "eventId": "x" }
		assert_true(not BoardMeetings.maybe_start_meeting(), "held while an event is live")
		assert_true(BoardMeetings.meeting_pending())
		GameState.state["event"] = null
	)

	run_case("agenda_hub_offers_the_three_cards_with_tokens_filled_and_a_skip_exit", func():
		var rarity := _set_owen_rarity(1.0)
		var original := _meeting_at_hub()
		var agenda: Array = GameState.state["boardMeetings"]["agenda"]
		var choices: Array = Events.current_card()["choices"]
		assert_eq(agenda.size(), 3, "sanity: three voices pitch")
		assert_eq(choices.size(), agenda.size() + 1, "one option per agenda card + exit")
		assert_eq(Events.hub_exit_index(), agenda.size(), "skip exit last")
		for i in agenda.size():
			var name: String = GameData.BOARD_VOICES[agenda[i]["voice"]]["name"]
			assert_eq(choices[i]["label"], "%s: %s" % [name, BoardMeetings.card_label(agenda[i])], "option %d label filled" % i)
		var hub_text: String = Events.revealed_cards().back()["text"]
		assert_true(not hub_text.contains("{"), "no unfilled tokens")
		assert_true(hub_text.contains("Base 2 · Target 3 · Stretch 4"), "tier numbers")
		assert_true(hub_text.contains("Pays: "), "reward preview line")
		var pitcher: String = GameData.BOARD_VOICES[agenda[0]["voice"]]["contactId"]
		var before := _relation(pitcher)
		Events.choose(0)
		var active: Dictionary = GameState.state["boardMeetings"]["active"]
		assert_eq(active["cardId"], agenda[0]["id"], "picked card is the goal")
		assert_true(not active["skip"])
		assert_eq(_relation(pitcher), before + int(GameData.BOARD_VOICES[agenda[0]["voice"]]["warmth"]))
		_finish_event()
		assert_eq(GameState.state["event"], null, "the meeting runs to its end")
		GameData.BOARD_LADDERS = original
		_set_owen_rarity(rarity)
		GameState.state["event"] = null
	)

	run_case("leaving_the_meeting_without_choosing_makes_archies_card_the_goal", func():
		var original := _meeting_at_hub()
		Events.choose(Events.hub_exit_index())
		var active: Dictionary = GameState.state["boardMeetings"]["active"]
		assert_eq(active["voice"], "archie")
		assert_true(active["skip"])
		_finish_event()
		GameData.BOARD_LADDERS = original
		GameState.state["event"] = null
	)

	run_case("debug_jump_starts_a_meeting_with_the_current_state", func():
		GameState.reset()
		var day: int = GameState.state["world"]["day"]
		DebugTools.board_jump_to_meeting()
		var board: Dictionary = GameState.state["boardMeetings"]
		assert_true(board["enabled"])
		assert_eq(board["week"], 1)
		assert_eq(GameState.state["event"]["eventId"], "board_meeting_week1")
		assert_eq(int(GameState.state["world"]["day"]), day, "the calendar doesn't move")
		GameState.state["event"] = null
	)

	# ── state purity ─────────────────────────────────────────────────────

	run_case("board_state_survives_a_save_round_trip_unchanged", func():
		_enabled_game()
		var original := _install_ladders()
		BoardMeetings.agenda(1)
		BoardMeetings.skip()
		var before: Dictionary = GameState.deep_copy(GameState.state["boardMeetings"])
		assert_true(SaveManager.import_string(SaveManager.export_string())["ok"])
		assert_eq(GameState.state["boardMeetings"], before)
		GameData.BOARD_LADDERS = original
	)

	# ── market share ladder + Act 2 spine ────────────────────────────────

	run_case("share_card_names_the_best_producing_ore_and_stays_pinned_until_taken", func():
		_enabled_game()
		assert_eq(BoardMeetings.eligible_cards().filter(func(c): return c["ladder"] == "market_share").size(), 0, "no production: no share card")
		Shares.record_ore("player", "life", 10)
		Shares.record_ore("firm", "life", 90)
		Shares.record_ore("player", "time", 5)
		Shares.record_ore("firm", "time", 95)
		var cards := BoardMeetings.agenda(1)
		assert_eq(cards[0]["rung"], "share_first", "pinned card first")
		assert_eq(cards[0]["ore"], "life", "the ore where the player's share is highest")
		assert_eq(cards[0]["goal"]["params"]["oreType"], "life")
		assert_true(cards.size() >= 2, "the other slots stay free")
		GameState.state["boardMeetings"]["agendaWeek"] = 0
		var week2 := BoardMeetings.agenda(2)
		assert_eq(week2[0]["rung"], "share_first", "passing keeps it next week")
		assert_true(not (BoardMeetings.spine_done("share_target")))
		assert_true(not (BoardMeetings.spine_unlocked("supplier_contract")))
	)

	run_case("completing_the_share_card_marks_spine_beat_one_done", func():
		_enabled_game()
		Shares.record_ore("player", "life", 10)
		Shares.record_ore("firm", "life", 90)
		BoardMeetings.agenda(1)
		assert_true(BoardMeetings.choose(BoardMeetings.card_id("market_share", "share_first"))["ok"])
		Shares.record_ore("player", "life", 20)
		BoardMeetings.judge_week()
		assert_eq(BoardMeetings.rung_status("market_share", "share_first"), "done")
		assert_true(BoardMeetings.spine_done("share_target"))
		assert_true(BoardMeetings.spine_unlocked("supplier_contract"))
	)

	run_case("already_met_share_rungs_are_skipped_and_later_rungs_open_from_state", func():
		_enabled_game()
		Shares.record_ore("player", "life", 41)
		Shares.record_ore("firm", "life", 59)
		Shares.record_ore("player", "time", 10)
		Shares.record_ore("firm", "time", 90)
		var cards := BoardMeetings.eligible_cards().filter(func(c): return c["ladder"] == "market_share")
		assert_eq(BoardMeetings.rung_status("market_share", "share_first"), "skipped", "41% beats the 25% target")
		assert_true(BoardMeetings.spine_done("share_target"), "a skipped spine rung still completes its beat")
		assert_eq(BoardMeetings.rung_status("market_share", "share_higher"), "skipped", "41% beats the 40% target")
		assert_eq(cards.size(), 1)
		assert_eq(cards[0]["rung"], "share_leader", "the first rung not already met (41% does not lead)")
	)

	run_case("second_ore_rung_avoids_ores_the_ladder_already_used", func():
		_enabled_game()
		Shares.record_ore("player", "life", 60)
		Shares.record_ore("firm", "life", 40)
		Shares.record_ore("player", "time", 10)
		Shares.record_ore("firm", "time", 90)
		var board: Dictionary = GameState.state["boardMeetings"]
		board["rungs"]["market_share"] = {
			"share_first": { "status": "done", "day": 1, "ore": "life" }, "share_higher": { "status": "done", "day": 2, "ore": "life" },
			"share_leader": { "status": "done", "day": 3, "ore": "life" },
		}
		var cards := BoardMeetings.eligible_cards().filter(func(c): return c["ladder"] == "market_share")
		assert_eq(cards[0]["rung"], "share_second")
		assert_eq(cards[0]["ore"], "time")
	)

	# ── Cultivation ladder (Owen) ────────────────────────────────────────

	run_case("cultivation_ladder_is_owens_with_placeholder_yield_tiers", func():
		var ladder: Dictionary = GameData.BOARD_LADDERS["cultivation"]
		assert_eq(ladder["voice"], "owen")
		assert_eq(ladder["rungs"].size(), 4)
		var tiers: Dictionary = ladder["rungs"][0]["tiers"]
		assert_eq(ladder["rungs"][0]["goal"]["type"], Objectives.TYPE_YIELD_MULTIPLE_AT_LEAST)
		assert_eq(float(tiers["base"]["multiple"]), 1.1)
		assert_eq(float(tiers["target"]["multiple"]), 1.25)
		assert_eq(float(tiers["stretch"]["multiple"]), 1.4)
		assert_true(float(GameData.BOARD_VOICES["owen"]["pitchRarity"]) < 1.0, "Owen pitches rarely, from data")
	)

	run_case("yield_rung_needs_a_harvest_baseline_to_open", func():
		_enabled_game()
		GameState.state["player"]["veins"].append(Cultivating.make_vein("life", 50, "", null, {}))
		var no_baseline := BoardMeetings.eligible_cards().filter(func(c): return c["rung"] == "cult_yield")
		assert_eq(no_baseline.size(), 0, "no harvest in the prior 10 days")
		_harvest(5, 10)
		var with_baseline := BoardMeetings.eligible_cards().filter(func(c): return c["rung"] == "cult_yield")
		assert_eq(with_baseline.size(), 1)
	)

	run_case("choosing_the_yield_card_captures_the_prior_ten_day_average", func():
		_enabled_game()
		GameState.state["player"]["veins"].append(Cultivating.make_vein("life", 50, "", null, {}))
		_harvest(10, 10)
		_pick_cultivation_card("cult_yield")
		var active: Dictionary = GameState.state["boardMeetings"]["active"]
		assert_eq(float(active["progress"]["yieldBaseline"]), 10.0)
		assert_eq(int(active["progress"]["sinceDay"]), 10)
		# baseline 10/day x 7 = 70; x1.1 = 77, x1.25 = 87.5, x1.4 = 98
		var goal: Dictionary = active["goal"]
		assert_eq(Objectives.tier_met(goal, active["progress"]), "none")
		Shares.record_ore("player", "life", 76)
		assert_eq(Objectives.tier_met(goal, active["progress"]), "none", "76 < 77")
		Shares.record_ore("player", "life", 1)
		assert_eq(Objectives.tier_met(goal, active["progress"]), "base", "77 = 1.1 x 70")
		Shares.record_ore("player", "life", 11)
		assert_eq(Objectives.tier_met(goal, active["progress"]), "target", "88 >= 87.5")
		Shares.record_ore("player", "life", 10)
		assert_eq(Objectives.tier_met(goal, active["progress"]), "stretch", "98 = 1.4 x 70")
	)

	run_case("yield_goal_ignores_harvest_after_the_goal_week", func():
		_enabled_game()
		GameState.state["player"]["veins"].append(Cultivating.make_vein("life", 50, "", null, {}))
		_harvest(10, 10)
		_pick_cultivation_card("cult_yield")
		var active: Dictionary = GameState.state["boardMeetings"]["active"]
		GameState.state["world"]["day"] = 17
		Shares.record_ore("player", "life", 500)
		assert_eq(Objectives.tier_met(active["goal"], active["progress"]), "none", "day 17 is past the 7-day goal week")
	)

	run_case("new_vein_rung_counts_only_veins_claimed_since_choose", func():
		_enabled_game()
		var old_vein := Cultivating.make_vein("life", 80, "", null, {})
		old_vein["claimedOnDay"] = 3
		GameState.state["player"]["veins"].append(old_vein)
		_mark_done("cult_yield")
		_pick_cultivation_card("cult_new_vein")
		var active: Dictionary = GameState.state["boardMeetings"]["active"]
		assert_eq(Objectives.tier_met(active["goal"], active["progress"]), "none", "the old vein is not new")
		var fresh := Cultivating.make_vein("time", 30, "", null, {})
		GameState.state["player"]["veins"].append(fresh)
		assert_eq(Objectives.tier_met(active["goal"], active["progress"]), "base")
		fresh["growth"] = 70
		assert_eq(Objectives.tier_met(active["goal"], active["progress"]), "stretch")
	)

	run_case("health_streak_rung_is_skipped_when_already_met", func():
		_enabled_game()
		var vein := Cultivating.make_vein("life", 95, "", null, {})
		vein["developmentStreak"] = 4
		GameState.state["player"]["veins"].append(vein)
		_mark_done("cult_yield")
		_mark_done("cult_new_vein")
		var cards := BoardMeetings.eligible_cards().filter(func(c): return c["ladder"] == "cultivation")
		assert_eq(BoardMeetings.rung_status("cultivation", "cult_health_streak"), "skipped", "a 4-night streak meets the target")
		assert_eq(cards[0]["rung"], "cult_second_ore", "the next rung opens")
	)

	run_case("second_ore_rung_needs_two_healthy_ore_types", func():
		_enabled_game()
		GameState.state["player"]["veins"].append(Cultivating.make_vein("life", 60, "", null, {}))
		for rung_id in ["cult_yield", "cult_new_vein", "cult_health_streak"]:
			_mark_done(rung_id)
		_pick_cultivation_card("cult_second_ore")
		var active: Dictionary = GameState.state["boardMeetings"]["active"]
		assert_eq(Objectives.tier_met(active["goal"], active["progress"]), "none")
		GameState.state["player"]["veins"].append(Cultivating.make_vein("time", 35, "", null, {}))
		assert_eq(Objectives.tier_met(active["goal"], active["progress"]), "base")
	)

	run_case("owen_with_zero_pitch_rarity_never_makes_the_agenda", func():
		_enabled_game()
		_cultivation_ready()
		var original := _set_owen_rarity(0.0)
		var cards := BoardMeetings.agenda(1)
		_set_owen_rarity(original)
		assert_true(not _voices(cards).has("owen"))
	)

	run_case("owen_with_full_pitch_rarity_pitches_his_card", func():
		_enabled_game()
		_cultivation_ready()
		var original := _set_owen_rarity(1.0)
		var cards := BoardMeetings.agenda(1)
		_set_owen_rarity(original)
		assert_true(_voices(cards).has("owen"))
	)

	run_case("owen_pitch_frequency_follows_the_data_rarity", func():
		_enabled_game()
		_cultivation_ready()
		var original := _set_owen_rarity(0.25)
		var pitched := 0
		for week in range(1, 41):
			GameState.state["boardMeetings"]["agenda"] = []
			if _voices(BoardMeetings.agenda(week)).has("owen"):
				pitched += 1
		_set_owen_rarity(original)
		assert_true(pitched > 0 and pitched < 20, "owen pitched %d of 40 weeks at 0.25" % pitched)
	)

	run_case("archie_fills_the_slot_when_owen_is_absent", func():
		_enabled_game()
		var original := _install_ladders()
		var rarity := _set_owen_rarity(0.0)
		var cards := BoardMeetings.agenda(1)
		_set_owen_rarity(rarity)
		GameData.BOARD_LADDERS = original
		assert_eq(cards.size(), 3)
		assert_eq(_voices(cards).count("archie"), 2, "Archie holds Owen's slot")
		assert_true(not _voices(cards).has("owen"))
	)

	run_case("choosing_a_cultivation_card_warms_owen", func():
		_enabled_game()
		_cultivation_ready()
		var before := _relation("owen")
		_pick_cultivation_card("cult_yield")
		assert_eq(_relation("owen"), before + int(GameData.BOARD_VOICES["owen"]["warmth"]))
	)

	# ── minutes reactions ────────────────────────────────────────────────

	run_case("minutes_have_two_variants_per_voice_and_result_group", func():
		var minutes: Dictionary = GameData.BOARD_MEETING["minutes"]
		for group in minutes["groups"].values():
			assert_true((minutes["skipped"][group] as Array).size() >= 2, "skipped %s" % group)
			for voice in GameData.BOARD_VOICES:
				assert_true((minutes["reactions"][voice][group] as Array).size() >= 2, "%s %s" % [voice, group])
	)

	run_case("minutes_line_fills_tokens_and_picks_by_week", func():
		_enabled_game()
		var history: Array = GameState.state["boardMeetings"]["history"]
		history.append({ "week": 1, "voice": "james", "ladder": "financial", "rung": "fin_reserve", "ore": "", "result": "missed", "reward": [], "skip": false })
		var first := BoardMeetings.minutes_line(2)
		assert_true(not first.contains("{"), "tokens filled")
		assert_true(first.contains(BoardMeetings.card_label(history[0])))
		history[0]["week"] = 2
		assert_true(BoardMeetings.minutes_line(3) != first, "next week picks the other variant")
		history[0]["skip"] = true
		assert_true(not BoardMeetings.minutes_line(3).contains("James"))
		assert_eq(BoardMeetings.minutes_line(9), GameData.BOARD_MEETING["minutesNone"])
	)

	run_case("aob_line_fills_tokens_and_never_repeats_consecutive_weeks", func():
		_enabled_game()
		var previous := ""
		for week in range(2, 30):
			GameState.state["boardMeetings"]["agenda"] = []
			GameState.state["boardMeetings"]["agendaWeek"] = week
			var line := BoardMeetings.aob_line(week)
			assert_true(line.begins_with(GameData.BOARD_MEETING["aob"]["lead"]))
			assert_true(not line.contains("{"), "tokens filled")
			assert_true(line != previous, "week %d repeats" % week)
			previous = line
	)

	run_case("aob_line_uses_competing_pool_when_cards_compete", func():
		_enabled_game()
		var board: Dictionary = GameState.state["boardMeetings"]
		board["agendaWeek"] = 4
		board["agenda"] = [
			{ "id": "a", "voice": "archie", "ore": "time", "competesWith": "b" },
			{ "id": "b", "voice": "james", "ore": "time", "competesWith": "a" },
		]
		var line := BoardMeetings.aob_line(4)
		assert_true(line.contains("Archie") and line.contains("James"), line)
		assert_true(not line.contains("{"), "tokens filled")
	)
