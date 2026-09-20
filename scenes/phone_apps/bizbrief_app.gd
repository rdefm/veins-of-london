# BizBrief: Brief tab (morning account — bank, operations, attention) and
# Manage tab (sales offers/contracts, lab production targets, vein-station
# procurement). The selected tab is view state held here, not in
# state.phoneNav, so it resets with the screen.
class_name BizBriefApp
extends PhoneApp

const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")
const OffersSystem := preload("res://systems/offers.gd")
const ContractsSystem := preload("res://systems/contracts.gd")
const ContractCard := preload("res://scenes/components/contract_card.gd")

const BRIEF_TAB := "brief"
const MANAGE_TAB := "manage"

var _tab := BRIEF_TAB


func build(content: VBoxContainer) -> void:
	content.add_child(back_button())
	content.add_child(UI.heading("BizBrief"))
	content.add_child(_build_tabs())
	if _tab == MANAGE_TAB:
		_build_manage(content)
		return
	_build_brief(content)


func _build_tabs() -> Control:
	var tabs := UI.hbox()
	var brief := UI.button("Brief", func(): _set_tab(BRIEF_TAB))
	brief.disabled = _tab == BRIEF_TAB
	tabs.add_child(UI.expand_fill(brief))
	var manage := UI.button("Manage", func(): _set_tab(MANAGE_TAB))
	manage.disabled = _tab == MANAGE_TAB
	tabs.add_child(UI.expand_fill(manage))
	return tabs


func _set_tab(tab: String) -> void:
	if tab == _tab:
		return
	_tab = tab
	refresh()


func _build_brief(content: VBoxContainer) -> void:
	content.add_child(UI.heading("Morning Brief", 16))
	var account = MorningAccountsSystem.latest()
	if account == null:
		content.add_child(UI.muted_label("No morning account yet."))
	else:
		content.add_child(UI.muted_label("Day %d · overnight changes" % account["day"]))
		content.add_child(_build_bank(account))
		if MorningAccountsSystem.has_operations(account):
			content.add_child(_build_operations(account))
	# Live, not tied to the presence of a rollover snapshot -- a
	# development-eligible vein (or an alarm/unread message) shows up here
	# even before the first morning account ever lands.
	var attention := MorningAccountsSystem.attention_items()
	if not attention.is_empty():
		content.add_child(_build_attention(attention))


func _build_manage(content: VBoxContainer) -> void:
	content.add_child(UI.heading("Manage", 16))
	content.add_child(_build_sales())
	content.add_child(_build_production())
	content.add_child(_build_procurement())


func _build_production() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Production", 14))

	if not GameState.state["home"]["rooms"].has("lab"):
		c["content"].add_child(UI.muted_label("Requires the Improved Lab."))
		return c["panel"]

	var flags: Dictionary = GameState.state["flags"]
	var any_unlocked := false
	for recipe_key in Rooms.RECIPE_UNLOCK_FLAGS.keys():
		var unlock_flag: String = Rooms.RECIPE_UNLOCK_FLAGS[recipe_key]
		if unlock_flag != "" and not flags.get(unlock_flag, false):
			continue
		any_unlocked = true
		c["content"].add_child(_build_production_recipe_row(recipe_key))
	if not any_unlocked:
		c["content"].add_child(UI.muted_label("No craftable recipes unlocked yet."))
	return c["panel"]


func _build_production_recipe_row(recipe_key: String) -> Control:
	var recipe: Dictionary = GameData.RECIPES[recipe_key]
	var target: int = GameState.state["labThresholds"].get(recipe_key, 0)
	var covering: bool = Rooms.lab_covers_contracts(recipe_key)

	var box := UI.vbox(4)
	box.add_child(UI.label(recipe["name"]))

	var target_text := "Personal target: %d" % target
	if covering:
		var need: int = Rooms.contract_need(recipe_key)
		target_text += " · contract need: %d · crafting to: %d" % [need, Rooms.effective_lab_target(recipe_key)]
	box.add_child(UI.muted_label(target_text))

	var target_row := UI.hbox()
	target_row.add_child(UI.button("-5", func(): Rooms.adjust_lab_threshold(recipe_key, -5)))
	target_row.add_child(UI.button("+5", func(): Rooms.adjust_lab_threshold(recipe_key, 5)))
	target_row.add_child(UI.button("Stop covering contracts" if covering else "Cover contract needs", func(): Rooms.set_lab_cover_contracts(recipe_key, not covering)))
	box.add_child(target_row)

	return box


