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

	# 82-contacts-des-nadia-hakim-cards: unlocked-gated, same pattern as the
	# James card below -- each unlocks separately over the Collective Act 1
	# questline (col_a1_intro unlocks des; col_a1_hub unlocks nadia and hakim
	# together), so a card only appears once its contact is actually reachable.
	if GameState.state["contacts"]["des"]["unlocked"]:
		_content.add_child(ContactCards.build_des_card())

	if GameState.state["contacts"]["nadia"]["unlocked"]:
		_content.add_child(ContactCards.build_nadia_card())

	if GameState.state["contacts"]["hakim"]["unlocked"]:
		_content.add_child(ContactCards.build_hakim_card())

	if GameState.state["contacts"]["james"]["unlocked"]:
		_content.add_child(ContactCards.build_james_card())
