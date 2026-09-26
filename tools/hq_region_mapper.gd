extends Control

# Desktop authoring tool for HQ room plates: pick a `<tierId>_room.png`,
# pick a zone, click round the object to trace its hit polygon, then save
# into data/hq_visuals.json's "rooms" block. Test-tap mode reports which
# zone(s) a click lands in. Points are stored in the plate's display space
# (docs/hq-diorama-vision.md §3). Run with:
#   godot --path . res://tools/hq_region_mapper.tscn

const DATA_PATH := "res://data/hq_visuals.json"
const ASSET_DIR := "res://assets/hq"
const TEMPLATE_PLATE := "bedsit"
const WINDOW_SIZE := Vector2i(1280, 900)
const PANEL_WIDTH := 300
const CANVAS_MARGIN := 16.0
const CLOSE_SNAP_PX := 12.0
const HELP_TEXT := "Click to add points. Close with a click on the first point, Enter, or right-click. Ctrl+Z / Backspace undoes a point, Esc cancels. Ctrl+S saves."

enum Mode { DRAW, TEST }

var _data: Dictionary = {}
var _zones: Array[Dictionary] = []
var _tiers: Array[Dictionary] = []
var _tier_index: int = 0
var _zone_id: String = ""
var _mode: Mode = Mode.DRAW
var _points: Array = []
var _hover: Vector2 = Vector2.ZERO
var _test_point: Variant = null
var _textures: Dictionary = {}
var _dirty: bool = false
var _errors: Array[String] = []

var _canvas: Control
var _info: Label
var _problems: Label
var _status: Label
var _zone_buttons: Dictionary = {}


