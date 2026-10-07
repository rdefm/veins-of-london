class_name StagePlayer
extends Control

# Live pixel-art stage for an event's VN image slot (data/stages/<event_id>.json).
# Renders a low-res world into a SubViewport and shows it at an integer pixel
# scale, so pixels stay square on any screen. show_card() snaps to the folded
# start state of a card (StageDirection) and then plays that card's timed
# steps. Reads GameData and the reducedMotion pref only; never writes state.

const LIGHT_BASE_ALPHA := 0.8
const DROP_GRAVITY := 520.0
const DROP_HOP_TIME := 0.2
const DROP_HOP_HEIGHT := 3.0
const WOBBLE_TIME := 0.35
const SHARD_COUNT := 8
const SHARD_LIFE := 0.45
const SHARD_SPEED := 60.0
const SHARD_COLOUR := Color(0.85, 0.93, 1.0)
const FIELD_SHADER := preload("res://scenes/stage/slow_field.gdshader")

var event_id := ""
var stage: Dictionary
var set_def: Dictionary
var motion := true
var shown_card := -1

var _viewport: SubViewport
var _display: TextureRect
var _world: Node2D
var _parallax_nodes: Array = []  # [{node, parallax}]
var _walkers: Array = []
var _ambient: Array = []
var _lights: Array = []
var _actors: Dictionary = {}
var _props_root: Node2D
var _near: Node2D
var _fields: Array = []  # [{field (StageDirection.slow_field), node, material, t, grow}]
var _pixel: Texture2D
var _objects: Dictionary = {}  # id -> {"back", "front" (or null), "x"}
var _fx: Array = []
var _steps: Array = []
var _moves: Array = []  # [{target, actor (or null), from, to, t, dur}]
var _clock := 0.0
var _camera_x := 0.0
var _camera_move: Dictionary = {}
var _wobble_object := ""
var _wobble_until := -1.0
var _fit: Dictionary = {"scale": 1, "size": Vector2i(180, 240)}
var _rng := RandomNumberGenerator.new()


func setup(stage_event_id: String) -> void:
	event_id = stage_event_id
	stage = GameData.STAGES[event_id]
	set_def = GameData.STAGE_SETS[stage["set"]]
	motion = not GameState.state["meta"].get("reducedMotion", false)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_viewport = SubViewport.new()
	_viewport.disable_3d = true
	_viewport.transparent_bg = false
	_viewport.snap_2d_transforms_to_pixel = true
	_viewport.snap_2d_vertices_to_pixel = true
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	_display = TextureRect.new()
	_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_display.stretch_mode = TextureRect.STRETCH_SCALE
	_display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_display.texture = _viewport.get_texture()
	add_child(_display)

	_world = Node2D.new()
	_viewport.add_child(_world)
	_build_world()
	_camera_x = float(stage["camera"]["x"])
	resized.connect(_fit_viewport)
	_fit_viewport()


func _build_world() -> void:
	var dir: String = set_def["dir"]
	_add_layers("back", dir)
	_build_walkers(dir)
	_add_layers("mid", dir)
	var near := _add_parallax_node(1.0)
	_near = near
	_build_ambient(near, dir)
	_build_lights(near, dir)
	for object_id in set_def["objects"]:
		var object_def: Dictionary = set_def["objects"][object_id]
		_objects[object_id] = {"x": float(object_def["x"]), "front": null,
			"back": _sprite(near, load(dir + String(object_def["back"])), Vector2.ZERO)}
	for actor_id in stage["actors"]:
		var actor_def: Dictionary = stage["actors"][actor_id]
		var actor := StageActor.new()
		actor.motion = motion
		actor.position = Vector2(float(actor_def["x"]), float(set_def["floor_y"]))
		near.add_child(actor)
		actor.setup(GameData.STAGE_RIGS[actor_def["rig"]])
		_actors[actor_id] = actor
	_props_root = Node2D.new()
	near.add_child(_props_root)
	for object_id in set_def["objects"]:
		var object_def: Dictionary = set_def["objects"][object_id]
		if object_def.has("front"):
			_objects[object_id]["front"] = _sprite(near, load(dir + String(object_def["front"])), Vector2.ZERO)
	_place_objects()
	_add_layers("front", dir)


func _add_parallax_node(parallax: float) -> Node2D:
	var node := Node2D.new()
	_world.add_child(node)
	_parallax_nodes.append({"node": node, "parallax": parallax})
	return node


