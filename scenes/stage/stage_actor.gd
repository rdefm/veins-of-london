class_name StageActor
extends Node2D

# One rigged character (data/stages/rigs/<rig>.json): layered part sprites on
# a shared canvas, feet at this node's position. Procedural offsets move in
# whole art pixels (rig `px` canvas pixels each). Attributes (arm frames, eyes,
# brows, mouth, tilt, facing) come from StageDirection snapshots and card
# steps; the idle life on top -- breathing, idle head drift,
# blinking, chewing, talk flaps and nods, the walk cycle while the player moves
# it -- runs here, each actor on its own jittered rhythm.

var rig: Dictionary
var attrs: Dictionary = {}
var motion := true
var walking := false

var _sprites: Dictionary = {}
var _textures: Dictionary = {}
var _shown: Dictionary = {}
var _walk_dist := 0.0
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
var _tilt_vel := 0.0
var _actions: Array = []
var _breathe_period := 1.0
var _breathe_phase := 0.0
var _idle_tilt := 0.0
var _idle_tilt_at := 0.0
var _nod := 0.0
var _dip := 0.0
var _px := 1.0
var _mirrored := false
var _flip_at := -1.0
var _crouch_until := -1.0
var _arm_tweens: Dictionary = {}


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
		_shown[part_id] = frames.keys()[0]
	_px = float(rig["px"])
	_rng.randomize()
	var behaviour: Dictionary = rig["behaviour"]
	_blink_at = _rand_in(behaviour["blink_every"])
	var jitter := float(behaviour["breathe_jitter"])
	_breathe_period = float(behaviour["breathe_period"]) * _rng.randf_range(1.0 - jitter, 1.0 + jitter)
	_breathe_phase = _rng.randf() * _breathe_period
	_idle_tilt_at = _rand_in(behaviour["idle_tilt_every"])
	apply_attrs(rig["defaults"])


func apply_attrs(new_attrs: Dictionary) -> void:
	for key in new_attrs:
		attrs[key] = new_attrs[key]
	_arm_tweens.clear()
	_flip_at = -1.0
	_mirrored = _faces_away()
	if not motion:
		_tilt = float(attrs.get("tilt", 0))
	_redraw()


# Jumps the head straight to its target tilt (card snaps, not eased).
func snap_tilt() -> void:
	_tilt = float(attrs.get("tilt", 0))
	_tilt_vel = 0.0
	_redraw()


# A live change: turning dips the body and flips halfway through; an arm
# moving to a new frame plays its in-betweens and dips the body for the effort.
func set_attr(key: String, value: Variant) -> void:
	var changed: bool = attrs.get(key) != value
	_tween_arm(key, attrs.get(key), value)
	attrs[key] = value
	if key == "facing":
		if motion and changed:
			var turn := float(rig["behaviour"]["turn_len"])
			_flip_at = _time + turn * 0.5
			_crouch_until = maxf(_crouch_until, _time + turn)
		else:
			_flip_at = -1.0
			_mirrored = _faces_away()
	elif key.begins_with("arm_") and changed:
		_effort()
	_redraw()


# Plays a rig action (timed attribute sets) from now.
func play(action_id: String) -> void:
	_effort()
	for step in rig["actions"][action_id]:
		_actions.append({"at": _time + float(step["t"]), "set": step["set"]})


func talk(seconds: float) -> void:
	if not motion:
		return
	_talk_until = _time + seconds
	_talk_next = _time
	_talk_index = 0


func stop_talking() -> void:
	_crouch_until = -1.0
	_talk_until = -1.0
	_talk_frame = ""
	_nod = 0.0
	_dip = 0.0
	_actions.clear()


func is_talking() -> bool:
	return _time < _talk_until


# Starts or stops the rig's walk cycle (no-op for rigs without one); stopping
# restores the standing frame.
func set_walking(on: bool) -> void:
	walking = on
	_walk_dist = 0.0
	_redraw()


# Feeds the walk cycle the distance just travelled: frames advance with the
# feet, not the clock, so they never skate.
func add_stride(px: float) -> void:
	_walk_dist += absf(px)


# Current walk frame index, or -1 when standing (or the rig has no walk).
func walk_index() -> int:
	if not (walking and motion and rig.has("walk")):
		return -1
	var walk: Dictionary = rig["walk"]
	var count: int = walk["frames"].size()
	return int(_walk_dist / float(walk["cycle_px"]) * count) % count

# Whether the actor is drawn mirrored right now (mid-turn it keeps the
# facing it turns from until the flip).
func is_mirrored() -> bool:
	return _mirrored


func _faces_away() -> bool:
	return StageDirection.is_mirrored(rig, attrs.get("facing", StageDirection.rig_faces(rig)))


# Starts the rig's in-betweens for an arm moving between two frames (a pair's
# frames, or its reverse played backwards); no-op without motion or a tween.
func _tween_arm(part_id: String, from: Variant, to: Variant) -> void:
	_arm_tweens.erase(part_id)
	if not motion or from == to or not part_id.begins_with("arm_"):
		return
	var pairs: Dictionary = rig.get("tweens", {}).get(part_id, {})
	var frames: Array = []
	if pairs.has("%s>%s" % [from, to]):
		frames = pairs["%s>%s" % [from, to]]
	elif pairs.has("%s>%s" % [to, from]):
		frames = pairs["%s>%s" % [to, from]].duplicate()
		frames.reverse()
	if not frames.is_empty():
		_arm_tweens[part_id] = {"frames": frames, "at": _time}


