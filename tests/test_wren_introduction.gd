extends "res://tests/test_base.gd"

const EVENT_ID := "wren_introduction"
const MET_CARD := "c3"

# Wren's introduction (.scratch/recipe-acquisition/spec.md § Wren
# introduction): queued as her pending message on the rollover after
# james_experiment, it registers the player as a Guild associate and opens
# her recipe shop and assay commissions.


# A fresh game just past james_experiment, on the same day.
func _fresh() -> void:
	GameState.reset()
	GameState.state["flags"]["jamesExperimentSeen"] = true


# Plays the event to its end; returns the card keys shown.
func _play() -> Array:
	Events.start_event(EVENT_ID)
	var seen := []
	while GameState.state["event"] != null:
		seen.append(str(Events.current_card().get("key", "")))
		Events.advance()
	return seen


func _wren_pending() -> Array:
	return Messages.pending_for("wren").filter(func(e): return e["kind"] == EVENT_ID)


func run() -> void:
	run_case("wren_message_is_queued_on_the_next_day_once", func():
		_fresh()
		var day := int(GameState.state["world"]["day"])
		assert_eq(_wren_pending().size(), 0, "nothing the same day")
		assert_true(not GameState.state["contacts"]["wren"]["unlocked"], "Wren not yet a contact")
		TimeSystem.do_rest()
		assert_eq(int(GameState.state["world"]["day"]), day + 1, "next day")
		assert_eq(_wren_pending().size(), 1, "Wren's message queued")
		assert_true(GameState.state["contacts"]["wren"]["unlocked"], "Wren unlocked by her message")
		assert_true(not GameState.state["flags"]["wrenMetBeforeIntro"], "not met before")
		TimeSystem.do_rest()
		assert_eq(_wren_pending().size(), 1, "queued only once")
	)

	run_case("no_message_before_james_experiment", func():
		GameState.reset()
		TimeSystem.do_rest()
		assert_eq(_wren_pending().size(), 0, "no Wren message")
	)

	run_case("first_meeting_plays_without_the_met_line_and_unlocks_everything", func():
		_fresh()
		RecipeKnowledge.maybe_queue_introductions()
		var seen := _play()
		assert_true(not seen.has(MET_CARD), "no already-met line")
		var flags: Dictionary = GameState.state["flags"]
		assert_true(flags["wrenIntroductionSeen"], "seen flag")
		assert_true(flags["wrenRecipesUnlocked"], "Wren's shop flag")
		assert_true(RecipeKnowledge.seller_unlocked("wren"), "Wren's shop open")
		assert_true(flags["assayCommissionsUnlocked"], "commissions flag")
		assert_eq(GameState.state["currentScreen"], "contacts", "-> contacts")
	)

	run_case("already_met_wren_hears_the_met_line", func():
		_fresh()
		GameState.state["contacts"]["wren"]["unlocked"] = true
		RecipeKnowledge.maybe_queue_introductions()
		assert_true(GameState.state["flags"]["wrenMetBeforeIntro"], "met before")
		assert_true(_play().has(MET_CARD), "already-met line shown")
	)

	run_case("ingram_has_one_line_and_wrens_intro_is_real", func():
		var cards: Array = GameData.EVENTS[EVENT_ID]["cards"]
		assert_eq(cards.filter(func(c): return c["speaker"] == "Ingram").size(), 1, "one Ingram card")
		var intro := str(KeyMembers.member("wren").get("intro", ""))
		assert_true(intro != "" and not intro.contains("Placeholder"), "placeholder intro replaced")
	)
