class_name BusinessStats
extends RefCounted

# Daily business performance for the BizBrief Stats tab (R§2 businessStats).
# Money and ore hooks add to today's tally as they happen; each rollover,
# while the business pot is active, folds the tally plus the day's
# productionLog items into days[], trimmed to BUSINESS_STATS_DAYS. Static
# funcs only.

const TALLIES := ["revenue", "expenses", "oreCultivator", "orePlayer"]
const METRICS := ["revenue", "expenses", "oreCultivator", "orePlayer", "items"]


static func _stats() -> Dictionary:
	return GameState.state["businessStats"]


static func _add(metric: String, amount: int) -> void:
	if amount <= 0:
		return
	var today: Dictionary = _stats()["today"]
	today[metric] = int(today.get(metric, 0)) + amount


# Contract settlement paid into the pot.
static func record_revenue(amount: int) -> void:
	_add("revenue", amount)


# Staff wages (pot or player cash) and Sales calc purchases.
static func record_expense(amount: int) -> void:
	_add("expenses", amount)


# A staff block's cultivator yield, { oreType: qty }.
static func record_cultivator_ore(ore: Dictionary) -> void:
	for ore_type in ore:
		_add("oreCultivator", int(ore[ore_type]))


# Ore the player pruned from a vein themselves.
static func record_player_ore(amount: int) -> void:
	_add("orePlayer", amount)


static func _empty_today() -> Dictionary:
	var today := {}
	for metric in TALLIES:
		today[metric] = 0
	return today


# Rollover step: snapshots the day that just ended (world.day - 1) while the
# pot is active, then resets today's tally and trims to the window.
static func capture_day() -> void:
	var stats := _stats()
	var day: int = GameState.state["world"]["day"] - 1
	if Business.is_pot_active():
		var snapshot := { "day": day, "items": _items_made(day) }
		for metric in TALLIES:
			snapshot[metric] = int(stats["today"].get(metric, 0))
		stats["days"].append(snapshot)
	stats["today"] = _empty_today()
	var oldest_kept := day - GameData.BUSINESS_STATS_DAYS + 1
	var kept: Array = []
	for record in stats["days"]:
		if int(record["day"]) >= oldest_kept:
			kept.append(record)
	stats["days"] = kept


static func _items_made(day: int) -> int:
	for day_record in GameState.state["productionLog"]:
		if int(day_record["day"]) == day:
			return int(Rooms.production_day_totals(day_record)["made"])
	return 0


# The chart window: the last BUSINESS_STATS_DAYS completed days (never
# before day 1), oldest first.
static func window_days() -> Array[int]:
	var last_day: int = GameState.state["world"]["day"] - 1
	var days: Array[int] = []
	for day in range(maxi(1, last_day - GameData.BUSINESS_STATS_DAYS + 1), last_day + 1):
		days.append(day)
	return days


# One metric's value per window day, zero where no snapshot exists.
static func series(metric: String) -> Array[int]:
	var by_day := {}
	for record in _stats()["days"]:
		by_day[int(record["day"])] = int(record.get(metric, 0))
	var values: Array[int] = []
	for day in window_days():
		values.append(int(by_day.get(day, 0)))
	return values
