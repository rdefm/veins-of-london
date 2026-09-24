class_name MapZoomButtons
extends Control


const MARGIN := Vector2(8.0, 8.0)
const BUTTON_SIZE := Vector2(UI.ICON_BUTTON_SIZE, UI.ICON_BUTTON_SIZE)
const PILL_RADIUS := 14

var map_canvas: MapCanvas

var _pill: PanelContainer
var _box: HBoxContainer
var _divider: ColorRect
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

	_pill = PanelContainer.new()
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill.add_theme_stylebox_override("panel", _pill_style())
	add_child(_pill)

	_box = UI.hbox(0)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pill.add_child(_box)

	_zoom_out_button = _build_button("−", "Zoom out", false, func(): map_canvas.step_zoom(-1))
	_box.add_child(_zoom_out_button)

	_divider = ColorRect.new()
	_divider.color = MapPalette.colour("chromeBorder")
	_divider.custom_minimum_size.x = 1.0
	_divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_divider)

	_zoom_in_button = _build_button("+", "Zoom in", true, func(): map_canvas.step_zoom(1))
	_box.add_child(_zoom_in_button)

	if map_canvas != null:
		map_canvas.zoom_changed.connect(_update_disabled)
	_update_disabled()
	_reposition()


func _build_button(glyph: String, tooltip: String, right_half: bool, callback: Callable) -> Button:
	var button := Button.new()
	button.text = glyph
	button.tooltip_text = tooltip
	button.custom_minimum_size = BUTTON_SIZE
	button.add_theme_font_size_override("font_size", 22)
	var ink := MapPalette.colour("chromeInk")
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_color_override("font_pressed_color", ink)
	button.add_theme_color_override("font_focus_color", ink)
	button.add_theme_color_override("font_disabled_color", Color(ink, 0.35))
	button.add_theme_stylebox_override("normal", _button_style(Color.TRANSPARENT, right_half))
	button.add_theme_stylebox_override("hover", _button_style(Color(ink, 0.06), right_half))
	button.add_theme_stylebox_override("pressed", _button_style(Color(ink, 0.12), right_half))
	button.add_theme_stylebox_override("focus", _button_style(Color(ink, 0.06), right_half))
	button.add_theme_stylebox_override("disabled", _button_style(Color.TRANSPARENT, right_half))
	button.pressed.connect(callback)
	return button


func _pill_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = MapPalette.colour("chromePaper")
	style.set_border_width_all(1)
	style.border_color = MapPalette.colour("chromeBorder")
	style.set_corner_radius_all(PILL_RADIUS)
	style.content_margin_left = 1.0
	style.content_margin_top = 1.0
	style.content_margin_right = 1.0
	style.content_margin_bottom = 1.0
	style.shadow_color = Color(MapPalette.colour("shadow"), 0.13)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 3.0)
	return style


func _button_style(fill: Color, right_half: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.content_margin_left = 8.0
	style.content_margin_top = 6.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 6.0
	if right_half:
		style.corner_radius_top_right = PILL_RADIUS - 1
		style.corner_radius_bottom_right = PILL_RADIUS - 1
	else:
		style.corner_radius_top_left = PILL_RADIUS - 1
		style.corner_radius_bottom_left = PILL_RADIUS - 1
	return style


func _update_disabled(_zoom: float = 0.0) -> void:
	if map_canvas == null:
		return
	_zoom_in_button.disabled = map_canvas.zoom_level >= MapZoom.MAX
	_zoom_out_button.disabled = map_canvas.zoom_level <= MapZoom.MIN


func _reposition() -> void:
	_box.size = _box.get_combined_minimum_size()
	_pill.size = _pill.get_combined_minimum_size()
	_pill.position = -_pill.size - MARGIN
