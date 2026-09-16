class_name MapLegend
extends Control


const SWATCH_SIZE := 12.0
const PANEL_OFFSET := Vector2(8.0, 8.0)

var _panel: PanelContainer
var _rows: VBoxContainer
var _expanded: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var section := UI.collapsible_section("Factions", _expanded, _on_toggle)
	_panel.add_child(section["panel"])
	_rows = section["content"]

	_build_rows()
	_reposition()


func _build_rows() -> void:
	for faction_id in GameData.FACTIONS.keys():
		_rows.add_child(_build_row(GameData.FACTIONS[faction_id]))


func _build_row(faction: Dictionary) -> Control:
	var row := UI.hbox(6)

	var swatch := ColorRect.new()
	swatch.color = Color(faction["colour"])
	swatch.custom_minimum_size = Vector2(SWATCH_SIZE, SWATCH_SIZE)
	row.add_child(swatch)

	var name_label := Label.new()
	name_label.text = String(faction["shortName"])
	row.add_child(name_label)

	return row


func _on_toggle(expanded: bool) -> void:
	_expanded = expanded
	_reposition()


func _reposition() -> void:
	_panel.size = _panel.get_combined_minimum_size()
	_panel.position = PANEL_OFFSET
