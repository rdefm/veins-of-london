class_name TitleScreen
extends Control

# 32-load-game-button-on-title-screen: the slot list (day/cash summary,
# reusing SaveManager's peek/load API already wired up for Phone's
# Save/Load app -- see phone.gd's _build_save_slot_row()) starts hidden and
# is revealed by tapping Load Game, rather than always shown alongside
# New Game/Debug Start.
var _slot_list: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)

	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	UI.anchor_center(layout)
	add_child(layout)

	var title := Label.new()
	title.text = "VEIN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var new_game_button := Button.new()
	new_game_button.text = "New Game"
	new_game_button.pressed.connect(_on_new_game_pressed)
	layout.add_child(new_game_button)

	var load_game_button := Button.new()
	load_game_button.text = "Load Game"
	load_game_button.disabled = not _any_slot_saved()
	load_game_button.pressed.connect(_on_load_game_pressed)
	layout.add_child(load_game_button)

	var debug_button := Button.new()
	debug_button.text = "Debug Start"
	debug_button.pressed.connect(_on_debug_start_pressed)
	layout.add_child(debug_button)

	_slot_list = VBoxContainer.new()
	_slot_list.visible = false
	layout.add_child(_slot_list)
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		_slot_list.add_child(_build_slot_row(slot))


func _any_slot_saved() -> bool:
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		if SaveManager.slot_exists(slot):
			return true
	return false


func _build_slot_row(slot: int) -> Control:
	var summary := SaveManager.slot_summary(slot)
	var filled: bool = not summary.is_empty()

	var c := UI.card()
	c["content"].add_child(UI.heading("Slot %d" % slot, 14))
	if filled:
		c["content"].add_child(UI.muted_label("Day %d · £%d" % [summary["day"], summary["cash"]]))
		c["content"].add_child(UI.button("Load", _on_load_slot_pressed.bind(slot)))
	else:
		c["content"].add_child(UI.muted_label("Empty"))

	return c["panel"]


func _on_load_game_pressed() -> void:
	_slot_list.visible = true


# load_from_slot() overwrites GameState.state (including currentScreen) and
# emits state_changed, but NOT screen_changed -- Main._show_screen only
# swaps the visible screen on screen_changed (scenes/Main.gd), so without
# this explicit Nav.go_to() the title screen would stay on-screen underneath
# the freshly loaded session. Going to the state's own (just-loaded)
# currentScreen resumes exactly where that save left off, same as the
# in-session Load button (phone.gd) does implicitly by already being on the
# right screen when it's pressed.
func _on_load_slot_pressed(slot: int) -> void:
	SaveManager.load_from_slot(slot)
	Nav.go_to(GameState.state["currentScreen"])


func _on_new_game_pressed() -> void:
	GameState.reset()
	Factions.seed_day_one_veins()
	Events.start_event("intro")


func _on_debug_start_pressed() -> void:
	DebugStart.apply()
