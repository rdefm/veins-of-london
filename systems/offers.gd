class_name Offers
extends RefCounted

# Pending sales offers and their immutable quotes. Fulfilment/settlement is
# deliberately left to tickets 25+; accepted entries only establish its ledger.

const PENDING_CAP := 4
const RANDOM_BASE_CHANCE := 0.20
const RANDOM_CHANCE_PER_SALES_LEVEL := 0.10
const RANDOM_MAX_CHANCE := 0.60
const RANDOM_EXPIRY_MIN_DAYS := 3
const RANDOM_EXPIRY_MAX_DAYS := 14
const RANDOM_ONE_OFF_QTY_MIN := 4
const RANDOM_ONE_OFF_QTY_MAX := 10
const RANDOM_RECURRING_QTY_MIN := 3
const RANDOM_RECURRING_QTY_MAX := 6
const RANDOM_ONE_OFF_DEADLINE_MIN_DAYS := 3
const RANDOM_ONE_OFF_DEADLINE_MAX_DAYS := 7
const CONTRACT_MULTIPLIER := 1.25
const SALES_LEVEL_BONUS := 0.05


static func pending_offers() -> Array:
	return GameState.state["sales"]["pendingOffers"]


static func active_contracts() -> Array:
	return GameState.state["sales"]["activeContracts"]


static func sales_skill() -> int:
	var contact_id: Variant = Contacts.get_contact_in_room("ops")
	if contact_id == null:
		return 1
	return int(GameState.state["contacts"][contact_id].get("salesSkill", 1))


static func random_offer_chance() -> float:
	return minf(RANDOM_MAX_CHANCE, RANDOM_BASE_CHANCE + RANDOM_CHANCE_PER_SALES_LEVEL * float(sales_skill() - 1))


static func daily_tick() -> void:
	expire_pending_offers()
	if pending_offers().size() >= PENDING_CAP or not Rng.chance(random_offer_chance()):
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
	if not _valid_request(request):
		return { "ok": false, "reason": "Invalid offer request." }
	var contract_type: String = template.get("contractType", "oneOff")
	if contract_type != "oneOff" and contract_type != "recurring":
		return { "ok": false, "reason": "Invalid contract type." }
	if not request.has("qty"):
		request["qty"] = Rng.randi_range(RANDOM_RECURRING_QTY_MIN, RANDOM_RECURRING_QTY_MAX) if contract_type == "recurring" else Rng.randi_range(RANDOM_ONE_OFF_QTY_MIN, RANDOM_ONE_OFF_QTY_MAX)
	var today: int = GameState.state["world"]["day"]
	var source: String = template.get("source", "random")
	var expiry_days: int = int(template.get("expiresAfterDays", Rng.randi_range(RANDOM_EXPIRY_MIN_DAYS, RANDOM_EXPIRY_MAX_DAYS)))
	var quote := quote_for_request(request, sales_skill())
	var sales: Dictionary = GameState.state["sales"]
	var offer := {
		"id": "offer-%d" % sales["nextOfferId"], "templateId": template.get("id", ""),
		"source": source, "contractType": contract_type, "request": request,
		"createdDay": today, "expiresDay": today + expiry_days, "weekday": int(template.get("weekday", 0)),
		"deadlineAfterDays": int(template.get("deadlineAfterDays", 0)), "quote": quote,
	}
	sales["nextOfferId"] += 1
	pending_offers().append(offer)
	if source == "random":
		var contact_id: Variant = Contacts.get_contact_in_room("ops")
		if contact_id != null:
			Contacts.award_contact_xp(contact_id, "sales", 5)
	EventBus.state_changed.emit()
	return { "ok": true, "offer": offer }


static func quote_for_request(request: Dictionary, skill: int) -> Dictionary:
	var unit_value := unit_value(request["kind"], request["type"])
	var live_value: int = unit_value * int(request["qty"])
	var payment := GameState.round_epsilon(float(live_value) * CONTRACT_MULTIPLIER * (1.0 + SALES_LEVEL_BONUS * float(maxi(skill - 1, 0))))
	return { "unitValue": unit_value, "liveValue": live_value, "payment": payment, "salesSkill": skill }


static func unit_value(kind: String, item_type: String) -> int:
	if kind == "ore":
		var ore: Dictionary = GameData.ORE_TYPES[item_type]
		return Barometer.get_effective_ore_price(item_type, ore["basePrice"])
	var recipe: Dictionary = GameData.RECIPES[item_type]
	var weighted_modifier := 0.0
	var total_ingredients := 0
	for ore_type in recipe["ingredients"].keys():
		var qty: int = int(recipe["ingredients"][ore_type])
		total_ingredients += qty
		weighted_modifier += Barometer.get_ore_price_modifier(ore_type) * float(qty)
	return GameState.round_epsilon(float(GameData.CONSUMABLE_PRICES[item_type]) * (1.0 + weighted_modifier / float(total_ingredients)))


static func accept_offer(offer_id: String) -> Dictionary:
	var pending := pending_offers()
	for index in pending.size():
		var offer: Dictionary = pending[index]
		if offer["id"] != offer_id:
			continue
		if int(offer["expiresDay"]) <= GameState.state["world"]["day"]:
			pending.remove_at(index)
			EventBus.state_changed.emit()
			return { "ok": false, "reason": "Offer expired." }
		var sales: Dictionary = GameState.state["sales"]
		var accepted_day: int = GameState.state["world"]["day"]
		var due_day := accepted_day + Rng.randi_range(RANDOM_ONE_OFF_DEADLINE_MIN_DAYS, RANDOM_ONE_OFF_DEADLINE_MAX_DAYS)
		if offer["contractType"] == "recurring":
			due_day = _next_weekday_strictly_after(accepted_day, int(offer["weekday"]))
		elif offer["source"] == "scripted":
			due_day = accepted_day + int(offer["deadlineAfterDays"])
		var contract := { "id": "contract-%d" % sales["nextContractId"], "periodId": "period-%d" % sales["nextPeriodId"], "offerId": offer_id, "templateId": offer["templateId"], "contractType": offer["contractType"], "request": offer["request"].duplicate(true), "quote": offer["quote"].duplicate(true), "acceptedDay": accepted_day, "dueDay": due_day, "weekday": offer["weekday"], "delegated": false, "delivered": {}, "status": "active" }
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
			pending.remove_at(index)
			EventBus.state_changed.emit()
			return { "ok": true }
	return { "ok": false, "reason": "Offer not found." }


static func expire_pending_offers() -> void:
	var today: int = GameState.state["world"]["day"]
	var pending := pending_offers()
	var changed := false
	for index in range(pending.size() - 1, -1, -1):
		if int(pending[index]["expiresDay"]) <= today:
			pending.remove_at(index)
			changed = true
	if changed:
		EventBus.state_changed.emit()


static func _next_weekday_strictly_after(day: int, weekday: int) -> int:
	var offset := posmod(weekday - posmod(day, 7), 7)
	return day + (7 if offset == 0 else offset)


static func _valid_request(request: Dictionary) -> bool:
	var kind: String = request.get("kind", "")
	var item_type: String = request.get("type", "")
	return (kind == "ore" and GameData.ORE_TYPES.has(item_type)) or (kind == "consumable" and GameData.CONSUMABLE_PRICES.has(item_type))
