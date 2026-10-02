class_name Business
extends RefCounted

# The business pot, weekly payday, and owed staff wages (R§3.10 "Business
# pot and payday"). While the pot is active, contract settlements credit
# the pot instead of player cash; on the rollover into each Monday the pot
# pays staff wages and the remainder splits evenly between the player and each
# partner, rounding to the player. The float is the player's reserve beside
# the pot: never split, only drawn when the pot can't cover a bill (spec
# §Business float). Static funcs only.


static func _business() -> Dictionary:
	return GameState.state["business"]


static func is_pot_active() -> bool:
	return bool(_business()["potActive"])


# Starts the pot (Beat 3): Archie and James become partners and Owen's
# wage starts accruing from today. A second call is a no-op.
static func activate() -> Dictionary:
	var business := _business()
	if business["potActive"]:
		return { "ok": false, "reason": "The business pot is already active." }
	var day: int = GameState.state["world"]["day"]
	business["potActive"] = true
	business["partners"] = ["archie", "james"]
	business["week"] = _new_week(day)
	business["wages"]["owen"] = {
		"weekly": int(GameData.BUSINESS_WEEKLY_WAGES["owen"]), "owed": 0, "unpaid": false,
		"hiredDay": day, "daysWorked": 0, "promptPending": false,
	}
	EventBus.state_changed.emit()
	return { "ok": true }


# A contract settlement's payment, credited to the pot and this week's
# receipts; then any owed wage the pot and float now cover is paid.
static func receive(amount: int) -> void:
	var business := _business()
	business["pot"] += amount
	business["week"]["receipts"] += amount
	BusinessStats.record_revenue(amount)
	pay_covered_owed()
	EventBus.state_changed.emit()


# Moves player cash into the float (not revenue); then any owed wage the pot
# and float now cover is paid.
static func donate(amount: int) -> Dictionary:
	var added := _add_float(amount)
	if added["ok"]:
		pay_covered_owed()
		EventBus.state_changed.emit()
	return added


static func _add_float(amount: int) -> Dictionary:
	if not is_pot_active():
		return { "ok": false, "reason": "The business pot isn't running yet." }
	var player: Dictionary = GameState.state["player"]
	if amount < 1 or amount > int(player["cash"]):
		return { "ok": false, "reason": "Not enough cash." }
	player["cash"] -= amount
	_business()["float"] += amount
	Bank.record(-amount, "Business float")
	return { "ok": true }


# Moves float back to player cash.
static func withdraw(amount: int) -> Dictionary:
	var business := _business()
	if amount < 1 or amount > int(business["float"]):
		return { "ok": false, "reason": "Not that much in the float." }
	business["float"] -= amount
	GameState.state["player"]["cash"] += amount
	Bank.record(amount, "Float withdrawal")
	EventBus.state_changed.emit()
	return { "ok": true }


# Takes `amount` from the pot, then the float for whatever the pot can't
# cover, in full or not at all.
static func _draw(amount: int) -> bool:
	var business := _business()
	var pot := int(business["pot"])
	if pot + int(business["float"]) < amount:
		return false
	var from_pot := mini(pot, amount)
	business["pot"] = pot - from_pot
	business["float"] -= amount - from_pot
	return true


# Pays a Sales calc purchase from the pot, backed by the float, in full or
# not at all; the week's expenses gain one `calc` line per source leg.
# legs: [{ source, oreType, qty, amount }]. Player cash is never touched.
static func pay_calc_purchase(contract_id: String, legs: Array) -> bool:
	var business := _business()
	var total := 0
	for leg in legs:
		total += int(leg["amount"])
	if total <= 0 or not _draw(total):
		return false
	BusinessStats.record_expense(total, BusinessStats.EXPENSE_CALC)
	for leg in legs:
		var expense: Dictionary = leg.duplicate()
		expense["kind"] = "calc"
		expense["contractId"] = contract_id
		business["week"]["expenses"].append(expense)
	EventBus.state_changed.emit()
	return true


# A hire's first week (R§3.10 "Hiring"): moves `top_up` cash into the float,
# then draws `weekly` from the pot, then the float, in full or not at all, as
# this week's `wage` expense, and opens their wage entry. paidThroughDay =
# today + 7: the rollovers into the prepaid days accrue nothing, so payday
# never re-charges them. The hire is paid before any other owed wage the
# top-up might now cover.
static func prepay_hire_wage(contact_id: String, weekly: int, top_up: int = 0) -> Dictionary:
	if not is_pot_active():
		return { "ok": false, "reason": "The business pot isn't running yet." }
	if shortfall(weekly) > top_up:
		return { "ok": false, "reason": "Top up the float by £%d to cover this hire." % shortfall(weekly) }
	if top_up > 0:
		var added := _add_float(top_up)
		if not added["ok"]:
			return added
	_draw(weekly)
	var business := _business()
	var day: int = GameState.state["world"]["day"]
	business["week"]["expenses"].append({ "kind": "wage", "contactId": contact_id, "amount": weekly })
	BusinessStats.record_expense(weekly, BusinessStats.EXPENSE_STAFF)
	business["wages"][contact_id] = {
		"weekly": weekly, "owed": 0, "unpaid": false, "hiredDay": day, "daysWorked": 0,
		"promptPending": false, "paidThroughDay": day + Calendar.days_per_week(),
	}
	pay_covered_owed()
	EventBus.state_changed.emit()
	return { "ok": true }


