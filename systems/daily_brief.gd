class_name DailyBrief
extends RefCounted

# BizBrief's Today card (.scratch/bizbrief-today/spec.md): a pure projection
# of the day's plan over GameState; mark_acted() is its only state write.
# Each row is plain data; `action` is a destination descriptor BizBrief
# routes through existing navigation. Tiers, templates and labels live in
# data/daily_brief.json.

const BADGE_TIERS := ["urgent", "story"]


# Ordered rows: fixed tier order, then `sort` (lower = sooner), then source
# order.
static func items() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	_alarm_rows(rows)
	_guard_shortfall_rows(rows)
	_bill_rows(rows)
	_arrears_rows(rows)
	_wage_rows(rows)
	_poach_rows(rows)
	_contract_at_risk_rows(rows)
	_vein_at_risk_rows(rows)
	_story_rows(rows)
	_rent_goal_rows(rows)
	_deposit_goal_rows(rows)
	_offer_expiring_rows(rows)
	_demand_spike_rows(rows)
	_favour_rows(rows)
	_development_rows(rows)
	_idle_staff_rows(rows)
	_ore_short_rows(rows)
	var tiers: Array = GameData.DAILY_BRIEF["tierOrder"]
	var order: Array = range(rows.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		var tier_a: int = tiers.find(rows[a]["tier"])
		var tier_b: int = tiers.find(rows[b]["tier"])
		if tier_a != tier_b:
			return tier_a < tier_b
		if rows[a]["sort"] != rows[b]["sort"]:
			return rows[a]["sort"] < rows[b]["sort"]
		return a < b
	)
	var ordered: Array[Dictionary] = []
	for i in order:
		ordered.append(rows[i])
	return ordered


# Records a row's key as acted on today (morningAccounts.briefTicks, cleared
# at rollover). A ticked row shows `done` while its condition still holds.
static func mark_acted(key: String) -> void:
	var ticks: Array = GameState.state["morningAccounts"]["briefTicks"]
	if ticks.has(key):
		return
	ticks.append(key)
	EventBus.state_changed.emit()


# Urgent + Story rows: what the Phone home BizBrief badge counts.
static func badge_count() -> int:
	return items().filter(func(row: Dictionary): return BADGE_TIERS.has(row["tier"])).size()


# Card header data: date label, time blocks left today, card rows per tier
# (a summary row counts once).
static func summary() -> Dictionary:
	var counts := {}
	for tier in GameData.DAILY_BRIEF["tierOrder"]:
		counts[tier] = 0
	var shown := card()
	for row in shown["visible"] + shown["hidden"]:
		counts[row["tier"]] += 1
	return {
		"dateLabel": Calendar.widget_date(int(GameState.state["world"]["day"])),
		"blocksLeft": TimeSystem.blocks_left(),
		"counts": counts,
	}


static func empty_text() -> String:
	return GameData.DAILY_BRIEF["emptyState"]


# What the Today card shows: every non-Routine row in order, two or more
# demandSpike rows folded into one demandSummary row where the first stood,
# then one routineSummary row when any Routine rows exist (a summary's
# `children` are its rows); `visible` is the first rowCap of those, `hidden`
# the rest, `more` its size.
static func card() -> Dictionary:
	var shown: Array[Dictionary] = []
	var routine: Array[Dictionary] = []
	var demand: Array[Dictionary] = []
	var demand_at := -1
	for row in items():
		if row["tier"] == "routine":
			routine.append(row)
			continue
		if row["kind"] == "demandSpike":
			if demand.is_empty():
				demand_at = shown.size()
				shown.append(row)
			demand.append(row)
			continue
		shown.append(row)
	if demand.size() > 1:
		shown[demand_at] = _demand_summary(demand)
	if not routine.is_empty():
		shown.append(_routine_summary(routine))
	var cap: int = GameData.DAILY_BRIEF["rowCap"]
	return { "visible": shown.slice(0, cap), "hidden": shown.slice(cap), "more": maxi(0, shown.size() - cap) }


