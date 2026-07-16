class_name Cultivating
extends RefCounted

# Seed/cultivate/harvest per R§3.4. Static funcs only.

const LEVEL_CAP := 5

# Verbatim from HTML generateLocationName().
const LOCATION_STREETS: Array[String] = [
	"Brick Lane", "Bethnal Green Rd", "Commercial St", "Whitechapel High St",
	"Mile End Rd", "Roman Rd", "Hackney Rd", "Cambridge Heath Rd", "Vallance Rd",
]
const LOCATION_SUFFIXES: Array[String] = [
	"near the off-licence", "behind the Tesco Metro", "under the railway arch",
	"in the car park", "by the bus stop", "beside the bookies",
]


static func generate_location_name() -> String:
	return "%s, %s" % [Rng.rand_from(LOCATION_STREETS), Rng.rand_from(LOCATION_SUFFIXES)]


static func get_cult_chance(skill: int) -> float:
	return min(0.90, 0.30 + (skill - 1) * 0.12)


static func get_bar_gain(skill: int) -> int:
	return 1 + skill


static func award_xp(amount: int) -> void:
	var player: Dictionary = GameState.state["player"]
	player["cultivatingXP"] = player["cultivatingXP"] + amount
	var max_level: int = GameData.CULTIVATING_XP_LEVELS.size() - 1
	while player["cultivatingSkill"] < max_level and player["cultivatingXP"] >= GameData.CULTIVATING_XP_LEVELS[player["cultivatingSkill"] + 1]:
		player["cultivatingSkill"] += 1
		Notify.push("Cultivating skill up — now level %d." % player["cultivatingSkill"])


static func seed(ore_type: String) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	var have: int = player["orichalchum"].get(ore_type, 0)
	if have < GameData.SEED_ORE_COST or TimeSystem.is_time_exhausted():
		return { "ok": false, "reason": "Not enough calc, or no blocks left today." }

	TimeSystem.advance_time_block()
	player["orichalchum"][ore_type] = have - GameData.SEED_ORE_COST

	var skill: int = player["cultivatingSkill"]
	var success: bool = Rng.chance(get_cult_chance(skill))

	if success:
		var vein := {
			"id": _make_vein_id(),
			"oreType": ore_type,
			"level": 1,
			"levelLabel": GameData.VEIN_LEVELS["1"]["label"],
			"devBar": get_bar_gain(skill),
			"charged": false,
			"chargeBlocks": 0,
			"security": "none",
			"location": generate_location_name(),
			"claimedOnDay": GameState.state["world"]["day"],
			"district": GameState.state["world"]["currentDistrict"],
			"hospitability": { "tier": "fair", "bonuses": [] },
		}
		player["veins"].append(vein)
		award_xp(30)
		EventBus.state_changed.emit()
		return { "ok": true, "success": true, "oreType": ore_type, "veinId": vein["id"] }
	else:
		award_xp(5)
		EventBus.state_changed.emit()
		return { "ok": true, "success": false, "oreType": ore_type }


static func cultivate(vein_id: String) -> Dictionary:
	if TimeSystem.is_time_exhausted():
		return { "ok": false, "reason": "No blocks left today." }
	var vein = _find_vein(vein_id)
	if vein == null:
		return { "ok": false, "reason": "Vein not found." }

	TimeSystem.advance_time_block()

	var player: Dictionary = GameState.state["player"]
	var skill: int = player["cultivatingSkill"]
	var success: bool = Rng.chance(get_cult_chance(skill))

	if success:
		var gain: int = get_bar_gain(skill)
		var level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]
		vein["devBar"] = vein["devBar"] + gain
		award_xp(20)
		var levelled_up: bool = vein["level"] < LEVEL_CAP and vein["devBar"] >= level_data["devBarMax"]
		if levelled_up:
			_level_up_vein(vein)
		EventBus.state_changed.emit()
		return { "ok": true, "success": true, "gain": gain, "veinId": vein_id, "levelledUp": levelled_up, "newLevel": vein["level"], "newLabel": vein["levelLabel"] }
	else:
		award_xp(8)
		EventBus.state_changed.emit()
		return { "ok": true, "success": false, "veinId": vein_id }