func _build_procurement() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Procurement", 14))

	if not GameState.state["home"]["rooms"].has("veinStation"):
		c["content"].add_child(UI.muted_label("Requires the Vein Cultivation Station room."))
		return c["panel"]

	var veins: Array = VeinList.veins(null, null)
	if veins.is_empty():
		c["content"].add_child(UI.muted_label("No veins yet."))
		return c["panel"]

	for vein in veins:
		c["content"].add_child(_build_procurement_vein_row(vein))
	return c["panel"]


func _build_procurement_vein_row(vein: Dictionary) -> Control:
	var vein_id: String = vein["id"]
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
	var district: Dictionary = GameData.DISTRICTS[vein["district"]]

	var box := UI.vbox(4)
	box.add_child(UI.label("%s — %s" % [district["name"], ore["name"]]))

	var station_text: Variant = Rooms.vein_station_target_text(vein_id)
	if station_text == null:
		box.add_child(UI.button("Assign to Vein Station", func(): Rooms.toggle_vein_station_vein(vein_id)))
		return box

	var target: int = GameState.state["veinStationTargets"].get(vein_id, Rooms.VEIN_STATION_DEFAULT_TARGET)
	box.add_child(UI.muted_label(String(station_text)))

	var row := UI.hbox()
	row.add_child(UI.button("-5", func(): Rooms.set_vein_station_target(vein_id, target - 5)))
	row.add_child(UI.button("+5", func(): Rooms.set_vein_station_target(vein_id, target + 5)))
	row.add_child(UI.button("Unassign", func(): Rooms.toggle_vein_station_vein(vein_id)))
	box.add_child(row)

	return box


func _request_type_name(kind: String, item_type: String) -> String:
	return GameData.ORE_TYPES[item_type]["name"] if kind == "ore" else GameData.RECIPES[item_type]["name"]


func _request_summary(request: Dictionary) -> String:
	var parts: Array = []
	for line in ContractsSystem.request_lines(request):
		parts.append("%d %s" % [line["qty"], _request_type_name(line["kind"], line["type"])])
	return " + ".join(parts)


func _contract_progress_summary(contract: Dictionary) -> String:
	var parts: Array = []
	for line in ContractsSystem.request_lines(contract["request"]):
		parts.append("%d/%d %s" % [ContractsSystem.delivered_qty(contract, line["type"]), line["qty"], _request_type_name(line["kind"], line["type"])])
	return ", ".join(parts)


func _build_sales() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Sales", 14))
	var offers: Array = OffersSystem.pending_offers()
	if offers.is_empty():
		c["content"].add_child(UI.muted_label("No pending offers."))
	for offer in offers:
		var request: Dictionary = offer["request"]
		c["content"].add_child(UI.label("%s · £%d · expires day %d" % [_request_summary(request), offer["quote"]["payment"], offer["expiresDay"]]))
		c["content"].add_child(UI.button("Accept", func(): OffersSystem.accept_offer(offer["id"])))
	var contracts: Array = ContractsSystem.active_contracts()
	if not contracts.is_empty():
		c["content"].add_child(UI.heading("Active contracts", 14))
		c["content"].add_child(UI.muted_label("Drag cards to set delivery priority."))
		for index in contracts.size():
			var contract: Dictionary = contracts[index]
			var card := ContractCard.new()
			card.configure(contract["id"], index)
			var box := VBoxContainer.new()
			card.add_child(box)
			box.add_child(UI.label("%d. %s: %s · due day %d · £%d" % [index + 1, contract["id"], _contract_progress_summary(contract), contract["dueDay"], contract["quote"]["payment"]]))
			box.add_child(UI.button("Remove Sales delegation" if contract.get("delegated", false) else "Delegate to Sales", func(): ContractsSystem.set_delegated(contract["id"], not contract.get("delegated", false))))
			if not contract.get("delegated", false):
				var row := UI.hbox()
				row.add_child(UI.button("Deliver 1", func(): ContractsSystem.deliver(contract["id"], 1)))
				row.add_child(UI.button("Deliver all", func(): ContractsSystem.deliver(contract["id"], ContractsSystem.remaining_qty(contract))))
				box.add_child(row)
			c["content"].add_child(card)
	var history: Array = GameState.state["sales"].get("contractHistory", [])
	if not history.is_empty():
		c["content"].add_child(UI.heading("History", 14))
		for entry in history:
			var settled: Dictionary = entry["settlement"]
			c["content"].add_child(UI.muted_label("%s · %s · £%d" % [settled["id"], "complete" if settled["complete"] else "partial", settled["payment"]]))
	return c["panel"]


