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


# A card with the keys card_tokens() reads, filled out for fixtures.
func _tokens_card(card: Dictionary) -> Dictionary:
	var full := card.duplicate(true)
	full["rung"] = full["template"]
	full["goal"]["tiers"] = { "base": { "minWeeks": 2 }, "target": { "minWeeks": 3 }, "stretch": { "minWeeks": 4 } }
	full["preview"] = { "base": "", "target": "", "stretch": "" }
	return full


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
	for i in 30:
		if GameState.state["event"] == null or Events.is_awaiting_choice():
			return
		Events.advance()


# Continues the live event to its end; capped.
func _finish_event() -> void:
	for i in 30:
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


const GOLDEN_PATH := "res://tests/fixtures/board_meeting_golden.json"
const GOLDEN_SEEDS: Array = [1, 2]
const GOLDEN_WEEKS: Array = [1, 2, 3, 4, 5, 6]
const GOLDEN_AGENDAS: Dictionary = {
	"zero": [], "one": ["a1"], "two": ["a1", "j1"], "three": ["a1", "j1", "o1"],
}


# The lines a player sees for one meeting: every revealed card's speaker and
# text up to the vote, then the vote's option labels and result texts.
func _played_run(week: int, roll_seed: int, agenda_ids: Array, clash_chance: float) -> Array:
	_enabled_game()
	GameState.state["world"]["rollSeed"] = roll_seed
	GameState.state["boardMeetings"]["week"] = week - 1
	var original := _install_ladders()
	var ladders: Dictionary = {}
	for id in agenda_ids:
		ladders[id] = GameData.BOARD_LADDERS[id]
	GameData.BOARD_LADDERS = ladders
	var rarity := _set_owen_rarity(1.0)
	var chance := float(GameData.BOARD_MEETING["debate"]["clashChance"])
	GameData.BOARD_MEETING["debate"]["clashChance"] = clash_chance
	BoardMeetings.open_week()
	var lines: Array = []
	if BoardMeetings.maybe_start_meeting():
		_advance_to_choice()
		for card in Events.revealed_cards():
			lines.append("%s|%s" % [str(card.get("speaker", "")), card.get("text", "")])
		for option in Events.current_card()["choices"]:
			lines.append("opt|%s|%s" % [option["label"], option.get("result_text", "")])
		GameState.state["event"] = null
	GameData.BOARD_MEETING["debate"]["clashChance"] = chance
	GameData.BOARD_LADDERS = original
	_set_owen_rarity(rarity)
	return lines


func _golden_runs() -> Dictionary:
	var runs := {}
	for name in GOLDEN_AGENDAS:
		for clash in [0.0, 1.0]:
			for week in GOLDEN_WEEKS:
				for roll_seed in GOLDEN_SEEDS:
					runs["%s|clash%d|w%d|s%d" % [name, int(clash), week, roll_seed]] = _played_run(week, roll_seed, GOLDEN_AGENDAS[name], clash)
	return runs