func _ready() -> void:
	var window := get_window()
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	window.size = WINDOW_SIZE
	window.move_to_center()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_data = HqRegionMapperLogic.normalize(JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)))
	_zones = HqRegionMapperLogic.zones_from_plate(_data["rooms"][TEMPLATE_PLATE])
	_tiers = HqRegionMapperLogic.room_images(DirAccess.get_files_at(ASSET_DIR), ASSET_DIR, GameData.HOME_TIER_ORDER)
	_build_ui()
	if not _zones.is_empty():
		_select_zone(_zones[0]["id"])
	_refresh()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color(0.12, 0.12, 0.14)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	root.add_child(margin)
	var panel := VBoxContainer.new()
	panel.custom_minimum_size.x = PANEL_WIDTH
	panel.add_theme_constant_override("separation", 6)
	margin.add_child(panel)

	panel.add_child(_label("Plate image"))
	var tier_picker := OptionButton.new()
	tier_picker.focus_mode = Control.FOCUS_NONE
	for tier in _tiers:
		tier_picker.add_item("%s  (%s)" % [tier["id"], String(tier["image"]).get_file()])
	tier_picker.item_selected.connect(_select_tier)
	panel.add_child(tier_picker)
	_info = _label("")
	panel.add_child(_info)

	panel.add_child(_label("Mode"))
	var mode_row := HBoxContainer.new()
	var mode_group := ButtonGroup.new()
	mode_row.add_child(_toggle("Draw", mode_group, true, func(): _set_mode(Mode.DRAW)))
	mode_row.add_child(_toggle("Test tap", mode_group, false, func(): _set_mode(Mode.TEST)))
	panel.add_child(mode_row)

	panel.add_child(_label("Zone"))
	var zone_group := ButtonGroup.new()
	for zone in _zones:
		var zone_id: String = zone["id"]
		var button := _toggle("", zone_group, false, func(): _select_zone(zone_id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		panel.add_child(button)
		_zone_buttons[zone_id] = button

	var shape_row := HBoxContainer.new()
	shape_row.add_child(_button("Undo point", _undo_point))
	shape_row.add_child(_button("Finish shape", _finish_shape))
	shape_row.add_child(_button("Cancel", _cancel_shape))
	panel.add_child(shape_row)
	panel.add_child(_button("Clear zone on this plate", _clear_zone))
	panel.add_child(_button("Save to data/hq_visuals.json", _save))

	_problems = _label("")
	_problems.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	panel.add_child(_problems)
	_status = _label("")
	_status.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	panel.add_child(_status)
	var help := _label(HELP_TEXT)
	help.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	panel.add_child(help)

	_canvas = Control.new()
	_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_canvas.clip_contents = true
	_canvas.draw.connect(_draw_canvas)
	_canvas.gui_input.connect(_on_canvas_input)
	_canvas.resized.connect(_canvas.queue_redraw)
	root.add_child(_canvas)


func _label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = PANEL_WIDTH
	return label


func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_pressed)
	return button


func _toggle(text: String, group: ButtonGroup, pressed: bool, on_pressed: Callable) -> Button:
	var button := _button(text, on_pressed)
	button.toggle_mode = true
	button.button_group = group
	button.button_pressed = pressed
	return button


# ── state ──

func _tier() -> Dictionary:
	return _tiers[_tier_index] if _tier_index < _tiers.size() else {}


func _plate() -> Dictionary:
	return _data["rooms"].get(_tier().get("id", ""), {})


func _texture() -> Texture2D:
	var path: String = _tier().get("image", "")
	if path.is_empty():
		return null
	if not _textures.has(path):
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		_textures[path] = ImageTexture.create_from_image(image) if image != null else null
	return _textures[path]


func _plate_size() -> Vector2:
	var plate := _plate()
	if not plate.is_empty():
		return Vector2(plate["width"], plate["height"])
	var texture := _texture()
	var width: int = _data["rooms"][TEMPLATE_PLATE]["width"]
	if texture == null:
		return Vector2(width, _data["rooms"][TEMPLATE_PLATE]["height"])
	return Vector2(HqRegionMapperLogic.display_size(Vector2i(texture.get_size()), width))


func _view_scale() -> float:
	var plate_size := _plate_size()
	var available := _canvas.size - Vector2.ONE * CANVAS_MARGIN * 2.0
	return maxf(0.01, minf(available.x / plate_size.x, available.y / plate_size.y))


func _view_origin() -> Vector2:
	return (_canvas.size - _plate_size() * _view_scale()) * 0.5


func _to_screen(point: Vector2) -> Vector2:
	return _view_origin() + point * _view_scale()


func _to_plate(screen: Vector2) -> Vector2:
	return (screen - _view_origin()) / _view_scale()


func _zone_label(zone_id: String) -> String:
	for zone in _zones:
		if zone["id"] == zone_id:
			return zone["label"]
	return zone_id


func _zone_color(zone_id: String) -> Color:
	for i in _zones.size():
		if _zones[i]["id"] == zone_id:
			return Color.from_hsv(float(i) / _zones.size(), 0.75, 1.0)
	return Color.WHITE


# ── actions ──

func _select_tier(index: int) -> void:
	_tier_index = index
	_points.clear()
	_test_point = null
	_status.text = ""
	_refresh()


func _select_zone(zone_id: String) -> void:
	_zone_id = zone_id
	_points.clear()
	_zone_buttons[zone_id].button_pressed = true
	_refresh()


func _set_mode(mode: Mode) -> void:
	_mode = mode
	_points.clear()
	_test_point = null
	_status.text = ""
	_refresh()


func _undo_point() -> void:
	if not _points.is_empty():
		_points.pop_back()
		_canvas.queue_redraw()


func _cancel_shape() -> void:
	_points.clear()
	_canvas.queue_redraw()


func _finish_shape() -> void:
	if _points.size() < 3:
		_status.text = "A shape needs at least 3 points."
		return
	var tier := _tier()
	if tier.is_empty() or _zone_id.is_empty():
		return
	var rooms: Dictionary = _data["rooms"]
	if not rooms.has(tier["id"]):
		var template: Dictionary = rooms[TEMPLATE_PLATE]
		var plate := HqRegionMapperLogic.new_plate(tier["image"], template["fallbackColor"], Vector2i(_plate_size()))
		_data["rooms"] = HqRegionMapperLogic.with_plate(rooms, tier["id"], plate, GameData.HOME_TIER_ORDER)
	HqRegionMapperLogic.set_region_polygon(_plate(), _zone_id, _zone_label(_zone_id), _points)
	_status.text = "%s set on %s (%d points). Unsaved." % [_zone_label(_zone_id), tier["id"], _points.size()]
	_points.clear()
	_dirty = true
	_refresh()


func _clear_zone() -> void:
	_points.clear()
	var regions: Dictionary = _plate().get("regions", {})
	if regions.erase(_zone_id):
		_dirty = true
		_status.text = "%s cleared from %s -- not reachable on this tier. Unsaved." % [_zone_label(_zone_id), _tier()["id"]]
	_refresh()


func _save() -> void:
	if not _errors.is_empty():
		_status.text = "Not saved: fix the problems listed above first."
		return
	var text := FileAccess.get_file_as_string(DATA_PATH)
	var nl := "\r\n" if text.contains("\r\n") else "\n"
	var updated := HqRegionMapperLogic.replace_rooms_block(text, HqRegionMapperLogic.serialize_rooms(_data["rooms"], nl))
	if updated.is_empty():
		_status.text = "Not saved: couldn't find the top-level \"rooms\" block."
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.WRITE)
	if file == null:
		_status.text = "Not saved: couldn't open %s for writing." % DATA_PATH
		return
	file.store_string(updated)
	file.close()
	_dirty = false
	_status.text = "Saved."
	_refresh()


func _refresh() -> void:
	var tables: Dictionary = GameData.snapshot().duplicate()
	tables["hq_visuals"] = _data
	_errors.clear()
	for e in GameData.validate_tables(tables):
		if e.begins_with("hq_visuals"):
			_errors.append(e)
	_problems.text = "" if _errors.is_empty() else "Problems:\n- " + "\n- ".join(PackedStringArray(_errors))

	var regions: Dictionary = _plate().get("regions", {})
	for zone in _zones:
		var region: Dictionary = regions.get(zone["id"], {})
		var state := "not set"
		if region.has("polygon"):
			state = "polygon, %d pts" % region["polygon"].size()
		elif not region.is_empty():
			state = "rect only"
		_zone_buttons[zone["id"]].text = "%s  —  %s" % [zone["label"], state]

	var texture := _texture()
	var plate_size := _plate_size()
	var source := "missing image" if texture == null else "%dx%d px" % [texture.get_width(), texture.get_height()]
	var entry := "in data" if not _plate().is_empty() else "not in data yet (created on first shape)"
	_info.text = "%s -> %dx%d display. Plate %s." % [source, plate_size.x, plate_size.y, entry]
	get_window().title = "HQ region mapper — %s%s" % [_tier().get("id", "?"), " *" if _dirty else ""]
	_canvas.queue_redraw()


