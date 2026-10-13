class_name Warmonger
extends RefCounted

# Warmonger meter (R§3.1e): the player's violent hostile acts (raids, stockpile
# raids) sum over a rolling window. At coalitionAt every faction's Threat toward
# the player gains a flat term and factions not at war with the player drift
# friendlier with each other daily; at coordinateAt factions pool intel on the
# player and same-day raids on the player get a joint-raid odds bonus.
# Non-violent moves never log. Data: constants.json warmonger.
# state.warmonger = { score, log: [ { day, act, weight } ] }

const ACT_RAID_CLAIM := "raidClaim"
const ACT_RAID_LOOT := "raidLoot"
const ACT_STOCKPILE_RAID := "stockpileRaid"


static func _cfg() -> Dictionary:
	return GameData.WARMONGER


static func new_state() -> Dictionary:
	return { "score": 0.0, "log": [] }


static func _day() -> int:
	return int(GameState.state["world"]["day"])


static func score() -> float:
	return float(GameState.state["warmonger"]["score"])


static func _recompute() -> void:
	var state: Dictionary = GameState.state["warmonger"]
	var total := 0.0
	for entry in state["log"]:
		total += float(entry["weight"])
	state["score"] = total


# Logs one violent act at its configured weight.
static func record(act: String) -> void:
	var state: Dictionary = GameState.state["warmonger"]
	state["log"].append({ "day": _day(), "act": act, "weight": float(_cfg()["weights"][act]) })
	_recompute()
	EventBus.state_changed.emit()


static func coalition_active() -> bool:
	return score() >= float(_cfg()["coalitionAt"])


static func coordinating() -> bool:
	return score() >= float(_cfg()["coordinateAt"])


# Extra Threat toward the player from every faction while the coalition holds.
static func pressure() -> float:
	return float(_cfg()["coalitionThreat"]) if coalition_active() else 0.0


# Odds bonus on a raid against the player when two or more factions raid on the
# same day while the factions coordinate.
static func joint_raid_bonus(distinct_attackers: int) -> float:
	if not coordinating() or distinct_attackers < 2:
		return 0.0
	return float(_cfg()["jointRaidOddsBonus"])


# Daily step: acts older than windowDays drop; then coalition drift and
# coordinated intel sharing.
static func daily_tick() -> void:
	var state: Dictionary = GameState.state["warmonger"]
	var day := _day()
	var window := int(_cfg()["windowDays"])
	state["log"] = state["log"].filter(func(entry: Dictionary) -> bool: return day - int(entry["day"]) < window)
	_recompute()
	if coalition_active():
		_drift_pairs()
	if coordinating():
		_share_intel()
	EventBus.state_changed.emit()


# Nudges every pair of factions not at war with the player (and not held)
# friendlier by pairDrift.
static func _drift_pairs() -> void:
	var drift := int(_cfg()["pairDrift"])
	for pair in FactionAI._pairs():
		var a: String = pair[0]
		var b: String = pair[1]
		if FactionAI.at_war(a, Shares.PLAYER) or FactionAI.at_war(b, Shares.PLAYER) or FactionAI.is_held_pair(a, b):
			continue
		Factions.adjust_relation(a, b, drift)


# Each faction's Intel meter on the player rises toward the best of the others,
# by at most shareIntelPerDay.
static func _share_intel() -> void:
	var ids: Array = GameData.FACTIONS.keys()
	var best := 0
	for faction_id in ids:
		best = maxi(best, Intel.meter(faction_id, Shares.PLAYER))
	var step := int(_cfg()["shareIntelPerDay"])
	for faction_id in ids:
		var gap := best - Intel.meter(faction_id, Shares.PLAYER)
		if gap > 0:
			Intel.raise(faction_id, Shares.PLAYER, mini(gap, step))
