class_name SaveLoadApp
extends PhoneApp

var _export_box: TextEdit
var _import_box: TextEdit


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("Save/Load"))

	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		content.add_child(_build_save_slot_row(slot))
	content.add_child(_build_export_card())
	content.add_child(_build_import_card())
	content.add_child(_build_new_game_card())


func _build_save_slot_row(slot: int) -> Control:
	var summary := SaveManager.slot_summary(slot)
	var filled: bool = not summary.is_empty()

	var summary_text: String
	if filled:
		summary_text = "Day %d · £%d" % [summary["day"], summary["cash"]]
	else:
		summary_text = "Empty"

	var c := UI.card()
	c["content"].add_child(UI.heading("Slot %d" % slot, 14))
	c["content"].add_child(UI.muted_label(summary_text))

	var actions := UI.hbox()
	actions.add_child(UI.button("Save", _on_save_slot_pressed.bind(slot)))
	if filled:
		actions.add_child(UI.button("Load", func(): SaveManager.load_from_slot(slot)))
		actions.add_child(UI.button("Delete", _on_delete_slot_pressed.bind(slot)))
	c["content"].add_child(actions)

	return c["panel"]


func _on_save_slot_pressed(slot: int) -> void:
	SaveManager.save_to_slot(slot)
	refresh()


func _on_delete_slot_pressed(slot: int) -> void:
	SaveManager.delete_slot(slot)
	refresh()


func _build_export_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Export", 14))
	_export_box = TextEdit.new()
	_export_box.custom_minimum_size = Vector2(0, 100)
	c["content"].add_child(_export_box)
	c["content"].add_child(UI.button("Generate export string", _on_export_pressed))
	return c["panel"]


func _on_export_pressed() -> void:
	_export_box.text = SaveManager.export_string()


func _build_import_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Import", 14))
	_import_box = TextEdit.new()
	_import_box.custom_minimum_size = Vector2(0, 100)
	c["content"].add_child(_import_box)
	c["content"].add_child(UI.button("Import", _on_import_pressed))
	return c["panel"]


func _on_import_pressed() -> void:
	SaveManager.import_string(_import_box.text)


func _build_new_game_card() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("New Game", 14))

	var nav: Dictionary = GameState.state["phoneNav"]
	if nav.get("confirmingNewGame", false):
		c["content"].add_child(UI.muted_label("This will erase all progress. Are you sure?"))
		var actions := UI.hbox()
		actions.add_child(UI.button("Confirm", _on_confirm_new_game_pressed))
		actions.add_child(UI.button("Cancel", func(): PhoneNav.cancel_new_game_confirm()))
		c["content"].add_child(actions)
	else:
		c["content"].add_child(UI.button("New Game", func(): PhoneNav.arm_new_game_confirm()))

	return c["panel"]


func _on_confirm_new_game_pressed() -> void:
	GameState.reset()
	Factions.seed_day_one_veins()
	Nav.go_to("intro")
