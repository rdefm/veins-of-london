class_name StageActor
extends Node2D

# One rigged character (data/stages/rigs/<rig>.json): layered part sprites on
# a shared canvas, feet at this node's position. Attributes (arm frames, eyes,
# brows, mouth, tilt) come from StageDirection snapshots and card steps; the
# idle life on top -- breathing, blinking, chewing, talk flaps -- runs here.

var rig: Dictionary
var attrs: Dictionary = {}
var motion := true

var _sprites: Dictionary = {}
var _textures: Dictionary = {}
var _body: Node2D
var _head: Node2D
var _origin: Vector2
var _neck: Vector2
var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _blink_at := 0.0
var _blink_until := -1.0
var _talk_until := -1.0
var _talk_next := 0.0
var _talk_frame := ""
var _talk_index := 0
var _chew_clock := 0.0
var _tilt := 0.0
var _actions: Array = []


func setup(rig_def: Dictionary) -> void:
	rig = rig_def
	_origin = _vec(rig["origin"])
	_neck = _vec(rig["anchors"]["neck"])
	_body = Node2D.new()
	_head = Node2D.new()
	_head.position = _neck - _origin
	for part_id in rig["order"]:
		var part: Dictionary = rig["parts"][part_id]
		var frames: Dictionary = {}
		for frame_id in part["frames"]:
			frames[frame_id] = load(String(rig["dir"]) + String(part["frames"][frame_id]))
		_textures[part_id] = frames
		var sprite := Sprite2D.new()
		sprite.centered = false
		sprite.texture = frames.values()[0]
		match part["group"]:
			"root":
				sprite.position = -_origin
				add_child(sprite)
			"body":
				sprite.position = -_origin
				if _body.get_parent() == null:
					add_child(_body)
				_body.add_child(sprite)
			"head":
				sprite.position = -_neck
				if _head.get_parent() == null:
					if _body.get_parent() == null:
						add_child(_body)
					_body.add_child(_head)
				_head.add_child(sprite)
		_sprites[part_id] = sprite
	_blink_at = _rng.randf_range(rig["behaviour"]["blink_every"][0], rig["behaviour"]["blink_every"][1])
	apply_attrs(rig["defaults"])


func apply_attrs(new_attrs: Dictionary) -> void:
	for key in new_attrs:
		attrs[key] = new_attrs[key]
	if not motion:
		_tilt = float(attrs.get("tilt", 0))
	_redraw()


# Jumps the head straight to its target tilt (card snaps, not eased).
func snap_tilt() -> void:
	_tilt = float(attrs.get("tilt", 0))
	_redraw()


func set_attr(key: String, value: Variant) -> void:
	attrs[key] = value
	_redraw()


# Plays a rig action (timed attribute sets) from now.
func play(action_id: String) -> void:
	for step in rig["actions"][action_id]:
		_actions.append({"at": _time + float(step["t"]), "set": step["set"]})


func talk(seconds: float) -> void:
	if not motion:
		return
	_talk_until = _time + seconds
	_talk_next = _time
	_talk_index = 0


func stop_talking() -> void:
	_talk_until = -1.0
	_talk_frame = ""
	_actions.clear()


func is_talking() -> bool:
	return _time < _talk_until


# Anchor in this actor's local space (relative to its feet).
func anchor(name: String) -> Vector2:
	var anchors: Dictionary = rig["anchors"]
	if name == "mouth":
		var mouth := _vec(anchors["mouth"]) - _neck
		return _body.position + _head.position + mouth.rotated(_head.rotation)
	var frame: String = attrs.get(name.replace("hand_", "arm_"), "")
	return _body.position + _vec(anchors[name][frame]) - _origin


# Driven by StagePlayer.advance() so the whole stage shares one clock.
func step(delta: float) -> void:
	_time += delta
	var due: Array = []
	for action in _actions:
		if action["at"] <= _time:
			due.append(action)
	for action in due:
		_actions.erase(action)
		for key in action["set"]:
			attrs[key] = action["set"][key]
	if not motion:
		_redraw()
		return
	var behaviour: Dictionary = rig["behaviour"]
	# blink
	if _time >= _blink_at:
		_blink_until = _time + float(behaviour["blink_len"])
		_blink_at = _time + _rng.randf_range(behaviour["blink_every"][0], behaviour["blink_every"][1])
	# talk flaps
	if is_talking() and _time >= _talk_next:
		var talk_frames: Array = rig["talk_frames"]
		_talk_frame = talk_frames[_talk_index % talk_frames.size()]
		_talk_index += 1 + _rng.randi_range(0, 1)
		_talk_next = _time + float(behaviour["talk_step"]) * _rng.randf_range(0.8, 1.3)
	elif not is_talking():
		_talk_frame = ""
	_chew_clock += delta
	# breathing: the whole upper body rises a pixel for part of each breath
	var period: float = behaviour["breathe_period"]
	_body.position.y = -1.0 if fmod(_time, period) < period * 0.45 else 0.0
	# tilt eases toward its target
	var target := float(attrs.get("tilt", 0))
	_tilt = move_toward(_tilt, target, float(behaviour["tilt_speed"]) * delta)
	_redraw()


func _redraw() -> void:
	for part_id in ["arm_l", "arm_r", "eyes", "brows"]:
		_show(part_id, attrs.get(part_id, ""))
	var eyes: String = attrs.get("eyes", "open")
	if motion and _time < _blink_until and eyes != "closed":
		_show("eyes", "closed")
	_show("mouth", _mouth_frame())
	_head.rotation_degrees = _tilt


func _mouth_frame() -> String:
	if _talk_frame != "":
		return _talk_frame
	var mouth: String = attrs.get("mouth", "closed")
	var states: Dictionary = rig["mouth_states"]
	if states.has(mouth):
		if not motion:
			return states[mouth][0]
		var behaviour: Dictionary = rig["behaviour"]
		var frames: Array = states[mouth]
		var run: float = float(behaviour["chew_step"]) * frames.size() * float(behaviour["chew_run"])
		var cycle: float = run + float(behaviour["chew_pause"])
		var t := fmod(_chew_clock, cycle)
		if t >= run:
			return frames[0]
		return frames[int(t / float(behaviour["chew_step"])) % frames.size()]
	return mouth


func _show(part_id: String, frame_id: String) -> void:
	var frames: Dictionary = _textures[part_id]
	if frames.has(frame_id):
		_sprites[part_id].texture = frames[frame_id]


static func _vec(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))
