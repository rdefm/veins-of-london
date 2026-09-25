class_name MorningAccounts
extends RefCounted

const RaidAlarmsSystem := preload("res://systems/raid_alarms.gd")

# Exact, persisted account of one completed daily tick plus the staff block
# output of the day before it. The temporary context returned by
# begin_rollover() exists only while TimeSystem runs the tick;
# finish_rollover() stores the compact result and discards snapshots.


static func begin_rollover() -> Dictionary:
	var player: Dictionary = GameState.state["player"]
	var block: Dictionary = _block_production()
	GameState.state["morningAccounts"]["blockProduction"] = _empty_block_production()
	return {
		"day": GameState.state["world"]["day"],
		"openingBalance": player["cash"],
		"bankIds": _bank_ids(),
		"openingOre": ore_snapshot(),
		"lastOre": ore_snapshot(),
		"blockOreMovement": block["oreMovement"],
		"lastVeins": _vein_ids(),
		"jobBefore": GameState.deep_copy(GameState.state.get("jamesJob")),
		"productionOre": block["ore"],
		"productionItems": block["items"],
		"lossOre": {},
		"lostVeins": 0,
		"sales": {},
		"payday": null,
		"exceptions": [],
	}


static func capture_job_expiry(context: Dictionary) -> void:
	var before = context.get("jobBefore")
	if before != null and before.get("type") == "craft" and GameState.state.get("jamesJob") == null:
		context["exceptions"].append({ "kind": "missedJob", "recipeKey": before.get("recipeKey", "") })


static func capture_losses(context: Dictionary, source: String) -> void:
	var current_ore := ore_snapshot()
	var lost: Dictionary = _negative_delta(context["lastOre"], current_ore)
	_merge_amounts(context["lossOre"], lost)
	var current_veins := _vein_ids()
	var vein_loss := 0
	for vein_id in context["lastVeins"]:
		if not current_veins.has(vein_id):
			vein_loss += 1
	context["lostVeins"] += vein_loss
	if not lost.is_empty() or vein_loss > 0:
		context["exceptions"].append({ "kind": "loss", "source": source })
	context["lastOre"] = current_ore
	context["lastVeins"] = current_veins


# Staff block output and the block's net ore change (yields, crafting
# spend, Sales deliveries) accumulate here through the day and fold into the
# next rollover's production summary and ore movement. ore_before is
# ore_snapshot() taken just before the block ran.
static func record_block(output: Dictionary, ore_before: Dictionary) -> void:
	var block: Dictionary = _block_production()
	_merge_amounts(block["ore"], output["ore"])
	_merge_amounts(block["items"], output["items"])
	_merge_amounts(block["oreMovement"], _signed_delta(ore_before, ore_snapshot()))


# Personal Production targets still unmet at rollover, while anyone holds
# the Production role.
static func capture_production_shortfalls(context: Dictionary) -> void:
	if Contacts.contacts_in_role("production").is_empty():
		return
	for recipe_key in GameState.state["labThresholds"]:
		var target: int = GameState.state["labThresholds"][recipe_key]
		var actual: int = Crafting.inventory_qty(recipe_key)
		if target > 0 and actual < target:
			context["exceptions"].append({ "kind": "productionShortfall", "recipeKey": recipe_key, "target": target, "actual": actual })


static func _block_production() -> Dictionary:
	var accounts: Dictionary = GameState.state["morningAccounts"]
	if not accounts.has("blockProduction"):
		accounts["blockProduction"] = _empty_block_production()
	var block: Dictionary = accounts["blockProduction"]
	if not block.has("oreMovement"):
		block["oreMovement"] = {}
	return block


static func _empty_block_production() -> Dictionary:
	return { "ore": {}, "items": {}, "oreMovement": {} }


# Business.daily_tick()'s result: the payday statement, and an exception per
# staff wage the pot couldn't cover.
static func capture_business(context: Dictionary, result: Dictionary) -> void:
	context["payday"] = result["payday"]
	for shortfall in result["shortfalls"]:
		context["exceptions"].append({ "kind": "wageShortfall", "contactId": shortfall["contactId"], "amount": shortfall["owed"] })


# Payday statement lines: receipts, each expense, then the shares.
# PROSE-REVIEW: payday statement lines.
static func payday_lines(payday: Dictionary) -> Array[String]:
	var lines: Array[String] = ["Receipts £%d" % payday["receipts"]]
	for expense in payday["expenses"]:
		match expense["kind"]:
			"wage":
				lines.append("Wages, %s −£%d" % [Contacts.display_name(expense["contactId"]), expense["amount"]])
			"calc":
				lines.append("Calc, %s −£%d" % [expense.get("source", "market"), expense["amount"]])
	var shares: Dictionary = payday["shares"]
	var parts: Array[String] = ["You £%d" % shares["player"]]
	for contact_id in shares:
		if contact_id != "player":
			parts.append("%s £%d" % [Contacts.display_name(contact_id), shares[contact_id]])
	lines.append("Shares: " + " · ".join(parts))
	return lines


