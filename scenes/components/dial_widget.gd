class_name DialWidget
extends Control


const HANDLE_TEXTURE_PATH := "res://assets/hq/dial/dial_device_base.png"
const NEEDLE_TEXTURE_PATH := "res://assets/hq/dial/dial-needle.png"

const WIDGET_PADDING := 8.0

const TOP_PADDING := 16.0

const HANDLE_NATIVE_SIZE := 500.0

const CROP_NATIVE_X := 130.0
const CROP_NATIVE_WIDTH := 260.0

const HANDLE_DISPLAY_SIZE := 400.0
const HANDLE_SCALE := HANDLE_DISPLAY_SIZE / HANDLE_NATIVE_SIZE

const RENDERED_WIDTH := CROP_NATIVE_WIDTH * HANDLE_SCALE

const WIDGET_SIZE := Vector2(RENDERED_WIDTH + WIDGET_PADDING * 2.0, HANDLE_DISPLAY_SIZE + WIDGET_PADDING + TOP_PADDING)

const WRAP_OFFSET := Vector2(WIDGET_PADDING, TOP_PADDING)

const _SOURCE_CENTER_X := 250.0
const FACE_CENTER_NATIVE := Vector2(_SOURCE_CENTER_X - CROP_NATIVE_X, 101.0)
const NEEDLE_ATLAS_REGION := Rect2(3.0, 1.0, 45.0, 37.0)
const NEEDLE_HUB_NATIVE := Vector2(13.0, 26.0)
const NEEDLE_MIN_DEG := -90.0
const NEEDLE_MAX_DEG := 90.0

const DOT_OFFSETS_NATIVE: Array[Vector2] = [
	Vector2(0.0, -88.0), Vector2(61.0, 0.0), Vector2(0.0, 88.0), Vector2(-61.0, 0.0),
]
const DOT_HIT_SIZE := Vector2(34.0, 34.0)
const MAX_DOTS := 4

const BUTTON_CENTER_NATIVE := Vector2(_SOURCE_CENTER_X - CROP_NATIVE_X, 280.0)
const BUTTON_HIT_SIZE := Vector2(64.0, 36.0)

var _dial: Dictionary = {}
var _selected_index: int = 0
var _on_selection_changed: Callable = Callable()
var _on_triggered: Callable = Callable()


func configure(dial: Dictionary, selected_index: int, on_selection_changed: Callable, on_triggered: Callable = Callable()) -> void:
	_dial = dial
	var loaded: Array = dial.get("loadedComplications", [])
	_selected_index = clampi(selected_index, 0, maxi(0, loaded.size() - 1))
	_on_selection_changed = on_selection_changed
	_on_triggered = on_triggered
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = WIDGET_SIZE
	size_flags_vertical = Control.SIZE_SHRINK_END
	clip_contents = true

	if get_child_count() == 0:
		_build_art()
	_position_needle()
	if _overlay != null:
		_overlay.queue_redraw()


func current_index() -> int:
	return _selected_index


func handle_select(index: int) -> void:
	var loaded: Array = _dial.get("loadedComplications", [])
	if index < 0 or index >= loaded.size():
		return
	if _on_selection_changed.is_valid():
		_on_selection_changed.call(index)