# One row counting the Routine rows by kind, in data routineParts order.
static func _routine_summary(routine: Array[Dictionary]) -> Dictionary:
	var by_kind := {}
	for row in routine:
		by_kind[row["kind"]] = by_kind.get(row["kind"], 0) + 1
	var parts: Array[String] = []
	var part_templates: Dictionary = GameData.DAILY_BRIEF["routineParts"]
	for kind in part_templates:
		if by_kind.has(kind):
			parts.append(String(part_templates[kind]).format({ "n": by_kind[kind] }))
	var row := _row("routineSummary", "routine", { "count": routine.size(), "parts": " · ".join(parts) }, { "to": "routine" }, 0)
	row["children"] = routine
	return row


# One row naming each qualifying good and its lift; done once every
# demandSpike row under it is.
static func _demand_summary(demand: Array[Dictionary]) -> Dictionary:
	var part_template := String(GameData.DAILY_BRIEF["demandPart"])
	var parts: Array[String] = []
	for row in demand:
		parts.append(part_template.format(row["values"]))
	var row := _row("demandSummary", "demand", { "count": demand.size(), "parts": " · ".join(parts) }, { "to": "demand" }, demand[0]["sort"])
	row["done"] = demand.all(func(child: Dictionary) -> bool: return child["done"])
	row["children"] = demand
	return row


static func _alarm_rows(rows: Array[Dictionary]) -> void:
	for alarm in RaidAlarms.summary_rows():
		var values := { "title": alarm["title"], "deadline": alarm["deadline"], "consequence": alarm["consequence"] }
		if alarm["kind"] == "home":
			rows.append(_row("alarmHome", "alarm:home", values, { "to": "alarms" }, 0))
		else:
			rows.append(_row("alarmVein", "alarm:%s" % alarm["veinId"], values, { "to": "alarms" }, 0))


static func _guard_shortfall_rows(rows: Array[Dictionary]) -> void:
	var shortfall: Variant = GuardUpkeep.pending_shortfall()
	if shortfall == null:
		return
	var deadline: int = shortfall["deadline"]
	var values := { "deadline": Calendar.format_day(deadline), "places": GuardUpkeep.places_text(shortfall["places"].keys()) }
	rows.append(_row("guardShortfall", "guardShortfall", values, { "to": "short_pay" }, deadline - int(GameState.state["world"]["day"])))


# The next weekly home bill, when its Monday rollover falls within
# billWindowDays and cash won't cover it.
static func _bill_rows(rows: Array[Dictionary]) -> void:
	var days_left: int = Home.next_bill_day() - int(GameState.state["world"]["day"])
	if days_left > int(GameData.DAILY_BRIEF["billWindowDays"]):
		return
	var bill := Home.weekly_bill_due()
	var cash: int = GameState.state["player"]["cash"]
	if cash >= bill:
		return
	var template_id := "billRent" if GameState.state["home"]["tenure"] == Home.TENURE_RENTED else "billUtilities"
	var values := { "bill": bill, "shortfall": bill - cash, "weekday": GameData.EVENT_LABELS["weekdayNames"][Calendar.weekday_index(Home.next_bill_day())] }
	rows.append(_row(template_id, "bill", values, { "to": "bank" }, days_left))


# Carried arrears, with the days to the next consequence from
# Home.arrears_countdown().
static func _arrears_rows(rows: Array[Dictionary]) -> void:
	var countdown := Home.arrears_countdown()
	if countdown.is_empty():
		return
	var values := { "arrears": countdown["arrears"], "countdown": " ".join(MorningAccounts.countdown_lines(countdown)) }
	# Interest already charged compounds at the next Monday rollover.
	var next_monday: int = Home.next_bill_day() - int(GameState.state["world"]["day"])
	var days := mini(int(countdown.get("interestInDays", next_monday)), int(countdown.get("downgradeInDays", next_monday)))
	rows.append(_row("arrears", "arrears", values, { "to": "property" }, days))


