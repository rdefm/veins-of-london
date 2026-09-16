class_name Home
extends RefCounted

# Home tier/security/rooms/raid system per R§3.3. Static funcs only.
#
# Carried ore (player.orichalchum) is what a home raid risks losing; see
# combat.gd's home-raid-loss handling.


# HQ's own "alarm" security id (data/home.json) -- distinct from Cultivating.
# ALARM_UPGRADE_ID (per-vein, data/vein_alarm.json), which shares the string.
const ALARM_SECURITY_ID := "alarm"

# Unlike other security ids (installed once, boolean membership via .has()),
# "guard" stacks; its count lives in home["guardCount"] instead.
const GUARD_SECURITY_ID := "guard"

# PROSE-REVIEW: drafted against CONTENT-GUIDE.md's tone (dry, administrative,
# one line).
const PENDING_RAID_WARNING := "Alarm's going off at HQ — someone's trying to get in. Get back there today to defend it."


static func get_home_raid_chance() -> float:
	return get_raid_chance_for_tier(GameState.state["home"]["tier"])


# Split out from get_home_raid_chance() so the Phone tab can preview a tier
# the player hasn't moved into yet.
static func get_raid_chance_for_tier(tier_id: String) -> float:
	var home: Dictionary = GameState.state["home"]
	var player: Dictionary = GameState.state["player"]
	var tier_data: Dictionary = GameData.HOME_TIERS[tier_id]
	var fx: Dictionary = Barometer.get_merged_effects()
	var raid_reduction := 0.0
	for security_id in home["security"]:
		raid_reduction += GameData.HOME_SECURITY[security_id]["raidReduction"]
	# Flat per-guard contribution, uncapped and non-escalating.
	raid_reduction += GameData.HOME_SECURITY[GUARD_SECURITY_ID]["raidReduction"] * home.get("guardCount", 0)
	var total_stored: int = _sum_ore(player["orichalchum"])
	var chance: float = tier_data["raidBaseChance"] + fx.get("homeRaid", 0.0) - raid_reduction + total_stored * 0.001
	return max(0.002, chance)


# Called from time_system.gd's daily_tick. Resolves any still-pending
# alarm-defend raid before rolling a fresh attempt.
static func roll_daily_raid() -> void:
	var home: Dictionary = GameState.state["home"]
	var day: int = GameState.state["world"]["day"]

	_expire_pending_raid()

	if day - home["lastRaidDay"] < 3:
		return
	if not Rng.chance(get_home_raid_chance()):
		return

	home["lastRaidDay"] = day

	if home["security"].has(ALARM_SECURITY_ID):
		_queue_pending_raid()
	else:
		_apply_raid_loss()


# Shared by the no-alarm immediate path and the alarm path's missed-window
# fallback (_expire_pending_raid() below).
static func _apply_raid_loss() -> void:
	var player: Dictionary = GameState.state["player"]
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


# With Alarm System installed, a raid queues a pending flag instead of
# resolving immediately; the player has until next daily_tick to Defend.
static func _queue_pending_raid() -> void:
	var home: Dictionary = GameState.state["home"]
	home["pendingRaid"] = true
	var notification := Notify.push(PENDING_RAID_WARNING, Notify.CATEGORY_WARNING, { "homeRaid": true })
	home["pendingRaidNotificationId"] = notification["id"]


# Before a missed-defend window applies raid loss, guardCount gets a chance
# to repel it (rates shared with Raiding.guard_repel_chance()).
static func guard_repel_chance(guard_count: int) -> float:
	return clampf(guard_count * GameData.GUARD_REPEL_CHANCE_PER_GUARD, 0.0, GameData.GUARD_REPEL_CHANCE_CAP)


# On success, pushes a "held without you" notification distinct from a
# player-defended win (silent) and _apply_raid_loss()'s loss line.
#
# PROSE-REVIEW: drafted against CONTENT-GUIDE.md's tone.
static func _guards_repel_pending_raid() -> bool:
	var guard_count: int = get_guard_count()
	if guard_count <= 0:
		return false
	if not Rng.chance(guard_repel_chance(guard_count)):
		return false
	Notify.push("Your guards caught them at HQ and saw them off before you got back. Nothing lost.", Notify.CATEGORY_SUCCESS)
	return true


# Resolves a still-pending raid unless the guard-repel roll above intercepts it.
static func _expire_pending_raid() -> void:
	var home: Dictionary = GameState.state["home"]
	if not home["pendingRaid"]:
		return
	home["pendingRaid"] = false
	home["pendingRaidNotificationId"] = null
	if _guards_repel_pending_raid():
		return
	_apply_raid_loss()


# Scopes to HQ's currently-pending raid so a stale warning can't reactivate
# Defend once HQ is raided again.
static func is_pending_raid_notification(notification_id: String) -> bool:
	var home: Dictionary = GameState.state["home"]
	return home["pendingRaid"] and home["pendingRaidNotificationId"] == notification_id


static func has_pending_raid() -> bool:
	return GameState.state["home"]["pendingRaid"]


# Re-checks the pending flag in case the window closed between render and tap.
static func trigger_defend() -> bool:
	var home: Dictionary = GameState.state["home"]
	if not home["pendingRaid"]:
		return false
	home["pendingRaid"] = false
	home["pendingRaidNotificationId"] = null
	Combat.start_home_raid_combat()
	return true


# Returns the next tier up the ladder, "" at the top tier.
static func get_next_tier_id(tier_id: String) -> String:
	var order: Array = GameData.HOME_TIER_ORDER
	var index: int = order.find(tier_id)
	if index == -1 or index >= order.size() - 1:
		return ""
	return order[index + 1]


static func upgrade_tier() -> Dictionary:
	var home: Dictionary = GameState.state["home"]
	var player: Dictionary = GameState.state["player"]

	var next_tier_id: String = get_next_tier_id(home["tier"])
	if next_tier_id == "":
		return { "ok": false, "reason": "Already at the top tier." }

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

	# "guard" never enters the array (see GUARD_SECURITY_ID above), so it
	# skips the minTier/cash checks below.
	if security_id != GUARD_SECURITY_ID and home["security"].has(security_id):
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

	if security_id == GUARD_SECURITY_ID:
		home["guardCount"] = home.get("guardCount", 0) + 1
		var guard_count: int = home["guardCount"]
		# PROSE-REVIEW: drafted against CONTENT-GUIDE.md's tone.
		var guard_msg: String = "Hired a guard for HQ." if guard_count == 1 else "Hired another guard for HQ — %d guards on watch now." % guard_count
		Notify.push(guard_msg, Notify.CATEGORY_SUCCESS)
	else:
		home["security"].append(security_id)
		Notify.push("Installed %s." % security_data["name"], Notify.CATEGORY_SUCCESS)

	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true }


# Saves without this key read as 0 (same convention as vein.get("extraGuards", 0)).
static func get_guard_count() -> int:
	return GameState.state["home"].get("guardCount", 0)


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
