class_name BusinessStats
extends RefCounted

# Daily business performance for the BizBrief Stats tab (R§2 businessStats).
# Money and ore hooks add to today's tally as they happen; each rollover,
# while the business pot is active, folds the tally plus the day's
# productionLog items into days[], trimmed to BUSINESS_STATS_DAYS. Static
# funcs only.

const EXPENSE_STAFF := "staff"
const EXPENSE_GUARD := "guard"
const EXPENSE_CALC := "calc"
# Expense kind -> its per-kind tally key; the kinds sum to "expenses".
const EXPENSE_KIND_METRICS := {
	EXPENSE_STAFF: "expensesStaff",
	EXPENSE_GUARD: "expensesGuard",
	EXPENSE_CALC: "expensesCalc",
}
const TALLIES := ["revenue", "expenses", "expensesStaff", "expensesGuard", "expensesCalc", "oreCultivator", "orePlayer"]
const METRICS := ["revenue", "expenses", "expensesStaff", "expensesGuard", "expensesCalc", "oreCultivator", "orePlayer", "items"]


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


# Staff wages, guard wages and Sales calc purchases (kind: an EXPENSE_* id),
# added to both the total and that kind's tally.
static func record_expense(amount: int, kind: String) -> void:
	assert(EXPENSE_KIND_METRICS.has(kind), "unknown expense kind '%s'" % kind)
	_add("expenses", amount)
	_add(EXPENSE_KIND_METRICS[kind], amount)


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
