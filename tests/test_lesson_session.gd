extends "res://tests/test_base.gd"

const TEST_SLOT := 95
const EVENT_ID := "test_lesson_event"

# The locked bench lesson (.scratch/recipe-acquisition/spec.md § Bench lesson
# session), opened through the event runner's start_lesson_session op on a
# fixture event: timePearl, goal rank 3, Hint I vague at the start.

var _real_bonus_chance: float
var _real_insight: Dictionary
var _real_lesson: Dictionary


func _event_def(rank: int) -> Dictionary:
	return {
		"id": EVENT_ID,
		"cards": [
			{ "type": "choice", "label": null, "speaker": null, "text": "Show me.", "choices": [
				{ "id": "bench", "label": "To the bench", "result_text": "Right then.",
					"effects": [{ "op": "start_lesson_session", "recipe": "timePearl", "rank": rank, "hintRung": "hint1" }] },
			] },
			{ "type": "narration", "label": null, "speaker": null, "text": "After." },
			{ "type": "narration", "label": null, "speaker": null, "text": "End." },
		],
	}


# A fresh game knowing timePearl at base, crafting skill 0, 20 time calc, no
# re-run bonus or insight, the fixture event started and its bench option picked.
func _open(rank: int = 3) -> void:
	GameState.reset()
	GameData.LAB["bonus"]["chance"] = 0.0
	GameData.RECIPE_KNOWLEDGE["insight"]["base"] = 0.0
	GameData.RECIPE_KNOWLEDGE["insight"]["perSkill"] = 0.0
	var player: Dictionary = GameState.state["player"]
	player["craftingSkill"] = 0
	player["orichalchum"]["time"] = 20
	Lab.grant_recipe("timePearl")
	GameData.EVENTS[EVENT_ID] = _event_def(rank)
	Events.start_event(EVENT_ID)
	Events.choose(0)


func _lesson() -> Variant:
	return GameState.state["lab"]["lesson"]


func _time_stock() -> int:
	return int(GameState.state["player"]["orichalchum"]["time"])


func _pearls() -> int:
	var total := 0
	for qty in GameState.state["player"]["inventory"].get("timePearl", {}).values():
		total += int(qty)
	return total


# Scores 40: rank 2, short of the goal.
func _rank_two_run() -> Dictionary:
	Lab.add_ore("timePearl", "time")
	Lab.perform_step("compression", 70.0)
	Lab.perform_step("heat", 25.0)
	return Lab.finish_run()


# The ideal procedure: score 100, rank 5.
func _perfect_run() -> Dictionary:
	Lab.add_ore("timePearl", "time")
	Lab.perform_step("compression", 82.0)
	Lab.perform_grind([50.0, 50.0, 50.0])
	Lab.perform_step("heat", 25.0)
	Lab.perform_step("compression", 30.0)
	return Lab.finish_run()


