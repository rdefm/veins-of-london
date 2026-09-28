class_name Offers
extends RefCounted

# Pending sales offers and their immutable quotes. Accepted entries become
# the ledger fulfilment/settlement (systems/contracts.gd) consume, carrying
# the offer's quote as signedQuote (R§3.10 "Offer price and expiry").

const PENDING_CAP := 4
const RANDOM_BASE_CHANCE := 0.20
const RANDOM_CHANCE_PER_SALES_LEVEL := 0.10
const RANDOM_MAX_CHANCE := 0.60
const RANDOM_ONE_OFF_QTY_MIN := 4
const RANDOM_ONE_OFF_QTY_MAX := 10
const RANDOM_RECURRING_QTY_MIN := 3
const RANDOM_RECURRING_QTY_MAX := 6
const RANDOM_ONE_OFF_DEADLINE_MIN_DAYS := 3
const RANDOM_ONE_OFF_DEADLINE_MAX_DAYS := 7
const CONTRACT_MULTIPLIER := 1.25
const SALES_LEVEL_BONUS := 0.05
# Mixed one-offs (request.types.size() > 1): every requested type beyond
# the first adds this many days to the deadline and this bonus to payment.
const MIXED_TYPE_QTY_MIN := 2
const MIXED_TYPE_QTY_MAX := 5
const MIXED_EXTRA_TYPE_DEADLINE_DAYS := 2
const MIXED_EXTRA_TYPE_BONUS := 0.20
# Every offer's weekday is Monday (Calendar weekday index 0): a recurring
# contract falls due on the rollover into each Monday (R§3.10 "Weekly cadence").
const RECURRING_WEEKDAY := 0


static func pending_offers() -> Array:
	return GameState.state["sales"]["pendingOffers"]


static func active_contracts() -> Array:
	return GameState.state["sales"]["activeContracts"]


static func sales_skill() -> int:
	var contact_id: Variant = Contacts.sales_contact()
	if contact_id == null:
		return 1
	return int(GameState.state["contacts"][contact_id].get("salesSkill", 1))


static func random_offer_chance() -> float:
	return minf(RANDOM_MAX_CHANCE, RANDOM_BASE_CHANCE + RANDOM_CHANCE_PER_SALES_LEVEL * float(sales_skill() - 1))


static func daily_tick() -> void:
	expire_pending_offers()
	if pending_offers().size() >= PENDING_CAP:
		return
	# An assigned-but-unpaid Sales role sources nothing this week; an unassigned
	# room isn't gated here since it never owes a wage (business-spec.md).
	if Contacts.get_contact_in_room("ops") != null and not Payroll.is_paid_this_week("ops"):
		return
	if not Rng.chance(random_offer_chance()):
		return
	var templates := random_templates()
	if templates.is_empty():
		return
	create_offer(Rng.rand_from(templates))


static func random_templates() -> Array:
	var templates: Array = []
	for template in GameData.OFFER_TEMPLATES.values():
		if template.get("source", "") == "random":
			templates.append(template)
	return templates


static func create_scripted_offer(template_id: String) -> Dictionary:
	var template: Dictionary = GameData.OFFER_TEMPLATES.get(template_id, {})
	if template.is_empty() or template.get("source", "") != "scripted":
		return { "ok": false, "reason": "Unknown scripted offer." }
	return create_offer(template)


static func create_offer(template: Dictionary) -> Dictionary:
	if pending_offers().size() >= PENDING_CAP:
		return { "ok": false, "reason": "Pending offers are full." }
	var request: Dictionary = template.get("request", {}).duplicate(true)
	var contract_type: String = template.get("contractType", "oneOff")
	if contract_type != "oneOff" and contract_type != "recurring":
		return { "ok": false, "reason": "Invalid contract type." }
	if not _valid_request(request, contract_type):
		return { "ok": false, "reason": "Invalid offer request." }
	_fill_request_quantities(request, contract_type)
	var source: String = template.get("source", "random")
	var offer := _issue_offer(template.get("id", ""), source, contract_type, request, int(template.get("deadlineAfterDays", 0)), "")
	if source == "random":
		var contact_id: Variant = Contacts.sales_contact()
		if contact_id != null:
			Contacts.award_contact_xp(contact_id, "sales", 5)
	EventBus.state_changed.emit()
	return { "ok": true, "offer": offer }


