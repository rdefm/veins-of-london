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
const TENURE_RENTED := "rented"
const TENURE_OWNED := "owned"

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
	Combat.start_home_alarm_defend_combat()
	return true


# Called by Combat's home_alarm_defend exit: a win costs nothing, anything
# else resolves exactly as an undefended raid.
static func resolve_defend_outcome(won: bool) -> void:
	if won:
		return
	_apply_raid_loss()


# Owned-home utilities per ADR 0006: utilitiesBase + round(utilitiesFraction × dailyCost).
static func utilities_for_tier(tier_id: String) -> int:
	var bills: Dictionary = GameData.HOME_BILLS
	var daily_cost: float = GameData.HOME_TIERS[tier_id]["dailyCost"]
	return int(bills["utilitiesBase"]) + GameState.round_epsilon(bills["utilitiesFraction"] * daily_cost)


# Pre-barometer daily bill: the tier's rent if rented, its utilities if owned.
static func bill_base_for(tier_id: String, tenure: String) -> int:
	if tenure == TENURE_OWNED:
		return utilities_for_tier(tier_id)
	return int(GameData.HOME_TIERS[tier_id]["dailyCost"])


static func current_bill_base() -> int:
	var home: Dictionary = GameState.state["home"]
	return bill_base_for(home["tier"], home["tenure"])


# Rollovers left before each arrears consequence (ADR 0006 "Daily ordering"),
# read from live state. Empty when not in arrears. "interestInDays" is absent
# once interest already compounds; "downgradeInDays" is absent at the bedsit.
static func arrears_countdown() -> Dictionary:
	var home: Dictionary = GameState.state["home"]
	if home["arrears"] <= 0:
		return {}
	var bills: Dictionary = GameData.HOME_BILLS
	var days: int = home["arrearsDays"]
	var result := { "arrears": home["arrears"], "tier": home["tier"] }
	var interest_threshold := int(bills["interestThresholdDays"])
	# Interest applies at a rollover that starts with arrearsDays ≥ threshold.
	if days < interest_threshold:
		result["interestInDays"] = interest_threshold + 1 - days
	# The downgrade fires at the rollover that brings arrearsDays to its threshold.
	if get_prev_tier_id(home["tier"]) != "":
		result["downgradeInDays"] = int(bills["downgradeThresholdDays"]) - days
	return result


# Returns the next tier up the ladder, "" at the top tier.
static func get_next_tier_id(tier_id: String) -> String:
	var order: Array = GameData.HOME_TIER_ORDER
	var index: int = order.find(tier_id)
	if index == -1 or index >= order.size() - 1:
		return ""
	return order[index + 1]


# Returns the next tier down the ladder, "" at the bedsit.
static func get_prev_tier_id(tier_id: String) -> String:
	var order: Array = GameData.HOME_TIER_ORDER
	var index: int = order.find(tier_id)
	if index <= 0:
		return ""
	return order[index - 1]


static func can_buy_tier(tier_id: String) -> bool:
	return not GameData.HOME_TIERS[tier_id]["rentOnly"]


static func buy_price(tier_id: String) -> int:
	return int(GameData.HOME_TIERS[tier_id]["buyPrice"])


# Shared tier move (ADR 0006): every installed room is wiped with no refund
# (staff unassigned, gym bonus reverted with hp clamped), security whose
# minTier is above the new tier is lost (guards follow the "guard" row), and
# the tenure is set. No cash moves here — callers charge first. Returns
# { roomsLost: Array, securityLost: Array, guardsLost: int }.
static func change_tier(new_tier_id: String, tenure: String) -> Dictionary:
	var home: Dictionary = GameState.state["home"]
	var rooms_lost: Array = home["rooms"].duplicate()
	for room_id in rooms_lost:
		_remove_room_effects(room_id)
	home["rooms"] = []

	var security_lost: Array = security_lost_moving_to(new_tier_id)
	for security_id in security_lost:
		home["security"].erase(security_id)
	var guards_lost: int = guards_lost_moving_to(new_tier_id)
	if guards_lost > 0:
		home["guardCount"] = 0

	home["tier"] = new_tier_id
	home["tenure"] = tenure
	EventBus.state_changed.emit()
	return { "roomsLost": rooms_lost, "securityLost": security_lost, "guardsLost": guards_lost }


