class_name Contracts
extends RefCounted

# Sales contract periods. This is deliberately separate from Offers: offers
# establish a quote; this system owns delivery, ordering, and settlement.

const COMPLETE_XP := 20
const PARTIAL_XP := 10
const PARTIAL_PAYMENT_MULTIPLIER := 0.80


static func active_contracts() -> Array:
	return GameState.state["sales"]["activeContracts"]


# A mixed one-off's request carries a request.types line per requested type;
# a single-type request acts as its own sole line, so every reader below can
# walk one shape regardless.
static func request_lines(request: Dictionary) -> Array:
	return request["types"] if request.has("types") else [request]


static func delivered_qty(contract: Dictionary, type_id: String = "") -> int:
	var request: Dictionary = contract["request"]
	var key: String = type_id if type_id != "" else String(request.get("type", ""))
	return int(contract.get("delivered", {}).get(key, 0))


# No type_id: total remaining across every requested type. A type_id: just
# that type's own remaining (0 if the contract doesn't request it).
static func remaining_qty(contract: Dictionary, type_id: String = "") -> int:
	var total := 0
	for line in request_lines(contract["request"]):
		if type_id != "" and line["type"] != type_id:
			continue
		total += maxi(0, int(line["qty"]) - delivered_qty(contract, line["type"]))
	return total


static func is_complete(contract: Dictionary) -> bool:
	return remaining_qty(contract) == 0


# Any contact holding the Sales role. A founder draws no daily wage; an
# Operations Room hire counts only once today's wage is paid.
static func has_staffed_sales() -> bool:
	for contact_id in Contacts.contacts_in_role("sales"):
		if Payroll.is_working(contact_id):
			return true
	return false


# Delegation is a per-contract assignment, not a second stock pool. It may
# remain configured while Operations is vacant; only a staffed Sales contact
# can execute it.
static func set_delegated(contract_id: String, delegated: bool) -> Dictionary:
	var contract := _find_active(contract_id)
	if contract.is_empty():
		return { "ok": false, "reason": "Contract not found." }
	contract["delegated"] = delegated
	EventBus.state_changed.emit()
	if delegated:
		shared_stock_increased()
	return { "ok": true, "delegated": delegated }


# business-spec.md: a mixed contract needs every one of its lines
# independently covered (one ore/item pool can never stand in for another),
# not an aggregate sum of shared stock across unrelated types.
static func _can_fully_deliver(contract: Dictionary) -> bool:
	for line in request_lines(contract["request"]):
		var line_remaining := remaining_qty(contract, line["type"])
		if line_remaining > 0 and _shared_stock_for_line(line) < line_remaining:
			return false
	return true


# Called after a shared-stock increase. Sales only closes fully fundable
# delegated periods here; partial delivery is deliberately daily-only.
static func shared_stock_increased() -> void:
	if not has_staffed_sales():
		return
	for contract in active_contracts().duplicate():
		if not contract.get("delegated", false):
			continue
		if not _can_fully_deliver(contract):
			continue
		_deliver_delegated(contract)


# Daily Sales pass: close every fully-funded period first, then spend any
# remaining shared stock on partials in priority order. The second loop
# needs no manual per-contract cap: _deliver_delegated's uncapped qty already
# caps each requested type by its own shared stock ("Sales has no delivery-cap limit").
static func process_delegated_deliveries() -> void:
	if not has_staffed_sales():
		return
	for contract in active_contracts().duplicate():
		if contract.get("delegated", false) and _can_fully_deliver(contract):
			_deliver_delegated(contract)
	for contract in active_contracts().duplicate():
		if not contract.get("delegated", false):
			continue
		_deliver_delegated(contract)


# The only stock-mutating delivery entry point (_deliver_delegated calls it
# with manual=false). qty is a TOTAL cap across every requested type,
# spent against request_lines() in order -- one type's remaining need is
# filled (capped by its own shared stock) before the next gets any leftover
# budget. Per business-spec.md §Fulfilment and settlement, delivery costs no
# time, and a delivery that leaves nothing remaining settles the period at
# once through settle(), so the due-day tick never sees that period again.
static func deliver(contract_id: String, qty: int, manual: bool = true) -> Dictionary:
	var contract := _find_active(contract_id)
	if contract.is_empty():
		return { "ok": false, "reason": "Contract not found." }
	if contract.get("delegated", false) and manual:
		return { "ok": false, "reason": "Delegated contracts cannot be delivered manually." }
	if qty <= 0:
		return { "ok": false, "reason": "Choose a quantity." }
	var budget := qty
	var delivered_total := 0
	var delivered: Dictionary = contract["delivered"]
	for line in request_lines(contract["request"]):
		if budget <= 0:
			break
		var line_remaining := remaining_qty(contract, line["type"])
		if line_remaining <= 0:
			continue
		var take := mini(mini(budget, line_remaining), _shared_stock_for_line(line))
		if take <= 0:
			continue
		_remove_shared_stock_for_line(line, take)
		delivered[line["type"]] = int(delivered.get(line["type"], 0)) + take
		delivered_total += take
		budget -= take
	if delivered_total <= 0:
		return { "ok": false, "reason": "No shared stock available." }
	if not is_complete(contract):
		EventBus.state_changed.emit()
		return { "ok": true, "delivered": delivered_total, "complete": false }
	var settled := settle(contract_id)
	return { "ok": true, "delivered": delivered_total, "complete": true, "settlement": settled.get("settlement", {}) }


