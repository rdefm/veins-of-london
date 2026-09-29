class_name GuardUpkeep
extends RefCounted

# Guard wages (R§1.6 "Guard upkeep"): the prorated hire advance, the weekly
# guard cost shown on security rows, and the per-day, per-place guard cost
# history (state.guardUpkeep.history). Static funcs only.

# Place id for HQ guards in expenses and history; veins use their vein id.
const HOME_PLACE_ID := "home"
const HIRE_BANK_LABEL := "Guard hire"


static func weekly_wage() -> int:
	return int(GameData.GUARD_UPKEEP["weeklyWage"])


# guard_count × weeklyWage.
static func weekly_cost(guard_count: int) -> int:
	return guard_count * weekly_wage()


# Days from `day` through Sunday inclusive: 7 on a Monday, 1 on a Sunday.
static func days_left_in_week(day: int) -> int:
	return Calendar.days_per_week() - Calendar.weekday_index(day)


# What hiring one guard costs today: this week's remaining wage, prorated
# like staff wages (spec §Hiring).
static func hire_advance() -> int:
	return Business.prorated_wage(weekly_wage(), days_left_in_week(GameState.state["world"]["day"]))


# "£357 today, then £500/week" for a guard hire button.
static func hire_cost_text() -> String:
	return "£%d today, then £%d/week" % [hire_advance(), weekly_wage()]


# "£1000/week" for a security row, or "" with no guards.
static func weekly_cost_text(guard_count: int) -> String:
	if guard_count <= 0:
		return ""
	return "£%d/week" % weekly_cost(guard_count)


# Takes today's advance from player cash for one guard at place_id (a vein
# id or HOME_PLACE_ID). Refused, with nothing changed, when cash is short.
# The caller adds the guard itself.
static func pay_hire_advance(place_id: String) -> Dictionary:
	var advance := hire_advance()
	var player: Dictionary = GameState.state["player"]
	if int(player["cash"]) < advance:
		return { "ok": false, "reason": "Not enough cash." }
	player["cash"] -= advance
	Bank.record(-advance, HIRE_BANK_LABEL)
	record_payment(place_id, advance)
	return { "ok": true, "amount": advance }


# A player guard payment: a guard expense in BusinessStats and today's
# history entry for place_id.
static func record_payment(place_id: String, amount: int) -> void:
	if amount <= 0:
		return
	BusinessStats.record_expense(amount, BusinessStats.EXPENSE_GUARD)
	var day: int = GameState.state["world"]["day"]
	var history: Array = GameState.state["guardUpkeep"]["history"]
	if history.is_empty() or int(history[-1]["day"]) != day:
		history.append({ "day": day, "places": {} })
	var places: Dictionary = history[-1]["places"]
	places[place_id] = int(places.get(place_id, 0)) + amount
	var oldest_kept: int = day - int(GameData.GUARD_UPKEEP["guardCostHistoryDays"]) + 1
	while not history.is_empty() and int(history[0]["day"]) < oldest_kept:
		history.remove_at(0)
