class_name SellMenuView
extends PanelContainer

# Trade-only chrome. Selections remain in GameState.sellState through Economy;
# tabs, expanded item groups and the review step are local presentation state.

const BG := Color("#222226")
const SURFACE := Color("#2c2c31")
const LINE := Color("#47474d")
const TEXT := Color("#ededee")
const MUTED := Color("#a6a7ab")
const BUTTON_BG := Color("#3b3b40")

var _data: Dictionary = {}
var _direction := "sell"
var _category := "ore"
var _review := false
var _expanded_items: Dictionary = {}
var _scroll: ScrollContainer


func refresh(data: Dictionary) -> void:
	_data = data
	_render()


func reset_ui() -> void:
	_data = {}
	_direction = "sell"
	_category = "ore"
	_review = false
	_expanded_items.clear()
	_scroll = null


func _render(reset_scroll: bool = false) -> void:
	var previous_scroll := 0
	if not reset_scroll and _scroll != null and is_instance_valid(_scroll):
		previous_scroll = _scroll.scroll_vertical
	for child in get_children():
		remove_child(child)
		child.queue_free()

	add_theme_stylebox_override("panel", _style(BG, 0))
	var layout := UI.vbox(0)
	add_child(layout)
	var entries := _entries()
	_build_header(layout)
	if not _review:
		_build_categories(layout)
	_scroll = TouchScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_scroll)
	var body_margin := MarginContainer.new()
	body_margin.add_theme_constant_override("margin_left", 14)
	body_margin.add_theme_constant_override("margin_right", 14)
	_scroll.add_child(body_margin)
	var body := UI.vbox(0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.add_child(body)
	if _review:
		_build_review(body, entries)
	else:
		_build_list(body, entries)
	_build_footer(layout, entries)
	_scroll.scroll_vertical = previous_scroll
	if is_inside_tree():
		_scroll.set_deferred("scroll_vertical", previous_scroll)


func _build_header(layout: VBoxContainer) -> void:
	var panel := _surface(SURFACE, 14)
	layout.add_child(panel)
	var content := UI.vbox(8)
	panel.add_child(content)
	var top := UI.hbox(8)
	content.add_child(top)
	var headings := UI.vbox(2)
	headings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(headings)
	var contact := "Archie" if not _is_faction() else Contacts.display_name(_data.get("contactId", "des"))
	var kicker := "%s / TRADE" % contact.to_upper()
	if _is_faction():
		kicker = "%s · %s / TRADE" % [contact.to_upper(), String(GameData.FACTIONS[_faction_id()]["name"]).to_upper()]
	headings.add_child(_label(kicker, 11, MUTED))
	headings.add_child(_label("Review trade" if _review else "Buy goods" if _direction == "buy" else "Sell goods", 22, TEXT))
	var close := _button("×", func(): SellMenuModal.cancel(), Color.TRANSPARENT, 44)
	close.custom_minimum_size.x = 44
	close.accessibility_name = "Close trade"
	top.add_child(close)
	var note := "Direct trade. No cut or mugging." if _is_faction() else "Archie's cut changes with your relation."
	content.add_child(_label(note, 12, MUTED))
	if _is_faction() and not _review:
		var direction_row := UI.hbox(5)
		content.add_child(direction_row)
		for direction in ["sell", "buy"]:
			var label := "Sell from my stock" if direction == "sell" else "Buy from contact"
			var fill := UI.action_colour() if _direction == direction else BUTTON_BG
			var button := _button(label, _select_direction.bind(direction), fill, 44)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			direction_row.add_child(button)


func _build_categories(layout: VBoxContainer) -> void:
	var panel := _surface(BG, 10)
	layout.add_child(panel)
	var row := UI.hbox(6)
	panel.add_child(row)
	for category in ["ore", "items", "veins"]:
		if category == "items" and _direction == "buy":
			continue
		if category == "veins" and not _veins_unlocked():
			continue
		var chosen: bool = _category == category
		var fill := TEXT if chosen else Color.TRANSPARENT
		var button := _button(category.capitalize(), _select_category.bind(category), fill, 40)
		button.add_theme_color_override("font_color", BG if chosen else TEXT)
		button.add_theme_color_override("font_hover_color", BG if chosen else TEXT)
		button.add_theme_color_override("font_pressed_color", BG if chosen else TEXT)
		row.add_child(button)


func _build_list(body: VBoxContainer, entries: Array) -> void:
	var relevant: Array = []
	for entry in entries:
		if entry["category"] == _category and entry["direction"] == _direction:
			relevant.append(entry)
	if relevant.is_empty():
		body.add_child(_label("Nothing available here.", 14, MUTED))
		return
	if _category == "items":
		_build_item_groups(body, relevant)
		return
	for entry in relevant:
		_add_row(body, entry)


func _build_item_groups(body: VBoxContainer, entries: Array) -> void:
	var groups: Dictionary = {}
	var order: Array[String] = []
	for entry in entries:
		var recipe_key: String = entry["recipeKey"]
		if not groups.has(recipe_key):
			groups[recipe_key] = []
			order.append(recipe_key)
		groups[recipe_key].append(entry)
	if _expanded_items.is_empty() and not order.is_empty():
		_expanded_items[order[0]] = true
	for recipe_key in order:
		var tiers: Array = groups[recipe_key]
		var held := 0
		var picked := 0
		for entry in tiers:
			held += int(entry["stock"])
			picked += int(entry["qty"])
		var expanded: bool = _expanded_items.get(recipe_key, false)
		var header := _button("", _toggle_item.bind(recipe_key), Color.TRANSPARENT, 68)
		header.accessibility_name = "%s, %d tiers, %d in stock, %d selected" % [tiers[0]["groupName"], tiers.size(), held, picked]
		body.add_child(header)
		var inner := UI.hbox(8)
		UI.anchor_full_rect(inner)
		inner.offset_left = 4
		inner.offset_right = -4
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(inner)
		var glyph := SymbolGlyph.new()
		glyph.symbol = tiers[0]["symbol"]
		glyph.draw_fallback = SymbolGlyph.generic_fallback()
		glyph.color = TEXT
		glyph.font_size = 19
		glyph.glyph_radius = 8.0
		glyph.custom_minimum_size = Vector2(28, 28)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(glyph)
		var item_info := UI.vbox(2)
		item_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.add_child(item_info)
		item_info.add_child(_label(tiers[0]["groupName"], 14, TEXT))
		item_info.add_child(_label("%d tiers · %d in stock" % [tiers.size(), held], 12, MUTED))
		if picked > 0:
			var badge := _surface(UI.action_colour(), 5)
			badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.add_child(_label("%d selected" % picked, 11, TEXT))
			inner.add_child(badge)
		inner.add_child(_label("⌃" if expanded else "⌄", 18, MUTED))
		if expanded:
			var indent := MarginContainer.new()
			indent.add_theme_constant_override("margin_left", 28)
			body.add_child(indent)
			var tier_box := UI.vbox(0)
			indent.add_child(tier_box)
			for entry in tiers:
				_add_row(tier_box, entry, true)
		body.add_child(_divider())


func _add_row(parent: VBoxContainer, entry: Dictionary, tier_row: bool = false) -> void:
	var row := UI.hbox(8)
	row.custom_minimum_size.y = 72 if not tier_row else 66
	parent.add_child(row)
	if not tier_row:
		var glyph := SymbolGlyph.new()
		glyph.custom_minimum_size = Vector2(28, 28)
		glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		glyph.color = TEXT
		glyph.glyph_radius = 8.0
		glyph.font_size = 19
		if entry["oreType"] != "":
			# Empty symbol forces OreGlyphs.draw(), the same silhouettes as MapCanvas.
			glyph.symbol = ""
			glyph.draw_fallback = SymbolGlyph.ore_fallback(entry["oreType"])
		else:
			glyph.symbol = entry["symbol"]
			glyph.draw_fallback = SymbolGlyph.generic_fallback()
		row.add_child(glyph)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	var name: String = entry["name"]
	if tier_row:
		name = "Untiered" if int(entry["tier"]) <= 0 else "Tier %d" % int(entry["tier"])
	info.add_child(_label(name, 14, TEXT))
	var meta := UI.hbox(3)
	info.add_child(meta)
	meta.add_child(_label("£%d" % int(entry["price"]), 12, _gold()))
	meta.add_child(_label(" / vein" if entry["kind"] == "vein" else " each", 12, MUTED))
	var stock_text := " · %d available" % int(entry["stock"])
	if entry["direction"] == "buy":
		stock_text = " · stock %d" % int(entry["stock"])
	meta.add_child(_label(stock_text, 12, MUTED))
	if entry["kind"] == "vein":
		var chosen := int(entry["qty"]) > 0
		var button := _button("✓ Added" if chosen else "+ Add", _toggle_vein.bind(entry), BUTTON_BG, 44)
		button.disabled = not chosen and int(entry["max"]) <= 0
		row.add_child(button)
	elif int(entry["max"]) <= 0:
		row.add_child(_label("Sold out" if int(entry["stock"]) <= 0 else "Unavailable", 12, MUTED))
	else:
		var stepper := UI.hbox(3)
		stepper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(stepper)
		var minus := _button("−", _adjust.bind(entry, -1), BUTTON_BG, 44)
		minus.custom_minimum_size.x = 44
		minus.disabled = int(entry["qty"]) <= 0
		minus.accessibility_name = "Remove one %s" % entry["name"]
		stepper.add_child(minus)
		var qty := _label(str(entry["qty"]), 14, TEXT)
		qty.custom_minimum_size.x = 22
		qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		stepper.add_child(qty)
		var plus := _button("+", _adjust.bind(entry, 1), BUTTON_BG, 44)
		plus.custom_minimum_size.x = 44
		plus.disabled = int(entry["qty"]) >= int(entry["max"])
		plus.accessibility_name = "Add one %s" % entry["name"]
		stepper.add_child(plus)
	parent.add_child(_divider())


func _build_review(body: VBoxContainer, entries: Array) -> void:
	var any_selected := false
	for entry in entries:
		if int(entry["qty"]) <= 0:
			continue
		any_selected = true
		var sign := "−" if entry["direction"] == "buy" else "+"
		var line := "%s %d × %s" % ["Buy" if entry["direction"] == "buy" else "Sell", entry["qty"], entry["name"]]
		var row := UI.hbox(8)
		row.custom_minimum_size.y = 44
		body.add_child(row)
		var description := _label(line, 13, TEXT)
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(description)
		row.add_child(_label("%s£%d" % [sign, int(entry["price"]) * int(entry["qty"])], 13, _gold()))
		body.add_child(_divider())
	if not any_selected:
		body.add_child(_label("No goods selected.", 14, MUTED))


func _build_footer(layout: VBoxContainer, entries: Array) -> void:
	var totals := _totals(entries)
	var panel := _surface(SURFACE, 12)
	layout.add_child(panel)
	var content := UI.vbox(6)
	panel.add_child(content)
	var summary := UI.hbox(8)
	content.add_child(summary)
	var explanation := UI.vbox(1)
	explanation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(explanation)
	var net: int = totals["net"]
	var settlement := "YOU PAY" if net < 0 else "YOU RECEIVE"
	if not _is_faction():
		settlement = "EST. YOU RECEIVE"
	explanation.add_child(_label(settlement, 11, TEXT))
	var note: String
	if _is_faction():
		note = "%d selected · sell £%d · buy £%d" % [totals["count"], totals["gross"], totals["cost"]]
	else:
		note = "%d selected · est. cut %d%% of £%d" % [totals["count"], int(round(Economy.get_archie_cut_ratio() * 100.0)), totals["gross"]]
	explanation.add_child(_label(note, 12, MUTED))
	summary.add_child(_label("£%d" % absi(net), 22, _gold()))
	if not _is_faction():
		var mug_base: float = Economy.MUG_BASE_CHANCE_VEIN if totals["veins"] > 0 else Economy.MUG_BASE_CHANCE
		content.add_child(_label("%d%% base chance of mugging" % int(round(mug_base * 100.0)), 12, MUTED))
	var actions := UI.hbox(8)
	content.add_child(actions)
	var secondary := _button("Back" if _review else "Cancel", _back_or_cancel, Color.TRANSPARENT, 44)
	actions.add_child(secondary)
	var primary := _button("Confirm trade" if _review else "Review trade →", _confirm if _review else _show_review, UI.action_colour(), 48)
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary.disabled = totals["count"] == 0 or (net < 0 and absi(net) > int(GameState.state["player"]["cash"]))
	actions.add_child(primary)


func _entries() -> Array:
	var entries: Array = []
	var player: Dictionary = GameState.state["player"]
	var sell_state: Dictionary = GameState.state["sellState"]
	var faction_id := _faction_id()
	var district: Dictionary = GameData.DISTRICTS.get(GameState.state["world"]["currentDistrict"], {})
	var price_mod: float = district.get("priceMod", 0.0)
	for ore_type in GameData.ORE_TYPES.keys():
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var have: int = player["orichalchum"].get(ore_type, 0)
		if have > 0:
			var sell_price: int
			if _is_faction():
				sell_price = Economy.get_faction_sell_price(faction_id, "ore", ore_type)
			else:
				sell_price = GameState.round_epsilon(Barometer.get_effective_ore_price(ore_type, ore["basePrice"]) * (1.0 + price_mod))
			var key := "ore_%s" % ore_type
			entries.append(_entry("sell", "ore", "ore", key, ore["name"], ore_type, ore["symbol"], sell_price, have, have, sell_state.get(key, 0)))
		if _is_faction():
			var stock: int = GameState.state["factions"][faction_id]["oreStock"].get(ore_type, 0)
			var buy_key := "buyOre_%s" % ore_type
			var max_qty := Economy.get_faction_buy_max_qty(faction_id, "ore", ore_type)
			entries.append(_entry("buy", "ore", "ore", buy_key, ore["name"], ore_type, ore["symbol"], Economy.get_faction_buy_price(faction_id, "ore", ore_type), stock, max_qty, sell_state.get(buy_key, 0)))
	if GameState.state["flags"]["canSellConsumables"]:
		for recipe_key in GameData.CONSUMABLE_PRICES.keys():
			var recipe: Dictionary = GameData.RECIPES[recipe_key]
			var buckets: Dictionary = player["inventory"].get(recipe_key, {})
			var tier_keys: Array = buckets.keys()
			tier_keys.sort_custom(func(a, b): return int(a) < int(b))
			for tier_key in tier_keys:
				var have: int = buckets[tier_key]
				if have <= 0:
					continue
				var tier := int(tier_key)
				var price: int
				if _is_faction():
					price = Economy.get_faction_sell_price(faction_id, "consumable", recipe_key)
				else:
					price = GameState.round_epsilon(GameData.CONSUMABLE_PRICES[recipe_key] * Economy.quality_price_multiplier(tier) * (1.0 + price_mod))
				var key := "con_%s_%s" % [recipe_key, tier_key]
				var tier_label := "untiered" if tier <= 0 else "tier %d" % tier
				var item := _entry("sell", "items", "consumable", key, "%s · %s" % [recipe["name"], tier_label], "", recipe["symbol"], price, have, have, sell_state.get(key, 0))
				item["recipeKey"] = recipe_key
				item["groupName"] = recipe["name"]
				item["tier"] = tier
				entries.append(item)
	if _veins_unlocked():
		for vein in player["veins"]:
			var price := VeinTrade.quote(vein) if _is_faction() else Economy.get_archie_vein_price(vein)
			var key := "vein_%s" % vein["id"]
			var name := "%s · %s" % [GameData.DISTRICTS[vein["district"]]["name"], GameData.ORE_TYPES[vein["oreType"]]["name"]]
			var entry := _entry("sell", "veins", "vein", key, name, vein["oreType"], "", price, 1, 1, sell_state.get(key, 0))
			entry["veinId"] = vein["id"]
			entries.append(entry)
		if _is_faction():
			for site in Sites.sites_with_faction_vein(faction_id):
				var vein: Dictionary = site["factionVein"]
				var key := "buyVein_%s" % vein["id"]
				var name := "%s · %s" % [GameData.DISTRICTS[vein["district"]]["name"], GameData.ORE_TYPES[vein["oreType"]]["name"]]
				var entry := _entry("buy", "veins", "vein", key, name, vein["oreType"], "", VeinTrade.quote(vein), 1, 1, sell_state.get(key, 0))
				entry["veinId"] = vein["id"]
				entries.append(entry)
	return entries


func _entry(direction: String, category: String, kind: String, key: String, name: String, ore_type: String, symbol: String, price: int, stock: int, max_qty: int, qty: int) -> Dictionary:
	return { "direction": direction, "category": category, "kind": kind, "key": key, "name": name, "oreType": ore_type, "symbol": symbol, "price": price, "stock": stock, "max": max_qty, "qty": qty }


func _totals(entries: Array) -> Dictionary:
	var gross := 0
	var cost := 0
	var count := 0
	var veins := 0
	for entry in entries:
		var qty: int = entry["qty"]
		if qty <= 0:
			continue
		count += qty
		if entry["kind"] == "vein" and entry["direction"] == "sell":
			veins += qty
		if entry["direction"] == "buy":
			cost += qty * int(entry["price"])
		else:
			gross += qty * int(entry["price"])
	var net := gross - cost if _is_faction() else int(floor(gross * Economy.get_archie_cut_ratio()))
	return { "gross": gross, "cost": cost, "net": net, "count": count, "veins": veins }


func _select_direction(direction: String) -> void:
	_direction = direction
	_category = "ore"
	_review = false
	_render(true)


func _select_category(category: String) -> void:
	_category = category
	_render(true)


func _toggle_item(recipe_key: String) -> void:
	_expanded_items[recipe_key] = not _expanded_items.get(recipe_key, false)
	_render()


func _adjust(entry: Dictionary, delta: int) -> void:
	Economy.adjust_sell_qty(entry["key"], delta, entry["max"])


func _toggle_vein(entry: Dictionary) -> void:
	if entry["direction"] == "buy":
		Economy.toggle_buy_vein(entry["veinId"])
	else:
		Economy.toggle_sell_vein(entry["veinId"])


func _show_review() -> void:
	_review = true
	_render(true)


func _back_or_cancel() -> void:
	if _review:
		_review = false
		_render()
	else:
		SellMenuModal.cancel()


func _confirm() -> void:
	if _is_faction():
		Collective.complete_trade(_data.get("contactId", ""))
	else:
		Economy.sell_from_sell_state()


func _is_faction() -> bool:
	return _faction_id() != ""


func _faction_id() -> String:
	return _data.get("factionId", "")


func _veins_unlocked() -> bool:
	return GameState.state["flags"].get("veinSaleUnlocked", false)


func _gold() -> Color:
	return GameData.PALETTE.get("calc_gold", Color("#d4af52"))


func _label(value: String, font_size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _button(value: String, callback: Callable, fill: Color, height: float) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = height
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.pressed.connect(callback)
	button.add_theme_stylebox_override("normal", _style(fill, 9))
	button.add_theme_stylebox_override("hover", _style(BUTTON_BG if fill.a < 0.01 else fill.lightened(0.10), 9))
	button.add_theme_stylebox_override("pressed", _style(fill.darkened(0.12), 9))
	button.add_theme_stylebox_override("disabled", _style(BUTTON_BG.darkened(0.25), 9))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_pressed_color", TEXT)
	button.add_theme_color_override("font_disabled_color", MUTED)
	return button


func _surface(fill: Color, margin: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(fill, margin))
	return panel


func _style(fill: Color, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	style.set_corner_radius_all(8)
	return style


func _divider() -> ColorRect:
	var line := ColorRect.new()
	line.color = LINE
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line
