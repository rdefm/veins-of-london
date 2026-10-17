extends "res://tests/test_base.gd"

const EVENT_ID := "james_experiment"
const CHOICE_CARD := 12

# James's experimenting lesson (.scratch/recipe-acquisition/spec.md § Event
# rename and rewrite): reached from Archie's motion beat, it teaches Time
# Pearl Hint I vague, runs the bench lesson to rank 3 on James's calc, then
# unlocks his recipe shop. Lesson mechanics live in test_lesson_session.gd.

var _real_bonus_chance: float
var _real_insight: Dictionary


# A fresh game knowing timePearl at base, crafting skill 0, no re-run bonus
# or insight.
func _fresh() -> void:
	GameState.reset()
	GameData.LAB["bonus"]["chance"] = 0.0
	GameData.RECIPE_KNOWLEDGE["insight"]["base"] = 0.0
	GameData.RECIPE_KNOWLEDGE["insight"]["perSkill"] = 0.0
	GameState.state["player"]["craftingSkill"] = 0
	GameState.state["contacts"]["james"]["unlocked"] = true
	Lab.grant_recipe("timePearl")


# Starts the event and Continues to the bench choice; returns the card
# indexes shown on the way.
func _play_to_bench() -> Array:
	Events.start_event(EVENT_ID)
	var seen := []
	while int(GameState.state["event"]["cardIndex"]) != CHOICE_CARD:
		seen.append(int(GameState.state["event"]["cardIndex"]))
		Events.advance()
	return seen


func _texts(indexes: Array) -> Array:
	var cards: Array = GameData.EVENTS[EVENT_ID]["cards"]
	return indexes.map(func(i): return cards[i]["text"])


func _rank_two_run() -> Dictionary:
	Lab.add_ore("timePearl", "time")
	Lab.perform_step("compression", 70.0)
	Lab.perform_step("heat", 25.0)
	return Lab.finish_run()


func _perfect_run() -> Dictionary:
	Lab.add_ore("timePearl", "time")
	Lab.perform_step("compression", 82.0)
	Lab.perform_grind([50.0, 50.0, 50.0])
	Lab.perform_step("heat", 25.0)
	Lab.perform_step("compression", 30.0)
	return Lab.finish_run()


func _finish_event() -> void:
	while GameState.state["event"] != null:
		Events.advance()


func run() -> void:
	_real_bonus_chance = float(GameData.LAB["bonus"]["chance"])
	_real_insight = GameData.RECIPE_KNOWLEDGE["insight"].duplicate()

	run_case("archie_motion_queues_the_james_experiment_message", func():
		_fresh()
		Events.start_event("archie_motion")
		_finish_event()
		var pending := Messages.pending_for("james")
		assert_true(pending.size() > 0 and pending.back()["kind"] == EVENT_ID, "queues the james_experiment pending entry")
	)

	run_case("lesson_runs_to_rank_three_then_the_recipe_talk_and_shop_unlock", func():
		_fresh()
		var relation_before := int(GameState.state["contacts"]["james"]["relation"])
		var seen := _play_to_bench()
		assert_true(seen.has(9) and not seen.has(10) and not seen.has(11), "first-timer hears the hint, not the disbelief")
		Events.choose(0)
		assert_eq(GameState.state["currentScreen"], "hq_lab_bench", "bench opened")
		assert_eq(LessonSession.lesson()["goalRank"], 3, "goal rank 3")
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint1"), "vague", "Hint I granted vague")
		_rank_two_run()
		assert_true(not LessonSession.resume()["ok"], "can't leave below rank 3")
		_perfect_run()
		assert_true(LessonSession.resume()["ok"], "resumes on success")
		assert_eq(GameState.state["currentScreen"], "event", "back at the event")
		Events.advance()
		assert_eq(int(GameState.state["event"]["cardIndex"]), CHOICE_CARD + 1, "the recipe talk follows the bench")
		_finish_event()
		var flags: Dictionary = GameState.state["flags"]
		assert_true(flags["jamesExperimentSeen"], "jamesExperimentSeen set")
		assert_true(flags["jamesRecipesUnlocked"], "James's recipe shop unlocked")
		assert_true(RecipeKnowledge.seller_unlocked("james"), "seller unlocked")
		assert_true(not Lab.is_known("enhancementPowder"), "no free Enhancement Powder")
		assert_eq(int(GameState.state["contacts"]["james"]["relation"]), relation_before + 1, "james relation +1")
		assert_eq(GameState.state["currentScreen"], "contacts", "-> contacts")
	)

	run_case("owning_hint_one_plays_the_disbelieving_lines_and_still_runs_the_lesson", func():
		_fresh()
		RecipeKnowledge.grant_rung("timePearl", "hint1", "exact")
		var seen := _play_to_bench()
		assert_true(seen.has(10) and seen.has(11) and not seen.has(9), "variant lines, not the hint")
		Events.choose(0)
		assert_true(LessonSession.is_running(), "the lesson still runs")
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint1"), "exact", "an exact hint isn't downgraded")
		_perfect_run()
		LessonSession.resume()
		_finish_event()
		assert_true(GameState.state["flags"]["jamesExperimentSeen"], "same ending")
	)

	run_case("escalation_shows_james_lines", func():
		_fresh()
		_play_to_bench()
		Events.choose(0)
		var lines: Dictionary = GameData.EVENTS[EVENT_ID]["cards"][CHOICE_CARD]["choices"][0]["effects"][0]["lines"]
		assert_eq(LessonSession.line("hintExact", "x"), lines["hintExact"], "James's hint line")
		assert_eq(LessonSession.line("talkThrough", "x"), lines["talkThrough"], "James's talk-through line")
		for i in range(3):
			_rank_two_run()
		assert_eq(RecipeKnowledge.rung_state("timePearl", "hint1"), "exact", "hint exact after 3 fails")
		for i in range(3):
			_rank_two_run()
		assert_true(LessonSession.talk_through(), "talk-through after 6 fails")
	)

	run_case("a_lesson_without_lines_falls_back", func():
		_fresh()
		assert_eq(LessonSession.line("hintExact", "fallback"), "fallback", "no lesson open")
		LessonSession.start("timePearl", 3)
		assert_eq(LessonSession.line("hintExact", "fallback"), "fallback", "lesson with no lines")
		GameState.state["lab"]["lesson"] = null
	)

	GameData.LAB["bonus"]["chance"] = _real_bonus_chance
	GameData.RECIPE_KNOWLEDGE["insight"]["base"] = _real_insight["base"]
	GameData.RECIPE_KNOWLEDGE["insight"]["perSkill"] = _real_insight["perSkill"]