static func harvest_cautious(vein_id: String) -> Dictionary:
	if TimeSystem.is_time_exhausted():
		return { "ok": false, "reason": "No blocks left today." }
	var vein = _find_vein(vein_id)
	if vein == null or not vein["charged"]:
		return { "ok": false, "reason": "Vein isn't charged." }

	TimeSystem.advance_time_block()

	var level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]
	var yield_range: Array = level_data["yieldCautious"]
	var amount: int = Rng.randi_range(yield_range[0], yield_range[1])

	var player: Dictionary = GameState.state["player"]
	var ore_type: String = vein["oreType"]
	player["orichalchum"][ore_type] = player["orichalchum"].get(ore_type, 0) + amount

	vein["charged"] = false
	vein["chargeBlocks"] = 0

	EventBus.state_changed.emit()
	return { "ok": true, "amount": amount, "oreType": ore_type, "veinId": vein_id }


static func harvest_full(vein_id: String) -> Dictionary:
	if TimeSystem.is_time_exhausted():
		return { "ok": false, "reason": "No blocks left today." }
	var vein = _find_vein(vein_id)
	if vein == null or not vein["charged"]:
		return { "ok": false, "reason": "Vein isn't charged." }

	TimeSystem.advance_time_block()

	var level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]
	var yield_range: Array = level_data["yieldFull"]
	var amount: int = Rng.randi_range(yield_range[0], yield_range[1])

	var player: Dictionary = GameState.state["player"]
	var ore_type: String = vein["oreType"]
	player["orichalchum"][ore_type] = player["orichalchum"].get(ore_type, 0) + amount

	vein["charged"] = false
	vein["chargeBlocks"] = 0
	vein["devBar"] = vein["devBar"] - level_data["devBarHarvestCost"]

	var levelled_down := false
	if vein["devBar"] <= 0:
		levelled_down = true
		_level_down_vein(vein)

	EventBus.state_changed.emit()
	return { "ok": true, "amount": amount, "oreType": ore_type, "veinId": vein_id, "levelledDown": levelled_down }


# Called from time_system.gd's daily_tick, step ④.
static func recharge_veins() -> void:
	for vein in GameState.state["player"]["veins"]:
		var level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]
		var recharge_blocks: int = level_data["rechargeBlocks"]
		if vein["chargeBlocks"] < recharge_blocks:
			vein["chargeBlocks"] += 1
		if vein["chargeBlocks"] >= recharge_blocks:
			vein["charged"] = true
	EventBus.state_changed.emit()


static func _level_up_vein(vein: Dictionary) -> void:
	if vein["level"] >= LEVEL_CAP:
		return
	vein["level"] += 1
	vein["levelLabel"] = GameData.VEIN_LEVELS[str(vein["level"])]["label"]
	vein["devBar"] = 0


static func _level_down_vein(vein: Dictionary) -> void:
	var location_street: String = String(vein["location"]).split(",")[0]
	if vein["level"] <= 1:
		var player: Dictionary = GameState.state["player"]
		var ore_name: String = GameData.ORE_TYPES[vein["oreType"]]["name"]
		var vein_id: String = vein["id"]
		player["veins"] = player["veins"].filter(func(v): return v["id"] != vein_id)
		Notify.push("Your %s vein on %s collapsed and disappeared." % [ore_name, location_street])
	else:
		vein["level"] -= 1
		vein["levelLabel"] = GameData.VEIN_LEVELS[str(vein["level"])]["label"]
		var new_level_data: Dictionary = GameData.VEIN_LEVELS[str(vein["level"])]
		vein["devBar"] = int(floor(new_level_data["devBarMax"] * 0.8))
		Notify.push("A vein on %s dropped to level %d." % [location_street, vein["level"]])


static func _find_vein(vein_id: String) -> Variant:
	for vein in GameState.state["player"]["veins"]:
		if vein["id"] == vein_id:
			return vein
	return null


static func _make_vein_id() -> String:
	return "v" + str(Time.get_ticks_usec()) + str(Rng.randi_range(1000, 999999))
