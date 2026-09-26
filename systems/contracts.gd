class_name Contracts
extends RefCounted

# Sales contract periods. This is deliberately separate from Offers: offers
# establish a quote; this system owns delivery, ordering, and settlement.

const COMPLETE_XP := 20
const PARTIAL_XP := 10
const PARTIAL_PAYMENT_MULTIPLIER := 0.80
# Beat 7's delegation unlock; a period only qualifies once it is set.
const DELEGATION_FLAG := "bizA1DelegationUnlocked"


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


static func delegation_unlocked() -> bool:
	return GameState.state["flags"].get(DELEGATION_FLAG, false)


# Delegation is a per-contract assignment, not a second stock pool. It may
# remain configured while Operations is vacant; only a staffed Sales contact
# can execute it. Turning it on needs the Beat 7 flag; turning it off never does.
static func set_delegated(contract_id: String, delegated: bool) -> Dictionary:
	var contract := _find_active(contract_id)
	if contract.is_empty():
		return { "ok": false, "reason": "Contract not found." }
	if delegated and not delegation_unlocked():
		return { "ok": false, "reason": "Delegation isn't unlocked yet." }
	contract["delegated"] = delegated
	# Delegating on the period's first day still covers the whole period.
	if not delegated:
		contract["delegatedWholePeriod"] = false
	elif int(contract.get("periodStartDay", -1)) == int(GameState.state["world"]["day"]):
		contract["delegatedWholePeriod"] = true
	EventBus.state_changed.emit()
	if delegated:
		shared_stock_increased()
	return { "ok": true, "delegated": delegated }


# Per-contract Sales calc purchasing (R§3.10 "Calc purchases"): when set, the
# daily Sales pass buys this contract's calc shortfall from the pot.
static func set_buy_calc(contract_id: String, enabled: bool) -> Dictionary:
	var contract := _find_active(contract_id)
	if contract.is_empty():
		return { "ok": false, "reason": "Contract not found." }
	contract["buyCalc"] = enabled
	EventBus.state_changed.emit()
	return { "ok": true, "buyCalc": enabled }


# R§3.10 "Unattended proof": every period starts untainted, and counts as
# delegated throughout only if delegation is already on at its start.
static func start_period(contract: Dictionary) -> void:
	contract["periodStartDay"] = int(GameState.state["world"]["day"])
	contract["playerAssisted"] = false
	contract["delegatedWholePeriod"] = contract.get("delegated", false)


# The player put the requested type into play (crafted, unstashed or bought
# it): every active period requesting that type counts as player-assisted.
static func note_player_supplied(type_id: String) -> void:
	for contract in active_contracts():
		for line in request_lines(contract["request"]):
			if line["type"] == type_id:
				contract["playerAssisted"] = true


# The player cultivated or pruned a vein: taints every active period when
# the vein sits on any cultivator's list.
static func note_player_tended_vein(vein_id: String) -> void:
	if Rooms.cultivator_of(vein_id) == null:
		return
	for contract in active_contracts():
		contract["playerAssisted"] = true


static func _period_qualifies(contract: Dictionary, complete: bool) -> bool:
	return contract["contractType"] == "recurring" and complete \
		and contract.get("delegated", false) \
		and contract.get("delegatedWholePeriod", contract.get("delegated", false)) \
		and not contract.get("playerAssisted", false) \
		and GameState.state["flags"].get(DELEGATION_FLAG, false)


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
	_buy_calc_shortfalls()
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
	if manual:
		contract["playerAssisted"] = true
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
		"qualified": _period_qualifies(contract, complete),
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
		start_period(contract)
	else:
		active_contracts().erase(contract)
		sales["priorityOrder"].erase(contract_id)
		BusinessQuest.note_starter_closed(contract.get("templateId", ""), complete)
	# A complete settlement can meet a contract-count objective (Beat 2), the
	# first Time Pearl period (Beat 6) or the recurring proof (Beat 7).
	Objectives.refresh()
	BusinessQuest.maybe_trigger_owen_intro()
	BusinessQuest.maybe_trigger_put_to_work()
	BusinessQuest.note_proof_met()
	EventBus.state_changed.emit()
	return { "ok": true, "settlement": settlement }