func handle_trigger() -> void:
	var result: Dictionary = Combat.cast_complication(_selected_index)
	if _on_triggered.is_valid():
		_on_triggered.call(result)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap_at(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_tap_at(event.position)


func _handle_tap_at(pos: Vector2) -> void:
	if _button_rect().has_point(pos):
		handle_trigger()
		return
	for i in range(MAX_DOTS):
		if _dot_rect(i).has_point(pos):
			handle_select(i)
			return


func _dot_position(index: int) -> Vector2:
	return FACE_CENTER_NATIVE * HANDLE_SCALE + DOT_OFFSETS_NATIVE[index] * HANDLE_SCALE + WRAP_OFFSET


func _dot_rect(index: int) -> Rect2:
	return Rect2(_dot_position(index) - DOT_HIT_SIZE / 2.0, DOT_HIT_SIZE)


func _button_position() -> Vector2:
	return BUTTON_CENTER_NATIVE * HANDLE_SCALE + WRAP_OFFSET


func _button_rect() -> Rect2:
	return Rect2(_button_position() - BUTTON_HIT_SIZE / 2.0, BUTTON_HIT_SIZE)


var _base_rect: TextureRect
var _needle_rect: TextureRect

var _overlay: Control


func _build_art() -> void:
	var wrap := Control.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.position = WRAP_OFFSET
	wrap.custom_minimum_size = Vector2(RENDERED_WIDTH, HANDLE_DISPLAY_SIZE)
	add_child(wrap)

	_base_rect = TextureRect.new()
	var base_atlas := AtlasTexture.new()
	base_atlas.atlas = load(HANDLE_TEXTURE_PATH)
	base_atlas.region = Rect2(CROP_NATIVE_X, 0.0, CROP_NATIVE_WIDTH, HANDLE_NATIVE_SIZE)
	_base_rect.texture = base_atlas
	_base_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_base_rect.size = Vector2(RENDERED_WIDTH, HANDLE_DISPLAY_SIZE)
	_base_rect.stretch_mode = TextureRect.STRETCH_SCALE
	wrap.add_child(_base_rect)

	_needle_rect = TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = load(NEEDLE_TEXTURE_PATH)
	atlas.region = NEEDLE_ATLAS_REGION
	_needle_rect.texture = atlas
	_needle_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_needle_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_needle_rect.stretch_mode = TextureRect.STRETCH_SCALE
	var needle_size: Vector2 = NEEDLE_ATLAS_REGION.size * HANDLE_SCALE
	_needle_rect.size = needle_size
	_needle_rect.pivot_offset = NEEDLE_HUB_NATIVE * HANDLE_SCALE
	wrap.add_child(_needle_rect)

	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.position = Vector2.ZERO
	_overlay.size = WIDGET_SIZE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


func _position_needle() -> void:
	if _needle_rect == null:
		return
	var hub_offset: Vector2 = NEEDLE_HUB_NATIVE * HANDLE_SCALE
	_needle_rect.position = FACE_CENTER_NATIVE * HANDLE_SCALE - hub_offset
	_needle_rect.rotation_degrees = _needle_rotation_degrees()


func _needle_rotation_degrees() -> float:
	var max_charge: float = float(_dial.get("maxCharge", 0))
	if max_charge <= 0.0:
		return NEEDLE_MIN_DEG
	var fraction: float = clampf(float(_dial.get("currentCharge", 0)) / max_charge, 0.0, 1.0)
	return lerpf(NEEDLE_MIN_DEG, NEEDLE_MAX_DEG, fraction)


func _draw_overlay() -> void:
	var loaded: Array = _dial.get("loadedComplications", [])
	var can_trigger: bool = float(_dial.get("currentCharge", 0)) >= 1.0

	for i in range(MAX_DOTS):
		var pos: Vector2 = _dot_position(i)
		if i >= loaded.size():
			_overlay.draw_arc(pos, 5.0, 0.0, TAU, 16, Color(0.9, 0.9, 0.92, 0.3), 1.0)
			continue
		var is_selected: bool = i == _selected_index
		var colour: Color = Color(1.0, 0.86, 0.35, 0.95) if is_selected else Color(0.85, 0.85, 0.9, 0.65)
		_overlay.draw_arc(pos, 9.0 if is_selected else 7.0, 0.0, TAU, 20, colour, 2.5 if is_selected else 1.5)

	var button_colour: Color = Color(1.0, 0.86, 0.35, 0.95) if can_trigger else Color(0.55, 0.55, 0.58, 0.7)
	_draw_two_arrow_icon(_button_position(), button_colour)


const ARROW_ICON_HALF_LENGTH := 9.0
const ARROW_ICON_ROW_GAP := 5.0
const ARROW_ICON_HEAD_SIZE := 4.5


func _draw_two_arrow_icon(center: Vector2, colour: Color) -> void:
	_draw_single_arrow(center + Vector2(0.0, -ARROW_ICON_ROW_GAP), 1.0, colour)
	_draw_single_arrow(center + Vector2(0.0, ARROW_ICON_ROW_GAP), -1.0, colour)


func _draw_single_arrow(mid: Vector2, direction: float, colour: Color) -> void:
	var tail: Vector2 = mid - Vector2(ARROW_ICON_HALF_LENGTH * direction, 0.0)
	var tip: Vector2 = mid + Vector2(ARROW_ICON_HALF_LENGTH * direction, 0.0)
	_overlay.draw_line(tail, tip, colour, 2.0)
	var back: Vector2 = tip - Vector2(ARROW_ICON_HEAD_SIZE * direction, 0.0)
	var head := PackedVector2Array([
		tip,
		back + Vector2(0.0, ARROW_ICON_HEAD_SIZE * 0.7),
		back + Vector2(0.0, -ARROW_ICON_HEAD_SIZE * 0.7),
	])
	_overlay.draw_colored_polygon(head, colour)
