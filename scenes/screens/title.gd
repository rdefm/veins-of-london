class_name TitleScreen
extends Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(layout)

	var title := Label.new()
	title.text = "VEIN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var new_game_button := Button.new()
	new_game_button.text = "New Game"
	new_game_button.pressed.connect(_on_new_game_pressed)
	layout.add_child(new_game_button)

	var debug_button := Button.new()
	debug_button.text = "Debug Start"
	debug_button.pressed.connect(_on_debug_start_pressed)
	layout.add_child(debug_button)


func _on_new_game_pressed() -> void:
	GameState.reset()
	Nav.go_to("intro")


func _on_debug_start_pressed() -> void:
	DebugStart.apply()
