class_name SaveScreen
extends Control

var _content: VBoxContainer
var _export_box: TextEdit
var _import_box: TextEdit


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_content = UI.screen_body(self)
	EventBus.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for child in _content.get_children():
		child.queue_free()

	_content.add_child(UI.back_button("world"))
	_content.add_child(UI.heading("Save & Load"))

	for slot in range(1, 4):
		_content.add_child(_build_slot_row(slot))

	_content.add_child(_build_export_card())
	_content.add_child(_build_import_card())
	_content.add_child(UI.button("New Game", _on_new_game_pressed))


func _build_slot_row(slot: int) -> Control:
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
	actions.add_child(UI.button("Save", _on_save_pressed.bind(slot)))
	if filled:
		actions.add_child(UI.button("Load", func(): SaveManager.load_from_slot(slot)))
		actions.add_child(UI.button("Delete", _on_delete_pressed.bind(slot)))
	c["content"].add_child(actions)

	return c["panel"]


# save_to_slot/delete_slot don't touch GameState.state, so they don't emit
# state_changed the way load_from_slot does — refresh explicitly so the
# slot list reflects what just happened.
func _on_save_pressed(slot: int) -> void:
	SaveManager.save_to_slot(slot)
	_refresh()


func _on_delete_pressed(slot: int) -> void:
	SaveManager.delete_slot(slot)
	_refresh()


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


func _on_new_game_pressed() -> void:
	GameState.reset()
	Nav.go_to("intro")
