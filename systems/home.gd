class_name Home
extends RefCounted

# Home tier/security/rooms/raid system per R§3.3. Static funcs only.
#
# M1-LONDON-T06: home.storedOre was merged into player.orichalchum — there is
# no deposit/withdraw mechanic anywhere, so a separate "stored" pool was
# always either empty or unreachable. Carried ore now IS what a raid is
# risking and losing; see systems/combat.gd's home-raid-loss code for the
# other mechanic this touches.


static func get_home_raid_chance() -> float:
	var home: Dictionary = GameState.state["home"]
	var player: Dictionary = GameState.state["player"]
	var tier_data: Dictionary = GameData.HOME_TIERS[home["tier"]]
	var fx: Dictionary = Barometer.get_merged_effects()
	var raid_reduction := 0.0
	for security_id in home["security"]:
		raid_reduction += GameData.HOME_SECURITY[security_id]["raidReduction"]
	var total_stored: int = _sum_ore(player["orichalchum"])
	var chance: float = tier_data["raidBaseChance"] + fx.get("homeRaid", 0.0) - raid_reduction + total_stored * 0.001
	return max(0.002, chance)


# Called from time_system.gd's daily_tick, step ②.
static func roll_daily_raid() -> void:
	var home: Dictionary = GameState.state["home"]
	var player: Dictionary = GameState.state["player"]
	var day: int = GameState.state["world"]["day"]

	if day - home["lastRaidDay"] < 3:
		return
	if not Rng.chance(get_home_raid_chance()):
		return

	home["lastRaidDay"] = day

	var stored: Dictionary = player["orichalchum"]
	var total: int = _sum_ore(stored)
	if total <= 0:
		return

	var ratio: float = 0.25 if _has_room("safeRoom") else 0.50
	var lost: Dictionary = {}
	for ore_type in stored.keys():
		var qty: int = stored[ore_type]
		var lose: int = int(floor(qty * ratio))
		if lose > 0:
			stored[ore_type] = qty - lose
			lost[ore_type] = lose

	var parts: Array[String] = []
	for ore_type in lost.keys():
		parts.append("%d %s" % [lost[ore_type], ore_type])
	var summary: String = ", ".join(parts) if not parts.is_empty() else "nothing"
	Notify.push("Home raided. Lost %s." % summary, Notify.CATEGORY_DANGER)
	EventBus.state_changed.emit()


static func upgrade_tier() -> Dictionary:
	var home: Dictionary = GameState.state["home"]
	var player: Dictionary = GameState.state["player"]
	var order: Array = GameData.HOME_TIER_ORDER

	var current_index: int = order.find(home["tier"])
	if current_index == -1 or current_index >= order.size() - 1:
		return { "ok": false, "reason": "Already at the top tier." }

	var next_tier_id: String = order[current_index + 1]
	var next_tier: Dictionary = GameData.HOME_TIERS[next_tier_id]
	var cost: int = next_tier["upgradeCost"]
	if player["cash"] < cost:
		return { "ok": false, "reason": "Not enough cash." }

	player["cash"] -= cost
	Bank.record(-cost, "HQ upgrade: %s" % next_tier["name"])
	home["tier"] = next_tier_id
	Notify.push("Moved up to %s." % next_tier["name"], Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true }


static func add_security(security_id: String) -> Dictionary:
	var home: Dictionary = GameState.state["home"]
	var player: Dictionary = GameState.state["player"]

	if home["security"].has(security_id):
		return { "ok": false, "reason": "Already installed." }

	var security_data: Dictionary = GameData.HOME_SECURITY[security_id]
	var order: Array = GameData.HOME_TIER_ORDER
	var current_index: int = order.find(home["tier"])
	var min_index: int = order.find(security_data["minTier"])
	if current_index < min_index:
		return { "ok": false, "reason": "Requires %s or better." % GameData.HOME_TIERS[security_data["minTier"]]["name"] }

	var cost: int = security_data["cost"]
	if GameState.state["flags"]["securityContactUnlocked"]:
		cost = GameState.round_epsilon(cost * 0.7)

	if player["cash"] < cost:
		return { "ok": false, "reason": "Not enough cash." }

	player["cash"] -= cost
	Bank.record(-cost, "HQ security: %s" % security_data["name"])
	home["security"].append(security_id)
	Notify.push("Installed %s." % security_data["name"], Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true }


static func add_room(room_id: String) -> Dictionary:
	var home: Dictionary = GameState.state["home"]
	var player: Dictionary = GameState.state["player"]

	if home["rooms"].has(room_id):
		return { "ok": false, "reason": "Already built." }

	var tier_data: Dictionary = GameData.HOME_TIERS[home["tier"]]
	if home["rooms"].size() >= tier_data["maxRooms"]:
		return { "ok": false, "reason": "No room slots free." }

	var room_data: Dictionary = GameData.HOME_ROOMS[room_id]
	var order: Array = GameData.HOME_TIER_ORDER
	var current_index: int = order.find(home["tier"])
	var min_index: int = order.find(room_data["minTier"])
	if current_index < min_index:
		return { "ok": false, "reason": "Requires %s or better." % GameData.HOME_TIERS[room_data["minTier"]]["name"] }

	var cost: int = room_data["cost"]
	if player["cash"] < cost:
		return { "ok": false, "reason": "Not enough cash." }

	player["cash"] -= cost
	Bank.record(-cost, "HQ room: %s" % room_data["name"])
	home["rooms"].append(room_id)

	if room_data["bonus"] == "body":
		var bonus_value: int = room_data["bonusValue"]
		player["hpMax"] += bonus_value
		player["hp"] = mini(player["hp"] + bonus_value, player["hpMax"])

	Notify.push("Built %s." % room_data["name"], Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true }


static func get_workshop_bonus() -> float:
	var home: Dictionary = GameState.state["home"]
	var bonus := 0.0
	for room_id in home["rooms"]:
		var room_data: Dictionary = GameData.HOME_ROOMS[room_id]
		if room_data["bonus"] == "crafting":
			bonus += room_data["bonusValue"]
	return bonus


static func _has_room(room_id: String) -> bool:
	return GameState.state["home"]["rooms"].has(room_id)


static func _sum_ore(ore_dict: Dictionary) -> int:
	var total := 0
	for qty in ore_dict.values():
		total += qty
	return total