# ── input ──

func _on_canvas_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null:
		_hover = motion.position
		if not _points.is_empty():
			_canvas.queue_redraw()
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	if click.button_index == MOUSE_BUTTON_RIGHT and _mode == Mode.DRAW:
		_finish_shape()
		return
	if click.button_index != MOUSE_BUTTON_LEFT:
		return
	var point := _to_plate(click.position)
	if not Rect2(Vector2.ZERO, _plate_size()).has_point(point):
		return
	var rounded := point.round()
	if _mode == Mode.TEST:
		_test_point = rounded
		var hits := HqRegionMapperLogic.regions_at(_plate().get("regions", {}), rounded)
		var names := PackedStringArray()
		for id in hits:
			names.append("%s (%s)" % [_zone_label(id), id])
		_status.text = "Tap at (%d, %d) -> %s" % [rounded.x, rounded.y, ", ".join(names) if not names.is_empty() else "no zone"]
		_canvas.queue_redraw()
		return
	if _points.size() >= 3 and click.position.distance_to(_to_screen(Vector2(_points[0][0], _points[0][1]))) <= CLOSE_SNAP_PX:
		_finish_shape()
		return
	_points.append([int(rounded.x), int(rounded.y)])
	_canvas.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			_finish_shape()
		KEY_ESCAPE:
			_cancel_shape()
		KEY_BACKSPACE:
			_undo_point()
		KEY_Z:
			if key.ctrl_pressed:
				_undo_point()
		KEY_S:
			if key.ctrl_pressed:
				_save()


# ── drawing ──

func _draw_canvas() -> void:
	var plate_rect := Rect2(_view_origin(), _plate_size() * _view_scale())
	var texture := _texture()
	if texture != null:
		_canvas.draw_texture_rect(texture, plate_rect, false)
	else:
		_canvas.draw_rect(plate_rect, Color(0.3, 0.3, 0.3))

	var regions: Dictionary = _plate().get("regions", {})
	for zone_id in regions:
		_draw_region(zone_id, regions[zone_id])

	if not _points.is_empty():
		var color := _zone_color(_zone_id)
		var screen_points := PackedVector2Array()
		for p in _points:
			screen_points.append(_to_screen(Vector2(p[0], p[1])))
		if screen_points.size() > 1:
			_canvas.draw_polyline(screen_points, color, 2.0)
		_canvas.draw_line(screen_points[-1], _hover, Color(color, 0.6), 1.0)
		for p in screen_points:
			_canvas.draw_circle(p, 4.0, color)
		if screen_points.size() >= 3:
			_canvas.draw_arc(screen_points[0], CLOSE_SNAP_PX, 0.0, TAU, 24, Color.WHITE, 2.0)

	if _test_point != null:
		var p := _to_screen(_test_point)
		_canvas.draw_circle(p, 6.0, Color.WHITE)
		_canvas.draw_circle(p, 3.0, Color.BLACK)


func _draw_region(zone_id: String, region: Dictionary) -> void:
	var selected := zone_id == _zone_id
	var color := _zone_color(zone_id)
	var label_at: Vector2
	if region.has("polygon"):
		var screen_points := PackedVector2Array()
		for p in region["polygon"]:
			screen_points.append(_to_screen(Vector2(p[0], p[1])))
		if not Geometry2D.triangulate_polygon(screen_points).is_empty():
			_canvas.draw_colored_polygon(screen_points, Color(color, 0.4 if selected else 0.22))
		var closed := screen_points.duplicate()
		closed.append(screen_points[0])
		_canvas.draw_polyline(closed, color, 3.0 if selected else 2.0)
		if selected:
			for p in screen_points:
				_canvas.draw_circle(p, 3.0, color)
		label_at = _to_screen(HqRegionMapperLogic.bounds(region["polygon"]).position)
	else:
		var rect := HqRegionMapperLogic.region_rect(region)
		var screen_rect := Rect2(_to_screen(rect.position), rect.size * _view_scale())
		_canvas.draw_rect(screen_rect, Color(color, 0.12), true)
		_canvas.draw_rect(screen_rect, Color(color, 0.8), false, 1.0)
		label_at = screen_rect.position
	var text := _zone_label(zone_id) + ("" if region.has("polygon") else " (rect)")
	var font := ThemeDB.fallback_font
	_canvas.draw_string(font, label_at + Vector2(5, 17), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
	_canvas.draw_string(font, label_at + Vector2(4, 16), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color.lightened(0.5))