func run() -> void:
	_real_bonus_chance = float(GameData.LAB["bonus"]["chance"])
	_real_insight = GameData.RECIPE_KNOWLEDGE["insight"].duplicate()
	_real_lesson = GameData.LAB["lesson"].duplicate()

	run_case("op_opens_the_bench_in_lesson_mode_on_its_own_pool", func():
		_open()
		var lesson: Dictionary = _lesson()
		assert_eq(GameState.state["currentScreen"], "hq_lab_bench", "bench opened")
		assert_eq(lesson["recipe"], "timePearl", "lesson recipe")
		assert_eq(lesson["goalRank"], 3, "goal rank")
		assert_eq(lesson["pool"], { "time": 5 }, "pool holds one run's cost")
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint1"), "vague", "Hint I granted vague")
		assert_eq(Lab.calc_available("time"), 5, "runs draw on the pool")
		assert_eq(GameState.state["event"]["eventId"], EVENT_ID, "event paused, not ended")
		_rank_two_run()
		assert_eq(_time_stock(), 20, "player's stock untouched by a session run")
		assert_true(not Lab.add_ore("healingSalve", "life")["ok"], "another recipe refused")
		assert_true(not Lab.batch("timePearl", 1)["ok"], "batch refused")
	)

	run_case("a_failed_run_refills_the_pool", func():
		_open()
		var finished := _rank_two_run()
		assert_eq(finished["lesson"]["met"], false, "rank 2 is a failure")
		assert_eq(_lesson()["failedRuns"], 1, "counted")
		assert_eq(_lesson()["pool"], { "time": 5 }, "refilled after a low rank")
		Lab.add_ore("timePearl", "time")
		Lab.perform_step("compression", 100.0)
		assert_eq(_lesson()["failedRuns"], 2, "crack counted")
		assert_eq(_lesson()["pool"], { "time": 5 }, "refilled after a crack")
		Lab.add_ore("timePearl", "time")
		assert_eq(Lab.calc_available("time"), 0, "pool spent mid-run")
		Lab.abandon_run()
		assert_eq(_lesson()["failedRuns"], 3, "abandon counted")
		assert_eq(_lesson()["pool"], { "time": 5 }, "refilled after an abandon")
		assert_eq(_time_stock(), 20, "player's stock untouched")
	)

	run_case("the_session_spends_no_time_block", func():
		_open()
		var world: Dictionary = GameState.state["world"]
		var block := int(world["timeBlock"])
		var day := int(world["day"])
		_rank_two_run()
		_perfect_run()
		LessonSession.resume()
		assert_eq(int(world["timeBlock"]), block, "same block")
		assert_eq(int(world["day"]), day, "same day")
	)

	run_case("both_rewinds_are_refused_during_the_session_and_back_after", func():
		_open()
		Crafting.inventory_add("rewind", 1, 2)
		assert_true(not Lab.can_rewind(), "bench Rewind unavailable")
		assert_eq(Lab.rewind()["reason"], "Not during a lesson.", "bench Rewind refused")
		_rank_two_run()
		assert_true(not Lab.has_rewind_point(), "a lesson run opens no Rewind point")
		GameState.state["blockStart"] = GameState.deep_copy(GameState.state)
		assert_eq(Rewind.block_rewind_block_reason(), "Not during a lesson.", "time-block Rewind refused")
		assert_true(not Rewind.rewind_to_block_start()["ok"], "time-block Rewind does nothing")
		_perfect_run()
		assert_eq(Rewind.block_rewind_block_reason(), "Not during a lesson.", "still refused until resumed")
		LessonSession.resume()
		Events.advance()
		Events.advance()
		Events.advance()
		assert_eq(GameState.state["event"], null, "event finished")
		assert_eq(Rewind.block_rewind_block_reason(), "", "time-block Rewind available again")
		GameState.state["player"]["orichalchum"]["time"] = 20
		_rank_two_run()
		assert_true(Lab.can_rewind(), "bench Rewind available again")
		assert_true(Lab.rewind()["ok"], "bench Rewind works again")
		assert_eq(_time_stock(), 20, "it refunds the player's own calc")
	)

	run_case("nav_and_exit_are_locked_until_the_goal_then_the_event_resumes", func():
		_open()
		Nav.go_to("phone")
		assert_eq(GameState.state["currentScreen"], "hq_lab_bench", "nav refused")
		assert_true(not LessonSession.resume()["ok"], "can't leave before the goal")
		_rank_two_run()
		assert_true(not LessonSession.resume()["ok"], "still can't after a failure")
		var finished := _perfect_run()
		assert_eq(finished["lesson"]["met"], true, "rank 5 meets rank 3")
		assert_true(not Lab.add_ore("timePearl", "time")["ok"], "no more lesson runs once met")
		Nav.go_to("phone")
		assert_eq(GameState.state["currentScreen"], "hq_lab_bench", "nav held until Continue")
		assert_true(LessonSession.resume()["ok"], "resumed")
		assert_eq(_lesson(), null, "lesson closed")
		assert_eq(GameState.state["currentScreen"], "event", "back at the event")
		Events.advance()
		assert_eq(Events.current_card()["text"], "After.", "the event goes on at the next card")
		Nav.go_to("phone")
		assert_eq(GameState.state["currentScreen"], "phone", "nav free again")
	)

	run_case("escalation_sharpens_the_hint_then_talks_through", func():
		_open(4)
		_rank_two_run()
		_rank_two_run()
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint1"), "vague", "still vague after 2")
		var third := _rank_two_run()
		assert_true(third["lesson"]["hintExact"], "third failure reports the sharpened hint")
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint1"), "exact", "exact after 3")
		_rank_two_run()
		_rank_two_run()
		var knowledge := Lab.known_procedure("timePearl").map(func(step): return step["knowledge"])
		assert_true(not knowledge.has("talkThrough"), "no talk-through after 5")
		var sixth := _rank_two_run()
		assert_true(sixth["lesson"]["talkThrough"], "sixth failure reports the talk-through")
		var steps := Lab.known_procedure("timePearl")
		assert_eq(steps[1]["knowledge"], "talkThrough", "Hint II's grind shown")
		assert_eq(steps[1]["target"], 50.0, "at its true target")
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint2"), "unknown", "shown, not learned")
	)

	run_case("escalation_thresholds_come_from_data", func():
		GameData.LAB["lesson"]["hintExactAfterFails"] = 1
		GameData.LAB["lesson"]["talkThroughAfterFails"] = 2
		_open(4)
		_rank_two_run()
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint1"), "exact", "exact after 1")
		_rank_two_run()
		assert_true(LessonSession.talk_through(), "talk-through after 2")
		GameData.LAB["lesson"] = _real_lesson.duplicate()
	)

	run_case("items_and_xp_from_session_runs_go_to_the_player", func():
		_open()
		var xp_before := int(GameState.state["player"]["craftingXP"])
		_rank_two_run()
		Lab.add_ore("timePearl", "time")
		Lab.abandon_run()
		_perfect_run()
		assert_eq(_pearls(), 2, "both finished runs filed a pearl")
		assert_true(int(GameState.state["player"]["craftingXP"]) > xp_before, "XP earned")
	)

	run_case("a_mid_session_save_round_trips", func():
		_open()
		_rank_two_run()
		Lab.add_ore("timePearl", "time")
		var before: Dictionary = GameState.deep_copy(_lesson())
		assert_eq(JSON.parse_string(JSON.stringify(GameState.state["lab"])) != null, true, "lab state is plain data")
		assert_true(SaveManager.save_to_slot(TEST_SLOT)["ok"], "saved")
		GameState.reset()
		assert_true(SaveManager.load_from_slot(TEST_SLOT)["ok"], "loaded")
		SaveManager.delete_slot(TEST_SLOT)
		assert_eq(_lesson(), before, "lesson restored")
		assert_eq(typeof(_lesson()["failedRuns"]), TYPE_INT, "ints restored")
		assert_true(LessonSession.is_running(), "still running")
		Lab.perform_step("compression", 70.0)
		Lab.perform_step("heat", 25.0)
		assert_eq(Lab.finish_run()["lesson"]["failedRuns"], 2, "the open run carries on")
	)

	GameData.EVENTS.erase(EVENT_ID)
	GameData.LAB["bonus"]["chance"] = _real_bonus_chance
	GameData.LAB["lesson"] = _real_lesson
	GameData.RECIPE_KNOWLEDGE["insight"]["base"] = _real_insight["base"]
	GameData.RECIPE_KNOWLEDGE["insight"]["perSkill"] = _real_insight["perSkill"]
