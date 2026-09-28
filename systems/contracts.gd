class_name Contracts
extends RefCounted

# Sales contract periods. This is deliberately separate from Offers: offers
# establish a quote; this system owns delivery, ordering, and settlement.

const COMPLETE_XP := 20
const PARTIAL_XP := 10
const PARTIAL_PAYMENT_MULTIPLIER := 0.80
# Set by Beat 7's scene; a period only qualifies once it is set.
const PROOF_FLAG := "bizA1DelegationUnlocked"


static func active_contracts() -> Array:
	return GameState.state["sales"]["activeContracts"]


# A mixed one-off's request carries a request.types line per requested type;
# a single-type request acts as its own sole line, so every reader below can
# walk one shape regardless.
static func request_lines(request: Dictionary) -> Array:
	return request["types"] if request.has("types") else [request]


# The ore types a request asks for, in canonical ore order: an ore line's
# own type; a crafted line's recipe ingredient types.
static func request_ore_types(request: Dictionary) -> Array[String]:
	var wanted: Dictionary = {}
	for line in request_lines(request):
		if line["kind"] == "ore":
			wanted[line["type"]] = true
			continue
		for ore_type in GameData.RECIPES[line["type"]]["ingredients"]:
			wanted[ore_type] = true
	var ordered: Array[String] = []
	for ore_type in GameData.CANONICAL_ORE_TYPES:
		if wanted.has(ore_type):
			ordered.append(ore_type)
	return ordered


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


# A recurring period that was filled and paid; deliveries stay locked until
# the next Monday rollover opens a fresh period.
static func is_period_filled(contract: Dictionary) -> bool:
	return contract.get("periodFilled", false)


# Any contact holding the Sales role. A founder draws no room wage; an
# Operations Room hire counts only while this week's wage is paid.
static func has_staffed_sales() -> bool:
	for contact_id in Contacts.contacts_in_role("sales"):
		if Payroll.is_working(contact_id):
			return true
	return false


# Per-contract Sales calc purchasing (R§3.10 "Calc purchases"): when set, the
# daily Sales pass buys this contract's calc shortfall from the pot.
static func set_buy_calc(contract_id: String, enabled: bool) -> Dictionary:
	var contract := _find_active(contract_id)
	if contract.is_empty():
		return { "ok": false, "reason": "Contract not found." }
	contract["buyCalc"] = enabled
	EventBus.state_changed.emit()
	return { "ok": true, "buyCalc": enabled }


# R§3.10 "Unattended proof": every period starts untainted.
static func start_period(contract: Dictionary) -> void:
	contract["periodStartDay"] = int(GameState.state["world"]["day"])
	contract["playerAssisted"] = false


# R§3.10 "Term": a recurring contract runs offers.json termWeeks from
# start_day and expires on the first Monday on or after its end.
static func start_term(contract: Dictionary, start_day: int) -> void:
	var term_weeks: int = GameData.OFFER_TERM_WEEKS
	contract["startDay"] = start_day
	contract["termWeeks"] = term_weeks
	contract["expiryDay"] = Calendar.monday_on_or_after(start_day + term_weeks * Calendar.days_per_week())


# The period due now is the term's last: it settles, then the contract expires.
static func _term_ended(contract: Dictionary) -> bool:
	return contract.has("expiryDay") and int(contract["dueDay"]) >= int(contract["expiryDay"])


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
		and not contract.get("playerAssisted", false) \
		and GameState.state["flags"].get(PROOF_FLAG, false)


# business-spec.md: a mixed contract needs every one of its lines
# independently covered (one ore/item pool can never stand in for another),
# not an aggregate sum of shared stock across unrelated types.
static func _can_fully_deliver(contract: Dictionary) -> bool:
	for line in request_lines(contract["request"]):
		var line_remaining := remaining_qty(contract, line["type"])
		if line_remaining > 0 and _shared_stock_for_line(line) < line_remaining:
			return false
	return true


# R§3.10 "Sales delivery": at the end of every time block's staff step, a
# working Sales contact closes every fully-coverable period first, then
# spends remaining shared stock on partials in priority order. Stock added
# mid-block waits for this pass, so the player can stash it first.
static func process_sales_deliveries() -> void:
	if not has_staffed_sales():
		return
	for contract in active_contracts().duplicate():
		if _can_fully_deliver(contract):
			_deliver(contract)
	for contract in active_contracts().duplicate():
		_deliver(contract)


# Daily Sales pass (rollover ⑥.3): buy flagged calc shortfalls, then deliver.
static func process_daily_sales() -> void:
	if not has_staffed_sales():
		return
	_buy_calc_shortfalls()
	process_sales_deliveries()


