class_name Business
extends RefCounted

# The business pot, weekly payday, and owed staff wages (R§3.10 "Business
# pot and payday"). While the pot is active, contract settlements credit
# the pot instead of player cash; every paydayIntervalDays the pot pays
# staff wages and the remainder splits evenly between the player and each
# partner, rounding to the player. Static funcs only.


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
# receipts.
static func receive(amount: int) -> void:
	var business := _business()
	business["pot"] += amount
	business["week"]["receipts"] += amount
	EventBus.state_changed.emit()


# Pays a Sales calc purchase from the pot, in full or not at all; the week's
# expenses gain one `calc` line per source leg. legs: [{ source, oreType,
# qty, amount }]. Player cash is never touched.
static func pay_calc_purchase(contract_id: String, legs: Array) -> bool:
	var business := _business()
	var total := 0
	for leg in legs:
		total += int(leg["amount"])
	if total <= 0 or int(business["pot"]) < total:
		return false
	business["pot"] -= total
	for leg in legs:
		var expense: Dictionary = leg.duplicate()
		expense["kind"] = "calc"
		expense["contractId"] = contract_id
		business["week"]["expenses"].append(expense)
	EventBus.state_changed.emit()
	return true


# A waged contact the pot couldn't cover stops acting at block ends until
# paid in full.
static func is_unpaid(contact_id: String) -> bool:
	return bool(_business()["wages"].get(contact_id, {}).get("unpaid", false))


static func owed(contact_id: String) -> int:
	return int(_business()["wages"].get(contact_id, {}).get("owed", 0))


# BizBrief Staff tab pay terms: a partner's share of the payday remainder,
# a weekly business wage, or a room hire's daily Payroll wage.
static func pay_terms(contact_id: String) -> String:
	var business := _business()
	var partners: Array = business["partners"]
	if partners.has(contact_id):
		return "%s share" % _share_fraction(partners.size() + 1)
	if business["wages"].has(contact_id):
		return "£%d a week" % int(business["wages"][contact_id]["weekly"])
	var room: Variant = GameState.state["contacts"][contact_id].get("assignedRoom")
	if room != null and Payroll.ROLE_SKILL_KEYS.has(room) and not Contacts.is_founder(contact_id):
		return "£%d a day" % Payroll.wage_for_room(room)
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
# or whether they act at block ends today.
static func staff_status(contact_id: String) -> String:
	if is_unpaid(contact_id):
		return "Unpaid · owed £%d" % owed(contact_id)
	if Contacts.role_of(contact_id) == null:
		return "Idle"
	return "Working" if Payroll.is_working(contact_id) else "Unpaid today"


# Contact ids whose wage shortfall still awaits the morning
# "pay from your own cash?" answer.
static func pending_wage_prompts() -> Array[String]:
	var ids: Array[String] = []
	var wages: Dictionary = _business()["wages"]
	for contact_id in wages:
		if wages[contact_id]["promptPending"] and int(wages[contact_id]["owed"]) > 0:
			ids.append(contact_id)
	return ids


# round(weekly × days / interval): a full week's wage, prorated for a
# partial week.
static func prorated_wage(weekly: int, days_worked: int) -> int:
	return GameState.round_epsilon(float(weekly) * float(days_worked) / float(GameData.BUSINESS_PAYDAY_INTERVAL_DAYS))


# Each partner takes floor(R / (partners + 1)); the player takes the rest,
# so rounding remainders go to the player.
static func split(remainder: int, partner_count: int) -> Dictionary:
	var partner_share := floori(float(remainder) / float(partner_count + 1))
	return { "partner": partner_share, "player": remainder - partner_count * partner_share }


# Pays a contact's owed wage from player cash (the morning prompt's Yes, and
# Pay now). Full payment resumes their work.
static func pay_owed_from_cash(contact_id: String) -> Dictionary:
	var wage: Dictionary = _business()["wages"].get(contact_id, {})
	var amount := int(wage.get("owed", 0))
	if amount <= 0:
		return { "ok": false, "reason": "Nothing owed." }
	var player: Dictionary = GameState.state["player"]
	if player["cash"] < amount:
		return { "ok": false, "reason": "Not enough cash." }
	player["cash"] -= amount
	Bank.record(-amount, "%s's wages" % Contacts.display_name(contact_id))
	_clear_owed(wage)
	EventBus.state_changed.emit()
	return { "ok": true, "paid": amount }


# The morning prompt's No: the contact stays unpaid and owed.
static func decline_wage_prompt(contact_id: String) -> void:
	var wage: Dictionary = _business()["wages"].get(contact_id, {})
	if wage.is_empty():
		return
	wage["promptPending"] = false
	EventBus.state_changed.emit()


# Rollover step, after due contract settlements: accrue a worked day for
# every paid staff member, then run payday on a payday, else retry owed
# wages from the pot. Returns { "payday": ledger record or null,
# "shortfalls": [{ contactId, owed }] } for the Morning Brief.
static func daily_tick() -> Dictionary:
	var result := { "payday": null, "shortfalls": [] }
	if not is_pot_active():
		return result
	var wages: Dictionary = _business()["wages"]
	for contact_id in wages:
		if not wages[contact_id]["unpaid"]:
			wages[contact_id]["daysWorked"] += 1
	var day: int = GameState.state["world"]["day"]
	if day % GameData.BUSINESS_PAYDAY_INTERVAL_DAYS == 0:
		result = _payday(day)
	else:
		_retry_owed()
	EventBus.state_changed.emit()
	return result


static func _retry_owed() -> void:
	var business := _business()
	for contact_id in business["wages"]:
		var wage: Dictionary = business["wages"][contact_id]
		var amount := int(wage["owed"])
		if amount <= 0 or business["pot"] < amount:
			continue
		business["pot"] -= amount
		business["week"]["expenses"].append({ "kind": "wage", "contactId": contact_id, "amount": amount })
		_clear_owed(wage)


# Wages due are this week's prorated days plus anything owed, paid from the
# pot in full or not at all. The ledger record is appended before any cash
# moves; a stable payday id already in the ledger is never paid twice.
static func _payday(day: int) -> Dictionary:
	var business := _business()
	var result := { "payday": null, "shortfalls": [] }
	var payday_id := "payday-%d" % int(business["nextPaydayId"])
	for record in business["ledger"]:
		if record["payday"] == payday_id:
			return result
	var expenses: Array = business["week"]["expenses"].duplicate(true)
	var pot: int = business["pot"]
	var paid := {}
	for contact_id in business["wages"]:
		var wage: Dictionary = business["wages"][contact_id]
		var due: int = prorated_wage(int(wage["weekly"]), int(wage["daysWorked"])) + int(wage["owed"])
		if due <= 0:
			continue
		if pot >= due:
			pot -= due
			paid[contact_id] = due
			expenses.append({ "kind": "wage", "contactId": contact_id, "amount": due })
		else:
			result["shortfalls"].append({ "contactId": contact_id, "owed": due })
	var partners: Array = business["partners"]
	var shares := split(pot, partners.size())
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


static func _clear_owed(wage: Dictionary) -> void:
	wage["owed"] = 0
	wage["unpaid"] = false
	wage["promptPending"] = false


static func _new_week(day: int) -> Dictionary:
	return { "startDay": day, "receipts": 0, "expenses": [] }
