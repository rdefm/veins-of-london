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
		assert_eq(BoardMeetings.agenda(4), first)
		GameData.BOARD_LADDERS = original
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
