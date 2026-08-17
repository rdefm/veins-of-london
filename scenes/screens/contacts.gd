class_name ContactsScreen
extends Control

# Actions gated by flags per R§3.11. The HTML's version routes several
# actions to dedicated per-event screens (event_buyer, event_archie_
# motion, ...) that don't exist under R§2.2 — M0-T13 replaces those with
# one generic "event" screen driven by state.event, started here via
# Events.start_event().


var _content: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	_content.add_child(UI.back_to_home_button())
	_content.add_child(UI.heading("Contacts"))

	_content.add_child(ContactCards.build_archie_card())

	if GameState.state["contacts"]["james"]["unlocked"]:
		_content.add_child(ContactCards.build_james_card())