# The only stock-mutating delivery path. Fills each requested line in
# request_lines() order, capped by its own shared stock. Per business-spec.md
# §Fulfilment and settlement, a delivery that leaves nothing remaining
# settles the period at once through settle(), so the due-day tick never
# sees that period again.
static func _deliver(contract: Dictionary) -> void:
	if is_period_filled(contract):
		return
	var delivered_total := 0
	var delivered: Dictionary = contract["delivered"]
	for line in request_lines(contract["request"]):
		var take := mini(remaining_qty(contract, line["type"]), _shared_stock_for_line(line))
		if take <= 0:
			continue
		var tiers := _remove_shared_stock_for_line(line, take)
		delivered[line["type"]] = int(delivered.get(line["type"], 0)) + take
		delivered_total += take
		var counterparty := Offers.ensure_counterparty(contract)
		Market.note_contract_delivery(counterparty, line["kind"], line["type"], take)
		_credit_buyer(counterparty, line, take, tiers)
	if delivered_total <= 0:
		return
	if is_complete(contract):
		settle(contract["id"])
	else:
		EventBus.state_changed.emit()


static func reorder(contract_id: String, destination_index: int) -> bool:
	var order: Array = GameState.state["sales"]["priorityOrder"]
	if not order.has(contract_id):
		return false
	order.erase(contract_id)
	order.insert(clampi(destination_index, 0, order.size()), contract_id)
	_sort_active_to_priority()
	EventBus.state_changed.emit()
	return true


# Ends a one-off or recurring contract now: no payment, no refund of ore
# already delivered. Its history entry carries "cancelledDay" and no
# "settlement", so no settlement-reading objective counts it. A quest
# starter/recurring contract is reissued as if its offer were declined.
# The counterparty alone loses cancelRelationHit relation (R§3.10 "Cancel").
static func cancel(contract_id: String) -> Dictionary:
	var contract := _find_active(contract_id)
	if contract.is_empty():
		return { "ok": false, "reason": "Contract not found." }
	Factions.adjust_player_relation(Offers.ensure_counterparty(contract), -int(GameData.OFFER_COUNTERPARTY["cancelRelationHit"]))
	var sales: Dictionary = GameState.state["sales"]
	active_contracts().erase(contract)
	sales["priorityOrder"].erase(contract_id)
	var record := contract.duplicate(true)
	record["status"] = "cancelled"
	sales["contractHistory"].append({ "contract": record, "cancelledDay": GameState.state["world"]["day"] })
	var template_id: String = contract.get("templateId", "")
	BusinessQuest.note_starter_closed(template_id, false)
	BusinessQuest.note_recurring_closed(template_id)
	EventBus.state_changed.emit()
	return { "ok": true }


static func is_cancelled(history_entry: Dictionary) -> bool:
	return not history_entry.has("settlement")


static func daily_tick() -> void:
	# Iterate a copy: one-off settlement removes entries, recurring settlement
	# renews its period in place. A filled period was already paid, so its
	# due day only opens the next one. Fresh periods wait for the next
	# block's Sales pass.
	for contract in active_contracts().duplicate():
		if int(contract["dueDay"]) > int(GameState.state["world"]["day"]):
			continue
		if is_period_filled(contract):
			_close_period(contract)
			EventBus.state_changed.emit()
		else:
			settle(contract["id"])


static func settle(contract_id: String) -> Dictionary:
	var contract := _find_active(contract_id)
	if contract.is_empty():
		return { "ok": false, "reason": "Contract not found." }
	var sales: Dictionary = GameState.state["sales"]
	var settlement_id := "settlement-%d" % int(sales["nextSettlementId"])
	# A persisted record is the idempotency receipt. It is appended before any
	# cash mutation, so a resumed/retried operation cannot pay twice.
	if _has_settlement(settlement_id) or is_period_filled(contract):
		return { "ok": false, "reason": "Period already settled." }
	var complete := is_complete(contract)
	var proportion := _delivered_proportion(contract)
	var payment: int = int(contract["signedQuote"]["payment"])
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
	if not contract["delivered"].is_empty():
		_award_sales_xp(COMPLETE_XP if complete else PARTIAL_XP)
	# A recurring period filled before its due day pays now and locks until
	# that Monday; one reaching its due day (filled or not) renews or, at the
	# term's end, expires at once.
	if contract["contractType"] == "recurring":
		if complete and int(contract["dueDay"]) > int(GameState.state["world"]["day"]):
			contract["periodFilled"] = true
		else:
			_close_period(contract)
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


# buyCalc contracts in priority order. Each contract's calc need
# claims shared stock before the next contract counts it, so two contracts
# never both count the same ore as on hand.
static func _buy_calc_shortfalls() -> void:
	if not Business.is_pot_active():
		return
	var claimed: Dictionary = {}
	for contract in active_contracts().duplicate():
		if not contract.get("buyCalc", false):
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
		var take := mini(left, Economy.get_faction_buy_max_qty(source["factionId"], "ore", ore_type, Market.line_total("ore", price, left), false))
		if take <= 0:
			continue
		legs.append({
			"factionId": source["factionId"], "source": String(GameData.FACTIONS[source["factionId"]]["name"]),
			"oreType": ore_type, "qty": take, "amount": Market.line_total("ore", price, take),
		})
		left -= take
	if legs.is_empty() or not Business.pay_calc_purchase(contract_id, legs):
		return
	for leg in legs:
		GameState.state["factions"][leg["factionId"]]["resources"] += int(leg["amount"])
		Economy.receive_faction_ore(leg["factionId"], ore_type, int(leg["qty"]))
		Market.record_demand("ore", ore_type, int(leg["qty"]), "player")