static func _wage_rows(rows: Array[Dictionary]) -> void:
	var prompts := Business.pending_wage_prompts()
	for contact_id in Business.owed_contact_ids():
		var values := { "name": Contacts.display_name(contact_id), "owed": Business.owed(contact_id), "topUp": Business.top_up_needed(contact_id) }
		var template_id := "wagePrompt" if prompts.has(contact_id) else "wagesOwed"
		rows.append(_row(template_id, "wages:%s" % contact_id, values, { "to": "bizbrief_staff", "contactId": contact_id }, 0))


# Unanswered poach offers on a hire (R§3.10 "Poached staff"); unmatched, the
# hire leaves at the rollover into expiresDay.
static func _poach_rows(rows: Array[Dictionary]) -> void:
	var today: int = GameState.state["world"]["day"]
	for contact_id in Hiring.pending_poach_ids():
		var pending := Hiring.pending_poach(contact_id)
		var expires: int = pending["expiresDay"]
		var values := {
			"name": Contacts.display_name(contact_id),
			"rival": Hiring.faction_name(pending["factionId"]),
			"offer": int(pending["offer"]),
			"wage": Hiring.weekly_wage(contact_id),
			"deadline": Calendar.format_day(expires),
		}
		rows.append(_row("poach", "poach:%s" % contact_id, values, { "to": "bizbrief_staff", "contactId": contact_id }, expires - today))


# Active contracts whose current period can't be met by its due day from
# stock plus reserved production (Contracts.period_shortfall). Filled periods
# are skipped; only active contracts are walked.
static func _contract_at_risk_rows(rows: Array[Dictionary]) -> void:
	var claimed := {}
	for contract in Contracts.active_contracts():
		var shortfall := Contracts.period_shortfall(contract, claimed)
		if shortfall <= 0:
			continue
		var faction: Dictionary = GameData.FACTIONS.get(contract.get("counterparty", ""), {})
		var due: int = contract["dueDay"]
		var values := {
			"buyer": faction.get("shortName", "A buyer"),
			"shortfall": shortfall,
			"deadline": Calendar.format_day(due),
		}
		rows.append(_row("contractAtRisk", "contract:%s" % contract["id"], values, { "to": "bizbrief_sales", "contractId": contract["id"] }, due - int(GameState.state["world"]["day"])))


# Veins in a data-listed low band and leaning down (growth under neutral).
# Nights come from Cultivating.days_to_wall (expected drift, no RNG); at or
# under veinCollapseNights the row is Urgent, otherwise Routine.
static func _vein_at_risk_rows(rows: Array[Dictionary]) -> void:
	var risk_bands: Array = GameData.DAILY_BRIEF["veinRiskBands"]
	var neutral: int = GameData.VEIN_GROWTH["neutral"]
	for vein in GameState.state["player"]["veins"]:
		var band := Cultivating.growth_band(vein)
		if not risk_bands.has(band["id"]) or int(vein["growth"]) >= neutral:
			continue
		var nights := Cultivating.days_to_wall(vein)
		if nights < 0:
			continue
		var values := {
			"ore": GameData.ORE_TYPES[vein["oreType"]]["name"],
			"district": GameData.DISTRICTS[vein["district"]]["name"],
			"band": band["label"],
			"growth": vein["growth"],
			"nights": nights,
		}
		var urgent: bool = nights <= int(GameData.DAILY_BRIEF["veinCollapseNights"])
		rows.append(_row("veinAtRiskUrgent" if urgent else "veinAtRiskRoutine", "vein_collapse:%s" % vein["id"], values, { "to": "map_vein", "veinId": vein["id"] }, nights))


# The current ToDo objective (Todo.current_objective) as the one Story row,
# worded exactly as ToDo words it. Its objective's briefAction (or, while the
# waiting wording shows, earlyBriefAction) names the destination; no action
# falls back to ToDo. briefNote/earlyBriefNote is the consequence line.
static func _story_rows(rows: Array[Dictionary]) -> void:
	var item := Todo.current_objective()
	if item.is_empty():
		return
	var def: Dictionary = GameData.OBJECTIVES[item["id"]]
	var early := Todo.is_early(def) and def.has("earlyBriefAction")
	var action: Dictionary = def.get("earlyBriefAction" if early else "briefAction", { "to": "todo" })
	var note: String = def.get("earlyBriefNote" if early else "briefNote", "")
	var row := _row("story", "story:%s" % item["id"], { "text": Todo.item_text(item), "note": note }, action, 0)
	row["actionLabel"] = GameData.DAILY_BRIEF["storyActions"][action["to"]]["actionLabel"]
	rows.append(row)