# PROSE-REVIEW: wage shortfall exception and prompt.
static func wage_shortfall_label(exception: Dictionary) -> String:
	return "Exception: the pot couldn't cover %s's wages. Owed £%d." % [Contacts.display_name(exception["contactId"]), exception["amount"]]


static func wage_prompt_label(contact_id: String) -> String:
	return "%s is owed £%d and has stopped working. Pay %s from your own cash?" % [Contacts.display_name(contact_id), Business.owed(contact_id), Contacts.display_name(contact_id)]


# Arrears exceptions (ADR 0006 "Morning account and notifications") from
# TimeSystem._apply_living_costs()'s result, then the live countdown while
# still in arrears.
static func capture_bills(context: Dictionary, result: Dictionary) -> void:
	var exceptions: Array = context["exceptions"]
	if result["interest"] > 0:
		exceptions.append({ "kind": "arrearsInterest", "amount": result["interest"] })
	if result["shortfall"] > 0:
		exceptions.append({ "kind": "arrearsShortfall", "amount": result["shortfall"], "arrears": result["arrears"] })
	var downgrade: Dictionary = result["downgrade"]
	if not downgrade.is_empty():
		exceptions.append({
			"kind": "forcedDowngrade", "fromTier": downgrade["fromTier"], "toTier": downgrade["toTier"],
			"roomsLost": downgrade["roomsLost"], "arrearsCleared": downgrade["arrearsCleared"], "arrears": downgrade["arrears"],
		})
	var countdown: Dictionary = Home.arrears_countdown()
	if not countdown.is_empty():
		countdown["kind"] = "arrearsCountdown"
		exceptions.append(countdown)


# BizBrief line for an arrears exception kind; "" for any other kind.
# PROSE-REVIEW: arrears exception and countdown lines.
static func arrears_label(exception: Dictionary) -> String:
	match exception["kind"]:
		"arrearsInterest":
			return "Exception: £%d interest on the arrears." % exception["amount"]
		"arrearsShortfall":
			return "Exception: £%d short on the bills. Owed £%d." % [exception["amount"], exception["arrears"]]
		"forcedDowngrade":
			var text := "Exception: lost the %s for unpaid bills. Renting the %s now." % [GameData.HOME_TIERS[exception["fromTier"]]["name"], GameData.HOME_TIERS[exception["toTier"]]["name"]]
			if exception["roomsLost"] > 0:
				text += " %d room%s gone." % [exception["roomsLost"], "" if exception["roomsLost"] == 1 else "s"]
			if exception["arrearsCleared"]:
				text += " The debt went with it."
			else:
				text += " Still owed £%d." % exception["arrears"]
			return text
		"arrearsCountdown":
			return " ".join(countdown_lines(exception))
	return ""


