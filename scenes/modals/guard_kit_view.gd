class_name GuardKitView
extends PanelContainer

# Guard kit stocking sheet, on the Trade sheet pattern (sell_menu_view.gd):
# Stock/Return tabs, grouped item tiers, a stepper per tier, sticky slot
# totals and a review step. modal.data.target is a GuardKit kit target.
# Picked quantities, the tab, expanded groups and the review step are local
# presentation state; only confirming moves items, through GuardKit.

const BG := Color("#222226")
const SURFACE := Color("#2c2c31")
const LINE := Color("#47474d")
const TEXT := Color("#ededee")
const MUTED := Color("#a6a7ab")
const BUTTON_BG := Color("#3b3b40")
const STOCK := "stock"
const RETURN := "return"

var _target: Dictionary = {}
var _direction := STOCK
var _review := false
var _picked: Dictionary = {}
var _expanded_items: Dictionary = {}
var _scroll: ScrollContainer


func refresh(data: Dictionary) -> void:
	_target = data.get("target", {})
	_render()


func reset_ui() -> void:
	_target = {}
	_direction = STOCK
	_review = false
	_picked.clear()
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
	var target_name := GuardKit.target_name(_target)
	headings.add_child(_label("GUARD KIT" if target_name == "" else "%s / GUARD KIT" % target_name.to_upper(), 11, MUTED))
	var title := "Review kit" if _review else "Return to stock" if _direction == RETURN else "Stock the kit"
	headings.add_child(_label(title, 22, TEXT))
	var close := _button("×", func(): Modal.close(), Color.TRANSPARENT, 44)
	close.custom_minimum_size.x = 44
	close.accessibility_name = "Close guard kit"
	top.add_child(close)
	content.add_child(_label("%d on guard. They use what's here when a fight comes to them." % GuardKit.target_guard_count(_target), 12, MUTED))
	if _review:
		return
	var tab_row := UI.hbox(5)
	content.add_child(tab_row)
	for direction in [STOCK, RETURN]:
		var fill := UI.action_colour() if _direction == direction else BUTTON_BG
		var button := _button("Stock" if direction == STOCK else "Return", _select_direction.bind(direction), fill, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_row.add_child(button)


func _build_list(body: VBoxContainer, entries: Array) -> void:
	var groups: Dictionary = {}
	var order: Array[String] = []
	for entry in entries:
		if entry["direction"] != _direction:
			continue
		var recipe_key: String = entry["recipeKey"]
		if not groups.has(recipe_key):
			groups[recipe_key] = []
			order.append(recipe_key)
		groups[recipe_key].append(entry)
	if order.is_empty():
		body.add_child(_label("Nothing your guards can use." if _direction == STOCK else "The kit is empty.", 14, MUTED))
		return
	if _expanded_items.is_empty():
		_expanded_items[order[0]] = true
	for recipe_key in order:
		var tiers: Array = groups[recipe_key]
		var held := 0
		var picked := 0
		for entry in tiers:
			held += int(entry["have"])
			picked += int(entry["qty"])
		var expanded: bool = _expanded_items.get(recipe_key, false)
		var where := "held" if _direction == STOCK else "in kit"
		var header := _button("", _toggle_item.bind(recipe_key), Color.TRANSPARENT, 68)
		header.accessibility_name = "%s, %d tiers, %d %s, %d selected" % [tiers[0]["groupName"], tiers.size(), held, where, picked]
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
		item_info.add_child(_label("%d tiers · %d %s" % [tiers.size(), held, where], 12, MUTED))
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
				_add_tier_row(tier_box, entry)
		body.add_child(_divider())


func _add_tier_row(parent: VBoxContainer, entry: Dictionary) -> void:
	var row := UI.hbox(8)
	row.custom_minimum_size.y = 66
	parent.add_child(row)
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	info.add_child(_label(_tier_name(int(entry["tier"])), 14, TEXT))
	info.add_child(_label("%d %s" % [int(entry["have"]), "held" if entry["direction"] == STOCK else "in kit"], 12, MUTED))
	var qty := int(entry["qty"])
	var minus := _button("−", _adjust.bind(entry["key"], -1, int(entry["max"])), BUTTON_BG, 44)
	minus.custom_minimum_size.x = 44
	minus.disabled = qty <= 0
	minus.accessibility_name = "%s fewer" % entry["name"]
	row.add_child(minus)
	var qty_label := _label(str(qty), 14, TEXT, false)
	qty_label.custom_minimum_size.x = 28
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(qty_label)
	var plus := _button("+", _adjust.bind(entry["key"], 1, int(entry["max"])), BUTTON_BG, 44)
	plus.custom_minimum_size.x = 44
	plus.disabled = qty >= int(entry["max"])
	plus.accessibility_name = "%s more" % entry["name"]
	row.add_child(plus)
	parent.add_child(_divider())


func _build_review(body: VBoxContainer, entries: Array) -> void:
	var any_selected := false
	for entry in entries:
		if int(entry["qty"]) <= 0:
			continue
		any_selected = true
		var verb := "Stock" if entry["direction"] == STOCK else "Return"
		var row := UI.hbox(8)
		row.custom_minimum_size.y = 44
		body.add_child(row)
		row.add_child(UI.expand_fill(_label("%s %d × %s" % [verb, int(entry["qty"]), entry["name"]], 13, TEXT)))
		body.add_child(_divider())
	if not any_selected:
		body.add_child(_label("Nothing selected.", 14, MUTED))


func _build_footer(layout: VBoxContainer, entries: Array) -> void:
	var totals := _totals(entries)
	var cap := GuardKit.target_capacity(_target)
	var panel := _surface(SURFACE, 12)
	layout.add_child(panel)
	var content := UI.vbox(6)
	panel.add_child(content)
	var summary := UI.hbox(8)
	content.add_child(summary)
	var explanation := UI.vbox(1)
	explanation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(explanation)
	explanation.add_child(_label("SLOTS USED", 11, TEXT))
	explanation.add_child(_label("%d to stock · %d to return" % [totals["stock"], totals["return"]], 12, MUTED))
	var slots := _label("%d/%d" % [totals["slots"], cap], 22, TEXT, false)
	slots.name = "SlotsTotal"
	summary.add_child(slots)
	if totals["slots"] > cap:
		content.add_child(_label("Over capacity. Items past it sit idle.", 12, MapPalette.colour("danger")))
	var actions := UI.hbox(8)
	content.add_child(actions)
	actions.add_child(_button("Back" if _review else "Cancel", _back_or_cancel, Color.TRANSPARENT, 44))
	var primary := _button("Confirm kit" if _review else "Review kit →", _confirm if _review else _show_review, UI.action_colour(), 48)
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary.disabled = totals["stock"] + totals["return"] == 0
	actions.add_child(primary)


# Stock rows: allowlisted items the player holds, by tier. Return rows: the
# kit by tier. A stock row's max leaves the projected kit within capacity.
func _entries() -> Array:
	var entries: Array = []
	var inventory: Dictionary = GameState.state["player"]["inventory"]
	var kit := GuardKit.target_kit(_target)
	for recipe_key in GameData.GUARD_KIT["items"]:
		for tier_key in _tier_keys(inventory.get(recipe_key, {})):
			entries.append(_entry(STOCK, recipe_key, int(tier_key), int(inventory[recipe_key][tier_key])))
		for tier_key in _tier_keys(kit.get(recipe_key, {})):
			entries.append(_entry(RETURN, recipe_key, int(tier_key), int(kit[recipe_key][tier_key])))
	var free := GuardKit.target_capacity(_target) - int(_totals(entries)["slots"])
	for entry in entries:
		if entry["direction"] == STOCK:
			entry["max"] = mini(int(entry["have"]), int(entry["qty"]) + maxi(0, free))
	return entries


func _entry(direction: String, recipe_key: String, tier: int, have: int) -> Dictionary:
	var recipe: Dictionary = GameData.RECIPES[recipe_key]
	var key := "%s_%s_%d" % [direction, recipe_key, tier]
	var qty := mini(int(_picked.get(key, 0)), have)
	return {
		"direction": direction, "key": key, "recipeKey": recipe_key, "tier": tier,
		"name": "%s · %s" % [recipe["name"], _tier_name(tier).to_lower()],
		"groupName": recipe["name"], "symbol": recipe["symbol"],
		"have": have, "qty": qty, "max": have,
	}


func _tier_keys(buckets: Dictionary) -> Array:
	var keys: Array = []
	for tier_key in buckets.keys():
		if int(buckets[tier_key]) > 0:
			keys.append(tier_key)
	keys.sort_custom(func(a, b): return int(a) < int(b))
	return keys


func _totals(entries: Array) -> Dictionary:
	var stocked := 0
	var returned := 0
	for entry in entries:
		if entry["direction"] == STOCK:
			stocked += int(entry["qty"])
		else:
			returned += int(entry["qty"])
	var slots := GuardKit.unit_count(GuardKit.target_kit(_target)) + stocked - returned
	return { "stock": stocked, "return": returned, "slots": slots }


func _tier_name(tier: int) -> String:
	return "Untiered" if tier <= 0 else "Tier %d" % tier


func _select_direction(direction: String) -> void:
	_direction = direction
	_expanded_items.clear()
	_render(true)


func _toggle_item(recipe_key: String) -> void:
	_expanded_items[recipe_key] = not _expanded_items.get(recipe_key, false)
	_render()


func _adjust(key: String, delta: int, max_qty: int) -> void:
	_picked[key] = clampi(int(_picked.get(key, 0)) + delta, 0, max_qty)
	_render()


func _show_review() -> void:
	_review = true
	_render(true)


func _back_or_cancel() -> void:
	if _review:
		_review = false
		_render()
	else:
		Modal.close()


# Returns go first so the slots they free are there for the stock lines.
func _confirm() -> void:
	var lines: Array = []
	for entry in _entries():
		if int(entry["qty"]) > 0:
			lines.append(entry)
	lines.sort_custom(func(a, b): return a["direction"] == RETURN and b["direction"] == STOCK)
	var target := _target.duplicate()
	_picked.clear()
	for entry in lines:
		if entry["direction"] == RETURN:
			GuardKit.unstock_target(target, entry["recipeKey"], entry["tier"], entry["qty"])
		else:
			GuardKit.stock_target(target, entry["recipeKey"], entry["tier"], entry["qty"])
	Modal.close()


func _label(value: String, font_size: int, colour: Color, wrap: bool = true) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
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