# Delegated buyCalc contracts in priority order. Each contract's calc need
# claims shared stock before the next contract counts it, so two contracts
# never both count the same ore as on hand.
static func _buy_calc_shortfalls() -> void:
	if not Business.is_pot_active():
		return
	var claimed: Dictionary = {}
	for contract in active_contracts().duplicate():
		if not contract.get("delegated", false) or not contract.get("buyCalc", false):
			continue
		var need := calc_need(contract)
		for ore_type in need:
			var on_hand: int = int(GameState.state["player"]["orichalchum"].get(ore_type, 0)) - int(claimed.get(ore_type, 0))
			var shortfall: int = int(need[ore_type]) - maxi(0, on_hand)
			claimed[ore_type] = int(claimed.get(ore_type, 0)) + int(need[ore_type])
			if shortfall > 0:
				_buy_calc(contract["id"], ore_type, shortfall)


# The calc a contract still needs, by ore type: an ore line's remaining qty;
# a crafted line's remaining units × the lowest-cost working producer's
# per-unit calc cost (nothing when no producer is working).
static func calc_need(contract: Dictionary) -> Dictionary:
	var need: Dictionary = {}
	for line in request_lines(contract["request"]):
		var remaining := remaining_qty(contract, line["type"])
		if remaining <= 0:
			continue
		if line["kind"] == "ore":
			need[line["type"]] = int(need.get(line["type"], 0)) + remaining
			continue
		var costs := _lowest_producer_cost(line["type"])
		for ore_type in costs:
			need[ore_type] = int(need.get(ore_type, 0)) + remaining * int(costs[ore_type])
	return need


static func _lowest_producer_cost(recipe_key: String) -> Dictionary:
	var best: Dictionary = {}
	var best_total := -1
	for contact_id in Contacts.contacts_in_role("production"):
		if not Payroll.is_working(contact_id):
			continue
		var skill: int = GameState.state["contacts"][contact_id].get("craftingSkill", 1)
		var costs: Dictionary = Crafting.calc_cost(recipe_key, skill)
		var total := 0
		for ore_type in costs:
			total += int(costs[ore_type])
		if best_total < 0 or total < best_total:
			best = costs
			best_total = total
	return best


# Every ore lane the player can buy from right now, cheapest first, ties to
# faction trade data order. Priced without any district modifier.
static func calc_sources(ore_type: String) -> Array:
	var sources: Array = []
	var lane_index := 0
	for faction_id in GameData.FACTION_TRADE:
		if Economy.can_buy_from_faction(faction_id):
			sources.append({
				"factionId": faction_id, "order": lane_index,
				"price": Economy.get_faction_buy_price(faction_id, "ore", ore_type, false),
			})
		lane_index += 1
	sources.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["price"] != b["price"]:
			return a["price"] < b["price"]
		return a["order"] < b["order"]
	)
	return sources


# Buys qty of one ore for one contract, spilling to the next-cheapest lane
# when a lane runs dry. The whole purchase is paid from the pot or skipped.
static func _buy_calc(contract_id: String, ore_type: String, qty: int) -> void:
	var legs: Array = []
	var left := qty
	for source in calc_sources(ore_type):
		if left <= 0:
			break
		var price: int = source["price"]
		var take := mini(left, Economy.get_faction_buy_max_qty(source["factionId"], "ore", ore_type, price * left, false))
		if take <= 0:
			continue
		legs.append({
			"factionId": source["factionId"], "source": String(GameData.FACTIONS[source["factionId"]]["name"]),
			"oreType": ore_type, "qty": take, "amount": price * take,
		})
		left -= take
	if legs.is_empty() or not Business.pay_calc_purchase(contract_id, legs):
		return
	for leg in legs:
		Economy.receive_faction_ore(leg["factionId"], ore_type, int(leg["qty"]))


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
