class_name Contracts
extends RefCounted

# Sales contract periods. This is deliberately separate from Offers: offers
# establish a quote; this system owns delivery, ordering, and settlement.

const COMPLETE_XP := 20
const PARTIAL_XP := 10
const PARTIAL_PAYMENT_MULTIPLIER := 0.80


static func active_contracts() -> Array:
	return GameState.state["sales"]["activeContracts"]


static func delivered_qty(contract: Dictionary) -> int:
	var request: Dictionary = contract["request"]
	return int(contract.get("delivered", {}).get(request["type"], 0))


static func remaining_qty(contract: Dictionary) -> int:
	return maxi(0, int(contract["request"]["qty"]) - delivered_qty(contract))


static func is_complete(contract: Dictionary) -> bool:
	return remaining_qty(contract) == 0


# ticket 28: "staffed" also requires today's Sales wage to have actually been
# paid -- an unpaid role does no work for the rest of the rollover (both this
# same-day real-time recheck and the daily partial-delivery pass below),
# gated via Payroll.is_paid_today() rather than a second parallel flag.
static func has_staffed_sales() -> bool:
	return Contacts.get_contact_in_room("ops") != null and Payroll.is_paid_today("ops")


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


# Called after a shared-stock increase. Sales only closes fully fundable
# delegated periods here; partial delivery is deliberately daily-only.
static func shared_stock_increased() -> void:
	if not has_staffed_sales():
		return
	for contract in active_contracts().duplicate():
		if not contract.get("delegated", false):
			continue
		if _shared_stock(contract["request"]) < remaining_qty(contract):
			continue
		_deliver_delegated(contract)


# Daily Sales pass: first close every fully-funded period, then spend any
# remaining shared stock on partials in the same persisted priority order.
static func process_delegated_deliveries() -> void:
	if not has_staffed_sales():
		return
	for contract in active_contracts().duplicate():
		if contract.get("delegated", false) and _shared_stock(contract["request"]) >= remaining_qty(contract):
			_deliver_delegated(contract)
	for contract in active_contracts().duplicate():
		if not contract.get("delegated", false):
			continue
		var available := _shared_stock(contract["request"])
		if available > 0:
			_deliver_delegated(contract, mini(available, remaining_qty(contract)))


# The only stock-mutating delivery entry point. Ticket 26 calls this too,
# with consume_time=false after it has chosen a delegated contract.
static func deliver(contract_id: String, qty: int, consume_time: bool = true) -> Dictionary:
	var contract := _find_active(contract_id)
	if contract.is_empty():
		return { "ok": false, "reason": "Contract not found." }
	if contract.get("delegated", false) and consume_time:
		return { "ok": false, "reason": "Delegated contracts cannot be delivered manually." }
	if qty <= 0:
		return { "ok": false, "reason": "Choose a quantity." }
	var request: Dictionary = contract["request"]
	var take := mini(mini(qty, remaining_qty(contract)), _shared_stock(request))
	if take <= 0:
		return { "ok": false, "reason": "No shared stock available." }
	_remove_shared_stock(request, take)
	var delivered: Dictionary = contract["delivered"]
	delivered[request["type"]] = int(delivered.get(request["type"], 0)) + take
	EventBus.state_changed.emit()
	if consume_time:
		TimeSystem.advance_time_block()
	return { "ok": true, "delivered": take, "complete": is_complete(contract) }


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
	var proportion := float(delivered_qty(contract)) / float(maxi(1, int(contract["request"]["qty"])))
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
	if payment > 0:
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
	var result := deliver(contract["id"], amount, false)
	if result.get("ok", false) and result.get("complete", false):
		settle(contract["id"])


static func _shared_stock(request: Dictionary) -> int:
	if request["kind"] == "ore":
		return int(GameState.state["player"]["orichalchum"].get(request["type"], 0))
	return Crafting.inventory_qty(request["type"])


static func _remove_shared_stock(request: Dictionary, qty: int) -> void:
	if request["kind"] == "ore":
		GameState.state["player"]["orichalchum"][request["type"]] -= qty
	else:
		Crafting.inventory_remove(request["type"], qty)


static func _has_settlement(settlement_id: String) -> bool:
	for settlement in GameState.state["sales"]["settlements"]:
		if settlement["id"] == settlement_id:
			return true
	return false


static func _award_sales_xp(amount: int) -> void:
	var contact_id: Variant = Contacts.get_contact_in_room("ops")
	if contact_id != null:
		Contacts.award_contact_xp(contact_id, "sales", amount)


static func _sort_active_to_priority() -> void:
	var order: Array = GameState.state["sales"]["priorityOrder"]
	active_contracts().sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return order.find(a["id"]) < order.find(b["id"])
	)
