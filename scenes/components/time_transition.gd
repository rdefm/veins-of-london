extends Control

const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")

var pending: Array[Dictionary] = []
var active := false
var elapsed := 0.0
var safe_elapsed := 0.0
var session: Dictionary = {}
var current: Dictionary = {}
var picture: TextureRect
var destination: Label
var atlas: Texture2D
var held_inputs: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	UI.anchor_full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	session = GameState.state
	var config: Dictionary = GameData.DAILY_CYCLE
	atlas = load(config["atlas"])
	var background := ColorRect.new()
	background.color = Color(config["background"])
	UI.anchor_full_rect(background)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var center := CenterContainer.new()
	UI.anchor_full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(column)
	picture = TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(picture)
	destination = Label.new()
	destination.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	destination.add_theme_color_override("font_color", Color(config["textColor"]))
	destination.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(destination)
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
	var ranges: Dictionary = config["ranges"]
	var source: Dictionary = current["source"]
	var target: Dictionary = current["destination"]
	var overnight: bool = target["day"] > source["day"]
	var reduced: bool = GameState.state["meta"].get("reducedMotion", false)
	var segments: Array = []
	if overnight:
		if ranges.has("evening_to_morning") and not reduced:
			for phase in range(int(source["phase"]), 3):
				segments.append(ranges[["morning_to_afternoon", "afternoon_to_evening", "evening_to_morning"][phase]])
	else:
		segments.append(ranges["morning_to_afternoon" if source["phase"] == 0 else "afternoon_to_evening"])
	var segment: Dictionary = ranges["morning_to_afternoon"]
	var index := 0
	if not segments.is_empty():
		var count := 0
		for entry in segments:
			count += int(entry["count"])
		var progress := clampf(elapsed / float(config["durationSeconds"]), 0.0, 1.0)
		index = count - 1 if reduced else mini(int(progress * count), count - 1)
		for entry in segments:
			segment = entry
			if index < int(entry["count"]):
				break
			index -= int(entry["count"])
	index += int(segment["start"])
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	var cell := int(config["cellSize"])
	var columns := int(config["columns"])
	texture.region = Rect2((index % columns) * cell, (index / columns) * cell, segment["size"][0], segment["size"][1])
	picture.texture = texture
	var available := minf(size.x, float(config["displaySize"]))
	var scale_factor := maxi(1, int(available / maxf(segment["size"][0], segment["size"][1])))
	picture.custom_minimum_size = Vector2(segment["size"][0], segment["size"][1]) * scale_factor


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
