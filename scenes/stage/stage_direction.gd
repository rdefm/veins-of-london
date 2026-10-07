class_name StageDirection
extends RefCounted

# Pure resolution of a stage's per-card direction (data/stages/<event_id>.json).
# A card's look at its start is the fold of every earlier card's steps, so any
# card -- after Rewind, a resume, or a fast tap -- renders without replaying
# history. Presentation only: nothing here reads or writes GameState.

# Snapshot shape:
# {"camera_x": float,
#  "actors": {id: {<rig attrs>, "facing": "left"|"right", "x": int, "visible": bool}},
#  "objects": {id: {"x": int}},
#  "props": [{"prop", "x", "y"}]}
static func initial(stage: Dictionary) -> Dictionary:
	var actors: Dictionary = {}
	for actor_id in stage["actors"]:
		var actor_def: Dictionary = stage["actors"][actor_id]
		var rig: Dictionary = GameData.STAGE_RIGS[actor_def["rig"]]
		var look: Dictionary = rig["defaults"].duplicate(true)
		look["facing"] = actor_def.get("facing", rig_faces(rig))
		look["x"] = roundi(float(actor_def["x"]))
		look["visible"] = not actor_def.get("hidden", false)
		actors[actor_id] = look
	var objects: Dictionary = {}
	var set_objects: Dictionary = GameData.STAGE_SETS[stage["set"]]["objects"]
	var overrides: Dictionary = stage.get("objects", {})
	for object_id in set_objects:
		var x: float = overrides.get(object_id, {}).get("x", set_objects[object_id]["x"])
		objects[object_id] = {"x": roundi(x)}
	return {"camera_x": float(stage["camera"]["x"]), "actors": actors, "objects": objects, "props": []}


# State at the start of card_index (before any of its own steps run).
static func resolve_start(stage: Dictionary, card_index: int) -> Dictionary:
	var snap := initial(stage)
	var cards: Array = stage["cards"]
	for i in range(mini(card_index, cards.size())):
		apply_card(stage, snap, cards[i])
	return snap


# State once every step of card_index has finished.
static func resolve_end(stage: Dictionary, card_index: int) -> Dictionary:
	var snap := resolve_start(stage, card_index)
	var cards: Array = stage["cards"]
	if card_index >= 0 and card_index < cards.size():
		apply_card(stage, snap, cards[card_index])
	return snap


static func apply_card(stage: Dictionary, snap: Dictionary, card: Dictionary) -> void:
	for step in sorted_steps(card):
		apply_step_end(stage, snap, step)


static func sorted_steps(card: Dictionary) -> Array:
	var steps: Array = card.get("steps", []).duplicate()
	steps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["t"]) < float(b["t"]))
	return steps


# The lasting effect of one step: sets and actions change attributes, a drop
# leaves its prop on the floor, a camera move leaves the camera there, a move
# leaves its actor/object at the target x, show/hide leave the actor so. Talk
# and throws leave nothing behind.
static func apply_step_end(stage: Dictionary, snap: Dictionary, step: Dictionary) -> void:
	if step.has("set"):
		apply_sets(snap, step["set"])
	elif step.has("play"):
		var target := split_target(step["play"])
		var rig := rig_for(stage, target[0])
		for action_step in rig["actions"][target[1]]:
			var prefixed: Dictionary = {}
			for attr in action_step["set"]:
				prefixed["%s.%s" % [target[0], attr]] = action_step["set"][attr]
			apply_sets(snap, prefixed)
	elif step.has("drop"):
		var drop: Dictionary = step["drop"]
		var look: Dictionary = snap["actors"][split_target(drop["from"])[0]]
		var landing := drop_landing(stage, drop, float(look["x"]), look["facing"])
		snap["props"].append({"prop": drop["prop"], "x": landing.x, "y": landing.y})
	elif step.has("camera"):
		snap["camera_x"] = float(step["camera"]["x"])
	elif step.has("move"):
		var move: Dictionary = step["move"]
		var group := "actors" if stage["actors"].has(move["target"]) else "objects"
		snap[group][move["target"]]["x"] = roundi(float(move["x"]))
	elif step.has("show"):
		snap["actors"][step["show"]]["visible"] = true
	elif step.has("hide"):
		snap["actors"][step["hide"]]["visible"] = false


static func apply_sets(snap: Dictionary, sets: Dictionary) -> void:
	for path in sets:
		var target := split_target(path)
		snap["actors"][target[0]][target[1]] = sets[path]


# "archie.mouth" -> ["archie", "mouth"]
static func split_target(path: String) -> PackedStringArray:
	var dot := path.find(".")
	return PackedStringArray([path.substr(0, dot), path.substr(dot + 1)])


static func rig_for(stage: Dictionary, actor_id: String) -> Dictionary:
	return GameData.STAGE_RIGS[stage["actors"][actor_id]["rig"]]


# The way a rig's art faces as drawn; the other facing mirrors it.
static func rig_faces(rig: Dictionary) -> String:
	return rig.get("faces", "right")


static func is_mirrored(rig: Dictionary, facing: String) -> bool:
	return facing != rig_faces(rig)


# A drop lands relative to the dropping actor's feet: land = [dx, dy], dx
# mirrored with the actor.
static func drop_landing(stage: Dictionary, drop: Dictionary, feet_x: float, facing: String) -> Vector2:
	var actor_id: String = split_target(drop["from"])[0]
	var floor_y: float = GameData.STAGE_SETS[stage["set"]]["floor_y"]
	var land: Array = drop["land"]
	var dx := float(land[0]) * (-1.0 if is_mirrored(rig_for(stage, actor_id), facing) else 1.0)
	return Vector2(feet_x + dx, floor_y + land[1])


# Eased travel for move steps: u in 0..1 -> 0..1.
static func ease_move(u: float) -> float:
	return smoothstep(0.0, 1.0, clampf(u, 0.0, 1.0))


# Seconds of mouth movement for a card's line: only the quoted speech counts
# (narration like "He tilts his head." stays silent), clamped by the rig.
static func talk_seconds(text: String, behaviour: Dictionary) -> float:
	var spoken := 0
	var inside := false
	var saw_quote := false
	for ch in text:
		if ch == "\"" or ch == "“" or ch == "”":
			inside = not inside
			saw_quote = true
		elif inside:
			spoken += 1
	if not saw_quote:
		spoken = text.length()
	return clampf(spoken * float(behaviour["talk_per_char"]), float(behaviour["talk_min"]), float(behaviour["talk_max"]))


# Integer pixel scale and low-res viewport size that cover frame_px exactly,
# keeping the design width as the minimum visible width.
static func viewport_fit(frame_px: Vector2, design_w: int) -> Dictionary:
	var scale := maxi(1, floori(frame_px.x / float(design_w)))
	var size := Vector2i(maxi(1, ceili(frame_px.x / scale)), maxi(1, ceili(frame_px.y / scale)))
	return {"scale": scale, "size": size}