# Cash the float needs so pot + float cover `amount`.
static func shortfall(amount: int) -> int:
	var business := _business()
	return maxi(0, amount - int(business["pot"]) - int(business["float"]))


# A waged contact the pot couldn't cover stops acting at block ends until
# paid in full.
static func is_unpaid(contact_id: String) -> bool:
	return bool(_business()["wages"].get(contact_id, {}).get("unpaid", false))


static func owed(contact_id: String) -> int:
	return int(_business()["wages"].get(contact_id, {}).get("owed", 0))


# BizBrief Staff tab pay terms: a partner's share of the payday remainder
# or a weekly business wage.
static func pay_terms(contact_id: String) -> String:
	var business := _business()
	var partners: Array = business["partners"]
	if partners.has(contact_id):
		return "%s share" % _share_fraction(partners.size() + 1)
	if business["wages"].has(contact_id):
		return "£%d a week" % int(business["wages"][contact_id]["weekly"])
	return "No pay"


static func _share_fraction(people: int) -> String:
	match people:
		2:
			return "½"
		3:
			return "⅓"
		4:
			return "¼"
	return "1/%d" % people


# BizBrief Staff tab status: unpaid (owed a business wage), idle (no role),
# or working.
static func staff_status(contact_id: String) -> String:
	if is_unpaid(contact_id):
		return "Unpaid · owed £%d" % owed(contact_id)
	if Contacts.role_of(contact_id) == null:
		return "Idle"
	return "Working"


# Contact ids whose wage shortfall still awaits the morning
# "top up the float?" answer.
static func pending_wage_prompts() -> Array[String]:
	var ids: Array[String] = []
	var wages: Dictionary = _business()["wages"]
	for contact_id in wages:
		if wages[contact_id]["promptPending"] and int(wages[contact_id]["owed"]) > 0:
			ids.append(contact_id)
	return ids


# round(weekly × days / 7): a full week's wage, prorated for a partial week.
static func prorated_wage(weekly: int, days_worked: int) -> int:
	return GameState.round_epsilon(float(weekly) * float(days_worked) / float(Calendar.days_per_week()))


# Each partner takes floor(R / (partners + 1)); the player takes the rest,
# so rounding remainders go to the player.
static func split(remainder: int, partner_count: int) -> Dictionary:
	var partner_share := floori(float(remainder) / float(partner_count + 1))
	return { "partner": partner_share, "player": remainder - partner_count * partner_share }


# Cash the float needs so pot + float cover the contact's owed wage.
static func top_up_needed(contact_id: String) -> int:
	return shortfall(owed(contact_id))


# The morning prompt's Yes, and the Staff tab's Pay now: moves
# top_up_needed() into the float, then pays this contact's owed wage from the
# pot, then the float. Full payment resumes their work.
static func top_up_and_pay_owed(contact_id: String) -> Dictionary:
	var wage: Dictionary = _business()["wages"].get(contact_id, {})
	var amount := int(wage.get("owed", 0))
	if amount <= 0:
		return { "ok": false, "reason": "Nothing owed." }
	var top_up := top_up_needed(contact_id)
	if top_up > 0:
		var added := _add_float(top_up)
		if not added["ok"]:
			return added
	_pay_owed(contact_id)
	EventBus.state_changed.emit()
	return { "ok": true, "paid": amount, "toppedUp": top_up }


# Pays, in wages order, every owed wage the pot then float can cover in
# full -- for every waged contact, not only at payday -- so a covered wage
# never waits on a prompt.
static func pay_covered_owed() -> void:
	var wages: Dictionary = _business()["wages"]
	for contact_id in wages:
		if int(wages[contact_id]["owed"]) > 0 and top_up_needed(contact_id) == 0:
			_pay_owed(contact_id)


# Draws contact_id's owed wage from the pot then float as a `wage` expense
# this week, and clears it. Caller has checked pot + float cover it.
static func _pay_owed(contact_id: String) -> void:
	var business := _business()
	var wage: Dictionary = business["wages"][contact_id]
	var amount := int(wage["owed"])
	_draw(amount)
	business["week"]["expenses"].append({ "kind": "wage", "contactId": contact_id, "amount": amount })
	BusinessStats.record_expense(amount, BusinessStats.EXPENSE_STAFF)
	_clear_owed(wage)


# The morning prompt's No: the contact stays unpaid and owed.
static func decline_wage_prompt(contact_id: String) -> void:
	var wage: Dictionary = _business()["wages"].get(contact_id, {})
	if wage.is_empty():
		return
	wage["promptPending"] = false
	EventBus.state_changed.emit()