# R§3.10 "Renewal offer": an expired recurring contract's request and
# counterparty, quoted fresh today. Bypasses PENDING_CAP.
static func create_renewal_offer(contract: Dictionary) -> Dictionary:
	var offer := _issue_offer(contract.get("templateId", ""), "renewal", "recurring", contract["request"].duplicate(true), 0, ensure_counterparty(contract))
	EventBus.state_changed.emit()
	return offer


# Prices and appends one pending offer; an empty counterparty is picked.
static func _issue_offer(template_id: String, source: String, contract_type: String, request: Dictionary, deadline_after_days: int, counterparty: String) -> Dictionary:
	var today: int = GameState.state["world"]["day"]
	var quote := quote_for_request(request, sales_skill())
	var extra_types: int = maxi(0, quote["lines"].size() - 1)
	var sales: Dictionary = GameState.state["sales"]
	var offer := {
		"id": "offer-%d" % sales["nextOfferId"], "templateId": template_id,
		"source": source, "contractType": contract_type, "request": request,
		"createdDay": today, "expiresDay": today + GameData.OFFER_EXPIRY_DAYS, "weekday": RECURRING_WEEKDAY,
		"deadlineAfterDays": deadline_after_days,
		"extraTypeDeadlineDays": extra_types * MIXED_EXTRA_TYPE_DEADLINE_DAYS, "quote": quote,
		"counterparty": counterparty if counterparty != "" else pick_counterparty(template_id, request, int(quote["payment"])),
	}
	sales["nextOfferId"] += 1
	pending_offers().append(offer)
	return offer


# One quote.lines entry per requested type (single or mixed) so settle()
# never special-cases the two; quote.unitValue is kept for single-type callers.
static func quote_for_request(request: Dictionary, skill: int) -> Dictionary:
	var lines: Array = Contracts.request_lines(request)
	var extra_types: int = maxi(0, lines.size() - 1)
	var live_value := 0
	var quote_lines: Array = []
	for line in lines:
		var uv := unit_value(line["kind"], line["type"])
		var lv: int = Market.line_total(line["kind"], uv, int(line["qty"]))
		live_value += lv
		quote_lines.append({ "kind": line["kind"], "type": line["type"], "unitValue": uv, "liveValue": lv })
	var multiplier := CONTRACT_MULTIPLIER * (1.0 + MIXED_EXTRA_TYPE_BONUS * float(extra_types)) * (1.0 + SALES_LEVEL_BONUS * float(maxi(skill - 1, 0)))
	var payment := GameState.round_epsilon(float(live_value) * multiplier)
	var quote := { "liveValue": live_value, "payment": payment, "salesSkill": skill, "lines": quote_lines }
	if lines.size() == 1:
		quote["unitValue"] = quote_lines[0]["unitValue"]
	return quote


# Today's London quote (R§3.13), per Market.price_lot units of the kind.
static func unit_value(kind: String, item_type: String) -> int:
	return Market.quote(kind, item_type)


# R§3.10 "Counterparty": a template's authored counterparty wins;
# otherwise an offer paying at least smallOfferThreshold is weighted across
# every faction by identity, and a smaller one (or one no faction weights)
# goes to the Collective or the Firm by fit.
# `factions` is the state.factions dict to read relations from (a save being
# loaded); empty means the live GameState.
static func pick_counterparty(template_id: String, request: Dictionary, payment: int, factions: Dictionary = {}) -> String:
	var authored: String = GameData.OFFER_TEMPLATES.get(template_id, {}).get("counterparty", "")
	if authored != "":
		return authored
	if payment >= int(GameData.OFFER_COUNTERPARTY["smallOfferThreshold"]):
		var weights := identity_weights(request)
		if not weights.is_empty():
			return _weighted_pick(weights)
	return small_counterparty(request, factions)


