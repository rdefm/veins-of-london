class_name SellMenuView
extends PanelContainer

# Trade-only chrome. Selections remain in GameState.sellState through Economy;
# tabs, expanded item groups and the review step are local presentation state.
# Five modes by data: Archie (no factionId), a Collective contact (factionId +
# contactId), a faction's own shop (factionId, empty contactId), a recipe
# seller (recipeSeller): buy-only knowledge via RecipeKnowledge.buy, with the
# selected rungs held locally (spec § Trade sheet recipe-seller mode), or the
# Soho Marketplace (soho): rows and fees from Soho, trades through Soho.trade.

const BG := Color("#222226")
const SURFACE := Color("#2c2c31")
const LINE := Color("#47474d")
const TEXT := Color("#ededee")
const MUTED := Color("#a6a7ab")
const BUTTON_BG := Color("#3b3b40")

# One live ore glyph, centred in its control.
class _OreChipGlyph extends Control:
	var ore_type := ""
	var colour := Color.WHITE

	func _draw() -> void:
		OreGlyphs.draw(self, size * 0.5, ore_type, colour, size.x * 0.38)


var _data: Dictionary = {}
var _direction := "sell"
var _category := "ore"
var _review := false
var _expanded_items: Dictionary = {}
var _picked_rungs: Dictionary = {}
var _expanded_recipes: Dictionary = {}
var _ore_filter := ""
var _soho_rung := -1
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
	_picked_rungs.clear()
	_expanded_recipes.clear()
	_ore_filter = ""
	_soho_rung = -1
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
	var entries := _recipe_entries() if _is_recipe_seller() else _entries()
	_build_header(layout)
	if not _review:
		_build_categories(layout)
	_scroll = TouchScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_scroll)
	var body_margin := MarginContainer.new()
	body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 14)
	body_margin.add_theme_constant_override("margin_right", 14)
	_scroll.add_child(body_margin)
	var body := UI.vbox(0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.add_child(body)
	if _is_recipe_seller():
		if _review:
			_build_recipe_review(body, entries)
		else:
			_build_recipe_list(body, entries)
		_build_recipe_footer(layout, entries)
	else:
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
	var kicker := "ARCHIE / TRADE"
	if _is_recipe_seller():
		kicker = "%s / TRADE" % RecipeKnowledge.seller_name(_recipe_seller()).to_upper()
	elif _is_soho():
		kicker = "SOHO MARKETPLACE / TRADE"
	elif _is_shop():
		kicker = "%s / TRADE" % String(GameData.FACTIONS[_faction_id()]["name"]).to_upper()
	elif _is_faction():
		var contact := Contacts.display_name(_data.get("contactId", "des"))
		kicker = "%s · %s / TRADE" % [contact.to_upper(), String(GameData.FACTIONS[_faction_id()]["name"]).to_upper()]
	headings.add_child(_label(kicker, 11, MUTED))
	var title := "Buy goods" if _direction == "buy" else "Sell goods"
	if _is_recipe_seller():
		title = "Buy recipes"
	headings.add_child(_label("Review trade" if _review else title, 22, TEXT))
	var close := _button("×", func(): SellMenuModal.cancel(), Color.TRANSPARENT, 44)
	close.custom_minimum_size.x = 44
	close.accessibility_name = "Close trade"
	top.add_child(close)
	var note := "Direct trade. No cut or mugging." if _is_faction() else "Archie's cut changes with your relation."
	if _is_soho():
		# PROSE-REVIEW: Soho sheet note.
		note = "Open market. No mugging. The bigger the order, the lower the fee."
	if _is_recipe_seller():
		# PROSE-REVIEW: recipe-seller sheet note.
		note = "Knowledge, not goods. It goes straight to your lab."
	content.add_child(_label(note, 12, MUTED))
	if _is_recipe_seller():
		return
	if Harassment.has_sell_penalty() and not _is_soho():
		content.add_child(_label("Some prices are marked down against you.", 12, MUTED))
	if (_is_faction() or _is_soho()) and not _review:
		var direction_row := UI.hbox(5)
		content.add_child(direction_row)
		for direction in ["sell", "buy"]:
			var label := "Sell from my stock"
			if direction == "buy":
				if _is_soho():
					label = "Buy from Soho"
				else:
					label = "Buy from %s" % GameData.FACTIONS[_faction_id()]["shortName"] if _is_shop() else "Buy from contact"
			var fill := UI.action_colour() if _direction == direction else BUTTON_BG
			var button := _button(label, _select_direction.bind(direction), fill, 44)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			direction_row.add_child(button)


func _build_categories(layout: VBoxContainer) -> void:
	var panel := _surface(BG, 10)
	layout.add_child(panel)
	var row := UI.hbox(6)
	panel.add_child(row)
	var categories := ["recipes"] if _is_recipe_seller() else ["ore", "items", "veins"]
	for category in categories:
		if category == "veins" and (_is_soho() or not _veins_unlocked()):
			continue
		var chosen: bool = _category == category or _is_recipe_seller()
		var fill := TEXT if chosen else Color.TRANSPARENT
		var button := _button(category.capitalize(), _select_category.bind(category), fill, 40)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	# Bought items arrive at the tiers the faction holds, so buy rows stay one per recipe.
	if _category == "items" and (_direction == "sell" or _is_soho()):
		_build_item_groups(body, relevant)
		return
	for entry in relevant:
		_add_row(body, entry)


func _build_item_groups(body: VBoxContainer, entries: Array) -> void:
	var groups: Dictionary = {}
	var order: Array[String] = []
	for entry in entries:
		var recipe_key: String = entry["groupKey"]
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
		glyph.icon = ItemIcons.texture(tiers[0]["recipeKey"])
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
			badge.add_child(_label("%d selected" % picked, 11, TEXT, false))
			inner.add_child(badge)
		inner.add_child(_label("⌃" if expanded else "⌄", 18, MUTED, false))
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
			glyph.icon = ItemIcons.texture(entry.get("recipeKey", ""))
		row.add_child(glyph)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	var name: String = entry["name"]
	if tier_row:
		name = "Untiered" if int(entry["tier"]) <= 0 else "Tier %d" % int(entry["tier"])
	info.add_child(_label(name, 14, TEXT))
	var meta := _meta_flow()
	info.add_child(meta)
	meta.add_child(_label(UI.price_text(entry["kind"], int(entry["price"])), 12, _gold(), false))
	if entry["kind"] != "vein":
		var move := Market.day_move(entry["kind"], entry["oreType"] if entry["kind"] == "ore" else entry["recipeKey"])
		if move != 0:
			meta.add_child(_label(" " + PriceMove.text(move), 12, PriceMove.colour(move, MUTED), false))
	if entry["kind"] == "vein":
		meta.add_child(_label(" / vein", 12, MUTED, false))
	elif Market.price_lot(entry["kind"]) <= 1:
		meta.add_child(_label(" each", 12, MUTED, false))
	if entry["kind"] == "vein":
		meta.add_child(_label(" · Lv %d" % int(entry["level"]), 12, MUTED, false))
	var stock_text := " · %d available" % int(entry["stock"])
	if entry["direction"] == "buy":
		stock_text = " · stock %d" % int(entry["stock"])
	meta.add_child(_label(stock_text, 12, MUTED, false))
	if entry["kind"] == "vein":
		var chosen := int(entry["qty"]) > 0
		var button := _button("✓ Added" if chosen else "+ Add", _toggle_vein.bind(entry), BUTTON_BG, 44)
		button.disabled = not chosen and int(entry["max"]) <= 0
		row.add_child(button)
	elif int(entry["max"]) <= 0:
		row.add_child(_label("Sold out" if int(entry["stock"]) <= 0 else "Unavailable", 12, MUTED, false))
	else:
		var slider := MapCardStyle.quantity_slider("", int(entry["qty"]), int(entry["max"]), func(_value: int): pass, _set_qty.bind(entry), 0)
		slider.custom_minimum_size.x = 150
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		(slider.get_child(0) as HSlider).accessibility_name = "%s quantity" % entry["name"]
		(slider.get_child(1) as Label).add_theme_color_override("font_color", TEXT)
		row.add_child(slider)
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
		row.add_child(_label("%s£%d" % [sign, Market.line_total(entry["kind"], int(entry["price"]), int(entry["qty"]))], 13, _gold(), false))
		body.add_child(_divider())
	if not any_selected:
		body.add_child(_label("No goods selected.", 14, MUTED))
	elif _is_soho():
		var rows := Soho.fee_rows(_direction, _soho_cart(entries))
		var fee_row := UI.hbox(8)
		fee_row.custom_minimum_size.y = 44
		body.add_child(fee_row)
		var fee_label := _label("Fee · %d%%" % int(round(float(rows["rate"]) * 100.0)), 13, MUTED)
		fee_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fee_row.add_child(fee_label)
		fee_row.add_child(_label("−£%d" % int(rows["fee"]), 13, _gold(), false))


func _build_footer(layout: VBoxContainer, entries: Array) -> void:
	if _is_soho():
		_build_soho_footer(layout, entries)
		return
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
	summary.add_child(_label("£%d" % absi(net), 22, _gold(), false))
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


func _build_soho_footer(layout: VBoxContainer, entries: Array) -> void:
	var rows := Soho.fee_rows(_direction, _soho_cart(entries))
	var panel := _surface(SURFACE, 12)
	layout.add_child(panel)
	var content := UI.vbox(6)
	panel.add_child(content)
	var summary := UI.hbox(8)
	content.add_child(summary)
	var explanation := UI.vbox(1)
	explanation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(explanation)
	var net: int = rows["net"]
	explanation.add_child(_label("YOU PAY" if net < 0 else "YOU RECEIVE", 11, TEXT))
	var rate_pct := int(round(float(rows["rate"]) * 100.0))
	explanation.add_child(_label("%d selected · £%d at %d%% fee (£%d)" % [rows["units"], rows["value"], rate_pct, rows["fee"]], 12, MUTED))
	summary.add_child(_label("£%d" % absi(net), 22, _gold(), false))
	if int(rows["units"]) > 0:
		var crossing := _soho_crossing_text(rows)
		if crossing != "":
			content.add_child(_label(crossing, 13, _gold(), false))
		_soho_rung = int(rows["rung"])
		content.add_child(_label("Rung %d of %d · %s" % [int(rows["rung"]) + 1, rows["rungCount"], _soho_rung_text(rows)], 12, MUTED))
		content.add_child(_label(_soho_ladder_text(rows), 12, MUTED))
		if _direction == "sell":
			var gap := int(rows["net"]) - int(rows["archieNet"])
			var versus := "Soho pays £%d %s than Archie (£%d, his fee %d%%)" % [absi(gap), "more" if gap >= 0 else "less", rows["archieNet"], int(round(float(rows["archieFeeRate"]) * 100.0))]
			content.add_child(_label(versus, 12, MUTED))
	else:
		_soho_rung = -1
	var actions := UI.hbox(8)
	content.add_child(actions)
	actions.add_child(_button("Back" if _review else "Cancel", _back_or_cancel, Color.TRANSPARENT, 44))
	var primary := _button("Confirm trade" if _review else "Review trade →", _confirm if _review else _show_review, UI.action_colour(), 48)
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary.disabled = int(rows["units"]) == 0 or (net < 0 and absi(net) > int(GameState.state["player"]["cash"]))
	actions.add_child(primary)


# PROSE-REVIEW: Soho rung / next-step lines.
func _soho_rung_text(rows: Dictionary) -> String:
	if rows["isTop"]:
		return "Best rate reached: %d%%." % int(round(float(rows["rate"]) * 100.0))
	var next: Dictionary = rows["next"]
	var verb := "Sell" if _direction == "sell" else "Buy"
	return "%s £%d more (about %d units) to drop to %d%%." % [verb, next["needValue"], next["needUnits"], int(round(float(next["rate"]) * 100.0))]


func _soho_crossing_text(rows: Dictionary) -> String:
	var rung := int(rows["rung"])
	if _soho_rung < 0 or rung == _soho_rung:
		return ""
	var pct := int(round(float(rows["rate"]) * 100.0))
	if rung > _soho_rung:
		return "Rung %d reached: fee drops to %d%%." % [rung + 1, pct]
	return "Back to rung %d: fee rises to %d%%." % [rung + 1, pct]


func _soho_ladder_text(rows: Dictionary) -> String:
	var parts: Array[String] = []
	for step in rows["ladder"]:
		var text := "£%d+ %d%%" % [step["from"], int(round(float(step["rate"]) * 100.0))]
		parts.append("[%s]" % text if step["active"] else text)
	return "Fee ladder: " + " · ".join(parts)


func _build_recipe_list(body: VBoxContainer, entries: Array) -> void:
	if entries.is_empty():
		body.add_child(_label("Nothing available here.", 14, MUTED))
		return
	_build_ore_filter(body)
	var shown := RecipeKnowledge.seller_recipes(_recipe_seller(), _ore_filter)
	var current := ""
	for entry in entries:
		var recipe_key: String = entry["recipeKey"]
		if not shown.has(recipe_key):
			continue
		if recipe_key != current:
			current = recipe_key
			_add_recipe_header(body, recipe_key)
		if _expanded_recipes.get(recipe_key, false):
			_add_recipe_row(body, entry)
	if shown.is_empty():
		body.add_child(_label("Nothing available here.", 14, MUTED))


# All plus only the ores this seller teaches.
func _build_ore_filter(body: VBoxContainer) -> void:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	body.add_child(flow)
	var options: Array = [""]
	options.append_array(RecipeKnowledge.seller_ores(_recipe_seller()))
	for ore in options:
		var ore_type: String = ore
		var title := "All" if ore_type.is_empty() else str(GameData.ORE_TYPES[ore_type]["name"]).get_slice(" ", 0)
		var picked := ore_type == _ore_filter
		var chip := _button(title, _set_ore_filter.bind(ore_type), UI.action_colour() if picked else BUTTON_BG, 36)
		chip.accessibility_name = "%s filter" % title
		chip.clip_text = false
		chip.custom_minimum_size = Vector2(96 if ore_type.is_empty() else 112, 40)
		flow.add_child(chip)
		if not ore_type.is_empty():
			for state in ["normal", "hover", "pressed"]:
				var box: StyleBoxFlat = chip.get_theme_stylebox(state).duplicate()
				box.content_margin_left = 34
				chip.add_theme_stylebox_override(state, box)
			var glyph := _OreChipGlyph.new()
			glyph.ore_type = ore_type
			glyph.colour = MapPalette.ore_colour_in(ore_type, false)
			glyph.set_anchors_preset(Control.PRESET_LEFT_WIDE)
			glyph.offset_left = 6
			glyph.offset_right = 32
			glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chip.add_child(glyph)
	body.add_child(_divider())


func _set_ore_filter(ore_type: String) -> void:
	_ore_filter = ore_type
	_render(true)


func _toggle_recipe(recipe_key: String) -> void:
	_expanded_recipes[recipe_key] = not _expanded_recipes.get(recipe_key, false)
	_render()


# Collapsed row: icon, name and effect sentence; a tap shows or hides its rungs.
func _add_recipe_header(body: VBoxContainer, recipe_key: String) -> void:
	var recipe: Dictionary = GameData.RECIPES[recipe_key]
	var open: bool = _expanded_recipes.get(recipe_key, false)
	var tap := _button("", _toggle_recipe.bind(recipe_key), Color.TRANSPARENT, 56)
	tap.accessibility_name = str(recipe.get("name", recipe_key))
	tap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(tap)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tap.add_child(margin)
	var row := UI.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var glyph := SymbolGlyph.new()
	glyph.symbol = recipe.get("symbol", "")
	glyph.draw_fallback = SymbolGlyph.generic_fallback()
	glyph.icon = ItemIcons.texture(recipe_key)
	glyph.color = TEXT
	glyph.font_size = 19
	glyph.glyph_radius = 8.0
	glyph.custom_minimum_size = Vector2(28, 28)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(glyph)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	info.add_child(_label(str(recipe.get("name", recipe_key)), 14, TEXT))
	info.add_child(_label(str(recipe.get("effectText", "")), 12, MUTED))
	row.add_child(_label("▾" if open else "▸", 14, MUTED, false))


func _add_recipe_row(body: VBoxContainer, entry: Dictionary) -> void:
	var indent := MarginContainer.new()
	indent.add_theme_constant_override("margin_left", 36)
	body.add_child(indent)
	var row := UI.hbox(8)
	row.custom_minimum_size.y = 60
	indent.add_child(row)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	info.add_child(_label("%s · rank %d" % [entry["name"], int(entry["ceiling"])], 14, TEXT))
	var meta := _meta_flow()
	info.add_child(meta)
	match entry["state"]:
		"owned":
			meta.add_child(_label("✓ Known", 12, MUTED, false))
		"master":
			info.add_child(_label(entry["reason"], 12, MUTED))
		_:
			meta.add_child(_label("£%d" % int(entry["price"]), 12, _gold(), false))
			if entry["vague"]:
				meta.add_child(_label(" · vague, buy it exact", 12, MUTED, false))
	if entry["state"] == "locked":
		info.add_child(_label(entry["reason"], 12, MUTED))
	if entry["state"] == "buyable":
		var chosen: bool = entry["selected"]
		var button := _button("✓ Added" if chosen else "+ Add", _toggle_rung.bind(entry), BUTTON_BG, 44)
		button.accessibility_name = "%s %s" % [GameData.RECIPES[entry["recipeKey"]].get("name", ""), entry["name"]]
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(button)
	body.add_child(_divider())


func _build_recipe_review(body: VBoxContainer, entries: Array) -> void:
	var any_selected := false
	for entry in entries:
		if not entry["selected"]:
			continue
		any_selected = true
		var row := UI.hbox(8)
		row.custom_minimum_size.y = 44
		body.add_child(row)
		var line := "Buy %s · %s" % [GameData.RECIPES[entry["recipeKey"]].get("name", ""), entry["name"]]
		var description := _label(line, 13, TEXT)
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(description)
		row.add_child(_label("−£%d" % int(entry["price"]), 13, _gold(), false))
		body.add_child(_divider())
	if not any_selected:
		body.add_child(_label("No recipes selected.", 14, MUTED))


func _build_recipe_footer(layout: VBoxContainer, entries: Array) -> void:
	var count := 0
	var cost := 0
	for entry in entries:
		if entry["selected"]:
			count += 1
			cost += int(entry["price"])
	var panel := _surface(SURFACE, 12)
	layout.add_child(panel)
	var content := UI.vbox(6)
	panel.add_child(content)
	var summary := UI.hbox(8)
	content.add_child(summary)
	var explanation := UI.vbox(1)
	explanation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(explanation)
	explanation.add_child(_label("YOU PAY", 11, TEXT))
	explanation.add_child(_label("%d selected" % count, 12, MUTED))
	summary.add_child(_label("£%d" % cost, 22, _gold(), false))
	var actions := UI.hbox(8)
	content.add_child(actions)
	actions.add_child(_button("Back" if _review else "Cancel", _back_or_cancel, Color.TRANSPARENT, 44))
	var primary := _button("Confirm trade" if _review else "Review trade →", _confirm if _review else _show_review, UI.action_colour(), 48)
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary.disabled = count == 0 or cost > int(GameState.state["player"]["cash"])
	actions.add_child(primary)


# One row per rung of each of the seller's recipes, in ladder order. A rung
# is buyable when buy() would take it now, short only of cash, or once the
# rung before it is selected; picks that stop being buyable are dropped.
func _recipe_entries() -> Array:
	var entries: Array = []
	var seller_id := _recipe_seller()
	var refusals: Dictionary = GameData.RECIPE_KNOWLEDGE.get("buyRefusals", {})
	var rungs := RecipeKnowledge.rungs()
	for recipe_key in GameData.RECIPES.keys():
		if RecipeKnowledge.seller_of(recipe_key) != seller_id or not RecipeKnowledge.teachable(recipe_key):
			continue
		var prev_ready := false
		for i in rungs.size():
			var rung: String = rungs[i]
			var key := "%s|%s" % [recipe_key, rung]
			var held := RecipeKnowledge.rung_state(recipe_key, rung)
			var block := RecipeKnowledge.buy_block(recipe_key, rung)
			var state := "locked"
			if rung == "master":
				state = "master"
			elif held == "exact":
				state = "owned"
			elif block.is_empty() or block == str(refusals.get("cash", "")):
				state = "buyable"
			elif prev_ready and i > 0 and block == str(refusals.get("order", "%s")) % RecipeKnowledge.rung_label(rungs[i - 1]):
				state = "buyable"
			if state != "buyable":
				_picked_rungs.erase(key)
			var selected: bool = _picked_rungs.has(key)
			entries.append({
				"recipeKey": recipe_key,
				"rung": rung,
				"key": key,
				"name": RecipeKnowledge.rung_label(rung),
				"ceiling": RecipeKnowledge.rung_ceiling(rung),
				"state": state,
				"vague": held == "vague",
				"reason": block,
				"price": 0 if rung == "master" else RecipeKnowledge.price(recipe_key, rung),
				"selected": selected,
			})
			# The next rung may ride on this one once it is held or selected.
			prev_ready = state == "owned" or held == "vague" or selected
	return entries


# Soho rows: sell lists what the pool holds, buy lists every good and tier
# London carries (empty ones show max 0). Cart qty lives in sellState under
# "soho_<side>_<kind>_<type>_<tier>".
func _soho_entries() -> Array:
	var entries: Array = []
	var sell_state: Dictionary = GameState.state["sellState"]
	for side in [Soho.SELL, Soho.BUY]:
		for ore_type in GameData.ORE_TYPES.keys():
			if not Soho.is_tradable("ore", ore_type, side):
				continue
			var held := Soho.sellable_qty("ore", ore_type)
			var stock := held if side == Soho.SELL else Soho.buyable_qty("ore", ore_type)
			if side == Soho.SELL and held <= 0:
				continue
			var ore: Dictionary = GameData.ORE_TYPES[ore_type]
			var key := "soho_%s_ore_%s_0" % [side, ore_type]
			var ore_entry := _entry(side, "ore", "ore", key, ore["name"], ore_type, ore["symbol"], Market.quote("ore", ore_type), stock, stock, sell_state.get(key, 0))
			ore_entry["good"] = ore_type
			ore_entry["tier"] = 0
			entries.append(ore_entry)
		for recipe_key in GameData.RECIPES.keys():
			if not Soho.is_tradable("consumable", recipe_key, side):
				continue
			var recipe: Dictionary = GameData.RECIPES[recipe_key]
			for tier in range(1, Market.tier_count() + 1):
				var stock := Soho.sellable_qty("consumable", recipe_key, tier) if side == Soho.SELL else Soho.buyable_qty("consumable", recipe_key, tier)
				if side == Soho.SELL and stock <= 0:
					continue
				var key := "soho_%s_consumable_%s_%d" % [side, recipe_key, tier]
				var item := _entry(side, "items", "consumable", key, "%s · tier %d" % [recipe["name"], tier], "", recipe["symbol"], Market.tier_price(recipe_key, tier), stock, stock, sell_state.get(key, 0))
				item["recipeKey"] = recipe_key
				item["groupName"] = recipe["name"]
				item["groupKey"] = recipe_key
				item["good"] = recipe_key
				item["tier"] = tier
				entries.append(item)
	return entries


# The current side's chosen rows as a Soho cart.
func _soho_cart(entries: Array) -> Array:
	var cart: Array = []
	for entry in entries:
		if entry["direction"] == _direction and int(entry["qty"]) > 0:
			cart.append({ "kind": entry["kind"], "type": entry["good"], "tier": entry["tier"], "qty": entry["qty"] })
	return cart


func _entries() -> Array:
	if _is_soho():
		return _soho_entries()
	var entries: Array = []
	var player: Dictionary = GameState.state["player"]
	var sell_state: Dictionary = GameState.state["sellState"]
	var faction_id := _faction_id()
	var price_mod: float = Turf.price_mod(GameState.state["world"]["currentDistrict"])
	for ore_type in GameData.ORE_TYPES.keys():
		var ore: Dictionary = GameData.ORE_TYPES[ore_type]
		var have: int = player["orichalchum"].get(ore_type, 0)
		if have > 0:
			var sell_price: int
			if _is_faction():
				sell_price = Economy.get_faction_sell_price(faction_id, "ore", ore_type)
			else:
				sell_price = Economy.get_archie_ore_price(ore_type, price_mod)
			var key := "ore_%s" % ore_type
			entries.append(_entry("sell", "ore", "ore", key, ore["name"], ore_type, ore["symbol"], sell_price, have, _sell_max(have, "ore", ore_type), sell_state.get(key, 0)))
		if _is_faction():
			var stock := FactionSim.ore_held(faction_id, ore_type)
			var buy_key := "buyOre_%s" % ore_type
			var max_qty := Economy.get_faction_buy_max_qty(faction_id, "ore", ore_type)
			entries.append(_entry("buy", "ore", "ore", buy_key, ore["name"], ore_type, ore["symbol"], Economy.get_faction_buy_price(faction_id, "ore", ore_type), stock, max_qty, sell_state.get(buy_key, 0)))
	if GameState.state["flags"]["canSellConsumables"]:
		for recipe_key in GameData.CONSUMABLE_PRICES.keys():
			var recipe: Dictionary = GameData.RECIPES[recipe_key]
			for multi in [false, true]:
				var buckets: Dictionary = player["inventory"].get(Crafting.inventory_key(recipe_key, multi), {})
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
						price = Economy.get_archie_consumable_price(recipe_key, tier, price_mod)
					var key := Economy.sell_key(recipe_key, tier_key, multi)
					var tier_label := "untiered" if tier <= 0 else "tier %d" % tier
					var item_name: String = recipe["name"] + (" (multi)" if multi else "")
					var item := _entry("sell", "items", "consumable", key, "%s · %s" % [item_name, tier_label], "", recipe["symbol"], price, have, _sell_max(have, "consumable", recipe_key), sell_state.get(key, 0))
					item["recipeKey"] = recipe_key
					item["groupName"] = item_name
					item["groupKey"] = recipe_key + ("_multi" if multi else "")
					item["tier"] = tier
					entries.append(item)
			if _is_faction():
				var buy_key := "buyCon_%s" % recipe_key
				var stock := FactionSim.for_sale(faction_id, "consumable", recipe_key)
				var max_qty := Economy.get_faction_buy_max_qty(faction_id, "consumable", recipe_key)
				var buy_item := _entry("buy", "items", "consumable", buy_key, recipe["name"], "", recipe["symbol"], Economy.get_faction_buy_price(faction_id, "consumable", recipe_key), stock, max_qty, sell_state.get(buy_key, 0))
				buy_item["recipeKey"] = recipe_key
				entries.append(buy_item)
	if _veins_unlocked():
		for vein in player["veins"]:
			var price := VeinTrade.quote(vein) if _is_faction() else Economy.get_archie_vein_price(vein)
			var key := "vein_%s" % vein["id"]
			var name := "%s · %s" % [GameData.DISTRICTS[vein["district"]]["name"], GameData.ORE_TYPES[vein["oreType"]]["name"]]
			var entry := _entry("sell", "veins", "vein", key, name, vein["oreType"], "", price, 1, 1, sell_state.get(key, 0))
			entry["veinId"] = vein["id"]
			entry["level"] = int(vein.get("level", 1))
			entries.append(entry)
		if _is_faction():
			for site in Sites.sites_with_faction_vein(faction_id):
				var vein: Dictionary = site["factionVein"]
				var key := "buyVein_%s" % vein["id"]
				var name := "%s · %s" % [GameData.DISTRICTS[vein["district"]]["name"], GameData.ORE_TYPES[vein["oreType"]]["name"]]
				var entry := _entry("buy", "veins", "vein", key, name, vein["oreType"], "", VeinTrade.quote(vein), 1, 1, sell_state.get(key, 0))
				entry["veinId"] = vein["id"]
				entry["level"] = int(vein.get("level", 1))
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
			cost += Market.line_total(entry["kind"], int(entry["price"]), qty)
		else:
			gross += Market.line_total(entry["kind"], int(entry["price"]), qty)
	var net := gross - cost if _is_faction() else int(floor(gross * Economy.get_archie_cut_ratio()))
	return { "gross": gross, "cost": cost, "net": net, "count": count, "veins": veins }


func _select_direction(direction: String) -> void:
	_direction = direction
	_soho_rung = -1
	_category = "ore"
	_review = false
	_render(true)


func _select_category(category: String) -> void:
	_category = category
	_render(true)


func _toggle_item(recipe_key: String) -> void:
	_expanded_items[recipe_key] = not _expanded_items.get(recipe_key, false)
	_render()


func _set_qty(qty: int, entry: Dictionary) -> void:
	Economy.set_sell_qty(entry["key"], qty, entry["max"])


# Dropping a rung drops the later rungs of that recipe picked on its back.
func _toggle_rung(entry: Dictionary) -> void:
	var key: String = entry["key"]
	if _picked_rungs.has(key):
		var rungs := RecipeKnowledge.rungs()
		for i in range(rungs.find(entry["rung"]), rungs.size()):
			_picked_rungs.erase("%s|%s" % [entry["recipeKey"], rungs[i]])
	else:
		_picked_rungs[key] = true
	_render()


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
	if _is_recipe_seller():
		_confirm_recipes()
	elif _is_soho():
		var result := Soho.trade(_direction, _soho_cart(_soho_entries()))
		ContactCards.notify_failure(result)
		if result["ok"]:
			Economy.clear_sell_state()
			_review = false
			_render(true)
	elif _is_shop():
		Economy.complete_shop_trade(_faction_id())
	elif _is_faction():
		Collective.complete_trade(_data.get("contactId", ""))
	else:
		Economy.sell_from_sell_state()


# Buys each selected rung in ladder order; the sheet stays open on the
# refreshed rows.
func _confirm_recipes() -> void:
	var picked: Array = []
	for entry in _recipe_entries():
		if entry["selected"]:
			picked.append(entry)
	_picked_rungs.clear()
	_review = false
	for entry in picked:
		ContactCards.notify_failure(RecipeKnowledge.buy(entry["recipeKey"], entry["rung"]))
	_render()


func _is_soho() -> bool:
	return bool(_data.get("soho", false))


func _is_recipe_seller() -> bool:
	return _recipe_seller() != ""


func _recipe_seller() -> String:
	return _data.get("recipeSeller", "")


func _is_faction() -> bool:
	return _faction_id() != ""


# A faction's own shop: a faction trade with no contact attached.
func _is_shop() -> bool:
	return _is_faction() and _data.get("contactId", "") == ""


# Shop sell rows also cap at what the faction's cash can pay for.
func _sell_max(have: int, kind: String, item_type: String) -> int:
	if not _is_shop():
		return have
	return mini(have, Economy.get_faction_sell_max_qty(_faction_id(), kind, item_type))


func _faction_id() -> String:
	return _data.get("factionId", "")


func _veins_unlocked() -> bool:
	return GameState.state["flags"].get("veinSaleUnlocked", false)


func _gold() -> Color:
	return GameData.PALETTE.get("calc_gold", Color("#d4af52"))


func _label(value: String, font_size: int, colour: Color, wrap: bool = true) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", font_size)
	return label


# Flow so a long price/stock line wraps below instead of widening the row.
func _meta_flow() -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 3)
	flow.add_theme_constant_override("v_separation", 0)
	return flow


func _button(value: String, callback: Callable, fill: Color, height: float) -> Button:
	var button := TapButton.new()
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
	panel.mouse_filter = Control.MOUSE_FILTER_PASS  # drags must reach the scroller
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
