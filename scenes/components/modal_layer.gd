class_name ModalLayer
extends Control


var _dim: ColorRect
var _card: PanelContainer
var _scroll: ScrollContainer
var _card_content: VBoxContainer

var _sell_ore_expanded: bool = true
var _sell_items_expanded: bool = true
var _sell_assets_expanded: bool = true

const MAX_CARD_HEIGHT := 620.0

func _ready() -> void:
	UI.anchor_full_rect(self)
	visible = false

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.5)
	UI.anchor_full_rect(_dim)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	_card = PanelContainer.new()
	UI.anchor_center(_card)
	add_child(_card)

	_scroll = UI.scroll_container()
	_scroll.custom_minimum_size = Vector2(330, 0)
	_card.add_child(_scroll)

	_card_content = UI.vbox(8)
	_card_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_card_content)

	EventBus.state_changed.connect(_refresh)
	_refresh()


func _on_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		_dismiss_modal()


func _dismiss_modal() -> void:
	var modal = GameState.state["modal"]
	if modal == null:
		return
	match modal.get("type", ""):
		"sell_menu":
			_on_sell_menu_cancel()
		"james_job_offer":
			JamesJobOfferModal.decline()
		"sale_result":
			SaleResultModal.close()
		"archie_deal_result":
			ArchieDealResultModal.close()
		_:
			Modal.close()


func _refresh() -> void:
	var modal = GameState.state["modal"]
	visible = modal != null
	if modal == null:
		return

	for child in _card_content.get_children():
		child.queue_free()

	_build_modal_content(modal)

	_size_card_to_content()
	_size_card_to_content.call_deferred()


func _size_card_to_content() -> void:
	if _card_content.get_child_count() == 0:
		return
	var content_height: float = _card_content.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = minf(content_height, MAX_CARD_HEIGHT)


func _build_modal_content(modal: Dictionary) -> void:
	var type_id: String = modal.get("type", "")
	var data: Dictionary = modal.get("data", {})

	if ModalRegistry.REGISTRY.has(type_id):
		ModalRegistry.REGISTRY[type_id].build(_card_content, data)
		return

	match type_id:
		"sell_menu":
			_build_sell_menu()
		"nadia_supply":
			_build_nadia_supply()
		"network_reference":
			_build_network_reference()
		"sell_vein_quote":
			_build_sell_vein_quote(data)
		"movement_craft":
			_build_movement_craft(data)
		"craft_components_menu":
			_build_craft_components_menu()
		"movement_swap":
			_build_movement_swap()
		"dial_load_complication":
			_build_dial_load_complication()
		"combat_setup":
			_build_combat_setup()
		"hq_ore_readout":
			_build_hq_ore_readout()
		"hq_gym":
			_build_hq_gym()
		"lab_bench_recipe_book":
			_build_lab_bench_recipe_book()
		"lab_bench_notes":
			_build_lab_bench_notes()
		"lab_bench_probe_result":
			_build_lab_bench_probe_result(data)
		_:
			_card_content.add_child(UI.heading(type_id))
			_card_content.add_child(UI.label("…"))
			_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _build_nadia_supply() -> void:
	var status := Collective.nadia_supply_status()
	var presentation: Dictionary = GameData.OBJECTIVES["col_a1_nadia_supply"].get("presentation", {})
	var stock: int = GameState.state["player"]["orichalchum"].get(status["oreType"], 0)
	var price: int = Economy.get_faction_sell_price("collective", "ore", status["oreType"])
	_card_content.add_child(UI.heading(presentation.get("heading", "")))
	_card_content.add_child(UI.label(presentation.get("delivered", "") % [status["delivered"], status["required"]]))
	_card_content.add_child(UI.label(presentation.get("remaining", "") % status["remaining"]))
	_card_content.add_child(UI.label(presentation.get("inStock", "") % [stock, GameData.ORE_TYPES[status["oreType"]]["name"]]))
	_card_content.add_child(UI.label(presentation.get("pricePerUnit", "") % price))

	var qty := SpinBox.new()
	qty.min_value = 1
	qty.max_value = maxi(stock, 1)
	qty.step = 1
	qty.value = mini(maxi(status["remaining"], 1), maxi(stock, 1))
	qty.allow_greater = false
	qty.editable = stock > 0
	_card_content.add_child(qty)

	var payment := UI.label("")
	_card_content.add_child(payment)
	var update_payment := func(value: float) -> void:
		payment.text = presentation.get("payment", "") % (price * int(value))
	update_payment.call(qty.value)
	qty.value_changed.connect(update_payment)

	var supply := UI.button(presentation.get("supply", ""), func():
		var result := Collective.supply_nadia(int(qty.value))
		if result.get("ok", false):
			Modal.open("sale_result", { "earned": result["earned"], "gross": result["earned"], "mugged": false })
	)
	supply.disabled = stock <= 0
	_card_content.add_child(supply)
	_card_content.add_child(UI.button(presentation.get("cancel", ""), func(): Modal.close()))