# An offer or contract's counterparty, assigning one by pick_counterparty()
# first if it has none (old-save backfill).
static func ensure_counterparty(entry: Dictionary, factions: Dictionary = {}) -> String:
	if String(entry.get("counterparty", "")) == "":
		entry["counterparty"] = pick_counterparty(entry.get("templateId", ""), entry["request"], int(entry.get("quote", entry.get("signedQuote", {})).get("payment", 0)), factions)
	return entry["counterparty"]


# Ore goods weight each faction crafting with that ore by 1; item goods
# weight each faction consuming them by its base weekly qty.
static func identity_weights(request: Dictionary) -> Dictionary:
	var weights := {}
	for line in Contracts.request_lines(request):
		if line["kind"] == "ore":
			for faction_id in Factions.factions_crafting_with_ore(line["type"]):
				weights[faction_id] = int(weights.get(faction_id, 0)) + 1
		else:
			for faction_id in Factions.factions_consuming(line["type"]):
				weights[faction_id] = int(weights.get(faction_id, 0)) + int(GameData.FACTIONS[faction_id]["consumes"][line["type"]])
	return weights


# Collective for life/emotion goods, Firm for physics goods (an item counts
# as its recipe's ingredient ores); anything else, or both, goes to the one
# the player stands better with, a tie rolled.
static func small_counterparty(request: Dictionary, factions: Dictionary = {}) -> String:
	var ores := {}
	for line in Contracts.request_lines(request):
		if line["kind"] == "ore":
			ores[line["type"]] = true
		else:
			for ore_type in GameData.RECIPES.get(line["type"], {}).get("ingredients", {}):
				ores[ore_type] = true
	var collective_fit: bool = ores.has("life") or ores.has("emotion")
	var firm_fit: bool = ores.has("physics")
	if collective_fit != firm_fit:
		return "collective" if collective_fit else "firm"
	if factions.is_empty():
		factions = GameState.state["factions"]
	var collective_rel := int(factions["collective"]["relation"])
	var firm_rel := int(factions["firm"]["relation"])
	if collective_rel != firm_rel:
		return "collective" if collective_rel > firm_rel else "firm"
	return Rng.rand_from(["collective", "firm"])


static func _weighted_pick(weights: Dictionary) -> String:
	var total := 0
	for weight in weights.values():
		total += int(weight)
	var roll := Rng.randf() * float(total)
	var last := ""
	for faction_id in weights:
		last = faction_id
		roll -= float(weights[faction_id])
		if roll < 0.0:
			return faction_id
	return last


