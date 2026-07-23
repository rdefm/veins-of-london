class_name PlaceholderScreen
extends Control

# Stand-in for any R§2.2 screen T12 hasn't rebuilt yet.


func _ready() -> void:
	UI.anchor_full_rect(self)

	var label := Label.new()
	label.text = "(screen not built yet)"
	UI.anchor_center(label)
	add_child(label)