# A recurring contract's due-day close, once its period is paid.
static func _close_period(contract: Dictionary) -> void:
	if _term_ended(contract):
		_expire(contract)
	else:
		_renew_period(contract)


# R§3.10 "Term": the contract leaves active; its last history entry (the
# final period's settlement) is marked expired, and a renewal offer issues.
static func _expire(contract: Dictionary) -> void:
	var sales: Dictionary = GameState.state["sales"]
	active_contracts().erase(contract)
	sales["priorityOrder"].erase(contract["id"])
	contract["status"] = "expired"
	var history: Array = sales["contractHistory"]
	for index in range(history.size() - 1, -1, -1):
		var entry: Dictionary = history[index]
		if entry["contract"]["id"] == contract["id"]:
			entry["contract"]["status"] = "expired"
			entry["expiredDay"] = GameState.state["world"]["day"]
			break
	Offers.create_renewal_offer(contract)


static func is_expired(history_entry: Dictionary) -> bool:
	return history_entry.has("expiredDay")


# A contract with no term (an older save) gains one at this renewal.
static func _renew_period(contract: Dictionary) -> void:
	if not contract.has("expiryDay"):
		start_term(contract, int(contract["dueDay"]))
	var sales: Dictionary = GameState.state["sales"]
	contract["periodId"] = "period-%d" % int(sales["nextPeriodId"])
	sales["nextPeriodId"] += 1
	contract["dueDay"] = int(contract["dueDay"]) + Calendar.days_per_week()
	contract["delivered"] = {}
	contract["periodFilled"] = false
	start_period(contract)


static func _find_active(contract_id: String) -> Dictionary:
	for contract in active_contracts():
		if contract["id"] == contract_id:
			return contract
	return {}


# Per requested-type line rather than per whole request, since a mixed
# contract's lines each draw from an independent ore/item pool.
static func _shared_stock_for_line(line: Dictionary) -> int:
	if line["kind"] == "ore":
		return int(GameState.state["player"]["orichalchum"].get(line["type"], 0))
	# Production's personal-target portion of a covered item's stock is a
	# protected buffer — Sales may only draw the contract-need portion.
	var reserved := Rooms.production_reserved_qty(line["type"])
	return maxi(0, Crafting.inventory_qty(line["type"]) - reserved)


# Returns the item tiers taken from stock ([{ tier, qty }]); empty for ore.
static func _remove_shared_stock_for_line(line: Dictionary, qty: int) -> Array:
	if line["kind"] == "ore":
		GameState.state["player"]["orichalchum"][line["type"]] -= qty
		return []
	return Crafting.inventory_remove(line["type"], qty)


# R§3.10 "Delivery hook": the delivered goods land in the buyer faction's
# holdings (items at the tiers the player gave up) and credit the player's
# supplier share with it. No Market supply, no ore/crafting share.
static func _credit_buyer(counterparty: String, line: Dictionary, qty: int, tiers: Array) -> void:
	if not GameState.state["factions"].has(counterparty):
		return
	if line["kind"] == "ore":
		FactionSim.add_ore(counterparty, line["type"], qty)
	else:
		for part in tiers:
			FactionSim.add_item(counterparty, line["type"], int(part["tier"]), int(part["qty"]))
	Shares.record_delivery(counterparty, Shares.ore_equivalent(line["kind"], line["type"], qty))


# business-spec.md "Fulfilment and settlement": delivered proportion is
# quoted-value weighted -- Σ(delivered_units × unit_value) / total_quote_value,
# via quote.lines' snapshotted per-unit values. Equivalent to a flat
# delivered/qty ratio for a single-type contract (unit_value cancels out),
# so both shapes share this one implementation.
static func _delivered_proportion(contract: Dictionary) -> float:
	var quote: Dictionary = contract["signedQuote"]
	if not quote.has("lines"):
		# An older snapshotted quote with no "lines" key -- fall back to a
		# flat ratio rather than KeyError on an in-flight save.
		return float(delivered_qty(contract)) / float(maxi(1, int(contract["request"]["qty"])))
	var total_quote_value: int = int(quote.get("liveValue", 0))
	if total_quote_value <= 0:
		return 0.0
	var delivered_value := 0
	for line in quote["lines"]:
		delivered_value += Market.line_total(line["kind"], int(line["unitValue"]), delivered_qty(contract, line["type"]))
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