# The Home.deposit_goal() savings row: cash against the target home's deposit.
static func _deposit_goal_rows(rows: Array[Dictionary]) -> void:
	var goal := Home.deposit_goal()
	if goal.is_empty():
		return
	rows.append(_row("depositGoal", "depositGoal", { "text": Home.deposit_goal_text(goal), "name": goal["name"] }, { "to": "property" }, 1))


# The Home.rent_goal() row: cash against the next weekly bill.
static func _rent_goal_rows(rows: Array[Dictionary]) -> void:
	var goal := Home.rent_goal()
	if goal.is_empty():
		return
	var values := { "cash": goal["cash"], "bill": goal["bill"], "weekday": GameData.EVENT_LABELS["weekdayNames"][Calendar.weekday_index(goal["day"])] }
	rows.append(_row("rentGoal", "rentGoal", values, { "to": "bank" }, 1))


# Pending Sales offers lapsing within offerWindowDays (an offer is gone on
# its expiresDay, Offers.is_expired).
static func _offer_expiring_rows(rows: Array[Dictionary]) -> void:
	var today: int = GameState.state["world"]["day"]
	for offer in Offers.pending_offers():
		var days_left: int = int(offer["expiresDay"]) - today
		if Offers.is_expired(offer) or days_left > int(GameData.DAILY_BRIEF["offerWindowDays"]):
			continue
		var faction: Dictionary = GameData.FACTIONS.get(offer.get("counterparty", ""), {})
		var values := {
			"buyer": faction.get("shortName", "A buyer"),
			"payment": int(offer["quote"]["payment"]),
			"deadline": Calendar.format_day(int(offer["expiresDay"])),
		}
		rows.append(_row("offerExpiring", "offer:%s" % offer["id"], values, { "to": "bizbrief_offer", "offerId": offer["id"] }, days_left))


# Sellable items the player holds whose Ticker demand modifier
# (Barometer.get_item_demand_mult − 1) is at or above demandThreshold.
# Items reach the Trade sheet only once canSellConsumables is set.
static func _demand_spike_rows(rows: Array[Dictionary]) -> void:
	if not GameState.state["flags"].get("canSellConsumables", false):
		return
	var threshold: float = GameData.DAILY_BRIEF["demandThreshold"]
	for recipe_key in GameData.CONSUMABLE_PRICES:
		var held := Crafting.inventory_qty(recipe_key)
		if held <= 0:
			continue
		var fraction := Barometer.get_item_demand_mult(recipe_key) - 1.0
		# Tolerance so a fraction landing exactly on the threshold counts.
		if fraction < threshold - 0.000001:
			continue
		var values := { "item": GameData.RECIPES[recipe_key]["name"], "percent": roundi(fraction * 100.0), "held": held }
		var row := _row("demandSpike", "demand:%s" % recipe_key, values, { "to": "trade" }, 0)
		# Kept for the card's demandSummary line.
		row["values"] = values
		rows.append(row)


# Open faction favour requests (R§3.10 "Favours"); answerable through the
# key member's thread until their expiresDay.
static func _favour_rows(rows: Array[Dictionary]) -> void:
	var today: int = GameState.state["world"]["day"]
	for entry in GameState.state["pendingMessages"]:
		if entry["kind"] != Diplomacy.FAVOUR_KIND:
			continue
		var payload: Dictionary = entry["payload"]
		var expires: int = int(payload.get("expiresDay", today))
		var values := {
			"faction": GameData.FACTIONS.get(payload.get("factionId", ""), {}).get("shortName", "A faction"),
			"name": Contacts.display_name(entry["contactId"]),
			"deadline": Calendar.format_day(expires),
		}
		rows.append(_row("favour", "favour:%s" % entry["id"], values, { "to": "thread", "contactId": entry["contactId"] }, expires - today))


