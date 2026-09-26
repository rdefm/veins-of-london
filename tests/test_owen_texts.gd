extends "res://tests/test_base.gd"

# systems/owen_texts.gd: the scheduler's cadence and pause rule, reply
# XP, vein templating, repeat order, and the data/owen_texts.json validator.
# Mechanism cases swap in a synthetic pool so content edits can't break them.

const Fixtures := preload("res://tests/support/fixtures.gd")

const TEST_POOL := {
	"intervalMinDays": 2,
	"intervalMaxDays": 3,
	"texts": [
		{ "id": "q_vein", "kind": "question", "needsVein": true,
			"text": "The {ore} vein on {street}, {district}?",
			"replies": [
				{ "text": "Right", "correct": true, "response": "Ta, {street}." },
				{ "text": "Wrong", "correct": false, "response": "Oh." },
			] },
		{ "id": "flavour", "kind": "flavour", "needsVein": false,
			"text": "Bus stop.",
			"replies": [
				{ "text": "A", "correct": false, "response": "a" },
				{ "text": "B", "correct": false, "response": "b" },
			] },
	],
}


func _join_owen(with_vein: bool) -> void:
	GameState.reset()
	GameData.OWEN_TEXTS = TEST_POOL.duplicate(true)
	GameState.state["contacts"]["owen"]["recruited"] = true
	GameState.state["flags"]["bizOwenCultivationRole"] = true
	GameState.state["flags"]["bizA1OwenJoined"] = true
	Business.activate()
	Contacts.set_role("owen", "cultivation")
	if with_vein:
		GameState.state["player"]["veins"] = [Fixtures.player_vein_with({ "location": "Brick Lane, East" })]
		Rooms.assign_vein("owen", "v1")


# Marks the flavour text played so send_next() picks the vein question.
func _send_question() -> String:
	GameState.state["owenTexts"]["played"]["flavour"] = 0
	return OwenTexts.send_next()


func _set_day(day: int) -> void:
	GameState.state["world"]["day"] = day


func _owen_thread() -> Array:
	return GameState.state["messages"].get("owen", [])


var _shipped_pool: Dictionary = {}


func _restore_pool() -> void:
	GameData.OWEN_TEXTS = _shipped_pool.duplicate(true)