# Installed security ids (not guards; see guards_lost_moving_to) a move to
# tier_id would lose because their minTier is above it.
static func security_lost_moving_to(tier_id: String) -> Array:
	var lost: Array = []
	for security_id in GameState.state["home"]["security"]:
		if _tier_below_min(tier_id, GameData.HOME_SECURITY[security_id]["minTier"]):
			lost.append(security_id)
	return lost


static func guards_lost_moving_to(tier_id: String) -> int:
	if _tier_below_min(tier_id, GameData.HOME_SECURITY[GUARD_SECURITY_ID]["minTier"]):
		return get_guard_count()
	return 0


static func _tier_below_min(tier_id: String, min_tier_id: String) -> bool:
	var order: Array = GameData.HOME_TIER_ORDER
	return order.find(tier_id) < order.find(min_tier_id)


# PROSE-REVIEW: tier-move notifications and refusal reasons below.
static func rent_up() -> Dictionary:
	var next_tier_id: String = get_next_tier_id(GameState.state["home"]["tier"])
	if next_tier_id == "":
		return { "ok": false, "reason": "Already at the top tier." }
	change_tier(next_tier_id, TENURE_RENTED)
	Notify.push("Signed the lease on the %s." % GameData.HOME_TIERS[next_tier_id]["name"], Notify.CATEGORY_SUCCESS)
	SaveManager.autosave()
	return { "ok": true }


static func buy_up() -> Dictionary:
	var next_tier_id: String = get_next_tier_id(GameState.state["home"]["tier"])
	if next_tier_id == "":
		return { "ok": false, "reason": "Already at the top tier." }
	return _buy_move(next_tier_id)


# Buys the currently rented tier outright; tier, rooms and staff are unchanged.
static func buy_out() -> Dictionary:
	var home: Dictionary = GameState.state["home"]
	var tier_id: String = home["tier"]
	if not can_buy_tier(tier_id):
		return { "ok": false, "reason": "This place can't be bought." }
	if home["tenure"] == TENURE_OWNED:
		return { "ok": false, "reason": "Already yours." }
	var price: int = buy_price(tier_id)
	var player: Dictionary = GameState.state["player"]
	if player["cash"] < price:
		return { "ok": false, "reason": "Not enough cash." }
	player["cash"] -= price
	Bank.record(-price, "HQ buy-out: %s" % GameData.HOME_TIERS[tier_id]["name"])
	home["tenure"] = TENURE_OWNED
	Notify.push("Bought out the %s. No more rent." % GameData.HOME_TIERS[tier_id]["name"], Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true }


# Voluntary one-tier move down, rented or bought (buying refused at the bedsit).
static func downgrade(tenure: String) -> Dictionary:
	var prev_tier_id: String = get_prev_tier_id(GameState.state["home"]["tier"])
	if prev_tier_id == "":
		return { "ok": false, "reason": "Nowhere lower to go." }
	if tenure == TENURE_OWNED:
		if not can_buy_tier(prev_tier_id):
			return { "ok": false, "reason": "This place can't be bought." }
		return _buy_move(prev_tier_id)
	change_tier(prev_tier_id, TENURE_RENTED)
	Notify.push("Moved down to a rented %s." % GameData.HOME_TIERS[prev_tier_id]["name"], Notify.CATEGORY_SUCCESS)
	SaveManager.autosave()
	return { "ok": true }


