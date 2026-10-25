extends RefCounted

# Shared event-driving helpers for tests. Static; use via
# `const EventPlay := preload("res://tests/support/event_play.gd")`.
#   play_event(id, ctx)              start an event and advance through every card
#   play_to_choice(id) -> int        start and advance up to the first choice card; returns its index
#   finish_after_choice(id, idx)     advance the rest of the cards after a choice at idx
#   play_through_choice(id)          play_to_choice + choose(0) + finish_after_choice
#   play_event_with_choices(id, cs)  play to the end, answering each choice card from cs in order


#   choose_id(option_id)             pick the current choice card's option by its `id`
#   current_key() -> String          the current card's `key`
#   key_index(event_id, key) -> int  position of the card with that `key` (-1 if none)
#   card_by_key(event_id, key)       that card's dict ({} if none)


static func choose_id(option_id: String) -> void:
	var choices: Array = Events.current_card().get("choices", [])
	for i in range(choices.size()):
		if str(choices[i].get("id", "")) == option_id:
			Events.choose(i)
			return
	push_error("choose_id: no option '%s' on card '%s'" % [option_id, current_key()])


static func current_key() -> String:
	return str(Events.current_card().get("key", ""))


static func key_index(event_id: String, key: String) -> int:
	var cards: Array = GameData.EVENTS[event_id]["cards"]
	for i in range(cards.size()):
		if str(cards[i].get("key", "")) == key:
			return i
	return -1


static func card_by_key(event_id: String, key: String) -> Dictionary:
	var i := key_index(event_id, key)
	return GameData.EVENTS[event_id]["cards"][i] if i >= 0 else {}


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
