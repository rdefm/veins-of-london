extends RefCounted

# Shared event-driving helpers for tests. Static; use via
# `const EventPlay := preload("res://tests/support/event_play.gd")`.
#   play_event(id, ctx)              start an event and advance through every card
#   play_to_choice(id) -> int        start and advance up to the first choice card; returns its index
#   finish_after_choice(id, idx)     advance the rest of the cards after a choice at idx
#   play_through_choice(id)          play_to_choice + choose(0) + finish_after_choice
#   play_event_with_choices(id, cs)  play to the end, answering each choice card from cs in order


static func play_event(event_id: String, context: Dictionary = {}) -> void:
	Events.start_event(event_id, context)
	for i in range(GameData.EVENTS[event_id]["cards"].size()):
		Events.advance()


static func play_to_choice(event_id: String) -> int:
	Events.start_event(event_id)
	var cards: Array = GameData.EVENTS[event_id]["cards"]
	var choice_index := -1
	for i in range(cards.size()):
		if cards[i]["type"] == "choice":
			choice_index = i
			break
	for i in range(choice_index):
		Events.advance()
	return choice_index


static func finish_after_choice(event_id: String, choice_index: int) -> void:
	var remaining: int = GameData.EVENTS[event_id]["cards"].size() - choice_index
	for i in range(remaining):
		Events.advance()


static func play_through_choice(event_id: String) -> void:
	var choice_index := play_to_choice(event_id)
	Events.choose(0)
	finish_after_choice(event_id, choice_index)


static func play_event_with_choices(event_id: String, choices: Array) -> void:
	Events.start_event(event_id)
	var choice_i := 0
	while GameState.state["event"] != null:
		if Events.is_awaiting_choice():
			Events.choose(choices[choice_i])
			choice_i += 1
		else:
			Events.advance()
