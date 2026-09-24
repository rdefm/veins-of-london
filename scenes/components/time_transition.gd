extends Control

const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")

var pending: Array[Dictionary] = []
var active := false
var elapsed := 0.0
var safe_elapsed := 0.0
var session: Dictionary = {}
var current: Dictionary = {}
var destination: Label
var foreground: Texture2D
var art_position := Vector2.ZERO
var frame: Dictionary = {}
var held_inputs: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UI.anchor_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	session = GameState.state
	var config: Dictionary = GameData.DAILY_CYCLE
	foreground = load(config["foreground"])
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	destination = Label.new()
	destination.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	destination.add_theme_color_override("font_color", Color(config["textColor"]))
	destination.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(destination)
	EventBus.time_advanced.connect(_capture)


func _capture(source: Dictionary, target: Dictionary) -> void:
	_sync_session()
	pending.append({ "source": source.duplicate(), "destination": target.duplicate() })
	safe_elapsed = 0.0


func _sync_session() -> void:
	if is_same(session, GameState.state):
		return
	session = GameState.state
	pending.clear()
	active = false
	visible = false
	current = {}
	frame = {}
	safe_elapsed = 0.0


static func outcome_finished() -> bool:
	var state: Dictionary = GameState.state
	return state.get("event") == null and not state["combat"].get("active", false) \
		and state.get("modal") == null and not state.get("bagDrawerOpen", false) \
		and state.get("currentScreen") not in ["event", "combat", "title", "intro"]


func _process(delta: float) -> void:
	_sync_session()
	var step := minf(delta, 0.1)
	if active:
		elapsed += step
		_render_frame()
		if elapsed >= float(GameData.DAILY_CYCLE["durationSeconds"]):
			var completed_target: Dictionary = current["destination"]
			var was_overnight: bool = completed_target["day"] > current["source"]["day"]
			active = false
			visible = false
			safe_elapsed = 0.0
			if was_overnight:
				MorningAccountsSystem.open_after_transition(completed_target["day"])
			return
	if pending.is_empty():
		return
	if not outcome_finished():
		safe_elapsed = 0.0
		return
	safe_elapsed += step
	if safe_elapsed < float(GameData.DAILY_CYCLE["outcomeHoldSeconds"]):
		return
	current = pending.pop_front()
	elapsed = 0.0
	active = true
	visible = true
	var target: Dictionary = current["destination"]
	destination.text = GameData.DAILY_CYCLE["destinationLabel"] % [target["day"], GameData.TIME_BLOCKS[int(target["phase"])]]
	_render_frame()


func _render_frame() -> void:
	var config: Dictionary = GameData.DAILY_CYCLE
	var duration := float(config["durationSeconds"])
	var entry := float(config["entrySeconds"])
	var exit_time := float(config["exitSeconds"])
	var reduced: bool = GameState.state["meta"].get("reducedMotion", false)
	var sky_progress := 1.0 if reduced else clampf((elapsed - entry) / (duration - entry - exit_time), 0.0, 1.0)
	frame = _sky_frame(sky_progress)
	var diameter := minf(float(config["diameter"]), size.x)
	var centered_y := (size.y - diameter - float(config["labelGap"]) - destination.get_minimum_size().y) * 0.5
	var offscreen_y := size.y + 1.0
	var y := centered_y
	if not reduced and elapsed < entry:
		y = lerpf(offscreen_y, centered_y, _smooth(elapsed / entry))
	elif not reduced and elapsed > duration - exit_time:
		y = lerpf(centered_y, offscreen_y, _smooth((elapsed - duration + exit_time) / exit_time))
	art_position = Vector2(roundf((size.x - diameter) * 0.5), roundf(y))
	destination.position = art_position + Vector2(0.0, diameter + float(config["labelGap"]))
	destination.size.x = diameter
	queue_redraw()


static func _smooth(t: float) -> float:
	var p := clampf(t, 0.0, 1.0)
	return p * p * (3.0 - 2.0 * p)


func _sky_frame(progress: float) -> Dictionary:
	var clips: Array = GameData.DAILY_CYCLE["clips"]
	var source_phase := int(current["source"]["phase"])
	var overnight: bool = current["destination"]["day"] > current["source"]["day"]
	var count := clips.size() - source_phase if overnight else 1
	var scaled := clampf(progress, 0.0, 1.0) * count
	var clip_index := mini(int(scaled), count - 1)
	var clip: Dictionary = clips[source_phase + clip_index]
	var local_progress := clampf(scaled - clip_index, 0.0, 1.0)
	var sky: Array = clip["sky"]
	var result := {
		"clip": clip["id"],
		"progress": local_progress,
		"top": Color(sky[0][0]).lerp(Color(sky[1][0]), local_progress),
		"bottom": Color(sky[0][1]).lerp(Color(sky[1][1]), local_progress),
		"sun": null,
		"moon": null,
	}
	for body in ["sun", "moon"]:
		if clip[body] != null:
			var endpoints: Array = clip[body]
			result[body] = Vector2(endpoints[0][0], endpoints[0][1]).lerp(
				Vector2(endpoints[1][0], endpoints[1][1]), local_progress)
	return result


func _draw() -> void:
	if not active or frame.is_empty():
		return
	var config: Dictionary = GameData.DAILY_CYCLE
	draw_rect(Rect2(Vector2.ZERO, size), Color(config["dimColor"]))
	var diameter := minf(float(config["diameter"]), size.x)
	var radius := diameter * 0.5
	var center := art_position + Vector2(radius, radius)
	for row in range(int(ceilf(diameter))):
		var y := float(row) - radius + 0.5
		var half_width := sqrt(maxf(radius * radius - y * y, 0.0))
		var colour: Color = frame["top"].lerp(frame["bottom"], float(row) / diameter)
		draw_rect(Rect2(center.x - half_width, art_position.y + row, half_width * 2.0, 1.0), colour)
	for body in ["sun", "moon"]:
		if frame[body] != null:
			_draw_body(body, art_position + (frame[body] as Vector2) * (diameter / float(config["diameter"])))
	draw_texture_rect(foreground, Rect2(art_position, Vector2(diameter, diameter)), false)


func _draw_body(body: String, position: Vector2) -> void:
	var config: Dictionary = GameData.DAILY_CYCLE
	var scale_factor := minf(float(config["diameter"]), size.x) / float(config["diameter"])
	var radius := float(config[body + "Radius"]) * scale_factor
	var rim := float(config["bodyRim"]) * scale_factor
	draw_circle(position, radius + rim, Color(config["bodyOutline"]))
	draw_circle(position, radius, Color(config[body + "Color"]))
	if body == "moon":
		var cutout: Array = config["moonCutout"]
		draw_circle(position + Vector2(cutout[0], cutout[1]) * radius,
			radius * float(cutout[2]), frame["top"])


func _input(event: InputEvent) -> void:
	var key := ""
	if event is InputEventScreenTouch:
		key = "touch%d" % event.index
	elif event is InputEventMouseButton:
		key = "mouse%d" % event.button_index
	elif event is InputEventKey:
		key = "key%d" % event.physical_keycode
	elif event is InputEventJoypadButton:
		key = "joy%d" % event.button_index
	var held := held_inputs.has(key)
	if not key.is_empty():
		if active and event.is_pressed():
			held_inputs[key] = true
		elif not event.is_pressed():
			held_inputs.erase(key)
	if active or held:
		get_viewport().set_input_as_handled()