func _add_layers(slot: String, dir: String) -> void:
	for layer in set_def["layers"]:
		if layer["slot"] == slot:
			var node := _add_parallax_node(float(layer["parallax"]))
			_sprite(node, load(dir + String(layer["file"])), Vector2.ZERO)


func _build_walkers(dir: String) -> void:
	var spec: Dictionary = set_def["walkers"]
	var node := _add_parallax_node(float(spec["parallax"]))
	for walker in spec["list"]:
		var frames: Array = []
		for file in walker["frames"]:
			frames.append(load(dir + String(file)))
		var sprite := _sprite(node, frames[0], Vector2.ZERO)
		sprite.flip_h = float(walker["dir"]) < 0
		_walkers.append({"sprite": sprite, "frames": frames, "x": float(walker["x"]),
			"speed": float(walker["speed"]), "dir": float(walker["dir"])})
	_place_walkers(0.0)


func _build_ambient(parent: Node2D, dir: String) -> void:
	for entry in set_def["ambient"]:
		var frames: Array = []
		for file in entry["frames"]:
			frames.append(load(dir + String(file)))
		var sprite := _sprite(parent, frames[0], Vector2(entry["pos"][0], entry["pos"][1]))
		_ambient.append({"sprite": sprite, "frames": frames, "holds": entry["hold"], "frame": 0,
			"until": _rng.randf_range(entry["hold"][0][0], entry["hold"][0][1])})


func _build_lights(parent: Node2D, dir: String) -> void:
	var lights: Dictionary = set_def["lights"]
	var texture: Texture2D = load(dir + String(lights["file"]))
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for point in lights["points"]:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.material = material
		sprite.position = Vector2(point[0], point[1])
		sprite.modulate.a = LIGHT_BASE_ALPHA
		parent.add_child(sprite)
		_lights.append({"sprite": sprite, "phase": _rng.randf_range(0.0, TAU)})


