class_name TitleScreen
extends Control
var _slot_list: VBoxContainer

func _ready() -> void:
	UI.anchor_full_rect(self)
	# Off the Map tab: light card family (MapCardStyle).
	MapPalette.build_light(_build)


func _build() -> void:
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	UI.anchor_center(layout)
	add_child(layout)

	var title := Label.new()
	title.text = "VEIN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	layout.add_child(MapCardStyle.chip_button("New Game", _on_new_game_pressed))
	layout.add_child(MapCardStyle.chip_button("Load Game", _on_load_game_pressed, not _any_slot_saved()))
	layout.add_child(MapCardStyle.chip_button("Debug Start", _on_debug_start_pressed))

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

	var c := MapCardStyle.card()
	c["content"].add_child(UI.heading("Slot %d" % slot, 14))
	if filled:
		c["content"].add_child(UI.muted_label("Day %d · £%d" % [summary["day"], summary["cash"]]))
		c["content"].add_child(MapCardStyle.footer([MapCardStyle.text_button("Load", _on_load_slot_pressed.bind(slot))]))
	else:
		c["content"].add_child(UI.muted_label("Empty"))

	return c["panel"]

func _on_load_game_pressed() -> void:
	_slot_list.visible = true
func _on_load_slot_pressed(slot: int) -> void:
	SaveManager.load_from_slot(slot)
	Nav.go_to(GameState.state["currentScreen"])

func _on_new_game_pressed() -> void:
	GameState.reset()
	Factions.seed_day_one_veins()
	Events.start_event("intro")

func _on_debug_start_pressed() -> void:
	DebugStart.apply()