static func reorder(contract_id: String, destination_index: int) -> bool:
	var order: Array = GameState.state["sales"]["priorityOrder"]
	if not order.has(contract_id):
		return false
	order.erase(contract_id)
	order.insert(clampi(destination_index, 0, order.size()), contract_id)
	_sort_active_to_priority()
	EventBus.state_changed.emit()
	return true


static func daily_tick() -> void:
	# Iterate a copy: one-off settlement removes entries, recurring settlement
	# renews its period in place.
	for contract in active_contracts().duplicate():
		if int(contract["dueDay"]) <= int(GameState.state["world"]["day"]):
			settle(contract["id"])



static func settle(contract_id: String) -> Dictionary:
	var contract := _find_active(contract_id)
	if contract.is_empty():
		return { "ok": false, "reason": "Contract not found." }
	var sales: Dictionary = GameState.state["sales"]
	var settlement_id := "settlement-%d" % int(sales["nextSettlementId"])
	# A persisted record is the idempotency receipt. It is appended before any
	# cash mutation, so a resumed/retried operation cannot pay twice.
	if _has_settlement(settlement_id):
		return { "ok": false, "reason": "Period already settled." }
	var complete := is_complete(contract)
	var proportion := _delivered_proportion(contract)
	var payment: int = int(contract["quote"]["payment"])
	if not complete:
		payment = GameState.round_epsilon(float(payment) * proportion * PARTIAL_PAYMENT_MULTIPLIER)
	var settlement := {
		"id": settlement_id, "contractId": contract["id"], "periodId": contract["periodId"],
		"day": GameState.state["world"]["day"], "payment": payment,
		"complete": complete, "delivered": contract["delivered"].duplicate(true),
	}
	sales["nextSettlementId"] += 1
	sales["settlements"].append(settlement)
	sales["contractHistory"].append({ "contract": contract.duplicate(true), "settlement": settlement.duplicate(true) })
	# Routed by the day it settles: the business pot while active, else the
	# player (R§3.10 "Business pot and payday").
	if payment > 0 and Business.is_pot_active():
		Business.receive(payment)
	elif payment > 0:
		GameState.state["player"]["cash"] += payment
		Bank.record(payment, "Contract settlement")
	if contract.get("delegated", false):
		_award_sales_xp(COMPLETE_XP if complete else PARTIAL_XP)
	if contract["contractType"] == "recurring":
		contract["periodId"] = "period-%d" % int(sales["nextPeriodId"])
		sales["nextPeriodId"] += 1
		contract["dueDay"] = int(contract["dueDay"]) + 7
		contract["delivered"] = {}
	else:
		active_contracts().erase(contract)
		sales["priorityOrder"].erase(contract_id)
		BusinessQuest.note_starter_closed(contract.get("templateId", ""), complete)
	# A complete settlement can meet a contract-count objective (Beat 2).
	Objectives.refresh()
	BusinessQuest.maybe_trigger_owen_intro()
	EventBus.state_changed.emit()
	return { "ok": true, "settlement": settlement }


static func _find_active(contract_id: String) -> Dictionary:
	for contract in active_contracts():
		if contract["id"] == contract_id:
			return contract
	return {}


static func _deliver_delegated(contract: Dictionary, qty: int = -1) -> void:
	var amount := remaining_qty(contract) if qty < 0 else qty
	if amount <= 0:
		return
	deliver(contract["id"], amount, false)


# Per requested-type line rather than per whole request, since a mixed
# contract's lines each draw from an independent ore/item pool.
static func _shared_stock_for_line(line: Dictionary) -> int:
	if line["kind"] == "ore":
		return int(GameState.state["player"]["orichalchum"].get(line["type"], 0))
	# Production's personal-target portion of a covered item's stock is a
	# protected buffer — Sales may only draw the contract-need portion.
	var reserved := Rooms.production_reserved_qty(line["type"])
	return maxi(0, Crafting.inventory_qty(line["type"]) - reserved)


static func _remove_shared_stock_for_line(line: Dictionary, qty: int) -> void:
	if line["kind"] == "ore":
		GameState.state["player"]["orichalchum"][line["type"]] -= qty
	else:
		Crafting.inventory_remove(line["type"], qty)


# business-spec.md "Fulfilment and settlement": delivered proportion is
# quoted-value weighted -- Σ(delivered_units × unit_value) / total_quote_value,
# via quote.lines' snapshotted per-unit values. Equivalent to a flat
# delivered/qty ratio for a single-type contract (unit_value cancels out),
# so both shapes share this one implementation.
static func _delivered_proportion(contract: Dictionary) -> float:
	var quote: Dictionary = contract["quote"]
	if not quote.has("lines"):
		# An older snapshotted quote with no "lines" key -- fall back to a
		# flat ratio rather than KeyError on an in-flight save.
		return float(delivered_qty(contract)) / float(maxi(1, int(contract["request"]["qty"])))
	var total_quote_value: int = int(quote.get("liveValue", 0))
	if total_quote_value <= 0:
		return 0.0
	var delivered_value := 0
	for line in quote["lines"]:
		delivered_value += delivered_qty(contract, line["type"]) * int(line["unitValue"])
	return float(delivered_value) / float(total_quote_value)


static func _has_settlement(settlement_id: String) -> bool:
	for settlement in GameState.state["sales"]["settlements"]:
		if settlement["id"] == settlement_id:
			return true
	return false


static func _award_sales_xp(amount: int) -> void:
	var contact_id: Variant = Contacts.sales_contact()
	if contact_id != null:
		Contacts.award_contact_xp(contact_id, "sales", amount)


static func _sort_active_to_priority() -> void:
	var order: Array = GameState.state["sales"]["priorityOrder"]
	active_contracts().sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return order.find(a["id"]) < order.find(b["id"])
	)