func _sprite(parent: Node, texture: Texture2D, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.centered = false
	sprite.texture = texture
	sprite.position = pos
	parent.add_child(sprite)
	return sprite


# ── cards ───────────────────────────────────────────────────────────

func show_card(card_index: int) -> void:
	if card_index == shown_card:
		return
	shown_card = card_index
	_set_running(true)
	_clear_card()
	var snap := StageDirection.resolve_start(stage, card_index) if motion else StageDirection.resolve_end(stage, card_index)
	_apply_snapshot(snap)
	if motion and card_index >= 0 and card_index < stage["cards"].size():
		for step in StageDirection.sorted_steps(stage["cards"][card_index]):
			_steps.append({"at": _clock + float(step["t"]), "step": step})
	_place_camera()


# Hides and idles the stage on a card past its last entry, so the event
# screen's card image shows through; the next show_card() wakes it.
func rest() -> void:
	if shown_card == -1 and not visible:
		return
	shown_card = -1
	_clear_card()
	_set_running(false)


func _clear_card() -> void:
	_steps.clear()
	for fx in _fx:
		fx["sprite"].queue_free()
	_fx.clear()
	for child in _props_root.get_children():
		child.queue_free()
	for field in _fields:
		field["node"].queue_free()
	_fields.clear()
	_camera_move = {}
	_moves.clear()
	_wobble_until = -1.0
	for actor in _actors.values():
		actor.stop_talking()
		actor.set_walking(false)


func _set_running(running: bool) -> void:
	visible = running
	set_process(running)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if running else SubViewport.UPDATE_DISABLED


func _apply_snapshot(snap: Dictionary) -> void:
	_camera_x = snap["camera_x"]
	for actor_id in snap["actors"]:
		var look: Dictionary = snap["actors"][actor_id]
		var actor: StageActor = _actors[actor_id]
		actor.apply_attrs(look)
		actor.snap_tilt()
		actor.position.x = float(look["x"])
		actor.visible = look["visible"]
	for object_id in snap["objects"]:
		_objects[object_id]["x"] = float(snap["objects"][object_id]["x"])
	_place_objects()
	for rest in snap["props"]:
		_prop_sprite(rest["prop"], Vector2(rest["x"], rest["y"]))
	for field in snap["fields"]:
		_add_field(field, 0.0)


func _prop_sprite(prop_id: String, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(String(set_def["dir"]) + String(set_def["props"][prop_id]))
	sprite.position = pos.round()
	_props_root.add_child(sprite)
	return sprite


func _process(delta: float) -> void:
	advance(delta)


# One shared clock for steps, actors, effects and ambient life.
func advance(delta: float) -> void:
	_clock += delta
	var due: Array = []
	for pending in _steps:
		if pending["at"] <= _clock:
			due.append(pending)
	for pending in due:
		_steps.erase(pending)
		_run_step(pending["step"])
	_update_fields(delta)
	_update_moves(delta)
	for actor in _actors.values():
		actor.step(delta * time_scale_of(actor))
	_update_fx(delta)
	_update_camera(delta)
	if motion:
		_update_ambient(delta)
	_place_camera()


func _run_step(step: Dictionary) -> void:
	if step.has("set"):
		for path in step["set"]:
			var target := StageDirection.split_target(path)
			_actors[target[0]].set_attr(target[1], step["set"][path])
	elif step.has("play"):
		var target := StageDirection.split_target(step["play"])
		_actors[target[0]].play(target[1])
	elif step.has("talk"):
		var actor: StageActor = _actors[step["talk"]]
		var text: String = GameData.EVENTS[event_id]["cards"][shown_card].get("text", "")
		actor.talk(StageDirection.talk_seconds(text, actor.rig["behaviour"]))
	elif step.has("drop"):
		var drop: Dictionary = step["drop"]
		var from := _anchor_world(drop["from"])
		var dropper: StageActor = _actors[StageDirection.split_target(drop["from"])[0]]
		var to := StageDirection.drop_landing(stage, drop, dropper.position.x, dropper.attrs["facing"])
		_fx.append({"kind": "drop", "sprite": _prop_sprite(drop["prop"], from), "prop": drop["prop"],
			"from": from, "to": to, "t": 0.0})
	elif step.has("throw"):
		var throw: Dictionary = step["throw"]
		var from := _anchor_world(throw["from"])
		var target: String = throw.get("to", "")
		var to := Vector2(float(throw.get("at", 0.0)), float(set_def["floor_y"]))
		if target != "":
			var target_def: Dictionary = set_def["objects"][target]
			to = _object_origin(target) + Vector2(target_def["mouth"][0], target_def["mouth"][1] + 6.0)
		_fx.append({"kind": "throw", "sprite": _prop_sprite(throw["prop"], from), "from": from, "to": to,
			"t": 0.0, "dur": float(throw["dur"]), "arc": float(throw["arc"]), "target": target})
	elif step.has("slow"):
		_add_field(StageDirection.slow_field(step["slow"]), float(step["slow"].get("grow", 0.0)))
	elif step.has("camera"):
		_camera_move = {"from": _camera_x, "to": float(step["camera"]["x"]), "t": 0.0,
			"dur": maxf(0.001, float(step["camera"].get("dur", 0.0)))}
	elif step.has("move"):
		_start_move(step["move"])
	elif step.has("show"):
		_actors[step["show"]].visible = true
	elif step.has("hide"):
		_actors[step["hide"]].visible = false


func _start_move(move: Dictionary) -> void:
	var target: String = move["target"]
	for running in _moves.duplicate():
		if running["target"] == target:
			_moves.erase(running)
	var actor: StageActor = _actors.get(target)
	var from: float = actor.position.x if actor != null else _objects[target]["x"]
	_moves.append({"target": target, "actor": actor, "from": from, "to": roundf(float(move["x"])),
		"t": 0.0, "dur": maxf(0.001, float(move.get("dur", 0.0)))})
	if actor != null:
		actor.set_walking(true)


func _update_moves(delta: float) -> void:
	var finished: Array = []
	for move in _moves:
		var actor: StageActor = move["actor"]
		move["t"] += delta * (time_scale_of(actor) if actor != null else 1.0)
		var u: float = move["t"] / move["dur"]
		var x := roundf(lerpf(move["from"], move["to"], StageDirection.ease_move(u)))
		if actor != null:
			actor.position.x = x
		else:
			_objects[move["target"]]["x"] = x
		if u >= 1.0:
			finished.append(move)
			if actor != null:
				actor.set_walking(false)
	for move in finished:
		_moves.erase(move)


func _anchor_world(path: String) -> Vector2:
	var target := StageDirection.split_target(path)
	var actor: StageActor = _actors[target[0]]
	return actor.position + actor.anchor(target[1])


func _update_fx(delta: float) -> void:
	var finished: Array = []
	var bursts: Array = []
	for fx in _fx:
		fx["t"] += delta
		var sprite: Sprite2D = fx["sprite"]
		var from: Vector2 = fx["from"]
		var to: Vector2 = fx["to"]
		if fx["kind"] == "drop":
			var fall_time := sqrt(2.0 * maxf(0.0, to.y - from.y) / DROP_GRAVITY)
			var t: float = fx["t"]
			var hop_from := to - Vector2(2.0, 0.0)
			if t < fall_time:
				var u := t / maxf(fall_time, 0.001)
				sprite.position = Vector2(lerpf(from.x, hop_from.x, u), from.y + 0.5 * DROP_GRAVITY * t * t).round()
			elif t < fall_time + DROP_HOP_TIME:
				var u := (t - fall_time) / DROP_HOP_TIME
				sprite.position = Vector2(lerpf(hop_from.x, to.x, u), to.y - DROP_HOP_HEIGHT * 4.0 * u * (1.0 - u)).round()
			else:
				sprite.position = to.round()
				finished.append(fx)
		elif fx["kind"] == "shard":
			var t: float = fx["t"]
			sprite.position = (from + fx["vel"] * t + Vector2(0.0, 0.5 * DROP_GRAVITY * t * t)).round()
			sprite.modulate.a = 1.0 - t / SHARD_LIFE
			if t >= SHARD_LIFE:
				sprite.queue_free()
				finished.append(fx)
		else:
			var s: float = clampf(fx["t"] / fx["dur"], 0.0, 1.0)
			var pos := from.lerp(to, s)
			pos.y -= fx["arc"] * 4.0 * s * (1.0 - s)
			sprite.position = pos.round()
			if s >= 1.0:
				sprite.queue_free()
				if fx["target"] == "":
					bursts.append(to)
				else:
					_wobble_object = fx["target"]
					_wobble_until = _clock + WOBBLE_TIME
				finished.append(fx)
	for fx in finished:
		_fx.erase(fx)
	for at in bursts:
		_shatter(at)
	_place_objects()


# A floor throw ends in a burst of glass: pixel shards fly up and out, fall,
# and fade.
func _shatter(at: Vector2) -> void:
	if not motion:
		return
	if _pixel == null:
		var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_pixel = ImageTexture.create_from_image(image)
	for i in range(SHARD_COUNT):
		var angle := PI + PI * (float(i) + _rng.randf_range(0.2, 0.8)) / SHARD_COUNT
		var sprite := Sprite2D.new()
		sprite.texture = _pixel
		sprite.modulate = SHARD_COLOUR
		sprite.position = at.round()
		_props_root.add_child(sprite)
		_fx.append({"kind": "shard", "sprite": sprite, "from": at, "to": at, "t": 0.0,
			"vel": Vector2.from_angle(angle) * SHARD_SPEED * _rng.randf_range(0.5, 1.0)})


# ── slow fields ─────────────────────────────────────────────────────

# Adds a standing slow field; grow > 0 swells it from nothing over that many
# seconds (motion only).
func _add_field(field: Dictionary, grow: float) -> void:
	var width := float(field["radius"]) * 2.0
	var height := float(field["height"])
	var material := ShaderMaterial.new()
	material.shader = FIELD_SHADER
	material.set_shader_parameter("size_px", Vector2(width, height))
	material.set_shader_parameter("motion", 1.0 if motion else 0.0)
	var node := ColorRect.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.material = material
	node.position = Vector2(float(field["x"]) - width / 2.0, float(set_def["floor_y"]) + 2.0 - height)
	node.size = Vector2(width, height)
	_near.add_child(node)
	var entry := {"field": field, "node": node, "material": material, "t": 0.0,
		"grow": grow if motion else 0.0}
	_fields.append(entry)
	_shade_field(entry)


func _update_fields(delta: float) -> void:
	for entry in _fields:
		entry["t"] += delta
		_shade_field(entry)


func _shade_field(entry: Dictionary) -> void:
	var material: ShaderMaterial = entry["material"]
	material.set_shader_parameter("grow", _field_growth(entry))
	material.set_shader_parameter("time", entry["t"] if motion else 0.0)


func _field_growth(entry: Dictionary) -> float:
	if entry["grow"] <= 0.0:
		return 1.0
	return smoothstep(0.0, 1.0, clampf(entry["t"] / entry["grow"], 0.0, 1.0))


# How fast an actor's own clock runs: slowed inside a slow field (as far as it
# has grown), normal outside.
func time_scale_of(actor: StageActor) -> float:
	var live: Array = []
	for entry in _fields:
		var field: Dictionary = entry["field"].duplicate()
		field["radius"] = float(field["radius"]) * _field_growth(entry)
		live.append(field)
	return StageDirection.time_scale_at(live, actor.position.x)


# Top-left of an object's sprites: centred on its x, resting on the floor.
func _object_origin(object_id: String) -> Vector2:
	var object_def: Dictionary = set_def["objects"][object_id]
	var x: float = _objects[object_id]["x"]
	return Vector2(roundf(x - object_def["size"][0] / 2.0), float(set_def["floor_y"]) + 2.0 - object_def["size"][1])


func _place_objects() -> void:
	for object_id in _objects:
		var pos := _object_origin(object_id)
		if object_id == _wobble_object and _clock < _wobble_until:
			pos.x += 1.0 if int(_clock / 0.06) % 2 == 0 else -1.0
		var entry: Dictionary = _objects[object_id]
		entry["back"].position = pos
		if entry["front"] != null:
			entry["front"].position = pos


func _update_camera(delta: float) -> void:
	if _camera_move.is_empty():
		return
	_camera_move["t"] += delta
	var u: float = clampf(_camera_move["t"] / _camera_move["dur"], 0.0, 1.0)
	_camera_x = lerpf(_camera_move["from"], _camera_move["to"], smoothstep(0.0, 1.0, u))
	if u >= 1.0:
		_camera_move = {}


func _update_ambient(delta: float) -> void:
	_place_walkers(delta)
	for entry in _ambient:
		if _clock >= entry["until"]:
			var next := 0 if entry["frame"] != 0 else _rng.randi_range(1, entry["frames"].size() - 1)
			entry["frame"] = next
			var hold: Array = entry["holds"][next]
			entry["until"] = _clock + _rng.randf_range(hold[0], hold[1])
			entry["sprite"].texture = entry["frames"][next]
	for light in _lights:
		var phase: float = light["phase"]
		var flicker := 0.12 * sin(_clock * 2.3 + phase) + 0.06 * sin(_clock * 7.7 + phase * 2.0)
		light["sprite"].modulate.a = LIGHT_BASE_ALPHA + flicker


func _place_walkers(delta: float) -> void:
	var spec: Dictionary = set_def["walkers"]
	var lo: float = spec["range"][0]
	var hi: float = spec["range"][1]
	for walker in _walkers:
		walker["x"] += walker["speed"] * walker["dir"] * delta
		if walker["dir"] > 0 and walker["x"] > hi:
			walker["x"] = lo
		elif walker["dir"] < 0 and walker["x"] < lo:
			walker["x"] = hi
		var frames: Array = walker["frames"]
		walker["sprite"].texture = frames[int(_clock / float(spec["frame_time"])) % frames.size()] if motion else frames[0]
		walker["sprite"].position = Vector2(roundf(walker["x"] - spec["size"][0] / 2.0), float(spec["feet_y"]) - spec["size"][1])


# ── camera + fit ────────────────────────────────────────────────────

func camera_left() -> float:
	var world_w: float = set_def["world"][0]
	var view_w: float = _fit["size"].x
	return clampf(_camera_x - view_w / 2.0, 0.0, maxf(0.0, world_w - view_w))


func _place_camera() -> void:
	var left := camera_left()
	for entry in _parallax_nodes:
		entry["node"].position.x = -roundf(left * entry["parallax"])


func _fit_viewport() -> void:
	var px_per_unit := 1.0
	if is_inside_tree():
		px_per_unit = (get_viewport().get_final_transform() * get_global_transform_with_canvas()).get_scale().x
	var frame_px := size * px_per_unit
	if frame_px.x < 1.0 or frame_px.y < 1.0:
		return
	_fit = StageDirection.viewport_fit(frame_px, int(set_def["design_size"][0]))
	_viewport.size = _fit["size"]
	var shown := Vector2(_fit["size"]) * float(_fit["scale"]) / px_per_unit
	_display.size = shown
	_display.position = (((size - shown) / 2.0) * px_per_unit).round() / px_per_unit
	_world.position.y = float(_fit["size"].y) - float(set_def["world"][1])
	_place_camera()
