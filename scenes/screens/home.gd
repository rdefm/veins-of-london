class_name HomeScreenPlaceholder
extends Control

# Minimal proof-of-navigation placeholder for T11. T12 rebuilds this with
# the real stats/to-do-list/actions layout per M0-PORT T12.

var _day_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_WIDE)

	var layout := VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(layout)

	var heading := Label.new()
	heading.text = "Home"
	layout.add_child(heading)

	_day_label = Label.new()
	layout.add_child(_day_label)

	var rest_button := Button.new()
	rest_button.text = "Rest"
	rest_button.pressed.connect(_on_rest_pressed)
	layout.add_child(rest_button)

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_day_label.text = "Day %d — £%d" % [GameState.state["world"]["day"], GameState.state["player"]["cash"]]


func _on_rest_pressed() -> void:
	TimeSystem.do_rest()
