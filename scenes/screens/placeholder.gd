class_name PlaceholderScreen
extends Control

func _ready() -> void:
	UI.anchor_full_rect(self)

	var label := Label.new()
	label.text = "%s — screen not built yet" % GameState.state["currentScreen"].capitalize()
	UI.anchor_center(label)
	add_child(label)
