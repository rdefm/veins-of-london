extends "res://tests/test_base.gd"

const EVENT_ID := "security_office_intro"

# The Security Office intro: queued by the first purchase, plays once, never
# replays after a room loss and re-buy. Arnie is named only inside it.


func _bought() -> void:
	GameState.reset()
	GameState.state["player"]["cash"] = 100000
	GameState.state["home"]["tier"] = "townhouse"
	Home.add_room("securityOffice")


# Plays the event to its end; returns the card keys shown (capped).
func _play() -> Array:
	Events.start_event(EVENT_ID)
	var seen := []
	for _i in 40:
		if GameState.state["event"] == null:
			break
		seen.append(str(Events.current_card().get("key", "")))
		Events.advance()
	return seen


func run() -> void:
	run_case("buying_the_office_queues_the_intro_and_nothing_before", func():
		GameState.reset()
		assert_true(not GameState.state["flags"]["securityIntroPending"], "not before")
		_bought()
		assert_true(GameState.state["flags"]["securityIntroPending"], "queued on purchase")
		assert_true(not GameState.state["flags"]["securityIntroSeen"], "not yet seen")
	)

	run_case("intro_covers_the_four_topics_and_opens_the_security_screen", func():
		_bought()
		var seen := _play()
		assert_true(seen.has("c5") and seen.has("c6") and seen.has("c7") and seen.has("c8"), "hiring, posting, reserve, costs")
		var flags: Dictionary = GameState.state["flags"]
		assert_true(flags["securityIntroSeen"], "seen")
		assert_true(not flags["securityIntroPending"], "pending cleared")
		assert_eq(GameState.state["currentScreen"], "security", "-> security")
	)

	run_case("losing_and_rebuying_the_room_never_requeues_the_intro", func():
		_bought()
		_play()
		GameState.state["home"]["rooms"].erase("securityOffice")
		Home.add_room("securityOffice")
		assert_true(not GameState.state["flags"]["securityIntroPending"], "no replay")
	)

	run_case("arnie_is_named_only_in_the_intro_event_among_muscle_data", func():
		assert_true(not GameData.MUSCLE_FIRST_NAMES.has("Arnie"), "not in the guard name pool")
	)
