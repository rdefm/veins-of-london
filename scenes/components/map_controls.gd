class_name MapControls
extends Control

const Preferences := preload("res://systems/preferences.gd")


const FILTER_LABELS := {
	"ownership": "Ownership",
	"type": "Type",
	"growth": "Growth",
	"security": "Security",
}


const PACING_LABELS := {
	"sequential": "Pace: Sequential",
	"simultaneous": "Pace: Simultaneous",
}

const DRAWER_WIDTH := 260.0

var map_canvas: MapCanvas

var _filter_mode: String = "ownership"
var _last_non_faction_filter: String = "ownership"
var _selected_faction_id: String = ""
var _faction_picker_open: bool = false
var _pacing_mode: String = MapEvents.DEFAULT_PACING_MODE
var _is_open: bool = false

var _dim: ColorRect
var _panel: PanelContainer
var _list: VBoxContainer


func _ready() -> void:
	UI.anchor_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_dim = ColorRect.new()
	_dim.color = Color(MapPalette.colour("scrim"), 0.5)
	UI.anchor_full_rect(_dim)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0
	_panel.anchor_top = 0
	_panel.anchor_right = 0
	_panel.anchor_bottom = 1
	_panel.offset_left = 0
	_panel.offset_top = 0
	_panel.offset_right = DRAWER_WIDTH
	_panel.offset_bottom = 0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.visible = false
	add_child(_panel)

	var scroll := UI.scroll_container()
	_panel.add_child(scroll)

	_list = UI.vbox(8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	if map_canvas != null:
		_pacing_mode = map_canvas.pacing_mode

	_rebuild()


func open() -> void:
	_set_open(true)


func close() -> void:
	_set_open(false)


func toggle() -> void:
	_set_open(not _is_open)


func _set_open(value: bool) -> void:
	_is_open = value
	_dim.visible = value
	_panel.visible = value


func _on_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		close()


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()

	_list.add_child(UI.heading("Filters", 14))
	for mode in MapStyle.FILTER_MODES:
		if mode == "faction":
			continue  # own row shape below, see _build_faction_rows()
		var b := UI.button(FILTER_LABELS[mode], func(): _select_filter(mode))
		b.disabled = mode == _filter_mode
		_list.add_child(b)

	_build_faction_rows()

	_list.add_child(UI.heading("Other", 14))
	_list.add_child(UI.button(PACING_LABELS[_pacing_mode], _toggle_pacing))
	var dark := CheckButton.new()
	dark.text = GameData.MAP_PALETTE["darkModeLabel"]
	dark.button_pressed = MapPalette.is_dark()
	dark.toggled.connect(Preferences.set_map_dark_mode)
	_list.add_child(dark)
	_list.add_child(UI.button("? Legend", func(): _open_legend()))
	_list.add_child(UI.button("Close", close))


func _select_filter(mode: String) -> void:
	_filter_mode = mode
	_selected_faction_id = ""
	_last_non_faction_filter = mode
	if map_canvas != null:
		map_canvas.set_filter(mode)
	_rebuild()
	close()


func _build_faction_rows() -> void:
	var row := UI.button(_faction_row_label(), _toggle_faction_picker)
	_list.add_child(row)

	if not _faction_picker_open:
		return

	for faction_id in GameData.FACTIONS.keys():
		var faction: Dictionary = GameData.FACTIONS[faction_id]
		var colour := MapPalette.faction_colour(faction_id)
		var faction_button := UI.button("   " + String(faction["shortName"]), func(): _select_faction(faction_id))
		faction_button.add_theme_color_override("font_color", colour)
		faction_button.add_theme_color_override("font_hover_color", colour)
		faction_button.disabled = _filter_mode == "faction" and _selected_faction_id == faction_id
		_list.add_child(faction_button)

	_list.add_child(UI.button("   Clear (show all)", _clear_faction_filter))


func _faction_row_label() -> String:
	if _filter_mode == "faction" and _selected_faction_id != "":
		return "Faction: %s" % GameData.FACTIONS[_selected_faction_id]["shortName"]
	return "Faction"


func _toggle_faction_picker() -> void:
	_faction_picker_open = not _faction_picker_open
	_rebuild()


func _select_faction(faction_id: String) -> void:
	_filter_mode = "faction"
	_selected_faction_id = faction_id
	_faction_picker_open = false
	if map_canvas != null:
		map_canvas.set_faction_filter(faction_id)
	_rebuild()
	close()


func _clear_faction_filter() -> void:
	_faction_picker_open = false
	_select_filter(_last_non_faction_filter)


func _toggle_pacing() -> void:
	var idx := MapEvents.PACING_MODES.find(_pacing_mode)
	_pacing_mode = MapEvents.PACING_MODES[(idx + 1) % MapEvents.PACING_MODES.size()]
	if map_canvas != null:
		map_canvas.set_pacing(_pacing_mode)
	_rebuild()
	close()


func _open_legend() -> void:
	Modal.open("network_reference")
	close()