# In-between frame an arm shows now, or "" once its tween is over. Ease-out:
# progress 1 - (1 - x)^2 over `arm_tween` seconds picks the frame, so the arm
# leaves fast and the last in-between holds before the target lands.
func _tween_frame(part_id: String) -> String:
	if not _arm_tweens.has(part_id):
		return ""
	var tween: Dictionary = _arm_tweens[part_id]
	var x := (_time - float(tween["at"])) / float(rig["behaviour"]["arm_tween"])
	if x >= 1.0:
		_arm_tweens.erase(part_id)
		return ""
	var frames: Array = tween["frames"]
	var eased := 1.0 - (1.0 - x) * (1.0 - x)
	return frames[mini(int(eased * frames.size()), frames.size() - 1)]


func _effort() -> void:
	if motion:
		_crouch_until = maxf(_crouch_until, _time + float(rig["behaviour"]["effort_dip"]))


# Frame id a part is currently showing.
func shown_frame(part_id: String) -> String:
	return _shown.get(part_id, "")


# Anchor relative to this actor's feet, in its parent's space (mirrored with
# the rig when it faces the other way).
func anchor(name: String) -> Vector2:
	var anchors: Dictionary = rig["anchors"]
	var point: Vector2
	if name == "mouth":
		var mouth := _vec(anchors["mouth"]) - _neck
		point = _body.position + _head.position + mouth.rotated(_head.rotation)
	else:
		var frame: String = attrs.get(name.replace("hand_", "arm_"), "")
		point = _body.position + _vec(anchors[name][frame]) - _origin
	if is_mirrored():
		point.x = -point.x
	return point


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
			_tween_arm(key, attrs.get(key), action["set"][key])
			attrs[key] = action["set"][key]
	if not motion:
		_redraw()
		return
	var behaviour: Dictionary = rig["behaviour"]
	# blink
	if _time >= _blink_at:
		_blink_until = _time + float(behaviour["blink_len"])
		_blink_at = _time + _rng.randf_range(behaviour["blink_every"][0], behaviour["blink_every"][1])
	# talk flaps, each beat sometimes nodding or dipping the head
	if is_talking() and _time >= _talk_next:
		var talk_frames: Array = rig["talk_frames"]
		_talk_frame = talk_frames[_talk_index % talk_frames.size()]
		_talk_index += 1 + _rng.randi_range(0, 1)
		_talk_next = _time + float(behaviour["talk_step"]) * _rng.randf_range(0.8, 1.3)
		if _rng.randf() < float(behaviour["talk_nod_chance"]):
			_nod = _rng.randf_range(-1.0, 1.0) * float(behaviour["talk_nod"])
		_dip = 1.0 if _rng.randf() < float(behaviour["talk_dip_chance"]) else 0.0
	elif not is_talking():
		_talk_frame = ""
		_nod = 0.0
		_dip = 0.0
	_chew_clock += delta
	if _flip_at >= 0.0 and _time >= _flip_at:
		_flip_at = -1.0
		_mirrored = _faces_away()
	# breathing: the upper body rises a pixel for part of each breath; a turn or
	# an effort sinks it a pixel instead
	var breath := fmod(_time + _breathe_phase, _breathe_period) < _breathe_period * 0.45
	var rise := -1.0 if breath else 0.0
	var stride := walk_index()
	if stride >= 0:
		rise = float(rig["walk"].get("bob", [])[stride]) if rig["walk"].has("bob") else 0.0
	_body.position.y = _px * (1.0 if _time < _crouch_until else rise)
	# the head drifts to a new small idle angle now and then
	if _time >= _idle_tilt_at:
		var drift := float(behaviour["idle_tilt"])
		_idle_tilt = 0.0 if _rng.randf() < 0.35 else _rng.randf_range(-drift, drift)
		_idle_tilt_at = _time + _rand_in(behaviour["idle_tilt_every"])
	_head.position = _neck - _origin + Vector2(0.0, _dip * _px)
	# tilt springs toward its target with a little overshoot
	var target := float(attrs.get("tilt", 0)) + _idle_tilt + _nod
	if stride >= 0:
		target += float(rig["walk"].get("lean", 0.0))
	var stiffness := float(behaviour["tilt_stiffness"])
	var damping := float(behaviour["tilt_damping"])
	var left := delta
	while left > 0.0:
		var h := minf(left, 1.0 / 120.0)
		_tilt_vel += (stiffness * (target - _tilt) - damping * _tilt_vel) * h
		_tilt += _tilt_vel * h
		left -= h
	_redraw()


func _redraw() -> void:
	for part_id in ["eyes", "brows"]:
		_show(part_id, attrs.get(part_id, ""))
	# arms swing against the legs while walking, where the pose has swing frames
	var stride := walk_index()
	var swing: int = int(rig["walk"]["swing"][stride]) if stride >= 0 and rig["walk"].has("swing") else 0
	for part_id in ["arm_l", "arm_r"]:
		var between := _tween_frame(part_id)
		if between != "":
			_show(part_id, between)
			continue
		var pose: String = attrs.get(part_id, "")
		var level := swing if part_id == "arm_l" else -swing
		var swung := "%s@%d" % [pose, level]
		_show(part_id, swung if level != 0 and _textures[part_id].has(swung) else pose)
	var eyes: String = attrs.get("eyes", "open")
	if motion and _time < _blink_until and eyes != "closed":
		_show("eyes", "closed")
	_show("mouth", _mouth_frame())
	_head.rotation_degrees = _tilt
	scale.x = -1.0 if is_mirrored() else 1.0
	if rig.has("walk"):
		var walk: Dictionary = rig["walk"]
		var frames: Array = walk["frames"]
		_show(walk["part"], frames[stride] if stride >= 0 else String(walk["stand"]))


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
		_shown[part_id] = frame_id


func _rand_in(span: Array) -> float:
	return _rng.randf_range(float(span[0]), float(span[1]))


static func _vec(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))