static func _buy_move(tier_id: String) -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	var tier: Dictionary = GameData.HOME_TIERS[tier_id]
	var price: int = buy_price(tier_id)
	if player["cash"] < price:
		return { "ok": false, "reason": "Not enough cash." }
	player["cash"] -= price
	Bank.record(-price, "HQ purchase: %s" % tier["name"])
	change_tier(tier_id, TENURE_OWNED)
	Notify.push("Bought the %s. The keys are yours." % tier["name"], Notify.CATEGORY_SUCCESS)
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


# Fills the next empty selectable slot (home.rooms is in slot order, R§2).
static func add_room(room_id: String) -> Dictionary:
	return set_room_use(GameState.state["home"]["rooms"].size(), room_id)


# Selectable slot count for the current tier; the fixed bedroom is not a slot.
static func get_room_slot_count() -> int:
	return GameData.HOME_TIERS[GameState.state["home"]["tier"]]["maxRooms"]


# Room id occupying selectable slot `slot`, or "" when that slot is empty.
static func get_room_in_slot(slot: int) -> String:
	var rooms: Array = GameState.state["home"]["rooms"]
	return rooms[slot] if slot >= 0 and slot < rooms.size() else ""


# "" when set_room_use(slot, room_id) would succeed, else the reason it's
# blocked. Checked in full before set_room_use mutates anything (R§3.3).
static func room_use_block_reason(slot: int, room_id: String) -> String:
	var home: Dictionary = GameState.state["home"]
	var rooms: Array = home["rooms"]

	if home["rooms"].has(room_id):
		return "Already built."
	if slot < 0 or slot > rooms.size() or slot >= get_room_slot_count():
		return "No room slots free."

	var room_data: Dictionary = GameData.HOME_ROOMS[room_id]
	var order: Array = GameData.HOME_TIER_ORDER
	if order.find(home["tier"]) < order.find(room_data["minTier"]):
		return "Requires %s or better." % GameData.HOME_TIERS[room_data["minTier"]]["name"]

	if GameState.state["player"]["cash"] < room_data["cost"]:
		return "Not enough cash."
	return ""


# Buys room_id into selectable slot `slot` at full price. An occupied slot's
# previous use ends with no refund: its effects stop and any contact
# staffing it is unassigned (R§3.3).
static func set_room_use(slot: int, room_id: String) -> Dictionary:
	var reason := room_use_block_reason(slot, room_id)
	if reason != "":
		return { "ok": false, "reason": reason }

	var home: Dictionary = GameState.state["home"]
	var player: Dictionary = GameState.state["player"]
	var room_data: Dictionary = GameData.HOME_ROOMS[room_id]
	var cost: int = room_data["cost"]
	var old_id: String = get_room_in_slot(slot)

	player["cash"] -= cost
	Bank.record(-cost, "HQ room: %s" % room_data["name"])

	if old_id != "":
		_remove_room_effects(old_id)
		home["rooms"][slot] = room_id
	else:
		home["rooms"].append(room_id)

	if room_data["bonus"] == "body":
		var bonus_value: int = room_data["bonusValue"]
		player["hpMax"] += bonus_value
		player["hp"] = mini(player["hp"] + bonus_value, player["hpMax"])

	if old_id != "":
		Notify.push("Replaced %s with %s." % [GameData.HOME_ROOMS[old_id]["name"], room_data["name"]], Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Built %s." % room_data["name"], Notify.CATEGORY_SUCCESS)
	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true }


# Reverses the one-time build effects of a room leaving its slot. Crafting
# and storage bonuses are read live from home.rooms, so they end on their own.
static func _remove_room_effects(room_id: String) -> void:
	var player: Dictionary = GameState.state["player"]
	var room_data: Dictionary = GameData.HOME_ROOMS[room_id]
	if room_data["bonus"] == "body":
		player["hpMax"] -= int(room_data["bonusValue"])
		player["hp"] = mini(player["hp"], player["hpMax"])
	Contacts.assign_to_room("none", room_id)


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
