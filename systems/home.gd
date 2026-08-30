class_name Home
extends RefCounted

# Home tier/security/rooms/raid system per R§3.3. Static funcs only.
#
# M1-LONDON-T06: home.storedOre was merged into player.orichalchum — there is
# no deposit/withdraw mechanic anywhere, so a separate "stored" pool was
# always either empty or unreachable. Carried ore now IS what a raid is
# risking and losing; see systems/combat.gd's home-raid-loss code for the
# other mechanic this touches.


# 106-hq-raid-alarm-defend-flow: HQ's own "alarm" security id (data/home.json)
# -- a separate concept from Cultivating.ALARM_UPGRADE_ID (a per-vein upgrade,
# data/vein_alarm.json) that happens to share the same raw string. Named here
# the same way that constant is named, so the check reads as "the alarm id"
# rather than a magic literal, without implying the two are the same flag.
const ALARM_SECURITY_ID := "alarm"

# Unlike every other id in home["security"] (installed once, boolean
# membership via .has()), "guard" stacks with no upper limit -- its count
# lives on home["guardCount"] instead, so add_security() and
# get_home_raid_chance() both special-case this id.
const GUARD_SECURITY_ID := "guard"

# PROSE-REVIEW: new notification copy, drafted against CONTENT-GUIDE.md's tone
# bible (dry, administrative, one line) -- the HQ mirror of Raiding.
# _queue_defend_raid()'s own warning text.
const PENDING_RAID_WARNING := "Alarm's going off at HQ — someone's trying to get in. Get back there today to defend it."


static func get_home_raid_chance() -> float:
	var home: Dictionary = GameState.state["home"]
	var player: Dictionary = GameState.state["player"]
	var tier_data: Dictionary = GameData.HOME_TIERS[home["tier"]]
	var fx: Dictionary = Barometer.get_merged_effects()
	var raid_reduction := 0.0
	for security_id in home["security"]:
		raid_reduction += GameData.HOME_SECURITY[security_id]["raidReduction"]
	# Flat per-guard contribution, uncapped and non-escalating -- a guard
	# count of 1 reproduces the old single-guard raidReduction exactly.
	raid_reduction += GameData.HOME_SECURITY[GUARD_SECURITY_ID]["raidReduction"] * home.get("guardCount", 0)
	var total_stored: int = _sum_ore(player["orichalchum"])
	var chance: float = tier_data["raidBaseChance"] + fx.get("homeRaid", 0.0) - raid_reduction + total_stored * 0.001
	return max(0.002, chance)


# Called from time_system.gd's daily_tick, step ②. 106-hq-raid-alarm-defend-
# flow: runs the previous tick's still-pending alarm-defend raid first (a
# player who never tapped Defend loses it exactly as the no-alarm path
# would), then rolls today's fresh attempt -- same expire-then-roll order
# Raiding.apply_raid_resolution() uses for the vein-raid mirror of this flow.
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


# The pre-ticket-106 behaviour, factored out so both the no-alarm immediate
# path and the alarm path's missed-window fallback (_expire_pending_raid()
# below) share one implementation.
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


# ── 106-hq-raid-alarm-defend-flow: alarm-gated defend queue ─────────────
# With the Alarm System security upgrade installed, a successful daily raid
# attempt doesn't resolve here -- it queues a single pending flag and alerts
# the player, giving them the rest of the current day (until the next
# daily_tick -- no separate countdown system, same shape as vein-raiding
# ticket 07's own alarm-defend window) to tap Defend, from either the
# Notifications app or the HQ screen's own Actions card, and fight it out via
# the existing (previously tutorial-only) home-raid combat encounter.
static func _queue_pending_raid() -> void:
	var home: Dictionary = GameState.state["home"]
	home["pendingRaid"] = true
	var notification := Notify.push(PENDING_RAID_WARNING, Notify.CATEGORY_WARNING, { "homeRaid": true })
	home["pendingRaidNotificationId"] = notification["id"]


# Resolves a still-pending raid via _apply_raid_loss() -- ticket 108 will
# layer a guard-based chance to avoid this; for now a missed window is
# always a loss, same as the no-alarm path always was.
static func _expire_pending_raid() -> void:
	var home: Dictionary = GameState.state["home"]
	if not home["pendingRaid"]:
		return
	home["pendingRaid"] = false
	home["pendingRaidNotificationId"] = null
	_apply_raid_loss()


# Is HQ's own currently-pending raid the one notification_id's entry warned
# about? Same notification-id scoping Raiding.is_defend_notification_pending()
# uses for the vein-raid Defend button -- the Notifications log is capped, not
# cleared, so an old already-resolved HQ-raid warning could otherwise
# reactivate its Defend button once HQ is raided again later.
static func is_pending_raid_notification(notification_id: String) -> bool:
	var home: Dictionary = GameState.state["home"]
	return home["pendingRaid"] and home["pendingRaidNotificationId"] == notification_id


static func has_pending_raid() -> bool:
	return GameState.state["home"]["pendingRaid"]


# Pops the pending flag and starts the existing home-raid combat encounter.
# Called from wherever the player taps Defend (the raid-warning notification,
# or the HQ screen's Actions card) -- both re-check has_pending_raid()/
# is_pending_raid_notification() before rendering the button, but this
# re-checks the flag itself too, the same defensive shape Raiding.
# trigger_defend() uses, in case the window closed between render and tap.
static func trigger_defend() -> bool:
	var home: Dictionary = GameState.state["home"]
	if not home["pendingRaid"]:
		return false
	home["pendingRaid"] = false
	home["pendingRaidNotificationId"] = null
	Combat.start_home_raid_combat()
	return true


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

	# "guard" never goes in the array (see GUARD_SECURITY_ID above), so it
	# has nothing to block on here -- it's always allowed past the
	# minTier/cash checks below.
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
		# PROSE-REVIEW: new notification copy, drafted against CONTENT-
		# GUIDE.md's tone bible.
		var guard_msg: String = "Hired a guard for HQ." if guard_count == 1 else "Hired another guard for HQ — %d guards on watch now." % guard_count
		Notify.push(guard_msg, Notify.CATEGORY_SUCCESS)
	else:
		home["security"].append(security_id)
		Notify.push("Installed %s." % security_data["name"], Notify.CATEGORY_SUCCESS)

	EventBus.state_changed.emit()
	SaveManager.autosave()  # R§6: autosave on purchase
	return { "ok": true }


# Single source of truth for HQ's guard count -- old saves without the key
# read as 0, same convention vein.get("extraGuards", 0) uses.
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
