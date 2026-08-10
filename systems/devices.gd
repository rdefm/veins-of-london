class_name Devices
extends RefCounted

# Device build/activation per R§3.5. Static funcs only. Not time-block
# gated, same as crafting.


static func get_device_calc_cost(device_key: String, skill: int) -> int:
	var dt: Dictionary = GameData.DEVICES[device_key]
	return Crafting.calc_cost(dt["recipeKey"], skill) * 2


static func can_build_device(device_key: String) -> bool:
	var dt: Dictionary = GameData.DEVICES[device_key]
	var skill: int = GameState.state["player"]["craftingSkill"]
	var cost: int = get_device_calc_cost(device_key, skill)
	var have: int = GameState.state["player"]["orichalchum"].get(dt["calcType"], 0)
	return have >= cost


static func start_device(device_key: String) -> Dictionary:
	if not GameData.DEVICES.has(device_key):
		return { "ok": false, "reason": "Unknown device." }
	var instance := {
		"id": _make_device_id(),
		"type": device_key,
		"progress": 10.0,
	}
	GameState.state["player"]["devicesInProgress"].append(instance)
	EventBus.state_changed.emit()
	return { "ok": true, "id": instance["id"] }


static func attempt_device_build(device_id: String) -> Dictionary:
	var device = _find_in_progress_device(device_id)
	if device == null:
		return { "ok": false, "reason": "Device not found." }

	var player: Dictionary = GameState.state["player"]
	var dt: Dictionary = GameData.DEVICES[device["type"]]
	var skill: int = player["craftingSkill"]
	var cost: int = get_device_calc_cost(device["type"], skill)
	var have: int = player["orichalchum"].get(dt["calcType"], 0)
	if have < cost:
		return { "ok": false, "reason": "Not enough calc." }

	player["orichalchum"][dt["calcType"]] = have - cost

	var recipe: Dictionary = GameData.RECIPES[dt["recipeKey"]]
	Crafting.award_crafting_xp(int(floor(float(recipe["xpReward"]) / 2.0)))

	var success: bool = Rng.chance(Crafting.craft_chance(dt["recipeKey"], skill))
	if success:
		device["progress"] = min(100.0, device["progress"] + 5.0)
		if device["progress"] >= 100.0:
			_complete_device(device)
			return { "ok": true, "success": true, "completed": true, "broken": false }
	else:
		device["progress"] = max(0.0, device["progress"] - 2.5)
		if device["progress"] <= 0.0:
			_break_device(device["id"])
			return { "ok": true, "success": false, "completed": false, "broken": true }

	EventBus.state_changed.emit()
	return { "ok": true, "success": success, "completed": false, "broken": false }


static func abandon_device(device_id: String) -> void:
	var player: Dictionary = GameState.state["player"]
	player["devicesInProgress"] = player["devicesInProgress"].filter(func(d): return d["id"] != device_id)
	EventBus.state_changed.emit()


static func equip_device(device_id: String) -> void:
	GameState.state["player"]["equipment"]["device"] = device_id
	EventBus.state_changed.emit()


static func unequip_device() -> void:
	GameState.state["player"]["equipment"]["device"] = null
	EventBus.state_changed.emit()


# Charges consumed, +10 device XP, level-up (per DEVICE_XP_LEVELS) grants
# +1 chargesPerDay. Called by combat.gd (T08) before it applies the
# device's actual effect (freeze/motion/rewind) to combat state.
static func activate(device_id: String) -> Dictionary:
	var device = _find_completed_device(device_id)
	if device == null:
		return { "ok": false, "reason": "Device not found." }
	if device["chargesUsedToday"] >= device["chargesPerDay"]:
		return { "ok": false, "reason": "No charges left today." }

	device["chargesUsedToday"] += 1
	var on_level_up := func():
		device["chargesPerDay"] += 1
		var dt: Dictionary = GameData.DEVICES[device["type"]]
		Notify.push("%s levelled up — now %d charges per day." % [dt["name"], device["chargesPerDay"]])
	Progression.award_xp(device, "xp", "level", GameData.DEVICE_XP_LEVELS, 10, on_level_up)

	EventBus.state_changed.emit()
	return { "ok": true, "type": device["type"] }


# Called from time_system.gd's daily_tick, step ⑦.
static func reset_daily_charges() -> void:
	var day: int = GameState.state["world"]["day"]
	for device in GameState.state["player"]["devicesCompleted"]:
		if device["lastResetDay"] < day:
			device["chargesUsedToday"] = 0
			device["lastResetDay"] = day
	EventBus.state_changed.emit()


static func _complete_device(device: Dictionary) -> void:
	var player: Dictionary = GameState.state["player"]
	var device_id: String = device["id"]
	player["devicesInProgress"] = player["devicesInProgress"].filter(func(d): return d["id"] != device_id)
	var completed := {
		"id": device_id,
		"type": device["type"],
		"level": 1,
		"xp": 0,
		"chargesPerDay": 1,
		"chargesUsedToday": 0,
		"lastResetDay": GameState.state["world"]["day"],
	}
	player["devicesCompleted"].append(completed)
	var dt: Dictionary = GameData.DEVICES[device["type"]]
	Notify.push("%s complete. Check your equipment." % dt["name"])
	EventBus.state_changed.emit()


static func _break_device(device_id: String) -> void:
	var player: Dictionary = GameState.state["player"]
	player["devicesInProgress"] = player["devicesInProgress"].filter(func(d): return d["id"] != device_id)
	Notify.push("Device collapsed. The calc dispersed. You'll need to start again.")
	EventBus.state_changed.emit()


static func _find_in_progress_device(device_id: String) -> Variant:
	for d in GameState.state["player"]["devicesInProgress"]:
		if d["id"] == device_id:
			return d
	return null


static func _find_completed_device(device_id: String) -> Variant:
	for d in GameState.state["player"]["devicesCompleted"]:
		if d["id"] == device_id:
			return d
	return null


static func _make_device_id() -> String:
	return "dev_" + str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))
