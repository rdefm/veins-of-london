class_name PlaceholderScreen
extends Control

# Stand-in for any R§2.2 screen T12 hasn't rebuilt yet.


func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER)

	var label := Label.new()
	label.text = "(screen not built yet)"
	add_child(label)
