class_name SkillWheel
extends VBoxContainer

# Profile's Body / Mind / Soul wheel. Renders the SkillTree
# projection only: a 3-segment circle, the selected segment rotated to the
# bottom, and a details panel (sub-skills, XP, feats) that animates open
# beneath it. Selection is view state, reported through `on_change`.

const SEGMENT_STEPS := 24
const FALLBACK_COLOUR := Color("#66767c")
const TEXT_COLOUR := Color("#ededee")
const OUTLINE_COLOUR := Color("#14120f")

var selected_id := ""
var expanded := false

var _tree: Array = []
var _config: Dictionary = {}
var _on_change: Callable
var _rotation := 0.0
var _wheel: Control
var _clip: Control
var _details: VBoxContainer
var _tween: Tween


# `selected`/`open` restore the view across a screen rebuild without animating.
static func build(tree: Array, selected: String, open: bool, on_change: Callable = Callable(), config: Dictionary = {}) -> SkillWheel:
	var w := SkillWheel.new()
	w._setup(tree, selected, open, on_change, config if not config.is_empty() else GameData.SKILL_FEATS.get("wheel", {}))
	return w


func _setup(tree: Array, selected: String, open: bool, on_change: Callable, config: Dictionary) -> void:
	_tree = tree
	_config = config
	_on_change = on_change
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
	_details.add_child(_skill_block(bucket, true))
	for sub in bucket["subSkills"]:
		_details.add_child(_skill_block(sub, false))


func _skill_block(skill: Dictionary, is_bucket: bool) -> Control:
	var c := UI.card()
	var box: VBoxContainer = c["content"]
	var title := UI.heading("%s — Lv%d" % [skill["label"], skill["level"]], 16 if is_bucket else 14)
	box.add_child(title)
	box.add_child(UI.muted_label(_xp_text(skill)))
	box.add_child(UI.bar(float(skill["xp"] - skill["xpFloor"]) if not skill["isMax"] else 1.0, float(skill["xpNext"] - skill["xpFloor"]) if not skill["isMax"] else 1.0))
	for feat in skill["feats"]:
		var line := "Lv%d: %s" % [feat["level"], feat["text"]]
		box.add_child(UI.label(line) if feat["unlocked"] else UI.muted_label(line))
	return c["panel"]


func _xp_text(skill: Dictionary) -> String:
	if skill["isMax"]:
		return "%d XP (max)" % skill["xp"]
	return "%d / %d XP" % [skill["xp"], skill["xpNext"]]
