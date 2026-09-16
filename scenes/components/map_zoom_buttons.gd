class_name MapZoomButtons
extends Control


const MARGIN := Vector2(8.0, 8.0)
const BUTTON_SIZE := Vector2(UI.ICON_BUTTON_SIZE, UI.ICON_BUTTON_SIZE)

var map_canvas: MapCanvas

var _box: VBoxContainer
var _zoom_in_button: Button
var _zoom_out_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN

	_box = UI.vbox(6)
	add_child(_box)

	_zoom_in_button = UI.button("+", func(): map_canvas.step_zoom(1))
	_zoom_in_button.custom_minimum_size = _zoom_in_button.custom_minimum_size.max(BUTTON_SIZE)
	_box.add_child(_zoom_in_button)

	_zoom_out_button = UI.button("-", func(): map_canvas.step_zoom(-1))
	_zoom_out_button.custom_minimum_size = _zoom_out_button.custom_minimum_size.max(BUTTON_SIZE)
	_box.add_child(_zoom_out_button)

	if map_canvas != null:
		map_canvas.zoom_changed.connect(_update_disabled)
	_update_disabled()
	_reposition()


func _update_disabled(_zoom: float = 0.0) -> void:
	if map_canvas == null:
		return
	_zoom_in_button.disabled = map_canvas.zoom_level >= MapZoom.MAX
	_zoom_out_button.disabled = map_canvas.zoom_level <= MapZoom.MIN


func _reposition() -> void:
	_box.size = _box.get_combined_minimum_size()
	_box.position = -_box.size - MARGIN
