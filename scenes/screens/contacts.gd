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
	_paint_family2_background()
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


# 08-family-2-chrome-contacts, ui-vision.md §10: Contacts is one of the
# always-dark "device shell" Phone-OS screens -- painted once behind
# UI.screen_body()'s own ScrollContainer, same near-black used for every
# other Family 2 app-content screen, replacing whatever the engine's default
# clear colour would otherwise show through (no screen painted its own
# background before this ticket).
func _paint_family2_background() -> void:
	var bg := Panel.new()
	UI.anchor_full_rect(bg)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = GameData.PALETTE.get("phone_bg_content", Color("#252528"))
	bg.add_theme_stylebox_override("panel", style)
	add_child(bg)


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

	# 08-family-2-chrome-contacts: one recolour pass over everything just
	# built -- see ContactCards.apply_phone_os_chrome()'s own comment.
	ContactCards.apply_phone_os_chrome(_content)
