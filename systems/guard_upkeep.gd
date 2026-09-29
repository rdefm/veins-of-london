class_name GuardUpkeep
extends RefCounted

# Guard wages (R§1.6 "Guard upkeep"): the prorated hire advance, the weekly
# guard cost shown on security rows, and the per-day, per-place guard cost
# history (state.guardUpkeep.history). Static funcs only.

# Place id for HQ guards in expenses and history; veins use their vein id.
const HOME_PLACE_ID := "home"
const HIRE_BANK_LABEL := "Guard hire"
const WAGES_BANK_LABEL := "Guard wages"


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


# Guards on duty per place: { vein id or HOME_PLACE_ID: count }, player
# veins in list order then HQ, places with no guards left out. Only veins in
# player.veins count, so guards on a sold or lost vein aren't billed.
static func player_guards_by_place() -> Dictionary:
	var places := {}
	for vein in GameState.state["player"]["veins"]:
		var count := Cultivating.vein_guard_count(vein)
		if count > 0:
			places[vein["id"]] = count
	var hq_count := Home.get_guard_count()
	if hq_count > 0:
		places[HOME_PLACE_ID] = hq_count
	return places


# Player Monday bill before the pot exists (spec §Player Monday bill, R§3.1
# ⑥.4a): on the rollover into a Monday, weeklyWage per guard on duty, from
# cash in full or not at all (bank "Guard wages"). Short cash takes nothing
# and returns short = true. Any other day, or with the pot active, bills
# nothing. Returns { billed, short, due, paid, guards }.
#
# PROSE-REVIEW: the paid notification.
static func pay_monday_bill() -> Dictionary:
	var result := { "billed": false, "short": false, "due": 0, "paid": 0, "guards": 0 }
	if not Calendar.is_monday(GameState.state["world"]["day"]) or Business.is_pot_active():
		return result
	var places := player_guards_by_place()
	for place_id in places:
		result["guards"] += int(places[place_id])
	if result["guards"] == 0:
		return result
	result["billed"] = true
	result["due"] = weekly_cost(result["guards"])
	var player: Dictionary = GameState.state["player"]
	if int(player["cash"]) < result["due"]:
		result["short"] = true
		return result
	player["cash"] -= result["due"]
	Bank.record(-result["due"], WAGES_BANK_LABEL)
	for place_id in places:
		record_payment(place_id, weekly_cost(int(places[place_id])))
	result["paid"] = result["due"]
	Notify.push("Guard wages: -£%d for %d guard%s this week." % [result["paid"], result["guards"], "" if result["guards"] == 1 else "s"])
	EventBus.state_changed.emit()
	return result


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