# Rollover step, after due contract settlements: accrue a worked day for
# every paid staff member, then run payday (which also retries owed wages)
# on the rollover into a Monday. Returns { "payday": ledger record or null,
# "shortfalls": [{ contactId, owed }], "guards": the guard bill result or
# null } for the Morning Brief.
static func daily_tick() -> Dictionary:
	var result := { "payday": null, "shortfalls": [], "guards": null }
	if not is_pot_active():
		return result
	var wages: Dictionary = _business()["wages"]
	var day: int = GameState.state["world"]["day"]
	for contact_id in wages:
		var wage: Dictionary = wages[contact_id]
		if not wage["unpaid"] and day > int(wage.get("paidThroughDay", 0)):
			wage["daysWorked"] += 1
	if Calendar.is_monday(day):
		result = _payday(day)
	EventBus.state_changed.emit()
	return result


# Wages due are this week's prorated days plus anything owed, paid from the
# pot (then the float) in full or not at all. Then the guard bill, then the
# split. Only the pot is split. The
# ledger record is appended before player cash moves; a stable payday id
# already in the ledger is never paid twice.
static func _payday(day: int) -> Dictionary:
	var business := _business()
	var result := { "payday": null, "shortfalls": [], "guards": null }
	var payday_id := "payday-%d" % int(business["nextPaydayId"])
	for record in business["ledger"]:
		if record["payday"] == payday_id:
			return result
	var expenses: Array = business["week"]["expenses"].duplicate(true)
	var paid := {}
	for contact_id in business["wages"]:
		var wage: Dictionary = business["wages"][contact_id]
		var due: int = prorated_wage(int(wage["weekly"]), int(wage["daysWorked"])) + int(wage["owed"])
		if due <= 0:
			continue
		if _draw(due):
			paid[contact_id] = due
			expenses.append({ "kind": "wage", "contactId": contact_id, "amount": due })
			BusinessStats.record_expense(due, BusinessStats.EXPENSE_STAFF)
		else:
			result["shortfalls"].append({ "contactId": contact_id, "owed": due })
	result["guards"] = _pay_guard_bill(expenses)
	var partners: Array = business["partners"]
	var shares := split(int(business["pot"]), partners.size())
	var share_record := { "player": shares["player"] }
	for partner_id in partners:
		share_record[partner_id] = shares["partner"]
	var record := {
		"payday": payday_id, "day": day, "receipts": int(business["week"]["receipts"]),
		"expenses": expenses, "shares": share_record,
	}
	business["ledger"].append(record)
	business["nextPaydayId"] += 1

	for contact_id in business["wages"]:
		var wage: Dictionary = business["wages"][contact_id]
		wage["daysWorked"] = 0
		if paid.has(contact_id):
			_clear_owed(wage)
	for shortfall in result["shortfalls"]:
		var wage: Dictionary = business["wages"][shortfall["contactId"]]
		wage["owed"] = shortfall["owed"]
		wage["unpaid"] = true
		wage["promptPending"] = true
	business["pot"] = 0
	business["week"] = _new_week(day)
	if shares["player"] > 0:
		GameState.state["player"]["cash"] += shares["player"]
		Bank.record(shares["player"], "Business share")
	result["payday"] = record.duplicate(true)
	return result


# Player Monday guard bill with the pot active (spec §Player Monday bill):
# weeklyWage per guard on duty, from the pot then the float, in full; each
# place's share becomes a `guard` expense line (placeId: vein id or "home").
# Pot and float together short: all of both is set aside as the guard wage
# reserve for the pending shortfall, nothing is split from it, and short =
# true. Returns { billed, short, due, paid, guards, reserve }.
#
# PROSE-REVIEW: the paid notification.
static func _pay_guard_bill(expenses: Array) -> Dictionary:
	var business := _business()
	var result := { "billed": false, "short": false, "due": 0, "paid": 0, "guards": 0, "reserve": 0 }
	var places := GuardUpkeep.player_guards_by_place()
	for place_id in places:
		result["guards"] += int(places[place_id])
	if result["guards"] == 0:
		return result
	result["billed"] = true
	result["due"] = GuardUpkeep.weekly_cost(result["guards"])
	if not _draw(result["due"]):
		result["short"] = true
		result["reserve"] = int(business["pot"]) + int(business["float"])
		business["pot"] = 0
		business["float"] = 0
		GuardUpkeep.start_shortfall(places, result["reserve"], result["due"])
		return result
	for place_id in places:
		var amount := GuardUpkeep.weekly_cost(int(places[place_id]))
		expenses.append({ "kind": "guard", "placeId": place_id, "amount": amount })
		GuardUpkeep.record_payment(place_id, amount)
	result["paid"] = result["due"]
	Notify.push("Guard wages: £%d from the business for %d guard%s this week." % [result["paid"], result["guards"], "" if result["guards"] == 1 else "s"])
	return result


static func _clear_owed(wage: Dictionary) -> void:
	wage["owed"] = 0
	wage["unpaid"] = false
	wage["promptPending"] = false


static func _new_week(day: int) -> Dictionary:
	return { "startDay": day, "receipts": 0, "expenses": [] }