static func accept_offer(offer_id: String) -> Dictionary:
	var pending := pending_offers()
	for index in pending.size():
		var offer: Dictionary = pending[index]
		if offer["id"] != offer_id:
			continue
		if is_expired(offer):
			pending.remove_at(index)
			BusinessQuest.note_starter_closed(offer.get("templateId", ""), false)
			BusinessQuest.note_recurring_closed(offer.get("templateId", ""))
			EventBus.state_changed.emit()
			return { "ok": false, "reason": "Offer expired." }
		var sales: Dictionary = GameState.state["sales"]
		var accepted_day: int = GameState.state["world"]["day"]
		var due_day := accepted_day + Rng.randi_range(RANDOM_ONE_OFF_DEADLINE_MIN_DAYS, RANDOM_ONE_OFF_DEADLINE_MAX_DAYS)
		if offer["contractType"] == "recurring":
			due_day = Calendar.next_weekday_after(accepted_day, int(offer["weekday"]))
		elif offer["source"] == "scripted":
			due_day = accepted_day + int(offer["deadlineAfterDays"])
		# Extra requested types were fixed at offer-creation (quote) time; their
		# deadline bonus applies on top of whichever base above was picked.
		due_day += int(offer.get("extraTypeDeadlineDays", 0))
		var contract := { "id": "contract-%d" % sales["nextContractId"], "periodId": "period-%d" % sales["nextPeriodId"], "offerId": offer_id, "templateId": offer["templateId"], "contractType": offer["contractType"], "request": offer["request"].duplicate(true), "signedQuote": offer["quote"].duplicate(true), "acceptedDay": accepted_day, "dueDay": due_day, "weekday": offer["weekday"], "delivered": {}, "status": "active", "counterparty": ensure_counterparty(offer) }
		Contracts.start_period(contract)
		if contract["contractType"] == "recurring":
			Contracts.start_term(contract, accepted_day)
		sales["nextContractId"] += 1
		sales["nextPeriodId"] += 1
		pending.remove_at(index)
		active_contracts().append(contract)
		sales["priorityOrder"].append(contract["id"])
		EventBus.state_changed.emit()
		return { "ok": true, "contract": contract }
	return { "ok": false, "reason": "Offer not found." }


static func decline_offer(offer_id: String) -> Dictionary:
	var pending := pending_offers()
	for index in pending.size():
		if pending[index]["id"] == offer_id:
			var template_id: String = pending[index].get("templateId", "")
			pending.remove_at(index)
			BusinessQuest.note_starter_closed(template_id, false)
			BusinessQuest.note_recurring_closed(template_id)
			EventBus.state_changed.emit()
			return { "ok": true }
	return { "ok": false, "reason": "Offer not found." }


static func is_expired(offer: Dictionary) -> bool:
	return int(offer["expiresDay"]) <= int(GameState.state["world"]["day"])


static func expire_pending_offers() -> void:
	var pending := pending_offers()
	var changed := false
	for index in range(pending.size() - 1, -1, -1):
		if is_expired(pending[index]):
			var template_id: String = pending[index].get("templateId", "")
			pending.remove_at(index)
			BusinessQuest.note_starter_closed(template_id, false)
			BusinessQuest.note_recurring_closed(template_id)
			changed = true
	if changed:
		EventBus.state_changed.emit()


# business-spec.md "Offer and contract types": mixed requests are one-off
# only; a recurring template always stays single-type.
static func _valid_request(request: Dictionary, contract_type: String) -> bool:
	if request.has("types"):
		if contract_type != "oneOff":
			return false
		var types: Array = request["types"]
		if types.size() < 2:
			return false
		for line in types:
			if not (line is Dictionary and _valid_request_line(line)):
				return false
		return true
	return _valid_request_line(request)


static func _valid_request_line(line: Dictionary) -> bool:
	var kind: String = line.get("kind", "")
	var item_type: String = line.get("type", "")
	return (kind == "ore" and GameData.ORE_TYPES.has(item_type)) or (kind == "consumable" and GameData.CONSUMABLE_PRICES.has(item_type))


# Random one-offs/recurring roll a qty when the template omits one; a mixed
# one-off's per-type qty band is 2-5 regardless of source (business-spec.md).
static func _fill_request_quantities(request: Dictionary, contract_type: String) -> void:
	if request.has("types"):
		for line in request["types"]:
			if not line.has("qty"):
				line["qty"] = Rng.randi_range(MIXED_TYPE_QTY_MIN, MIXED_TYPE_QTY_MAX)
		return
	if not request.has("qty"):
		request["qty"] = Rng.randi_range(RANDOM_RECURRING_QTY_MIN, RANDOM_RECURRING_QTY_MAX) if contract_type == "recurring" else Rng.randi_range(RANDOM_ONE_OFF_QTY_MIN, RANDOM_ONE_OFF_QTY_MAX)