func _build_sell_menu() -> void:
	var modal: Dictionary = GameState.state["modal"]
	var data: Dictionary = modal.get("data", {})
	var faction_id: String = data.get("factionId", "")
	if faction_id != "":
		_build_faction_sell_menu(faction_id, data.get("contactId", ""))
		return

	var player: Dictionary = GameState.state["player"]
	var sell_state: Dictionary = GameState.state["sellState"]

	_card_content.add_child(UI.heading("Find a buyer"))
	_card_content.add_child(UI.muted_label("Archie splits 50/50. Select what you want to move."))

	var gross := 0
	var ore_rows: Array = []
	var item_rows: Array = []

	for ore_type in GameData.ORE_TYPES.keys():
		var have: int = player["orichalchum"].get(ore_type, 0)
		if have <= 0:
			continue
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var key := "ore_%s" % ore_type
		var qty: int = sell_state.get(key, 0)
		gross += ore["basePrice"] * qty
		ore_rows.append(_build_sell_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s (£%d/u, have %d)" % [ore["name"], ore["basePrice"], have]], key, qty, have))

	if GameState.state["flags"]["canSellConsumables"]:
		for recipe_key in GameData.CONSUMABLE_PRICES.keys():
			var buckets: Dictionary = player["inventory"].get(recipe_key, {})
			var recipe: Dictionary = GameData.RECIPES[recipe_key]
			var base_price: int = GameData.CONSUMABLE_PRICES[recipe_key]
			var tier_keys: Array = buckets.keys()
			tier_keys.sort_custom(func(a, b): return int(a) < int(b))
			for tier_key in tier_keys:
				var have: int = buckets[tier_key]
				if have <= 0:
					continue
				var tier: int = int(tier_key)
				var price: int = GameState.round_epsilon(base_price * Economy.quality_price_multiplier(tier))
				var key := "con_%s_%s" % [recipe_key, tier_key]
				var qty: int = sell_state.get(key, 0)
				gross += price * qty
				var tier_label := "untiered" if tier <= 0 else "tier %d" % tier
				item_rows.append(_build_sell_row([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s (%s, £%d/ea, have %d)" % [recipe["name"], tier_label, price, have]], key, qty, have))

	var asset_rows: Array = []
	var veins_selected := 0
	if GameState.state["flags"].get("veinSaleUnlocked", false):
		for vein in player["veins"]:
			var vein_key := "vein_%s" % vein["id"]
			var selected: bool = sell_state.get(vein_key, 0) > 0
			var vein_price := Economy.get_archie_vein_price(vein)
			if selected:
				gross += vein_price
				veins_selected += 1
			var vein_ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
			var vein_district: Dictionary = GameData.DISTRICTS[vein["district"]]
			var vein_parts := ["%s — " % vein_district["name"], { "symbol": vein_ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, " %s (£%d)" % [vein_ore["name"], vein_price]]
			asset_rows.append(_build_sell_vein_row(vein_parts, vein["id"], selected))

	_build_sell_sections(ore_rows, item_rows, asset_rows)

	var cut_ratio := Economy.get_archie_cut_ratio()
	var player_cut: int = int(floor(gross * cut_ratio))
	_card_content.add_child(UI.label("Your cut (%d%%): £%d" % [int(round(cut_ratio * 100)), player_cut]))
	var mug_pct: float = Economy.MUG_BASE_CHANCE_VEIN if veins_selected > 0 else Economy.MUG_BASE_CHANCE
	_card_content.add_child(UI.muted_label("%d%% chance of mugging" % int(round(mug_pct * 100))))

	var go_button := UI.button("Go — find a buyer", func(): Economy.sell_from_sell_state())
	go_button.disabled = player_cut == 0
	_card_content.add_child(go_button)
	_card_content.add_child(UI.button("Cancel", _on_sell_menu_cancel))


func _on_sell_menu_cancel() -> void:
	Economy.clear_sell_state()
	Modal.close()


func _build_faction_sell_menu(faction_id: String, contact_id: String) -> void:
	var player: Dictionary = GameState.state["player"]
	var sell_state: Dictionary = GameState.state["sellState"]
	var faction_name: String = GameData.FACTIONS[faction_id]["name"]

	_card_content.add_child(UI.heading("Trade with %s" % faction_name))
	_card_content.add_child(UI.muted_label("Straight sale. No cut, no risk of a mugging."))

	var gross := 0
	var ore_rows: Array = []
	var item_rows: Array = []

	for ore_type in GameData.ORE_TYPES.keys():
		var have: int = player["orichalchum"].get(ore_type, 0)
		if have <= 0:
			continue
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var key := "ore_%s" % ore_type
		var qty: int = sell_state.get(key, 0)
		var price := Economy.get_faction_sell_price(faction_id, "ore", ore_type)
		gross += price * qty
		ore_rows.append(_build_sell_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s (£%d/u, have %d)" % [ore["name"], price, have]], key, qty, have))

	var ore_stock: Dictionary = GameState.state["factions"][faction_id]["oreStock"]
	var buy_cost := 0
	var ore_bought := 0
	for ore_type in GameData.ORE_TYPES.keys():
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var buy_key := "buyOre_%s" % ore_type
		var buy_qty: int = sell_state.get(buy_key, 0)
		var buy_price := Economy.get_faction_buy_price(faction_id, "ore", ore_type)
		var buy_max: int = Economy.get_faction_buy_max_qty(faction_id, "ore", ore_type)
		var stock: int = int(ore_stock.get(ore_type, 0))
		if buy_qty > 0:
			buy_cost += buy_price * buy_qty
			ore_bought += buy_qty
		ore_rows.append(_build_buy_ore_row(["Buy: ", { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, " %s (£%d/u, stock %d)" % [ore["name"], buy_price, stock]], buy_key, buy_qty, buy_max))

	if GameState.state["flags"]["canSellConsumables"]:
		for recipe_key in GameData.CONSUMABLE_PRICES.keys():
			var buckets: Dictionary = player["inventory"].get(recipe_key, {})
			var recipe: Dictionary = GameData.RECIPES[recipe_key]
			var price := Economy.get_faction_sell_price(faction_id, "consumable", recipe_key)
			var tier_keys: Array = buckets.keys()
			tier_keys.sort_custom(func(a, b): return int(a) < int(b))
			for tier_key in tier_keys:
				var have: int = buckets[tier_key]
				if have <= 0:
					continue
				var key := "con_%s_%s" % [recipe_key, tier_key]
				var qty: int = sell_state.get(key, 0)
				gross += price * qty
				var tier_label := "untiered" if int(tier_key) <= 0 else "tier %d" % int(tier_key)
				item_rows.append(_build_sell_row([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s (%s, £%d/ea, have %d)" % [recipe["name"], tier_label, price, have]], key, qty, have))

	var asset_rows: Array = []
	var veins_selected := 0
	var veins_bought := 0
	if GameState.state["flags"].get("veinSaleUnlocked", false):
		for vein in player["veins"]:
			var vein_key := "vein_%s" % vein["id"]
			var selected: bool = sell_state.get(vein_key, 0) > 0
			var vein_price := VeinTrade.quote(vein)
			if selected:
				gross += vein_price
				veins_selected += 1
			var vein_ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]
			var vein_district: Dictionary = GameData.DISTRICTS[vein["district"]]
			var vein_parts := ["%s — " % vein_district["name"], { "symbol": vein_ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, " %s (£%d)" % [vein_ore["name"], vein_price]]
			asset_rows.append(_build_sell_vein_row(vein_parts, vein["id"], selected))

		for site in Sites.sites_with_faction_vein(faction_id):
			var faction_vein: Dictionary = site["factionVein"]
			var buy_key := "buyVein_%s" % faction_vein["id"]
			var buy_selected: bool = sell_state.get(buy_key, 0) > 0
			var buy_price := VeinTrade.quote(faction_vein)
			if buy_selected:
				buy_cost += buy_price
				veins_bought += 1
			var buy_ore: Dictionary = GameData.ORE_TYPES[faction_vein["oreType"]]
			var buy_district: Dictionary = GameData.DISTRICTS[faction_vein["district"]]
			var buy_parts := ["Buy: %s — " % buy_district["name"], { "symbol": buy_ore["symbol"], "fallback": SymbolGlyph.ore_fallback(faction_vein["oreType"]) }, " %s (£%d)" % [buy_ore["name"], buy_price]]
			asset_rows.append(_build_buy_vein_row(buy_parts, faction_vein["id"], buy_selected))

	_build_sell_sections(ore_rows, item_rows, asset_rows)

	var net := gross - buy_cost
	if net >= 0:
		_card_content.add_child(UI.label("You'll get: £%d" % net))
	else:
		_card_content.add_child(UI.label("You'll pay: £%d" % -net))

	var go_label := "Go — trade"
	var go_notes: Array = []
	if veins_selected == 1:
		go_notes.append("1 vein sale")
	elif veins_selected > 1:
		go_notes.append("%d vein sales" % veins_selected)
	if veins_bought == 1:
		go_notes.append("1 vein purchase")
	elif veins_bought > 1:
		go_notes.append("%d vein purchases" % veins_bought)
	if ore_bought > 0:
		go_notes.append("%d ore bought" % ore_bought)
	if not go_notes.is_empty():
		go_label += " (includes %s)" % ", ".join(go_notes)
	var go_button := UI.button(go_label, func(): Collective.complete_trade(contact_id))
	var nothing_selected := gross == 0 and buy_cost == 0
	var unaffordable: bool = net < 0 and -net > int(player["cash"])
	go_button.disabled = nothing_selected or unaffordable
	_card_content.add_child(go_button)
	_card_content.add_child(UI.button("Cancel", _on_sell_menu_cancel))


func _build_sell_sections(ore_rows: Array, item_rows: Array, asset_rows: Array) -> void:
	var ore_section := UI.collapsible_section("Ore", _sell_ore_expanded, func(v): _sell_ore_expanded = v)
	for row in ore_rows:
		ore_section["content"].add_child(row)
	_card_content.add_child(ore_section["panel"])

	var items_section := UI.collapsible_section("Items", _sell_items_expanded, func(v): _sell_items_expanded = v)
	for row in item_rows:
		items_section["content"].add_child(row)
	_card_content.add_child(items_section["panel"])

	if GameState.state["flags"].get("veinSaleUnlocked", false):
		var assets_section := UI.collapsible_section("Assets", _sell_assets_expanded, func(v): _sell_assets_expanded = v)
		for row in asset_rows:
			assets_section["content"].add_child(row)
		_card_content.add_child(assets_section["panel"])


func _build_sell_vein_row(parts: Array, vein_id: String, selected: bool) -> Control:
	var row := UI.hflow(6)
	row.add_child(UI.button("☑" if selected else "☐", func(): Economy.toggle_sell_vein(vein_id)))
	var text_row := UI.symbol_row(parts)
	text_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_row)
	return row


func _build_buy_vein_row(parts: Array, vein_id: String, selected: bool) -> Control:
	var row := UI.hflow(6)
	row.add_child(UI.button("☑" if selected else "☐", func(): Economy.toggle_buy_vein(vein_id)))
	var text_row := UI.symbol_row(parts)
	text_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_row)
	return row


func _build_buy_ore_row(parts: Array, key: String, qty: int, max_qty: int) -> Control:
	var row := UI.hflow()
	var text_row := UI.symbol_row(parts)
	text_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_row)
	if max_qty <= 0:
		row.add_child(UI.muted_label("Sold out"))
		return row
	var stepper := UI.hbox()
	stepper.add_child(UI.button("-", func(): Economy.adjust_sell_qty(key, -1, max_qty)))
	stepper.add_child(UI.label(str(qty)))
	stepper.add_child(UI.button("+", func(): Economy.adjust_sell_qty(key, 1, max_qty)))
	row.add_child(stepper)
	return row


func _build_sell_row(parts: Array, key: String, qty: int, max_qty: int) -> Control:
	var row := UI.hflow()
	var text_row := UI.symbol_row(parts)
	text_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_row)
	var stepper := UI.hbox()
	stepper.add_child(UI.button("-", func(): Economy.adjust_sell_qty(key, -1, max_qty)))
	stepper.add_child(UI.label(str(qty)))
	stepper.add_child(UI.button("+", func(): Economy.adjust_sell_qty(key, 1, max_qty)))
	row.add_child(stepper)
	return row


func _build_network_reference() -> void:
	_card_content.add_child(UI.heading("Network Reference"))
	_card_content.add_child(UI.muted_label("The lines are money. The dots are where it's coming from — or where someone beat you to it."))
	_card_content.add_child(_legend_row("Amber line", "Your line — stops joined in claim order."))
	_card_content.add_child(_legend_row("Coloured line", "A faction's line, in their colour."))
	_card_content.add_child(_legend_row("Grey stub", "Someone else's claim — not yours, not connected to anything."))
	_card_content.add_child(_legend_row("Ringed dot + symbol", "Your vein. The symbol shows the ore."))
	_card_content.add_child(_legend_row("Tick mark", "Unclaimed site. Double tick — richer ground."))
	_card_content.add_child(_legend_row("Filled grey dot", "Claimed. Not by you."))
	_card_content.add_child(_legend_row("Amber halo", "Charged — ready to harvest."))
	_card_content.add_child(_legend_row("Numeral badge", "Vein level."))
	_card_content.add_child(_legend_row("Padlock", "Security tier — colour shows how well-warded."))
	_card_content.add_child(_legend_row("Zone tint", "A faction's presence in the district."))
	_card_content.add_child(_legend_glyph_row("⌂", Icons.draw_home, " pin", "Home. Taps through to HQ."))
	_card_content.add_child(_legend_glyph_row("✉", Icons.draw_phone, " pin", "Someone's waiting on you there."))
	_card_content.add_child(_legend_row("Padlocked pin", "The Soho market. Not yet."))
	_card_content.add_child(_legend_row("Amber ring", "Where you are right now."))
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _legend_row(glyph_label: String, description: String) -> Control:
	var row := UI.vbox(2)
	row.add_child(UI.label(glyph_label))
	row.add_child(UI.muted_label(description))
	return row


func _legend_glyph_row(symbol: String, fallback: Callable, suffix_text: String, description: String) -> Control:
	var row := UI.vbox(2)
	row.add_child(UI.symbol_row([{ "symbol": symbol, "fallback": fallback }, suffix_text]))
	row.add_child(UI.muted_label(description))
	return row


func _build_sell_vein_quote(data: Dictionary) -> void:
	var vein_id: String = data["veinId"]
	var price: int = data["price"]
	var vein: Variant = Cultivating.find_vein(vein_id)
	if vein == null:
		Modal.close()
		return
	var ore: Dictionary = GameData.ORE_TYPES[vein["oreType"]]

	_card_content.add_child(UI.heading("Sell this vein?"))
	_card_content.add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(vein["oreType"]) }, "%s vein — £%d." % [ore["name"], price]]))
	_card_content.add_child(UI.muted_label("It stops being yours. Someone else's line, someone else's cut, from here on."))
	_card_content.add_child(UI.button("Confirm sale", func(): _on_sell_vein_confirm(vein_id)))
	_card_content.add_child(UI.button("Cancel", func(): Modal.close()))


func _on_sell_vein_confirm(vein_id: String) -> void:
	VeinTrade.sell_to_faction(vein_id, VeinTrade.SELL_FACTION_ID)
	Modal.close()


func _build_craft_components_menu() -> void:
	_card_content.add_child(UI.heading("Craft Components"))
	for archetype in GameData.CANONICAL_MOVEMENT_ARCHETYPES:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
		var block := UI.vbox(4)
		block.add_child(UI.symbol_row([{ "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, m["name"]]))
		block.add_child(UI.muted_label(m.get("description", "")))
		var captured_archetype: String = archetype
		block.add_child(UI.button("Craft", func(): Modal.open("movement_craft", { "archetype": captured_archetype })))
		_card_content.add_child(block)
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _build_movement_swap() -> void:
	_card_content.add_child(UI.heading("Swap Movement"))
	var player: Dictionary = GameState.state["player"]
	var inventory: Array = player["movementInventory"]
	for i in range(inventory.size()):
		var inv_movement: Dictionary = inventory[i]
		var md: Dictionary = GameData.DIAL_MOVEMENTS[inv_movement["archetype"]]
		var captured_index: int = i
		_card_content.add_child(UI.symbol_button([{ "symbol": md["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s — attuned %s, tier %d" % [md["name"], inv_movement["oreType"], inv_movement["tier"]]], func():
			Dial.seat_movement(captured_index)
			Modal.close()
		))
	_card_content.add_child(UI.button("Cancel", func(): Modal.close()))


func _build_dial_load_complication() -> void:
	_card_content.add_child(UI.heading("Load a Complication"))
	var player: Dictionary = GameState.state["player"]
	var any_loadable := false
	for recipe_key in GameData.RECIPES.keys():
		var recipe: Dictionary = GameData.RECIPES[recipe_key]
		var buckets: Dictionary = player["inventory"].get(recipe_key, {})
		for tier_key in buckets.keys():
			if buckets[tier_key] <= 0:
				continue
			any_loadable = true
			var captured_key: String = recipe_key
			var captured_tier: int = int(tier_key)
			_card_content.add_child(UI.symbol_button([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s tier %s (%d)" % [recipe["name"], tier_key, buckets[tier_key]]], func():
				Dial.load_complication(captured_key, captured_tier)
				Modal.close()
			))
	if not any_loadable:
		_card_content.add_child(UI.muted_label("Nothing in stock to load."))
	_card_content.add_child(UI.button("Cancel", func(): Modal.close()))


func _build_movement_craft(data: Dictionary) -> void:
	var archetype: String = data.get("archetype", "")
	var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var cost: int = Dial.movement_calc_cost(archetype, skill)
	var chance_pct: int = int(round(Dial.movement_craft_chance(archetype, skill) * 100))

	_card_content.add_child(UI.symbol_row([{ "symbol": m["symbol"], "fallback": SymbolGlyph.generic_fallback() }, m["name"]], { "heading_size": 20 }))
	_card_content.add_child(UI.muted_label(m.get("description", "")))
	for ore_type in GameData.ORE_TYPES.keys():
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var have: int = player["orichalchum"].get(ore_type, 0)
		var captured_archetype: String = archetype
		var captured_ore: String = ore_type
		var b := UI.symbol_button([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s — %d calc, chance %d%%" % [ore["name"], cost, chance_pct]], func(): _on_movement_craft_pressed(captured_archetype, captured_ore))
		b.disabled = have < cost
		_card_content.add_child(b)
	_card_content.add_child(UI.button("Cancel", func(): Modal.close()))


func _on_movement_craft_pressed(archetype: String, ore_type: String) -> void:
	var result := Dial.attempt_craft_movement(archetype, ore_type)
	Modal.close()
	if not result["ok"]:
		Notify.push(result["reason"], Notify.CATEGORY_WARNING)
	elif result["success"]:
		var m: Dictionary = GameData.DIAL_MOVEMENTS[archetype]
		Notify.push("Movement crafted: %s (tier %d)." % [m["name"], result["tier"]], Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("Movement-crafting failed — calc spent, no Movement gained.", Notify.CATEGORY_DANGER)


func _build_combat_setup() -> void:
	_card_content.add_child(UI.heading("Combat setup"))

	var template_options: Array = ["Random"]
	template_options.append_array(GameData.ENEMY_RAID_GUARDS.keys())
	_card_content.add_child(UI.label("Enemy type"))
	var template_select := UI.option_button(template_options)
	_card_content.add_child(template_select)

	var count_options: Array = []
	for i in range(1, Combat.SQUAD_MAX + 1):
		count_options.append(str(i))
	_card_content.add_child(UI.label("Number of enemies"))
	var count_select := UI.option_button(count_options)
	_card_content.add_child(count_select)

	var tier_options: Array = []
	for i in range(1, 7):
		tier_options.append(str(i))
	_card_content.add_child(UI.label("Value tier"))
	var tier_select := UI.option_button(tier_options)
	_card_content.add_child(tier_select)

	_card_content.add_child(UI.label("Allies"))
	var selected_allies: Array = []
	var eligible_allies := false
	for contact_id in GameState.state["contacts"].keys():
		if not Contacts.can_join_combat(contact_id):
			continue
		eligible_allies = true
		_card_content.add_child(_build_combat_setup_ally_row(contact_id, selected_allies))
	if not eligible_allies:
		_card_content.add_child(UI.muted_label("No recruited contact is fit for a fight right now."))

	_card_content.add_child(UI.button("Fight", func():
		var template_key: String = template_select.get_item_text(template_select.selected)
		if template_key == "Random":
			template_key = ""
		var count: int = count_select.get_item_text(count_select.selected).to_int()
		var value_tier: int = tier_select.get_item_text(tier_select.selected).to_int()
		Modal.close()
		Combat.start_raid("debug_combat_setup", value_tier, count, template_key, Combat.CONTEXT_RAID, selected_allies)
	))
	_card_content.add_child(UI.button("Cancel", func(): Modal.close()))


func _build_combat_setup_ally_row(contact_id: String, selected_allies: Array) -> Control:
	var row := UI.hbox(6)
	var toggle_btn: Button
	toggle_btn = UI.button("☐", func():
		if contact_id in selected_allies:
			selected_allies.erase(contact_id)
			toggle_btn.text = "☐"
		else:
			selected_allies.append(contact_id)
			toggle_btn.text = "☑"
	)
	row.add_child(toggle_btn)
	row.add_child(UI.label(Contacts.display_name(contact_id)))
	return row





func _build_hq_ore_readout() -> void:
	var player: Dictionary = GameState.state["player"]

	var slip := UI.card()
	slip["panel"].add_theme_stylebox_override("panel", _slip_panel_style())
	var slip_content: VBoxContainer = slip["content"]

	slip_content.add_child(UI.heading("Ore store", 14))
	var rule := _SlipRule.new()
	rule.custom_minimum_size = Vector2(0, 10)
	slip_content.add_child(rule)

	var any_ore := false
	for ore_type in GameData.ORE_TYPES.keys():
		var qty: int = player["orichalchum"].get(ore_type, 0)
		if qty <= 0:
			continue
		any_ore = true
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		slip_content.add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s — %d" % [ore["name"], qty]]))
	if not any_ore:
		slip_content.add_child(UI.muted_label("None in stock."))

	var raid_pct: int = int(round(Home.get_home_raid_chance() * 100))
	slip_content.add_child(_build_raid_stamp(raid_pct))
	slip_content.add_child(UI.muted_label("Ore kept at the flat is what a raid takes — carry less, lose less."))

	_card_content.add_child(slip["panel"])
	_card_content.add_child(_build_personal_stash_section())
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _build_personal_stash_section() -> Control:
	var card := UI.card()
	var content: VBoxContainer = card["content"]
	content.add_child(UI.heading("Personal stash", 14))
	content.add_child(UI.muted_label("Stashed stock is off-limits to contracts and staff — and to a raid."))

	var player: Dictionary = GameState.state["player"]
	var any_ore_row := false
	for ore_type in GameData.ORE_TYPES.keys():
		var shared: int = int(player["orichalchum"].get(ore_type, 0))
		var stashed: int = Stash.stashed_ore_qty(ore_type)
		if shared <= 0 and stashed <= 0:
			continue
		any_ore_row = true
		content.add_child(_build_stash_ore_row(ore_type, GameData.ORE_TYPES[ore_type], shared, stashed))
	if not any_ore_row:
		content.add_child(UI.muted_label("No ore to stash."))

	content.add_child(UI.heading("Crafted items", 13))
	var any_item_row := false
	for recipe_key in GameData.RECIPES.keys():
		var shared_qty: int = Crafting.inventory_qty(recipe_key)
		var stashed_qty: int = Stash.stashed_item_qty(recipe_key)
		if shared_qty <= 0 and stashed_qty <= 0:
			continue
		any_item_row = true
		content.add_child(_build_stash_item_row(recipe_key, GameData.RECIPES[recipe_key], shared_qty, stashed_qty))
	if not any_item_row:
		content.add_child(UI.muted_label("No crafted items to stash."))

	return card["panel"]


func _build_stash_ore_row(ore_type: String, ore: Dictionary, shared: int, stashed: int) -> Control:
	var row := UI.vbox(4)
	row.add_child(UI.symbol_row([{ "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ore_type) }, "%s — shared %d / stashed %d" % [ore["name"], shared, stashed]]))

	var stepper_max: int = maxi(shared, stashed)
	var qty: int = clampi(Stash.get_ore_move_qty(ore_type), 1, maxi(stepper_max, 1))
	var stepper := UI.hbox()
	stepper.add_child(UI.label("Qty:"))
	stepper.add_child(UI.button("-", func(): Stash.adjust_ore_move_qty(ore_type, -1, stepper_max)))
	stepper.add_child(UI.label(str(qty)))
	stepper.add_child(UI.button("+", func(): Stash.adjust_ore_move_qty(ore_type, 1, stepper_max)))
	row.add_child(stepper)

	var buttons := UI.hflow()
	var to_stash := UI.button("→ Stash", func(): Stash.move_ore_to_stash(ore_type, Stash.get_ore_move_qty(ore_type)))
	to_stash.disabled = qty > shared
	buttons.add_child(to_stash)
	var to_shared := UI.button("← Shared", func(): Stash.move_ore_to_shared(ore_type, Stash.get_ore_move_qty(ore_type)))
	to_shared.disabled = qty > stashed
	buttons.add_child(to_shared)
	row.add_child(buttons)

	return row


func _build_stash_item_row(recipe_key: String, recipe: Dictionary, shared: int, stashed: int) -> Control:
	var row := UI.vbox(4)
	row.add_child(UI.symbol_row([{ "symbol": recipe["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s — shared %d / stashed %d" % [recipe["name"], shared, stashed]]))

	var stepper_max: int = maxi(shared, stashed)
	var qty: int = clampi(Stash.get_item_move_qty(recipe_key), 1, maxi(stepper_max, 1))
	var stepper := UI.hbox()
	stepper.add_child(UI.label("Qty:"))
	stepper.add_child(UI.button("-", func(): Stash.adjust_item_move_qty(recipe_key, -1, stepper_max)))
	stepper.add_child(UI.label(str(qty)))
	stepper.add_child(UI.button("+", func(): Stash.adjust_item_move_qty(recipe_key, 1, stepper_max)))
	row.add_child(stepper)

	var buttons := UI.hflow()
	var to_stash := UI.button("→ Stash", func(): Stash.move_item_to_stash(recipe_key, Stash.get_item_move_qty(recipe_key)))
	to_stash.disabled = qty > shared
	buttons.add_child(to_stash)
	var to_shared := UI.button("← Shared", func(): Stash.move_item_to_shared(recipe_key, Stash.get_item_move_qty(recipe_key)))
	to_shared.disabled = qty > stashed
	buttons.add_child(to_shared)
	row.add_child(buttons)

	return row


const _SLIP_FILL := Color(0.976471, 0.960784, 0.882353, 1)
const _SLIP_INK := Color(0.219608, 0.219608, 0.239216, 1)
const _STAMP_ROTATION_DEGREES := -3.5

func _slip_panel_style() -> StyleBoxFlat:
	return _bordered_panel_style(_SLIP_FILL, _SLIP_INK, 2, 16, 14)


func _bordered_panel_style(fill: Color, border_color: Color, corner_radius: int, margin_h: int, margin_v: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = margin_h
	style.content_margin_top = margin_v
	style.content_margin_right = margin_h
	style.content_margin_bottom = margin_v
	return style


func _build_raid_stamp(raid_pct: int) -> Control:
	var accent := _action_color()

	var stamp := _SlipStamp.new()
	stamp.ink_color = accent
	stamp.rotation_degrees = _STAMP_ROTATION_DEGREES
	stamp.add_theme_constant_override("margin_left", 10)
	stamp.add_theme_constant_override("margin_top", 6)
	stamp.add_theme_constant_override("margin_right", 10)
	stamp.add_theme_constant_override("margin_bottom", 6)

	var raid_label := UI.label("Raid risk: %d%%" % raid_pct)
	raid_label.add_theme_color_override("font_color", accent)
	stamp.add_child(raid_label)

	return stamp


static func _draw_ink_polyline(target: CanvasItem, points: PackedVector2Array, ink_color: Color) -> void:
	for i in range(points.size() - 1):
		target.draw_line(points[i], points[i + 1], ink_color, 1.5)


class _SlipRule extends Control:
	var ink_color: Color = _SLIP_INK

	func _draw() -> void:
		if size.x <= 0:
			return
		var segments := 5
		var jitter_amount := 1.5
		var y: float = size.y * 0.5
		var seg_w: float = size.x / float(segments)
		var points := PackedVector2Array()
		for i in range(segments + 1):
			var jitter: float = 0.0
			if i > 0 and i < segments:
				jitter = jitter_amount if i % 2 == 0 else -jitter_amount
			points.append(Vector2(seg_w * i, y + jitter))
		ModalLayer._draw_ink_polyline(self, points, ink_color)


class _SlipStamp extends MarginContainer:
	var ink_color: Color = ModalLayer._ACTION_COLOR_FALLBACK

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w <= 0 or h <= 0:
			return
		var points := PackedVector2Array([
			Vector2(2, 2), Vector2(w * 0.5, 0), Vector2(w - 2, 3),
			Vector2(w - 1, h * 0.5), Vector2(w - 3, h - 2),
			Vector2(w * 0.5, h - 1), Vector2(1, h - 3), Vector2(2, h * 0.5),
			Vector2(2, 2),
		])
		ModalLayer._draw_ink_polyline(self, points, ink_color)


const _ACTION_COLOR_FALLBACK := Color(0.784314, 0.062745, 0.180392, 1)
const _ACTION_DISABLED_COLOR := Color(0.541176, 0.541176, 0.541176, 1)
const _ACTION_CARD_FILL := Color(0.980392, 0.972549, 0.952941, 1)

func _action_color() -> Color:
	return GameData.PALETTE.get("ui_action_red", _ACTION_COLOR_FALLBACK)


func _action_card_panel_style(accent: Color) -> StyleBoxFlat:
	return _bordered_panel_style(_ACTION_CARD_FILL, accent, 10, 16, 16)


func _action_button_style(accent: Color, alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, alpha)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style


func _style_action_button(b: Button, accent: Color) -> void:
	b.add_theme_stylebox_override("normal", _action_button_style(accent, 0.0))
	b.add_theme_stylebox_override("hover", _action_button_style(accent, 0.14))
	b.add_theme_stylebox_override("pressed", _action_button_style(accent, 0.22))
	b.add_theme_stylebox_override("disabled", _action_button_style(accent, 0.0))
	b.add_theme_color_override("font_color", accent)
	b.add_theme_color_override("font_hover_color", accent)
	b.add_theme_color_override("font_pressed_color", accent)
	b.add_theme_color_override("font_disabled_color", accent)


func _build_hq_gym() -> void:
	var player: Dictionary = GameState.state["player"]
	var has_gym: bool = GameState.state["home"]["rooms"].has("homeGym")
	_card_content.add_child(UI.heading("Gym", 14))
	_card_content.add_child(UI.label("Combat Skill: Lv%d (%d XP)" % [player["combatSkill"], player["combatXP"]]))
	if not has_gym:
		_card_content.add_child(UI.muted_label("Build a Home Gym to get more out of each workout."))
	_card_content.add_child(_build_train_button())
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _build_train_button() -> Control:
	var disabled: bool = TimeSystem.is_time_exhausted()
	var accent: Color = _ACTION_DISABLED_COLOR if disabled else _action_color()

	var c := UI.card()
	c["panel"].add_theme_stylebox_override("panel", _action_card_panel_style(accent))

	var b := UI.button(UI.format_block_cost_label("Train", 1, not disabled), func(): Combat.train())
	b.disabled = disabled
	_style_action_button(b, accent)
	c["content"].add_child(b)

	return c["panel"]



func _build_lab_bench_recipe_book() -> void:
	_card_content.add_child(UI.heading("Recipe book"))
	var found := Bench.found_recipe_keys()
	if found.is_empty():
		_card_content.add_child(UI.muted_label("Nothing found yet."))
	else:
		for recipe_key in found:
			_card_content.add_child(_build_lab_bench_recipe_row(recipe_key))
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _build_lab_bench_recipe_row(recipe_key: String) -> Control:
	var player: Dictionary = GameState.state["player"]
	var skill: int = player["craftingSkill"]
	var r: Dictionary = GameData.RECIPES[recipe_key]
	var costs: Dictionary = Crafting.calc_cost(recipe_key, skill)
	var chance: float = Crafting.craft_chance(recipe_key, skill)
	var power = Crafting.effect_power(recipe_key, skill)
	var can_make: bool = Crafting.can_craft(recipe_key)
	var stock: int = Crafting.inventory_qty(recipe_key)

	var c := UI.card()
	c["content"].add_child(UI.symbol_row([{ "symbol": r["symbol"], "fallback": SymbolGlyph.generic_fallback() }, r["name"]], { "heading_size": 15 }))
	c["content"].add_child(UI.muted_label(r["description"]))
	for ingredient in costs:
		var have: int = player["orichalchum"].get(ingredient, 0)
		var ore: Dictionary = GameData.ORE_TYPES[ingredient]
		c["content"].add_child(UI.symbol_row(["Ingredient: ", { "symbol": ore["symbol"], "fallback": SymbolGlyph.ore_fallback(ingredient) }, " %s — %d/%d" % [ore["name"], have, costs[ingredient]]]))
	c["content"].add_child(UI.label("Success: %d%%   Effect: %s   Stock: %d" % [int(round(chance * 100)), str(power), stock]))

	var qty: int = Crafting.get_craft_qty(recipe_key)
	var qty_row := UI.hbox()
	qty_row.add_child(UI.label("Batch:"))
	qty_row.add_child(UI.button("-", func(): Crafting.adjust_craft_qty(recipe_key, -1)))
	qty_row.add_child(UI.label(str(qty)))
	qty_row.add_child(UI.button("+", func(): Crafting.adjust_craft_qty(recipe_key, 1)))
	c["content"].add_child(qty_row)

	var craft_btn := UI.button("Craft ×%d" % qty, func(): Crafting.attempt_craft_batch(recipe_key, qty))
	craft_btn.disabled = not can_make
	c["content"].add_child(craft_btn)

	var discovery: Dictionary = r.get("discovery", {})
	if not discovery.is_empty():
		_append_lab_bench_refine_controls(c["content"], r, discovery["types"], discovery["approach"])

	return c["panel"]


func _append_lab_bench_refine_controls(container: Control, recipe: Dictionary, types: Array, approach: String) -> void:
	var tier := Bench.refine_tier_target(types, approach)
	var reason := Bench.refine_block_reason(types, approach)
	var refine_btn := UI.button(UI.format_block_cost_label("Refine to tier %d" % tier, 1, reason.is_empty()), func(): _on_lab_bench_refine_pressed(recipe["name"], types, approach, tier))
	refine_btn.disabled = reason != ""
	container.add_child(refine_btn)
	if reason != "":
		container.add_child(UI.muted_label(reason))


func _on_lab_bench_refine_pressed(recipe_name: String, types: Array, approach: String, tier: int) -> void:
	var result := Bench.refine(types, approach)
	if result.get("outcome", "") == "refined":
		Notify.push("%s refined to tier %d." % [recipe_name, tier], Notify.CATEGORY_SUCCESS)
	else:
		Notify.push("No improvement this time. Still tier %d." % (tier - 1), Notify.CATEGORY_WARNING)


func _build_lab_bench_notes() -> void:
	_card_content.add_child(UI.heading("Bench notes"))
	var touched := Bench.touched_type_sets()
	if touched.is_empty():
		_card_content.add_child(UI.muted_label("Nothing recorded yet."))  # PROSE-REVIEW: new empty-state line, tone bible per docs/CONTENT-GUIDE.md.
	else:
		for types in touched:
			_card_content.add_child(_build_lab_bench_notes_card(types))
	_card_content.add_child(UI.button("Close", func(): Modal.close()))


func _build_lab_bench_notes_card(types: Array) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading(_lab_bench_pairing_label(types), 15))
	c["content"].add_child(UI.label("%d/%d" % [Bench.found_count_in_set(types), Bench.get_surveyed_count(types)]))
	for row in _lab_bench_found_recipe_rows(types):
		c["content"].add_child(row)
	for entry in Bench.notes_for(types):
		c["content"].add_child(UI.muted_label(_lab_bench_history_line(entry)))
	return c["panel"]


func _lab_bench_found_recipe_rows(types: Array) -> Array:
	var rows: Array = []
	for approach_id in GameData.APPROACHES.keys():
		var recipe_key := Bench.find_recipe_for_cell(types, approach_id)
		if recipe_key == "" or Bench.cell_state(types, approach_id) != "found":
			continue
		var r: Dictionary = GameData.RECIPES[recipe_key]
		var tier: int = Bench.get_cell(types, approach_id)["refine"]
		var row := UI.vbox(4)
		row.add_child(UI.symbol_row([{ "symbol": r["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s — tier %d" % [r["name"], tier]]))
		_append_lab_bench_refine_controls(row, r, types, approach_id)
		rows.append(row)
	return rows


func _lab_bench_pairing_label(types: Array) -> String:
	var names: Array[String] = []
	for type_id in types:
		names.append(String(type_id).capitalize())
	if names.size() == 1:
		return names[0]
	return "%s and %s" % [names[0], names[1]]


func _lab_bench_history_line(entry: Dictionary) -> String:
	var approach_name: String = GameData.APPROACHES[entry["approach"]]["name"]
	return "Day %d — %s: %s" % [entry["day"], approach_name, _lab_bench_outcome_heading(entry["outcome"])]


func _lab_bench_outcome_heading(outcome: String) -> String:
	match outcome:
		"found":
			return "Found it."
		"hot":
			return "Something's there."
		"inert":
			return "Inert."
		"refined":
			return "Refined."
		"refine_failed":
			return "No better this time."
		_:
			return ""


func _build_lab_bench_probe_result(data: Dictionary) -> void:
	_card_content.add_child(UI.heading(_lab_bench_outcome_heading(data.get("outcome", ""))))
	_card_content.add_child(UI.symbol_row(_lab_bench_probe_prose_parts(data)))
	_card_content.add_child(UI.button("Got it", func(): Modal.close()))


func _lab_bench_probe_prose_parts(data: Dictionary) -> Array:
	match data.get("outcome", ""):
		"found":
			var r: Dictionary = GameData.RECIPES[data["recipeKey"]]
			return [{ "symbol": r["symbol"], "fallback": SymbolGlyph.generic_fallback() }, "%s. %s Craftable now." % [r["name"], r["description"]]]
		"hot":
			return ["Something's in there. It didn't come out this time."]
		"inert":
			return ["Nothing in it. Never was."]
		_:
			return [""]
