class_name SkillWheel
extends VBoxContainer

# Profile's Body / Mind / Soul wheel. Renders the SkillTree
# projection only: a 3-segment circle, the selected segment rotated to the
# bottom, and the selected bucket's sub-skills as Move Book-style rows
# (level badge, XP track, teaser; open: XP line + feat cards) that animate
# open beneath it. Selection and the open row are view state, reported
# through `on_change` / `on_sub`.

const SEGMENT_STEPS := 24
const MINI_TRACK_WIDTH := 64.0
const FALLBACK_COLOUR := Color("#66767c")
const TEXT_COLOUR := Color("#ededee")
const OUTLINE_COLOUR := Color("#14120f")

var selected_id := ""
var expanded := false
var open_sub := ""

var _tree: Array = []
var _config: Dictionary = {}
var _on_change: Callable
var _on_sub: Callable
var _rotation := 0.0
var _wheel: Control
var _clip: Control
var _details: VBoxContainer
var _tween: Tween


# `selected`/`open`/`sub` restore the view across a screen rebuild without
# animating; `on_sub` gets the open sub-skill id ("" = none).
static func build(tree: Array, selected: String, open: bool, on_change: Callable = Callable(), config: Dictionary = {}, sub := "", on_sub: Callable = Callable()) -> SkillWheel:
	var w := SkillWheel.new()
	w._setup(tree, selected, open, on_change, config if not config.is_empty() else GameData.SKILL_FEATS.get("wheel", {}), sub, on_sub)
	return w


func _setup(tree: Array, selected: String, open: bool, on_change: Callable, config: Dictionary, sub: String, on_sub: Callable) -> void:
	_tree = tree
	_config = config
	_on_change = on_change
	_on_sub = on_sub
	open_sub = sub
	add_theme_constant_override("separation", 8)
	selected_id = selected if _index_of(selected) >= 0 else (str(tree[0]["id"]) if not tree.is_empty() else "")
	expanded = open
	_rotation = _rotation_for(maxi(_index_of(selected_id), 0))

	_wheel = Control.new()
	_wheel.custom_minimum_size = Vector2(0, float(_config.get("diameter", 240)))
	_wheel.mouse_filter = Control.MOUSE_FILTER_STOP
	_wheel.draw.connect(_draw_wheel)
	_wheel.gui_input.connect(_on_wheel_input)
	add_child(_wheel)

	_clip = Control.new()
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_clip)
	_details = UI.vbox(6)
	_details.mouse_filter = Control.MOUSE_FILTER_PASS
	_clip.add_child(_details)
	_fill_details()
	_clip.custom_minimum_size.y = _open_height() if expanded else 0.0
	_clip.resized.connect(_on_clip_resized)


# Tap target: selects `id`, or collapses when it is already the open one.
func select(id: String) -> void:
	var index := _index_of(id)
	if index < 0:
		return
	if id == selected_id and expanded:
		expanded = false
		_animate_to(_rotation, false)
	else:
		var was_open := expanded
		selected_id = id
		expanded = true
		_animate_to(_rotation_near(index), was_open)
	if _on_change.is_valid():
		_on_change.call(selected_id, expanded)


func segment_at(point: Vector2) -> String:
	var offset := point - _wheel.size / 2.0
	if offset.length() > _radius() or offset.length() < 1.0 or _tree.is_empty():
		return ""
	var step := TAU / _tree.size()
	for i in _tree.size():
		if absf(angle_difference(_centre_angle(i), offset.angle())) <= step / 2.0:
			return str(_tree[i]["id"])
	return ""


func _on_wheel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var id := segment_at(event.position)
		if id != "":
			select(id)


func _index_of(id: String) -> int:
	for i in _tree.size():
		if _tree[i]["id"] == id:
			return i
	return -1


# Body (index 0) sits at the bottom (+PI/2 in canvas angles) at rest.
func _rotation_for(index: int) -> float:
	return -index * TAU / maxi(_tree.size(), 1)


func _centre_angle(index: int) -> float:
	return PI / 2.0 + index * TAU / maxi(_tree.size(), 1) + _rotation


# The equivalent target angle reached by the shortest turn.
func _rotation_near(index: int) -> float:
	var target := _rotation_for(index)
	return _rotation + angle_difference(_rotation, target)


func _radius() -> float:
	return minf(_wheel.size.x, _wheel.size.y) / 2.0 - 4.0


func _set_rotation(value: float) -> void:
	_rotation = value
	_wheel.queue_redraw()