func run() -> void:
	_shipped_pool = GameData.OWEN_TEXTS.duplicate(true)
	run_case("scheduler_seeds_from_the_join_day_and_fires_every_2_to_3_days", func():
		_join_owen(false)
		Rng.set_seed(7)
		_set_day(10)
		OwenTexts.daily_tick()
		var next_day: int = GameState.state["owenTexts"]["nextDay"]
		assert_true(next_day >= 11 and next_day <= 12, "first text 2-3 days after joining on day 9, got %d" % next_day)
		assert_eq(_owen_thread().size(), 0, "seeding sends nothing")

		for day in range(11, next_day):
			_set_day(day)
			OwenTexts.daily_tick()
		assert_eq(_owen_thread().size(), 0, "nothing before the due day")

		_set_day(next_day)
		OwenTexts.daily_tick()
		assert_eq(_owen_thread().size(), 1, "fires on the due day")
		var after: int = GameState.state["owenTexts"]["nextDay"]
		assert_true(after - next_day >= 2 and after - next_day <= 3, "next interval 2-3 days")
		_restore_pool()
	)

	run_case("scheduler_is_deterministic_under_a_seeded_rng", func():
		var runs: Array = []
		for i in range(2):
			_join_owen(true)
			Rng.set_seed(42)
			for day in range(1, 20):
				_set_day(day)
				OwenTexts.daily_tick()
				if GameState.state["owenTexts"]["active"] != null:
					OwenTexts.reply(0)
			runs.append(_owen_thread().map(func(m): return [m["day"], m["text"]]))
		assert_eq(runs[0], runs[1], "same seed, same texts on the same days")
		assert_true(runs[0].size() > 0, "texts were sent")
		_restore_pool()
	)

	run_case("no_texts_before_owen_joins", func():
		_join_owen(false)
		GameState.state["flags"]["bizA1OwenJoined"] = false
		for day in range(1, 10):
			_set_day(day)
			OwenTexts.daily_tick()
		assert_eq(GameState.state["owenTexts"]["nextDay"], null, "never seeded")
		assert_eq(_owen_thread().size(), 0)
		_restore_pool()
	)

	run_case("the_clock_pauses_while_owen_is_not_working", func():
		_join_owen(false)
		GameState.state["owenTexts"]["nextDay"] = 5
		GameState.state["business"]["wages"]["owen"]["unpaid"] = true
		assert_true(not Payroll.is_working("owen"), "sanity: unpaid Owen isn't working")
		for day in range(5, 9):
			_set_day(day)
			OwenTexts.daily_tick()
		assert_eq(_owen_thread().size(), 0, "no texts while he isn't working")
		assert_eq(GameState.state["owenTexts"]["nextDay"], 9, "due day pushed back one per paused day")

		GameState.state["business"]["wages"]["owen"]["unpaid"] = false
		_set_day(9)
		OwenTexts.daily_tick()
		assert_eq(_owen_thread().size(), 1, "fires once he's working again")
		_restore_pool()
	)

	run_case("a_due_text_waits_while_the_last_is_unanswered", func():
		_join_owen(false)
		GameState.state["owenTexts"]["nextDay"] = 3
		_set_day(3)
		OwenTexts.daily_tick()
		GameState.state["owenTexts"]["nextDay"] = 4
		_set_day(4)
		OwenTexts.daily_tick()
		assert_eq(_owen_thread().size(), 1, "second text held back")
		OwenTexts.reply(0)
		_set_day(5)
		OwenTexts.daily_tick()
		assert_eq(_owen_thread().size(), 4, "fires on the rollover after the reply")
		_restore_pool()
	)

	run_case("the_right_answer_grants_cultivating_xp_and_owen_replies", func():
		_join_owen(true)
		assert_eq(_send_question(), "q_vein", "the unplayed question goes out")
		var xp_before: int = GameState.state["contacts"]["owen"]["cultivatingXP"]
		assert_eq(OwenTexts.active_replies(), ["Right", "Wrong"])

		var result := OwenTexts.reply(0)
		assert_true(result["ok"] and result["correct"])
		assert_eq(GameState.state["contacts"]["owen"]["cultivatingXP"], xp_before + GameData.CULTIVATOR_ACTION_XP)
		var thread := _owen_thread()
		assert_eq(thread[-2]["from"], "player")
		assert_eq(thread[-2]["text"], "Right")
		assert_eq(thread[-1]["from"], "them")
		assert_eq(thread[-1]["text"], "Ta, Brick Lane.", "follow-up templated too")
		assert_eq(GameState.state["owenTexts"]["active"], null, "answered")
		assert_eq(OwenTexts.active_replies(), [], "no replies left to tap")
		_restore_pool()
	)

	run_case("a_wrong_answer_grants_no_xp_but_owen_still_replies", func():
		_join_owen(true)
		_send_question()
		var xp_before: int = GameState.state["contacts"]["owen"]["cultivatingXP"]
		var result := OwenTexts.reply(1)
		assert_true(result["ok"] and not result["correct"])
		assert_eq(GameState.state["contacts"]["owen"]["cultivatingXP"], xp_before)
		assert_eq(_owen_thread()[-1]["text"], "Oh.")
		_restore_pool()
	)

	run_case("reply_xp_respects_owens_skill_cap", func():
		_join_owen(true)
		var owen: Dictionary = GameState.state["contacts"]["owen"]
		owen["cultivatingSkill"] = 3
		owen["cultivatingXP"] = 100000
		_send_question()
		OwenTexts.reply(0)
		assert_eq(owen["cultivatingSkill"], 3, "capped at level 3")
		_restore_pool()
	)

	run_case("vein_texts_template_a_real_assigned_vein", func():
		_join_owen(true)
		_send_question()
		assert_eq(_owen_thread()[-1]["text"], "The time vein on Brick Lane, Shoreditch?")
		_restore_pool()
	)

	run_case("vein_texts_are_skipped_when_owen_has_no_vein", func():
		_join_owen(false)
		assert_eq(OwenTexts.send_next(), "flavour", "only the vein-free text is eligible")
		OwenTexts.reply(0)
		assert_eq(OwenTexts.send_next(), "flavour", "repeats rather than send a vein text")
		GameData.OWEN_TEXTS["texts"] = [TEST_POOL["texts"][0].duplicate(true)]
		OwenTexts.reply(0)
		assert_eq(OwenTexts.send_next(), "", "nothing eligible, nothing sent")
		_restore_pool()
	)

	run_case("each_text_plays_once_then_repeats_least_recently_used_first", func():
		_join_owen(true)
		var first := OwenTexts.send_next()
		OwenTexts.reply(0)
		var second := OwenTexts.send_next()
		OwenTexts.reply(0)
		assert_true(first != second, "the unplayed text goes before any repeat")
		assert_eq(OwenTexts.send_next(), first, "then the least recently played")
		OwenTexts.reply(0)
		assert_eq(OwenTexts.send_next(), second)
		_restore_pool()
	)

	run_case("owen_texts_state_is_pure_and_backfills_on_old_saves", func():
		_join_owen(true)
		OwenTexts.send_next()
		var owen_texts: Dictionary = GameState.state["owenTexts"]
		assert_eq(JSON.parse_string(JSON.stringify(owen_texts))["active"]["id"], owen_texts["active"]["id"], "round-trips through JSON")
		var old_save: Dictionary = GameState.state.duplicate(true)
		old_save.erase("owenTexts")
		assert_eq(SaveManager.backfill_defaults(old_save)["owenTexts"]["nextDay"], null, "old saves get the default")
		_restore_pool()
	)

	run_case("shipped_owen_texts_pool_validates", func():
		var errors := GameData.validate_tables(GameData.snapshot()).filter(func(e): return e.begins_with("owen_texts"))
		assert_eq(errors, [], "no owen_texts errors")
		var has_question := false
		for entry in GameData.OWEN_TEXTS["texts"]:
			has_question = has_question or entry["kind"] == "question"
		assert_true(has_question, "ships at least one XP question")
	)

	run_case("validator_rejects_a_malformed_pool", func():
		var bad := TEST_POOL.duplicate(true)
		bad["texts"][0]["replies"][1]["correct"] = true
		bad["texts"][1]["text"] = "On {street}."
		bad["texts"][1]["replies"].resize(1)
		bad["texts"].append(bad["texts"][1].duplicate(true))
		var t := GameData.snapshot()
		t["owen_texts"] = bad
		var errors := GameData.validate_tables(t).filter(func(e): return e.begins_with("owen_texts"))
		var joined := "\n".join(errors)
		assert_true(joined.contains("exactly 1 correct"), "two correct answers rejected")
		assert_true(joined.contains("{street} needs needsVein"), "vein placeholder without needsVein rejected")
		assert_true(joined.contains("needs 2-3 replies"), "one reply rejected")
		assert_true(joined.contains("duplicate id"), "duplicate id rejected")
	)