func _build_bank(account: Dictionary) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Reynard's", 14))
	c["content"].add_child(UI.label("Opening £%d · Closing £%d" % [account["openingBalance"], account["closingBalance"]]))
	c["content"].add_child(UI.label("Income +£%d · Expenses −£%d" % [account["income"], account["expenses"]]))
	c["content"].add_child(UI.button("Transaction history →", func(): MorningAccountsSystem.open_bank()))
	return c["panel"]


func _build_operations(account: Dictionary) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Operations", 14))
	for ore_type in account["oreMovement"]:
		var change: int = account["oreMovement"][ore_type]
		c["content"].add_child(UI.symbol_row([{ "symbol": GameData.ORE_TYPES[ore_type]["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s stock %s" % [GameData.ORE_TYPES[ore_type]["name"], _signed_amount(change)]]))
	for ore_type in account["production"]["ore"]:
		c["content"].add_child(UI.muted_label("Produced %d %s" % [account["production"]["ore"][ore_type], GameData.ORE_TYPES[ore_type]["name"]]))
	for recipe_key in account["production"]["items"]:
		c["content"].add_child(UI.symbol_row([{ "symbol": GameData.RECIPES[recipe_key]["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "Produced %d %s" % [account["production"]["items"][recipe_key], GameData.RECIPES[recipe_key]["name"]]]))
	for sale_key in account["sales"]:
		c["content"].add_child(UI.label("Sold %s: %d" % [sale_key, account["sales"][sale_key]]))
	for ore_type in account["losses"]["ore"]:
		c["content"].add_child(UI.symbol_row([{ "symbol": GameData.ORE_TYPES[ore_type]["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "Lost %d %s" % [account["losses"]["ore"][ore_type], GameData.ORE_TYPES[ore_type]["name"]]], { "muted": true }))
	if account["losses"]["veins"] > 0:
		c["content"].add_child(UI.muted_label("Lost %d vein%s" % [account["losses"]["veins"], "" if account["losses"]["veins"] == 1 else "s"]))
	for exception in account["exceptions"]:
		match exception["kind"]:
			"missedJob":
				c["content"].add_child(UI.muted_label("Exception: James's order expired."))
			"productionShortfall":
				var recipe: Dictionary = GameData.RECIPES[exception["recipeKey"]]
				c["content"].add_child(UI.muted_label("Exception: %s stock %d/%d." % [recipe["name"], exception["actual"], exception["target"]]))
	return c["panel"]


func _build_attention(items: Array[Dictionary]) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Attention", 14))
	c["content"].add_child(UI.muted_label("Still unresolved"))
	for item in items:
		var captured: Dictionary = item
		var glyph: Callable = Icons.draw_attack
		if item["kind"] == "message":
			glyph = Icons.draw_phone
		elif item["kind"] == "development":
			glyph = Icons.draw_cultivate
		var row := UI.hbox()
		var icon := UI.icon_glyph_control(glyph, 0.7)
		icon.custom_minimum_size = Vector2(24, 24)
		row.add_child(icon)
		row.add_child(UI.expand_fill(UI.button(MorningAccountsSystem.attention_label(item), func(): MorningAccountsSystem.open_attention(captured))))
		c["content"].add_child(row)
	return c["panel"]


func _signed_amount(amount: int) -> String:
	return "+%d" % amount if amount > 0 else str(amount)