func _animate_to(target_rotation: float, swap_content: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not is_inside_tree():
		_set_rotation(target_rotation)
		_fill_details()
		_clip.custom_minimum_size.y = _open_height() if expanded else 0.0
		return
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	var rotate_secs := float(_config.get("rotateSeconds", 0.0))
	_tween.tween_method(_set_rotation, _rotation, target_rotation, rotate_secs)
	if swap_content or not expanded:
		_tween.parallel().tween_property(_clip, "custom_minimum_size:y", 0.0, float(_config.get("closeSeconds", 0.0)))
	if expanded:
		_tween.tween_callback(_fill_details)
		_tween.tween_callback(_open_clip)


func _open_clip() -> void:
	var open_secs := float(_config.get("openSeconds", 0.0))
	var open_tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	open_tween.tween_property(_clip, "custom_minimum_size:y", _open_height(), open_secs)
	_tween = open_tween


func _open_height() -> float:
	return _details.get_combined_minimum_size().y


func _on_clip_resized() -> void:
	_details.size.x = _clip.size.x


func _colour_of(id: String) -> Color:
	var palette_id: String = str(_config.get("colours", {}).get(id, ""))
	return GameData.PALETTE.get(palette_id, FALLBACK_COLOUR)


func _draw_wheel() -> void:
	if _tree.is_empty():
		return
	var centre := _wheel.size / 2.0
	var radius := _radius()
	var step := TAU / _tree.size()
	var font: Font = ThemeDB.fallback_font
	for i in _tree.size():
		var bucket: Dictionary = _tree[i]
		var mid := _centre_angle(i)
		var pts := PackedVector2Array([centre])
		for s in SEGMENT_STEPS + 1:
			var a := mid - step / 2.0 + step * s / SEGMENT_STEPS
			pts.append(centre + Vector2.from_angle(a) * radius)
		var colour := _colour_of(str(bucket["id"]))
		if str(bucket["id"]) != selected_id:
			colour = colour.darkened(0.25)
		_wheel.draw_colored_polygon(pts, colour)
		_wheel.draw_polyline(pts, OUTLINE_COLOUR, 2.0)
		var text_at := centre + Vector2.from_angle(mid) * radius * 0.6
		var name_size := 18
		var name_text := str(bucket["label"])
		var level_text := "Lv%d" % int(bucket["level"])
		var name_w := font.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x
		var level_w := font.get_string_size(level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x
		_wheel.draw_string(font, text_at + Vector2(-name_w / 2.0, 0), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, TEXT_COLOUR)
		_wheel.draw_string(font, text_at + Vector2(-level_w / 2.0, name_size + 2), level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, TEXT_COLOUR)


# ---- details panel ----

func _fill_details() -> void:
	for child in _details.get_children():
		_details.remove_child(child)
		child.queue_free()
	var i := _index_of(selected_id)
	if i < 0:
		return
	var bucket: Dictionary = _tree[i]
	if _index_of_sub(bucket, open_sub) < 0:
		open_sub = ""
	for sub in bucket["subSkills"]:
		_details.add_child(_sub_row(sub, str(sub["id"]) == open_sub))


# Deferred: the details' minimum size is only recomputed after the new rows land.
func _fit_clip() -> void:
	if expanded:
		_clip.custom_minimum_size.y = _open_height()


func _index_of_sub(bucket: Dictionary, id: String) -> int:
	for i in bucket["subSkills"].size():
		if str(bucket["subSkills"][i]["id"]) == id:
			return i
	return -1


# Opens/closes a sub-skill row in place (no wheel animation) and reports it.
func toggle_sub(id: String) -> void:
	open_sub = "" if open_sub == id else id
	_fill_details()
	_fit_clip.call_deferred()
	if _on_sub.is_valid():
		_on_sub.call(open_sub)


func _sub_row(skill: Dictionary, is_open: bool) -> Control:
	var level_badge := "Lv%d" % int(skill["level"])
	var head := MoveBook.head_row(str(skill["label"]), level_badge, bool(skill["isMax"]), _mini_track(skill), _teaser(skill), is_open, toggle_sub.bind(str(skill["id"])))
	return MoveBook.row_panel(head, _sub_body(skill) if is_open else null)


func _mini_track(skill: Dictionary) -> Control:
	var track := UI.bar(_xp_into_level(skill), _xp_span(skill))
	track.custom_minimum_size = Vector2(MINI_TRACK_WIDTH, 8)
	track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return track


func _sub_body(skill: Dictionary) -> Control:
	var column := UI.vbox(10)
	column.add_child(UI.expand_fill(MapCardStyle.section_label(_xp_text(skill), 12)))
	var next_found := false
	for feat in skill["feats"]:
		var state := "earned"
		if not feat["unlocked"]:
			state = "locked" if next_found else "next"
			next_found = true
		column.add_child(MoveBook.unlock_card({ "state": state, "tag": "LV%d" % int(feat["level"]), "what": feat["text"] }))
	return column


func _teaser(skill: Dictionary) -> String:
	for feat in skill["feats"]:
		if not feat["unlocked"]:
			return str(_config.get("teaserNext", "")) % [int(feat["level"]), str(feat["text"])]
	return str(_config.get("teaserDone", ""))


func _xp_into_level(skill: Dictionary) -> float:
	return 1.0 if skill["isMax"] else float(skill["xp"] - skill["xpFloor"])


func _xp_span(skill: Dictionary) -> float:
	return 1.0 if skill["isMax"] else float(skill["xpNext"] - skill["xpFloor"])


func _xp_text(skill: Dictionary) -> String:
	if skill["isMax"]:
		return "%d XP (max)" % skill["xp"]
	return "%d / %d XP" % [skill["xp"], skill["xpNext"]]