# Live eligibility, re-derived from state every call, so a vein pruned past
# the threshold drops off at once.
static func _development_rows(rows: Array[Dictionary]) -> void:
	for vein in GameState.state["player"]["veins"]:
		if not Cultivating.is_development_eligible(vein):
			continue
		var values := {
			"ore": GameData.ORE_TYPES[vein["oreType"]]["name"],
			"district": GameData.DISTRICTS[vein["district"]]["name"],
			"threshold": int(GameData.VEIN_GROWTH["developmentThreshold"]),
		}
		rows.append(_row("development", "development:%s" % vein["id"], values, { "to": "map_vein", "veinId": vein["id"] }, 0))


# Recruited, working staff with nothing to do: no role while one is open to
# them (a founder with no unlocked role isn't idle), or a cultivator with an
# empty vein list. Unpaid staff are already the wage rows.
static func _idle_staff_rows(rows: Array[Dictionary]) -> void:
	var contacts: Dictionary = GameState.state["contacts"]
	for contact_id in contacts:
		if not contacts[contact_id]["recruited"] or not Payroll.is_working(contact_id):
			continue
		var role: Variant = Contacts.role_of(contact_id)
		var template_id := ""
		if role == null and (not Contacts.is_founder(contact_id) or not Contacts.available_roles(contact_id).is_empty()):
			template_id = "idleStaffNoRole"
		elif role == "cultivation" and Rooms.cultivator_veins(contact_id).is_empty():
			template_id = "idleStaffNoVeins"
		if template_id != "":
			rows.append(_row(template_id, "idle:%s" % contact_id, { "name": Contacts.display_name(contact_id) }, { "to": "bizbrief_staff", "contactId": contact_id }, 0))


# Production recipes under their effective target that no working producer
# able to make them can afford one attempt of from shared ore (the same
# check Rooms._producer_act makes); the short ore types are the first such
# producer's.
static func _ore_short_rows(rows: Array[Dictionary]) -> void:
	var producers: Array = Contacts.contacts_in_role("production").filter(func(contact_id: String) -> bool: return Payroll.is_working(contact_id))
	var ore: Dictionary = GameState.state["player"]["orichalchum"]
	for recipe_key in GameData.RECIPES:
		var held := Crafting.inventory_qty(recipe_key)
		var target := Rooms.effective_lab_target(recipe_key)
		if held >= target:
			continue
		var short_types: Array = []
		var makers := 0
		var affordable := false
		for contact_id in producers:
			if not Rooms.producible_recipes(contact_id).has(recipe_key):
				continue
			makers += 1
			var costs: Dictionary = Lab.base_calc(recipe_key)
			var lacking: Array = costs.keys().filter(func(ingredient: String) -> bool: return ore.get(ingredient, 0) < costs[ingredient])
			if lacking.is_empty():
				affordable = true
				break
			if short_types.is_empty():
				short_types = lacking
		if makers == 0 or affordable:
			continue
		var values := {
			"item": GameData.RECIPES[recipe_key]["name"],
			"ore": ", ".join(short_types.map(func(t: String) -> String: return GameData.ORE_TYPES[t]["name"])),
			"held": held,
			"target": target,
		}
		rows.append(_row("oreShort", "oreShort:%s" % recipe_key, values, { "to": "bizbrief_production", "recipeKey": recipe_key }, 0))


static func _row(template_id: String, key: String, values: Dictionary, action: Dictionary, sort: int) -> Dictionary:
	var template: Dictionary = GameData.DAILY_BRIEF["rows"][template_id]
	return {
		"key": key,
		"tier": template["tier"],
		"kind": template["kind"],
		"label": String(template["label"]).format(values),
		"consequence": String(template["consequence"]).format(values),
		"action": action,
		"actionLabel": template["actionLabel"],
		"done": GameState.state["morningAccounts"]["briefTicks"].has(key),
		"sort": sort,
	}
