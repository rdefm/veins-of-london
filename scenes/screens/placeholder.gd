class_name PlaceholderScreen
extends Control

# Stand-in for any R§2.2 screen not built yet — currently the D4 tabs
# (map/hq/phone/you) that later M1 tickets (04/06/07) build out.


func _ready() -> void:
	UI.anchor_full_rect(self)

	var label := Label.new()
	label.text = "%s — screen not built yet" % GameState.state["currentScreen"].capitalize()
	UI.anchor_center(label)
	add_child(label)