func run() -> void:
	if OS.get_environment("WRITE_BOARD_GOLDEN") != "":
		var out := FileAccess.open(GOLDEN_PATH, FileAccess.WRITE)
		out.store_string(JSON.stringify(_golden_runs(), "  ", true))
		out.close()
		return

	# ── data ─────────────────────────────────────────────────────────────

	run_case("meeting_plays_the_same_lines_as_the_captured_golden_runs", func():
		var golden: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))
		var now := _golden_runs()
		assert_eq(now.keys().size(), golden.keys().size(), "same run set")
		for key in golden:
			# Golden runs predate the splice skeleton: a 0-goal run there holds an unfilled opener card, filtered here.
			var expected: Array = (golden[key] as Array).filter(func(l): return not String(l).begins_with("{opener_speaker}|"))
			var got: Array = now.get(key)
			# The old Week-1 event had no minutes card; the shared skeleton opens with it.
			if "|w1|" in key:
				got = got.slice(1)
			assert_eq(got, expected, "golden run %s" % key)
	)

	run_case("financial_placeholder_tiers_are_2_3_4_weeks", func():
		var rung: Dictionary = GameData.BOARD_LADDERS["financial"]["rungs"][0]
		assert_eq(GameData.BOARD_LADDERS["financial"]["voice"], "archie")
		assert_eq(rung["goal"]["type"], Objectives.TYPE_RESERVE_WEEKS_AT_LEAST)
		assert_eq(int(rung["tiers"]["base"]["minWeeks"]), 2)
		assert_eq(int(rung["tiers"]["target"]["minWeeks"]), 3)
		assert_eq(int(rung["tiers"]["stretch"]["minWeeks"]), 4)
	)

	run_case("share_leader_has_james_alt_voice_with_same_goal", func():
		_enabled_game()
		var ladder: Dictionary = GameData.BOARD_LADDERS["market_share"]
		var rung: Dictionary = {}
		for r in ladder["rungs"]:
			if r["id"] == "share_leader":
				rung = r
		var a := BoardMeetings._build_card("market_share", ladder, rung)
		var j := BoardMeetings._build_card("market_share", ladder, rung, "james", "share_leader_james")
		assert_eq(a["voice"], "archie")
		assert_eq(j["voice"], "james")
		assert_eq(a["id"], j["id"])
		assert_eq(a["goal"], j["goal"])
		assert_eq(a["rewards"], j["rewards"])
		assert_true(GameData.BOARD_TEMPLATES.has(j["template"]))
	)

	run_case("alt_voice_rung_is_offered_once_per_agenda", func():
		_enabled_game()
		var original := _install_ladders()
		var rung := _rung("lead")
		rung["altVoices"] = [{ "voice": "james", "template": "share_leader_james" }]
		GameData.BOARD_LADDERS = { "m": { "voice": "archie", "rungs": [rung] } }
		var eligible := BoardMeetings.eligible_cards()
		assert_eq(_voices(eligible), ["archie", "james"])
		var seen := {}
		for week in range(1, 12):
			GameState.state["boardMeetings"]["agenda"] = []
			GameState.state["boardMeetings"]["agendaWeek"] = 0
			var cards := BoardMeetings.agenda(week)
			assert_eq(cards.size(), 1, "one card for the rung, week %d" % week)
			seen[cards[0]["voice"]] = true
		assert_true(seen.has("archie") and seen.has("james"), "both voices can pitch it")
		GameData.BOARD_LADDERS = original
	)

	run_case("alt_voice_pitch_credits_that_voice", func():
		_enabled_game()
		var rung := _rung("lead")
		rung["altVoices"] = [{ "voice": "james", "template": "share_leader_james" }]
		var original: Dictionary = GameData.BOARD_LADDERS
		GameData.BOARD_LADDERS = { "m": { "voice": "archie", "rungs": [rung] } }
		var cards := BoardMeetings.agenda(1)
		var voice: String = cards[0]["voice"]
		var contact: String = GameData.BOARD_VOICES[voice]["contactId"]
		var before := _relation(contact)
		assert_true(BoardMeetings.choose(cards[0]["id"])["ok"])
		assert_eq(GameState.state["boardMeetings"]["active"]["voice"], voice)
		assert_true(_relation(contact) > before, "warmth credited to the pitching voice")
		GameData.BOARD_LADDERS = original
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
		var pack: Dictionary = GameData.BOARD_PROSE["fin_reserve"]
		assert_true((pack["cards"] as Array).size() > 1, "variant list")
		for i in 8:
			var card := { "id": "c%d" % i, "template": "fin_reserve", "voice": "archie", "goal": { "type": "reserve_weeks_at_least" } }
			var prose: String = str(BoardMeetings.card_tokens(_tokens_card(card))["case"])
			assert_true(not prose.contains("{"), "tokens filled: " + prose)
			assert_eq(str(BoardMeetings.card_tokens(_tokens_card(card))["case"]), prose, "stable per card")
		var text: String = BoardMeetings.fill_prose("{expenses} {float} {weeks}", { "id": "x", "goal": { "type": "reserve_weeks_at_least" } })
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
		assert_eq(cards[0]["voice"], "archie")
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
		var original: Dictionary = GameData.BOARD_LADDERS
		GameData.BOARD_LADDERS = { "j1": { "voice": "james", "rungs": [_rung("j1_r")] } }
		BoardMeetings.agenda(1)
		GameData.BOARD_LADDERS = original
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
			assert_eq(board["history"][0]["voice"], "archie")
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
		assert_eq(GameState.state["event"]["eventId"], "board_meeting")
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
		assert_true(hub_text.begins_with("Over to you."), "vote prompt leads")
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

	# ── the debate ───────────────────────────────────────────────────────

	run_case("every_template_has_case_prose_and_the_debate_data_is_complete", func():
		for id in GameData.BOARD_TEMPLATES:
			var template: Dictionary = GameData.BOARD_TEMPLATES[id]
			assert_true(GameData.BOARD_PROSE.has(id), "%s has a prose pack" % id)
			assert_true(not template.has("case") and not template.has("pitch") and not template.has("why"), "%s: prose lives in the pack" % id)
		var debate: Dictionary = GameData.BOARD_MEETING["debate"]
		for key in ["opener", "response", "rebuttal", "clash", "chosen", "concede"]:
			assert_true(not debate.has(key), "debate.%s moved to the _debate pack" % key)
		var pool := func(slot: String, filters: Dictionary) -> Array: return BoardMeetings._prose(GameData.BOARD_PROSE_DEBATE, slot, filters)
		for voice_id in GameData.BOARD_VOICES:
			for slot in ["opener", "rebuttal", "chosen", "concede"]:
				assert_true(not pool.call(slot, { "voice": voice_id }).is_empty(), "%s %s" % [slot, voice_id])
			for pitcher in GameData.BOARD_VOICES:
				if pitcher != voice_id:
					assert_true(not pool.call("reply", { "voice": voice_id, "to": pitcher }).is_empty(), "reply %s to %s" % [voice_id, pitcher])
		var owen_stances := BoardMeetings._prose_values(pool.call("reply", { "voice": "owen", "to": "james" }), "stance")
		assert_eq(owen_stances, ["wobble"], "Owen only wobbles")
		for pair in debate["clashOrder"]:
			var voices: PackedStringArray = String(pair).split("|")
			var exchanges: Array = pool.call("clash", { "voice": voices[0], "to": voices[1] })
			assert_true(not exchanges.is_empty(), "clash %s" % pair)
			for exchange in exchanges:
				assert_eq((exchange["cards"] as Array).size(), 2, "clash %s is a two-line pair" % pair)
		assert_true(not GameData.BOARD_MEETING.has("agendaCard") and not GameData.BOARD_MEETING.has("agendaSeparator"))
	)

	run_case("meeting_plays_with_one_two_or_three_goals_and_no_card_is_empty", func():
		var rarity := _set_owen_rarity(1.0)
		var a1 := { "voice": "archie", "rungs": [_rung("a1_r")] }
		var j1 := { "voice": "james", "rungs": [_rung("j1_r")] }
		var o1 := { "voice": "owen", "rungs": [_rung("o1_r")] }
		var sets := { 1: { "a1": a1 }, 2: { "a1": a1, "j1": j1 }, 3: { "a1": a1, "j1": j1, "o1": o1 } }
		var original: Dictionary = GameData.BOARD_LADDERS
		for count in sets:
			for chance in [0.0, 1.0]:
				_enabled_game()
				GameState.state["boardMeetings"]["week"] = 0
				GameData.BOARD_LADDERS = sets[count]
				GameData.BOARD_MEETING["debate"]["clashChance"] = chance
				BoardMeetings.open_week()
				assert_eq(GameState.state["boardMeetings"]["agenda"].size(), count, "sanity: %d goals" % count)
				assert_true(BoardMeetings.maybe_start_meeting())
				_advance_to_choice()
				var cards := Events.revealed_cards()
				var speakers := 0
				for card in cards:
					var text := str(card["text"])
					assert_true(not text.contains("{"), "%d goals: card filled: %s" % [count, text])
					if card["type"] == "speaker":
						speakers += 1
						assert_true(str(card["speaker"]) != "" and not str(card["speaker"]).contains("{"), "speaker filled")
				# opener + (case + response) per goal, plus the clash pair when it fires.
				assert_true(speakers >= 1 + 2 * count, "%d goals: %d spoken cards" % [count, speakers])
				var clash_lines: Array = []
				for exchange in BoardMeetings._prose(GameData.BOARD_PROSE_DEBATE, "clash"):
					for line in exchange["cards"]:
						clash_lines.append(line["text"])
				var clashed := cards.any(func(c): return clash_lines.has(str(c["text"])))
				assert_eq(clashed, chance == 1.0 and count >= 2, "%d goals, clash chance %s" % [count, str(chance)])
				assert_eq(Events.current_card()["choices"].size(), count + 1, "options + skip")
				Events.choose(Events.hub_exit_index())
				_finish_event()
				assert_eq(GameState.state["event"], null)
		GameData.BOARD_MEETING["debate"]["clashChance"] = 0.5
		GameData.BOARD_LADDERS = original
		_set_owen_rarity(rarity)
	)

	run_case("the_same_week_and_seed_give_an_identical_plain_data_context", func():
		var rarity := _set_owen_rarity(1.0)
		_enabled_game()
		var original := _install_ladders()
		var first := BoardMeetings.meeting_context(1)
		var second := BoardMeetings.meeting_context(1)
		assert_eq(first, second, "same week, same scene")
		assert_eq(JSON.parse_string(JSON.stringify(first)), first, "context is plain JSON data")
		GameData.BOARD_LADDERS = original
		_set_owen_rarity(rarity)
	)

	run_case("response_and_rebuttal_follow_the_stance_and_the_pitcher_never_answers_themself", func():
		var rarity := _set_owen_rarity(1.0)
		_enabled_game()
		var original := _install_ladders()
		var seen := {}
		for week in range(1, 40):
			GameState.state["boardMeetings"]["agendaWeek"] = 0
			var context := BoardMeetings.meeting_context(week)
			var agenda: Array = GameState.state["boardMeetings"]["agenda"]
			for i in agenda.size():
				var pitcher: String = GameData.BOARD_VOICES[agenda[i]["voice"]]["name"]
				var slot: Array = context["slot%d" % i]
				assert_true(slot.size() == 2 or slot.size() == 3, "case, response, optional rebuttal")
				assert_eq(slot[0]["speaker"], pitcher, "pitcher opens the slot")
				assert_true(slot[1]["speaker"] != pitcher, "responder is another voice")
				var rebuttal: bool = slot.size() == 3
				if rebuttal:
					assert_eq(slot[2]["speaker"], pitcher, "pitcher rebuts")
				if slot[1]["speaker"] == "Owen":
					assert_true(not rebuttal, "Owen wobbles, so no rebuttal")
				seen[rebuttal] = true
		assert_true(seen.has(true) and seen.has(false), "both a rebutted challenge and a plain response occur")
		GameData.BOARD_LADDERS = original
		_set_owen_rarity(rarity)
	)

	run_case("a_one_goal_meeting_plays_no_stray_or_empty_cards_and_a_zero_goal_one_goes_to_the_vote", func():
		for clash in [0.0, 1.0]:
			for week in [2, 3, 4, 5, 6]:
				var one := _played_run(week, 1, ["a1"], clash)
				# minutes, opener, case, response, [rebuttal], vote, then two options
				assert_true(one.size() in [7, 8], "one goal plays a tight run, got %d" % one.size())
				var none := _played_run(week, 1, [], clash)
				assert_eq(none.size(), 3, "minutes, vote prompt, skip option only")
	)

	run_case("rewinding_to_before_a_meeting_replays_the_same_meeting", func():
		var first := _played_run(3, 2, ["a1", "j1", "o1"], 1.0)
		var second := _played_run(3, 2, ["a1", "j1", "o1"], 1.0)
		assert_eq(first, second, "same meeting for the same seed and state")
		_enabled_game()
		var original := _install_ladders()
		GameState.state["boardMeetings"]["week"] = 0
		BoardMeetings.open_week()
		assert_true(BoardMeetings.maybe_start_meeting())
		var cards_before: Array = Events.live_cards().duplicate(true)
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)
		GameState.state["event"] = null
		GameState.state = GameState.deep_copy(snapshot)
		assert_eq(Events.live_cards(), cards_before, "expanded card list survives snapshot restore")
		GameState.state["event"] = null
		GameData.BOARD_LADDERS = original
	)

	run_case("chosen_option_text_has_the_pitchers_line_then_a_different_voices_concede", func():
		var rarity := _set_owen_rarity(1.0)
		var original := _meeting_at_hub()
		var agenda: Array = GameState.state["boardMeetings"]["agenda"]
		var choices: Array = Events.current_card()["choices"]
		for i in agenda.size():
			var pitcher: String = GameData.BOARD_VOICES[agenda[i]["voice"]]["name"]
			var lines: PackedStringArray = str(choices[i]["result_text"]).split("\n\n")
			assert_eq(lines.size(), 2, "chosen + concede")
			assert_true(lines[0].begins_with(pitcher + ": "), "pitcher speaks first")
			assert_true(not lines[1].begins_with(pitcher + ": "), "someone else concedes")
		Events.choose(1)
		assert_eq(GameState.state["boardMeetings"]["active"]["cardId"], agenda[1]["id"], "board_choose unchanged")
		_finish_event()
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

	run_case("week1_context_carries_the_explainer_and_later_weeks_do_not", func():
		_enabled_game()
		var week1 := BoardMeetings.meeting_context(1)
		var texts: Array = week1["explainer"].map(func(c: Dictionary) -> String: return str(c["text"]))
		assert_eq(texts.size(), 6, "intro, explainer, rules, next week, Owen, poach")
		assert_true(texts[5].contains("poached"), "Owen-poach gag")
		assert_eq(week1["explainer"][0]["type"], "narration")
		assert_eq(week1["explainer"][1]["speaker"], "Archie")
		assert_true(BoardMeetings.meeting_context(2)["explainer"].is_empty(), "no explainer after Week 1")
	)

	run_case("debug_jump_starts_a_meeting_with_the_current_state", func():
		GameState.reset()
		var day: int = GameState.state["world"]["day"]
		DebugTools.board_jump_to_meeting()
		var board: Dictionary = GameState.state["boardMeetings"]
		assert_true(board["enabled"])
		assert_eq(board["week"], 1)
		assert_eq(GameState.state["event"]["eventId"], "board_meeting")
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

	run_case("share_card_prose_fills_live_share_rival_and_contested_tokens", func():
		_enabled_game()
		Shares.record_ore("player", "life", 10)
		Shares.record_ore("firm", "life", 60)
		Shares.record_ore("guild", "life", 30)
		Shares.record_ore("firm", "time", 50)
		Shares.record_ore("guild", "time", 50)
		var card: Dictionary = BoardMeetings.agenda(1)[0]
		var tokens := BoardMeetings.card_tokens(card)
		var text := str(tokens["case"]) + str(tokens["label"])
		assert_true(not text.contains("{"), "no unfilled token: " + text)
		assert_true(str(tokens["case"]).contains("10%") or str(tokens["case"]).contains("Orichalchum"), "live tokens: " + str(tokens["case"]))
		assert_true(str(tokens["label"]).contains("life calc"), "short calc token")
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
		assert_eq(cards.size(), 2, "Archie and James variants of the one rung")
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

	# ── Crafting ladder (James) ──────────────────────────────────────────

	run_case("crafting_rung_needs_crafting_then_opens_on_the_best_craft_ore", func():
		_enabled_game()
		var none := BoardMeetings.eligible_cards().filter(func(c): return c["ladder"] == "crafting")
		assert_eq(none.size(), 0, "no crafting in the window, no card")
		Shares.record_craft("player", { "life": 5 })
		Shares.record_craft("firm", { "life": 95, "time": 50 })
		Shares.record_craft("player", { "time": 20 })
		var cards := BoardMeetings.eligible_cards().filter(func(c): return c["ladder"] == "crafting")
		assert_eq(cards.size(), 1)
		assert_eq(cards[0]["voice"], "james")
		assert_eq(cards[0]["ore"], "time", "player's best craft share: 20/70 beats 5/100")
		assert_eq(cards[0]["goal"]["tiers"]["base"]["minPercent"], 20)
	)

	run_case("crafting_rung_already_at_target_is_skipped", func():
		_enabled_game()
		Shares.record_craft("player", { "life": 40 })
		Shares.record_craft("firm", { "life": 60 })
		var cards := BoardMeetings.eligible_cards().filter(func(c): return c["ladder"] == "crafting")
		assert_eq(cards.size(), 0)
		assert_eq(BoardMeetings.rung_status("crafting", "craft_first"), "skipped")
	)

	run_case("crafting_ladder_walks_share_then_rankup_then_master", func():
		_enabled_game()
		Shares.record_craft("player", { "life": 40 })
		Shares.record_craft("firm", { "life": 60 })
		GameState.state["lab"]["bestRanks"]["a"] = 3
		var cards := BoardMeetings.eligible_cards().filter(func(c): return c["ladder"] == "crafting")
		assert_eq(cards[0]["rung"], "craft_rankup", "share rung already met, skipped")
		assert_eq(cards[0]["ore"], "")
		BoardMeetings.agenda(1)
		BoardMeetings.choose(cards[0]["id"])
		GameState.state["lab"]["bestRanks"]["a"] = 4
		assert_eq(Objectives.tier_met(GameState.state["boardMeetings"]["active"]["goal"], GameState.state["boardMeetings"]["active"]["progress"]), "base")
		GameState.state["boardMeetings"]["rungs"]["crafting"]["craft_rankup"] = { "status": "done", "day": 1, "ore": "" }
		var next := BoardMeetings.eligible_cards().filter(func(c): return c["ladder"] == "crafting")
		assert_eq(next[0]["rung"], "craft_master")
	)

	# ── Landmark deals ladder (Archie) + supplier beat ────────────────────

	run_case("supplier_beat_pins_only_after_share_beat_and_completes_spine", func():
		_enabled_game()
		var landmark := BoardMeetings.eligible_cards().filter(func(c): return c["ladder"] == "landmark")
		assert_eq(landmark.size(), 0, "locked until beat 1")
		GameState.state["boardMeetings"]["spine"]["share_target"] = "done"
		Shares.record_ore("player", "life", 10)
		Shares.record_ore("firm", "life", 90)
		landmark = BoardMeetings.eligible_cards().filter(func(c): return c["ladder"] == "landmark")
		assert_eq(landmark[0]["rung"], "landmark_supplier")
		assert_true(landmark[0]["pinned"])
		assert_eq(landmark[0]["voice"], "archie")
		GameState.state["boardMeetings"]["rungs"]["landmark"] = { "landmark_supplier": { "status": "done", "day": 1 } }
		BoardMeetings._complete_spine("supplier_contract")
		assert_true(BoardMeetings.spine_done("supplier_contract"))
		landmark = BoardMeetings.eligible_cards().filter(func(c): return c["ladder"] == "landmark")
		assert_eq(landmark[0]["rung"], "landmark_1")
	)

	run_case("landmark_reward_creates_its_authored_recurring_offer", func():
		_enabled_game()
		BoardMeetings._pay({ "kind": "contract", "templateId": "landmark_2" })
		var offer: Dictionary = Offers.pending_offers().back()
		assert_eq(offer["templateId"], "landmark_2")
		assert_eq(offer["counterparty"], "firm")
		assert_eq(int(offer["quote"]["payment"]), 1100)
		var accepted: Dictionary = Offers.accept_offer(offer["id"])
		assert_true(accepted["ok"])
		assert_eq(int(accepted["contract"]["termWeeks"]), 8)
		assert_eq(BoardMeetings.reward_preview([{ "kind": "contract", "templateId": "landmark_2" }]), "Contract: Southwark retainer")
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

	# ── meeting facts, `when`, weighted pick, no-repeat ──────────────────

	run_case("meeting_facts_read_business_history_and_shares", func():
		_enabled_game()
		_set_float(250)
		var board: Dictionary = GameState.state["boardMeetings"]
		board["history"] = [
			{ "week": 1, "voice": "archie", "result": "base", "skip": false },
			{ "week": 2, "voice": "james", "result": "target", "skip": false },
		]
		var facts := BoardMeetings.meeting_facts(3)
		for key in GameData.BOARD_FACTS:
			assert_true(facts.has(key), "fact %s present" % key)
		assert_eq(facts["float_weeks"], 2.5)
		assert_eq(facts["last_result"], "hit")
		assert_eq(facts["streak"], 2)
		assert_eq(facts["last_pitcher"], "james")
		assert_eq(facts["week"], 3)
		assert_eq(BoardMeetings.meeting_facts(5)["last_result"], "none", "no goal judged last week")
		board["history"][1]["result"] = BoardMeetings.RESULT_MISSED
		assert_eq(BoardMeetings.meeting_facts(3)["last_result"], "miss")
		assert_eq(BoardMeetings.meeting_facts(3)["streak"], 0)
		board["history"][1]["skip"] = true
		assert_eq(BoardMeetings.meeting_facts(3)["last_result"], "skip")
		GameState.state["shares"]["days"] = [{ "day": 9, "ore": { "player": { "time": 2 }, "independents": { "time": 8 } }, "craft": {}, "deliveries": {} }]
		var card := { "id": "c", "ore": "time", "goal": { "type": "reserve_weeks_at_least" } }
		var share_facts := BoardMeetings.meeting_facts(3, card)
		assert_eq(share_facts["share"], 20)
		assert_eq(share_facts["share_gap"], 60)
		assert_eq(share_facts["lead_gap"], 0, "behind: no lead")
		assert_eq(share_facts["rival_present"], true)
		assert_eq(share_facts["ore"], GameData.ORE_TYPES["time"]["name"])
		assert_eq(BoardMeetings.fact_tokens(share_facts)["share"], "20")
	)

	run_case("war_and_faction_facts_read_wars_weariness_stance_and_share", func():
		_enabled_game()
		var calm := BoardMeetings.meeting_facts(3)
		assert_eq(calm["at_war"], false)
		assert_eq(calm["enemy"], "nobody")
		assert_eq(calm["enemy_weariness"], 0)
		assert_eq(calm["my_weariness"], 0)
		assert_eq(BoardMeetings.fact_tokens(calm).has("factions"), false, "per-faction facts are not tokens")
		var war: Dictionary = GameState.state["factionWar"]
		war["wars"].append({ "parties": ["player", "guild"], "startDay": 1, "lastHostileDay": 1, "weariness": {} })
		war["wars"].append({ "parties": ["player", "firm"], "startDay": 1, "lastHostileDay": 1, "weariness": {} })
		war["weariness"]["guild"] = 42.0
		war["weariness"]["firm"] = 70.0
		war["weariness"]["player"] = 55.0
		GameState.state["factionStances"]["player"]["guild"]["stance"] = FactionAI.HOSTILE
		GameState.state["shares"]["days"] = [{ "day": 9, "ore": { "player": { "time": 2 }, "guild": { "time": 6 }, "independents": { "time": 2 } }, "craft": {}, "deliveries": {} }]
		var facts := BoardMeetings.meeting_facts(3, { "id": "c", "ore": "time", "goal": { "type": "reserve_weeks_at_least" } })
		assert_eq(facts["at_war"], true)
		assert_eq(facts["enemy"], GameData.FACTIONS["firm"]["name"], "worst-off enemy")
		assert_eq(facts["enemy_weariness"], 70)
		assert_eq(facts["my_weariness"], 55)
		var guild: Dictionary = facts["factions"]["guild"]
		assert_eq(guild["share_vs"], 60)
		assert_eq(guild["share_gap_vs"], 40)
		assert_eq(guild["stance_vs"], "hostile")
		assert_eq(guild["at_war_vs"], true)
		assert_eq(guild["weariness_vs"], 42)
		assert_eq(facts["factions"]["network"]["at_war_vs"], false)
		assert_true(Events.condition_met({ "fact": "weariness_vs", "faction": "guild", "op": "gte", "value": 40 }, [], facts))
		assert_true(not Events.condition_met({ "fact": "weariness_vs", "faction": "guild", "op": "lt", "value": 40 }, [], facts))
		assert_true(Events.condition_met({ "fact": "share_gap_vs", "faction": "guild", "gt": 0 }, [], facts), "guild ahead of you")
		assert_true(not Events.condition_met({ "fact": "at_war_vs", "faction": "network", "eq": true }, [], facts))
		assert_true(not Events.condition_met({ "fact": "at_war_vs", "faction": "nope", "eq": true }, [], facts), "unknown faction never holds")
		assert_true(not Events.condition_met({ "fact": "at_war_vs", "eq": true }, [], facts), "faction fact without a faction never holds")
	)

	run_case("fact_leaves_compare_meeting_facts_and_never_hold_without_them", func():
		var facts := { "n": 3, "s": "miss", "b": true }
		assert_true(Events.condition_met({ "fact": "n", "op": ">=", "value": 3 }, [], facts))
		assert_true(not Events.condition_met({ "fact": "n", "gt": 3 }, [], facts))
		assert_true(Events.condition_met({ "fact": "s", "eq": "miss" }, [], facts))
		assert_true(Events.condition_met({ "fact": "b", "op": "==", "value": true }, [], facts))
		assert_true(Events.condition_met({ "any": [{ "fact": "n", "lt": 1 }, { "not": { "fact": "s", "ne": "miss" } }] }, [], facts))
		assert_true(not Events.condition_met({ "fact": "nope", "lt": 1 }, [], facts), "unknown fact")
		assert_true(not Events.condition_met({ "fact": "n" }, [], facts), "no operator")
		assert_true(not Events.condition_met({ "fact": "n", "lt": 9 }), "no facts in scope")
	)

	run_case("a_prose_card_plays_only_when_its_when_holds", func():
		_enabled_game()
		var saved: Array = GameData.BOARD_PROSE["fin_reserve"]["cards"]
		GameData.BOARD_PROSE["fin_reserve"]["cards"] = [
			{ "id": "t.rich", "slot": "case", "voice": "archie", "when": { "fact": "float_weeks", "op": ">=", "value": 3 }, "cards": [{ "speaker": "Archie", "text": "rich" }] },
			{ "id": "t.poor", "slot": "case", "voice": "archie", "when": { "all": [{ "fact": "float_weeks", "lt": 3 }, { "not": { "fact": "rival_present", "eq": true } }] }, "cards": [{ "speaker": "Archie", "text": "poor" }] },
		]
		var card := _tokens_card({ "id": "c1", "template": "fin_reserve", "voice": "archie", "goal": { "type": "reserve_weeks_at_least" } })
		for i in 12:
			card["id"] = "c%d" % i
			_set_float(500)
			assert_eq(str(BoardMeetings._case_prose(card, 4)["id"]), "t.rich")
			_set_float(100)
			assert_eq(str(BoardMeetings._case_prose(card, 4)["id"]), "t.poor")
		_set_float(100)
		GameState.state["shares"]["days"] = [{ "day": 9, "ore": { "independents": { "time": 8 } }, "craft": {}, "deliveries": {} }]
		card["ore"] = "time"
		assert_eq(BoardMeetings._case_prose(card, 4), {}, "no card qualifies, none plays")
		GameData.BOARD_PROSE["fin_reserve"]["cards"] = saved
	)

	run_case("weights_shift_the_pick_across_card_ids", func():
		_enabled_game()
		GameState.state["world"]["rollSeed"] = 7
		var pool := [
			{ "id": "t.heavy", "weight": 9, "cards": [] },
			{ "id": "t.light", "weight": 1, "cards": [] },
		]
		var heavy := 0
		for i in 200:
			if BoardMeetings._pick_prose(pool, 4, "case|c%d" % i)["id"] == "t.heavy":
				heavy += 1
		assert_true(heavy > 150 and heavy < 200, "9:1 weights favour the heavy card: %d/200" % heavy)
		pool[0]["weight"] = 1
		heavy = 0
		for i in 200:
			if BoardMeetings._pick_prose(pool, 4, "case|c%d" % i)["id"] == "t.heavy":
				heavy += 1
		assert_true(heavy > 60 and heavy < 140, "equal weights split the pick: %d/200" % heavy)
	)

	run_case("last_meetings_prose_card_is_skipped_when_another_qualifies", func():
		_enabled_game()
		var board: Dictionary = GameState.state["boardMeetings"]
		var pool := [{ "id": "t.a", "cards": [] }, { "id": "t.b", "cards": [] }]
		board["lastProse"] = ["3|t.a"]
		for i in 40:
			assert_eq(BoardMeetings._pick_prose(pool, 4, "s%d" % i)["id"], "t.b", "t.a played last week")
			assert_eq(BoardMeetings._pick_prose([pool[0]], 4, "s%d" % i)["id"], "t.a", "the only qualifier still plays")
		board["lastProse"] = ["3|t.a", "2|t.b"]
		BoardMeetings._record_prose(4, ["t.x"])
		BoardMeetings._record_prose(4, ["t.x", "t.y"])
		assert_eq(board["lastProse"], ["3|t.a", "4|t.x", "4|t.y"], "keeps last meeting, replaces this week's")
	)

	run_case("the_same_goal_does_not_repeat_its_case_prose_two_weeks_running_and_replays_on_rewind", func():
		var rarity := _set_owen_rarity(1.0)
		_enabled_game()
		GameState.state["boardMeetings"]["week"] = 0
		var original := _install_ladders()
		GameData.BOARD_LADDERS = { "f1": { "voice": "archie", "rungs": [_rung("fin_reserve")] } }
		var saved: Array = GameData.BOARD_PROSE["fin_reserve"]["cards"]
		GameData.BOARD_PROSE["fin_reserve"]["cards"] = [
			{ "id": "t.one", "slot": "case", "voice": "archie", "cards": [{ "speaker": "Archie", "text": "one" }] },
			{ "id": "t.two", "slot": "case", "voice": "archie", "cards": [{ "speaker": "Archie", "text": "two" }] },
		]
		BoardMeetings.open_week()
		var snapshot: Dictionary = GameState.deep_copy(GameState.state["boardMeetings"])
		var first := BoardMeetings.meeting_context(1)
		BoardMeetings.open_week()
		var second := BoardMeetings.meeting_context(2)
		assert_true(first["slot0"][0]["text"] != second["slot0"][0]["text"], "week 2 swaps the case card")
		assert_true((GameState.state["boardMeetings"]["lastProse"] as Array).has("1|t.one") or (GameState.state["boardMeetings"]["lastProse"] as Array).has("1|t.two"), "week 1 picks kept")
		GameState.state["boardMeetings"] = snapshot
		assert_eq(BoardMeetings.meeting_context(1), first, "Rewind replays the same meeting")
		GameData.BOARD_PROSE["fin_reserve"]["cards"] = saved
		GameData.BOARD_LADDERS = original
		_set_owen_rarity(rarity)
	)

	run_case("case_card_with_replies_plays_its_own_exchange_else_generic", func():
		_enabled_game()
		var card := { "id": "c1", "template": "craft_first", "voice": "james", "ore": "time", "goal": { "type": "craftShare", "tiers": {} } }
		var saved: Array = GameData.BOARD_PROSE["craft_first"]["cards"]
		var case_card := {
			"id": "t.case", "slot": "case", "voice": "james",
			"cards": [{ "speaker": "James", "text": "case" }],
			"replies": [
				{ "id": "t.rep", "slot": "reply", "voice": "archie", "stance": "challenge", "cards": [{ "speaker": "Archie", "text": "own reply" }] },
				{ "id": "t.reb", "slot": "rebuttal", "voice": "james", "cards": [{ "speaker": "James", "text": "own rebuttal" }] },
			],
		}
		GameData.BOARD_PROSE["craft_first"]["cards"] = [case_card]
		var texts: Array = BoardMeetings._exchange_cards(card, 0, 4).map(func(c): return c["text"])
		assert_eq(texts, ["case", "own reply", "own rebuttal"], "authored exchange plays")
		case_card.erase("replies")
		texts = BoardMeetings._exchange_cards(card, 0, 4).map(func(c): return c["text"])
		assert_eq(texts[0], "case")
		assert_true(not texts.has("own reply"), "no replies falls back to the generic pack")
		GameData.BOARD_PROSE["craft_first"]["cards"] = saved
	)

	run_case("goal_pack_chosen_and_concede_win_over_generic", func():
		_enabled_game()
		var card := { "id": "c1", "template": "craft_first", "voice": "james", "ore": "time", "goal": { "type": "craftShare", "tiers": {} } }
		var saved: Array = GameData.BOARD_PROSE["craft_first"]["cards"]
		GameData.BOARD_PROSE["craft_first"]["cards"] = saved + [
			{ "id": "t.ch", "slot": "chosen", "voice": "james", "cards": [{ "speaker": "James", "text": "goal chosen" }] },
			{ "id": "t.co", "slot": "concede", "voice": "archie", "cards": [{ "speaker": "Archie", "text": "goal concede" }] },
		]
		var text := BoardMeetings._result_text(card, 0, 4)
		assert_true(text.contains("goal chosen") and text.contains("goal concede"), "goal lines used: %s" % text)
		GameData.BOARD_PROSE["craft_first"]["cards"] = saved
		text = BoardMeetings._result_text(card, 0, 4)
		assert_true(text != "" and not text.contains("goal "), "generic when goal pack has none: %s" % text)
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