# Countdown sentences for a Home.arrears_countdown()-shaped dictionary.
static func countdown_lines(countdown: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if countdown.has("interestInDays"):
		lines.append("Interest starts %s." % _days_phrase(countdown["interestInDays"]))
	else:
		lines.append("Interest compounds daily.")
	if countdown.has("downgradeInDays"):
		lines.append("Lose the %s %s." % [GameData.HOME_TIERS[countdown["tier"]]["name"], _days_phrase(countdown["downgradeInDays"])])
	return lines


static func _days_phrase(days: int) -> String:
	return "tomorrow" if days == 1 else "in %d days" % days


# Future daily contract/staff operations report settled quantities here;
# this records only an operation that already ran and never executes a sale.
static func record_sale(context: Dictionary, sale_id: String, quantity: int) -> void:
	if quantity > 0:
		context["sales"][sale_id] = context["sales"].get(sale_id, 0) + quantity


static func finish_rollover(context: Dictionary) -> Dictionary:
	var income := 0
	var expenses := 0
	for entry in GameState.state["bankLog"]:
		if context["bankIds"].has(entry["id"]):
			continue
		var amount: int = entry["amount"]
		if amount >= 0:
			income += amount
		else:
			expenses += -amount

	var account := {
		"day": context["day"],
		"openingBalance": context["openingBalance"],
		"closingBalance": GameState.state["player"]["cash"],
		"income": income,
		"expenses": expenses,
		"oreMovement": _combined_movement(context["blockOreMovement"], _signed_delta(context["openingOre"], ore_snapshot())),
		"production": { "ore": context["productionOre"], "items": context["productionItems"] },
		"sales": context["sales"],
		"payday": context["payday"],
		"losses": { "ore": context["lossOre"], "veins": context["lostVeins"] },
		"exceptions": context["exceptions"],
	}
	GameState.state["morningAccounts"]["latest"] = account
	EventBus.state_changed.emit()
	return account


static func latest() -> Variant:
	return GameState.state["morningAccounts"].get("latest")


static func has_operations(account: Dictionary) -> bool:
	return not account["oreMovement"].is_empty() \
		or not account["production"]["ore"].is_empty() \
		or not account["production"]["items"].is_empty() \
		or not account["sales"].is_empty() \
		or not account["losses"]["ore"].is_empty() \
		or account["losses"]["veins"] > 0 \
		or not account["exceptions"].is_empty()


static func attention_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	if GameState.state["home"].get("pendingRaid", false):
		items.append({ "kind": "alarm", "target": "home" })
	for raid in GameState.state["world"].get("pendingDefendRaids", []):
		items.append({ "kind": "alarm", "target": "vein", "veinId": raid["veinId"] })
	# Live eligibility, re-derived from state every call -- never a rollover
	# snapshot, so a vein that's been harvested past the threshold since the
	# last tick drops off immediately rather than lingering as a stale item.
	for vein in GameState.state["player"]["veins"]:
		if Cultivating.is_development_eligible(vein):
			items.append({ "kind": "development", "veinId": vein["id"], "vein": vein })
	for contact_id in GameState.state["messages"]:
		var count := Messages.unread_count(contact_id)
		if count > 0:
			items.append({ "kind": "message", "contactId": contact_id, "count": count })
	return items


static func attention_label(item: Dictionary) -> String:
	if item["kind"] == "message":
		return "%s — %d unread" % [Contacts.display_name(item["contactId"]), item["count"]]
	if item["kind"] == "development":
		var vein: Dictionary = item["vein"]
		# R§3.4: combined_magnitude, not raw value_tier -- this vein's earned
		# level (if any) is felt in the exposure figure the player sees here.
		var exposure: int = Cultivating.combined_magnitude(vein)
		return "%s — %s ready to develop · raid exposure %d" % [GameData.ORE_TYPES[vein["oreType"]]["name"], GameData.DISTRICTS[vein["district"]]["name"], exposure]
	if item["target"] == "home":
		return "HQ raid alarm"
	var vein = Cultivating.find_vein(item["veinId"])
	if vein == null:
		return "Vein raid alarm"
	return "%s — %s" % [GameData.ORE_TYPES[vein["oreType"]]["name"], GameData.DISTRICTS[vein["district"]]["name"]]


static func open_attention(item: Dictionary) -> void:
	if item["kind"] == "message":
		PhoneNav.select_conversation(item["contactId"])
	elif item["kind"] == "development":
		# Same manage-vein navigation VeinList's own Manage option uses.
		VeinList.apply_option(VeinList.MANAGE_ID, item["veinId"])
	else:
		RaidAlarmsSystem.open()


static func open_bank() -> void:
	PhoneNav.open_app("bank")


static func open_after_transition(day: int) -> bool:
	var accounts: Dictionary = GameState.state["morningAccounts"]
	var account = accounts.get("latest")
	if account == null or account["day"] != day or accounts.get("autoOpenedDay", 0) == day:
		return false
	accounts["autoOpenedDay"] = day
	Nav.go_to("phone")
	PhoneNav.open_app("bizbrief")
	return true


static func _bank_ids() -> Dictionary:
	var ids := {}
	for entry in GameState.state["bankLog"]:
		ids[entry["id"]] = true
	return ids


static func ore_snapshot() -> Dictionary:
	var result := {}
	for ore_type in GameData.ORE_TYPES:
		result[ore_type] = int(GameState.state["player"]["orichalchum"].get(ore_type, 0))
	return result


static func _vein_ids() -> Array[String]:
	var ids: Array[String] = []
	for vein in GameState.state["player"]["veins"]:
		ids.append(vein["id"])
	return ids


static func _combined_movement(first: Dictionary, second: Dictionary) -> Dictionary:
	var result: Dictionary = first.duplicate()
	_merge_amounts(result, second)
	for key in result.keys():
		if result[key] == 0:
			result.erase(key)
	return result


static func _signed_delta(before: Dictionary, after: Dictionary) -> Dictionary:
	var result := {}
	for key in before:
		var change: int = after.get(key, 0) - before[key]
		if change != 0:
			result[key] = change
	return result


static func _positive_delta(before: Dictionary, after: Dictionary) -> Dictionary:
	var result := {}
	for key in before:
		var change: int = after.get(key, 0) - before[key]
		if change > 0:
			result[key] = change
	return result


static func _negative_delta(before: Dictionary, after: Dictionary) -> Dictionary:
	var result := {}
	for key in before:
		var change: int = before[key] - after.get(key, 0)
		if change > 0:
			result[key] = change
	return result


static func _merge_amounts(target: Dictionary, additions: Dictionary) -> void:
	for key in additions:
		target[key] = target.get(key, 0) + additions[key]
