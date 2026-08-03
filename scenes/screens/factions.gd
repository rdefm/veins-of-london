class_name FactionsScreen
extends Control

var _content: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	_content.add_child(UI.back_button("home"))
	_content.add_child(UI.heading("Factions"))
	_content.add_child(UI.muted_label("Build relations. Join. Use rooms."))

	for faction_id in GameData.FACTIONS.keys():
		_content.add_child(ContactCards.build_faction_card(faction_id))
