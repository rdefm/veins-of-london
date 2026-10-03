# The Ticker: News tab (one headline card per barometer axis, drilling into
# an axis detail view with push/pull and greyed influence actions when
# state.phoneNav.selectedAxis is set, plus a faction-headline wires card)
# and Stock Market tab (London prices
# with ▲/▼ versus yesterday, active demand modifiers, and a per-good price
# chart with annotations; ore-type + "In stock" filters, collapsible Ore/Items
# lists). The tab, selected good, filter and collapse are view state held
# here, not in state.phoneNav, so they reset with the screen.
class_name TickerApp
extends PhoneApp

const LineChartScript := preload("res://scenes/components/line_chart.gd")

const SECTION_LABELS := { "economic": "Economic", "social": "Social", "political": "Political" }
const NEWS_TAB := "news"
const STOCK_TAB := "stock"
const ANNOTATION_COLOURS := { "ticker": "pastel_ochre", "flood": "pastel_tan", "undercut": "pastel_tan", "deny": "pastel_sage", "stabiliseSell": "pastel_tan", "stabiliseBuy": "pastel_sage", "positionBuy": "pastel_sage", "positionSell": "pastel_tan", "dump": "pastel_blue", "buy": "pastel_sage", "spike": "pastel_teal", "crash": "pastel_pink" }
const MUTED := Color("#999a9d")
const NEWS_BG := Color("#252528")
const NEWS_INK := Color("#f0eced")
const NEWS_MUTED := Color("#aaa8ac")
const NEWS_RULE := Color("#575157")
const NEWS_RED := Color("#9c2340")
const NEWS_PAPER := Color("#f1eae3")
const NEWS_PAPER_INK := Color("#2a2022")
const SERIF_NAMES: PackedStringArray = ["Georgia", "Times New Roman", "Noto Serif", "DejaVu Serif", "serif"]

var _tab := NEWS_TAB
# { kind, type } of the good whose chart is open, or empty for the list.
var _selected_good := {}
# Stock Market filter: ore types unticked, the "In stock" box, and which
# good lists ("ore"/"consumable") are collapsed. Defaults show everything.
var _hidden_types := {}
var _in_stock_only := false
var _collapsed := {}
var _root: Control = null
var _serif: SystemFont = null


func build(content: VBoxContainer) -> void:
	var selected_axis = GameState.state["phoneNav"].get("selectedAxis")
	if selected_axis != null:
		_build_axis_detail(content, selected_axis)
		return
	if _tab == STOCK_TAB and not _selected_good.is_empty():
		_build_good_detail(content, _selected_good["kind"], _selected_good["type"])
		return
	var page := _mount_news_root()
	if _tab == STOCK_TAB:
		_build_stock_market(page)
	else:
		_build_ticker(page)


func teardown() -> void:
	if _root != null:
		if _root.get_parent() != null:
			_root.get_parent().remove_child(_root)
		_root.queue_free()
		_root = null


func _mount_news_root() -> VBoxContainer:
	_root = UI.vbox(0)
	_root.name = "TickerRoot"
	shell.mount_custom_root(_root)
	_root.add_child(_build_news_header())
	var scroll := UI.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var surface := StyleBoxFlat.new()
	surface.bg_color = NEWS_BG
	scroll.add_theme_stylebox_override("panel", surface)
	_root.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 19)
	margin.add_theme_constant_override("margin_right", 19)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)
	var page := UI.vbox(0)
	page.name = "TickerPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(page)
	return page


func _build_news_header() -> Control:
	var panel := PanelContainer.new()
	panel.name = "TickerHeader"
	var style := StyleBoxFlat.new()
	style.bg_color = NEWS_BG
	style.content_margin_left = 19
	style.content_margin_right = 19
	style.content_margin_top = 9
	panel.add_theme_stylebox_override("panel", style)
	var column := UI.vbox(0)
	panel.add_child(column)
	var top := UI.hbox()
	var back := UI.button("‹ Phone", func(): PhoneNav.go_home())
	back.flat = true
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.add_theme_color_override("font_color", NEWS_INK)
	top.add_child(back)
	var publisher := _news_text(GameData.BAROMETER_NEWS["publisher"], 10, NEWS_MUTED)
	publisher.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(publisher)
	column.add_child(top)
	var brand := UI.hbox(10)
	brand.add_child(_brand_mark())
	var brand_copy := UI.vbox(2)
	brand_copy.add_child(_news_text(GameData.BAROMETER_NEWS["masthead"], 28, NEWS_INK, true))
	brand_copy.add_child(_news_text(GameData.BAROMETER_NEWS["tagline"], 10, NEWS_MUTED))
	brand.add_child(brand_copy)
	column.add_child(_news_margins(brand, 0, 15, 0, 15))
	column.add_child(_news_rule(NEWS_RED, 3))
	column.add_child(_build_news_tabs())
	return panel


func _brand_mark() -> Control:
	var mark := PanelContainer.new()
	mark.custom_minimum_size = Vector2(39, 39)
	var style := StyleBoxFlat.new()
	style.bg_color = NEWS_RED
	mark.add_theme_stylebox_override("panel", style)
	var glyph := _news_text("T·", 27, NEWS_PAPER, true)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.add_child(glyph)
	return mark


func _build_news_tabs() -> Control:
	var tabs := UI.hbox(24)
	for tab in [{ "id": NEWS_TAB, "title": "News" }, { "id": STOCK_TAB, "title": "Stock Market" }]:
		var selected: bool = tab["id"] == _tab
		var tab_column := UI.vbox(0)
		var button := UI.button(tab["title"], func(): _set_tab(tab["id"]))
		button.name = "TickerTab_%s" % tab["id"]
		button.flat = true
		button.disabled = selected
		button.custom_minimum_size.y = 46
		for colour_name in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			button.add_theme_color_override(colour_name, NEWS_INK if selected else NEWS_MUTED)
		tab_column.add_child(button)
		tab_column.add_child(_news_rule(NEWS_INK if selected else NEWS_BG, 2))
		tabs.add_child(tab_column)
	return tabs


func _set_tab(tab: String) -> void:
	_tab = tab
	_selected_good = {}
	refresh()


func _select_good(kind: String, good_type: String) -> void:
	_selected_good = { "kind": kind, "type": good_type }
	refresh()


func _build_ticker(content: VBoxContainer) -> void:
	var banner := PanelContainer.new()
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = NEWS_RED
	banner_style.set_content_margin_all(10)
	banner.add_theme_stylebox_override("panel", banner_style)
	var banner_row := UI.hbox()
	banner_row.add_child(_news_text(GameData.BAROMETER_NEWS["banner"], 11, NEWS_PAPER))
	var current := _news_text(GameData.BAROMETER_NEWS["bannerDetail"], 10, NEWS_PAPER)
	current.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	banner_row.add_child(current)
	banner.add_child(banner_row)
	content.add_child(_news_margins(banner, 0, 14, 0, 13))

	var order := Barometer.news_sections_order()
	for index in range(order.size()):
		var section: String = order[index]
		content.add_child(_build_headline_card(section, index == 0))
	var wires := Barometer.headlines()
	content.add_child(_build_wires_card(wires))


# Faction headlines (vein takeovers and the like), newest first.
func _build_wires_card(wires: Array) -> Control:
	var column := UI.vbox(0)
	column.add_child(_news_rule(NEWS_RED, 2))
	column.add_child(_section_heading(GameData.BAROMETER_NEWS["wires"], GameData.BAROMETER_NEWS["wiresDetail"]))
	if wires.is_empty():
		column.add_child(_news_text(GameData.BAROMETER_NEWS["emptyWires"], 12, NEWS_MUTED))
	for entry in wires:
		column.add_child(_news_rule(NEWS_RULE, 1))
		column.add_child(_news_text(entry["text"], 14, NEWS_INK, true))
		column.add_child(_news_text(Calendar.format_day(int(entry["day"])), 11, NEWS_MUTED))
		column.add_child(_news_margins(Control.new(), 0, 0, 0, 10))
	return _news_margins(column, 0, 25, 0, 0)


# ── Stock Market ────────────────────────────────────────────────────────

func _build_stock_market(content: VBoxContainer) -> void:
	var mods := UI.card()
	mods["content"].add_child(UI.heading("Demand modifiers", 14))
	var modifiers: Array = Market.demand_modifiers()
	if modifiers.is_empty():
		mods["content"].add_child(UI.muted_label("Nothing on the Ticker is moving demand."))
	for mod in modifiers:
		mods["content"].add_child(UI.muted_label(_modifier_text(mod)))
	content.add_child(mods["panel"])

	content.add_child(_build_stock_filter())
	content.add_child(_build_good_section("ore", "Ore"))
	content.add_child(_build_good_section("consumable", "Items"))


# One toggle per ore type plus "In stock"; ticked shows ●, unticked ○.
func _build_stock_filter() -> Control:
	var filter := UI.hflow()
	for ore_type in GameData.MARKET["goods"]["ore"]:
		var shown := not _hidden_types.has(ore_type)
		filter.add_child(UI.button("%s %s" % ["●" if shown else "○", GameData.ORE_TYPES[ore_type]["name"]], func(): _toggle_type(ore_type)))
	filter.add_child(UI.button("%s In stock" % ("●" if _in_stock_only else "○"), func(): _toggle_in_stock()))
	return filter


func _build_good_section(kind: String, title: String) -> Control:
	var section := UI.collapsible_section(title, not _collapsed.has(kind), func(open: bool): _set_section_open(kind, open))
	var goods := shown_goods(kind)
	if goods.is_empty():
		section["content"].add_child(UI.muted_label("Nothing matches the filter."))
	for good_type in goods:
		section["content"].add_child(_good_row(kind, good_type))
	return section["panel"]


# The goods of one kind ("ore" or "consumable") the filter shows, in market order.
func shown_goods(kind: String) -> Array:
	var goods: Array = []
	for good_type in GameData.MARKET["goods"][kind]:
		if _matches_filter(kind, good_type):
			goods.append(good_type)
	return goods


# An ore matches its own type; an item matches if any recipe ingredient's type is ticked.
func _matches_filter(kind: String, good_type: String) -> bool:
	var types: Array = [good_type] if kind == "ore" else GameData.RECIPES[good_type]["ingredients"].keys()
	if types.all(func(t): return _hidden_types.has(t)):
		return false
	return not _in_stock_only or _held(kind, good_type) > 0


func _held(kind: String, good_type: String) -> int:
	if kind == "ore":
		return int(GameState.state["player"]["orichalchum"].get(good_type, 0))
	return Crafting.inventory_qty(good_type)


func _toggle_type(ore_type: String) -> void:
	toggle_type(ore_type)
	refresh()


func toggle_type(ore_type: String) -> void:
	if _hidden_types.has(ore_type):
		_hidden_types.erase(ore_type)
	else:
		_hidden_types[ore_type] = true


func _toggle_in_stock() -> void:
	set_in_stock_only(not _in_stock_only)
	refresh()


func set_in_stock_only(on: bool) -> void:
	_in_stock_only = on


# Header taps toggle visibility in place; this only remembers it across refreshes.
func _set_section_open(kind: String, open: bool) -> void:
	if open:
		_collapsed.erase(kind)
	else:
		_collapsed[kind] = true


func _good_name(kind: String, good_type: String) -> String:
	return GameData.ORE_TYPES[good_type]["name"] if kind == "ore" else GameData.RECIPES[good_type]["name"]


func _good_symbol(kind: String, good_type: String) -> Dictionary:
	if kind == "ore":
		return { "symbol": GameData.ORE_TYPES[good_type]["symbol"], "fallback": SymbolGlyph.ore_fallback(good_type) }
	return { "symbol": GameData.RECIPES[good_type]["symbol"], "fallback": SymbolGlyph.generic_fallback() }


# One tappable price row: symbol, name, price, ▲/▼ + £ delta.
func _good_row(kind: String, good_type: String) -> Control:
	var move := Market.day_move(kind, good_type)
	var b := Button.new()
	b.custom_minimum_size.y = 44
	b.pressed.connect(func(): _select_good(kind, good_type))
	var inner := UI.hbox(8)
	UI.anchor_full_rect(inner)
	b.add_child(inner)
	var symbol := UI.symbol_row([_good_symbol(kind, good_type), _good_name(kind, good_type)])
	symbol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	symbol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inner.add_child(symbol)
	var price := UI.label(UI.price_text(kind, Market.quote(kind, good_type)))
	price.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inner.add_child(price)
	var delta := UI.tinted_label(PriceMove.text(move, true), PriceMove.colour(move, MUTED))
	delta.custom_minimum_size.x = 64
	delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	delta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inner.add_child(delta)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in inner.find_children("*", "Control", true, false):
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _build_good_detail(content: VBoxContainer, kind: String, good_type: String) -> void:
	content.add_child(UI.button("‹ Back to Stock Market", func(): _select_good_list()))
	content.add_child(UI.symbol_row([_good_symbol(kind, good_type), _good_name(kind, good_type)], { "heading_size": 20 }))
	var move := Market.day_move(kind, good_type)
	var price_row := UI.hbox()
	price_row.add_child(UI.label(UI.price_text(kind, Market.quote(kind, good_type))))
	price_row.add_child(UI.tinted_label("%s vs yesterday" % PriceMove.text(move, true), PriceMove.colour(move, MUTED)))
	content.add_child(price_row)

	var series: Dictionary = Market.price_series(kind, good_type)
	var days: Array[int] = series["days"]
	var notes: Array = Market.annotations_for(kind, good_type)
	var markers: Array = []
	for note in notes:
		var index := days.find(int(note["day"]))
		if index >= 0:
			markers.append({ "index": index, "colour_id": ANNOTATION_COLOURS[note["kind"]] })
	var chart_card := UI.card()
	chart_card["content"].add_child(UI.label("Price, last %d days" % days.size()))
	if days.is_empty():
		chart_card["content"].add_child(UI.muted_label("No trading days on record yet."))
	else:
		var chart: LineChart = LineChartScript.new()
		chart_card["content"].add_child(chart.setup(series["values"], days, "calc_gold_light", "£").with_markers(markers))
	content.add_child(chart_card["panel"])

	var notes_card := UI.card()
	notes_card["content"].add_child(UI.heading("Annotations", 14))
	if notes.is_empty():
		notes_card["content"].add_child(UI.muted_label("Nothing worth a note."))
	for i in range(notes.size() - 1, -1, -1):
		var note: Dictionary = notes[i]
		var colour: Color = GameData.PALETTE.get(ANNOTATION_COLOURS[note["kind"]], MUTED)
		notes_card["content"].add_child(UI.tinted_label("%s · %s" % [Calendar.format_day(int(note["day"])), _annotation_text(note)], colour))
	content.add_child(notes_card["panel"])

	var demand_card := UI.card()
	if kind == "ore":
		demand_card["content"].add_child(UI.heading("Demand driven by", 14))
		var drivers: Array = Market.ore_demand_drivers(good_type)
		if drivers.is_empty():
			demand_card["content"].add_child(UI.muted_label("No item shortages pulling on this ore."))
		for driver in drivers:
			demand_card["content"].add_child(UI.muted_label("%s — %d short in London" % [GameData.RECIPES[driver["recipeKey"]]["name"], int(driver["shortage"])]))
	else:
		demand_card["content"].add_child(UI.heading("Ticker demand", 14))
		var any_mod := false
		for mod in Market.demand_modifiers():
			if mod["target"] == "all" or mod["target"] == good_type:
				any_mod = true
				demand_card["content"].add_child(UI.muted_label(_modifier_text(mod)))
		if any_mod:
			demand_card["content"].add_child(UI.label("Net demand ×%.2f" % Barometer.get_item_demand_mult(good_type)))
		else:
			demand_card["content"].add_child(UI.muted_label("The Ticker isn't touching this one."))
	content.add_child(demand_card["panel"])


func _select_good_list() -> void:
	_selected_good = {}
	refresh()


func _modifier_text(mod: Dictionary) -> String:
	var state_label: String = GameData.BAROMETER_STATES[mod["section"]][mod["state"]]["label"]
	var target: String = "All items" if mod["target"] == "all" else GameData.RECIPES[mod["target"]]["name"]
	return "%s: %s demand %+d%%" % [state_label, target, roundi(float(mod["fraction"]) * 100.0)]


func _annotation_text(note: Dictionary) -> String:
	match note["kind"]:
		"ticker":
			for section in Barometer.SECTIONS:
				if GameData.BAROMETER_STATES[section].has(note["source"]):
					return "Ticker: %s" % GameData.BAROMETER_STATES[section][note["source"]]["label"]
			return "Ticker shift"
		"flood":
			return "%s flooded %d below the quote" % [_annotation_who(note["source"]), int(note["value"])]
		"undercut":
			return "%s undercut with %d" % [_annotation_who(note["source"]), int(note["value"])]
		"deny":
			return "%s bought up %d to deny it" % [_annotation_who(note["source"]), int(note["value"])]
		"stabiliseSell":
			return "%s sold %d into the spike" % [_annotation_who(note["source"]), int(note["value"])]
		"stabiliseBuy":
			return "%s bought %d out of the crash" % [_annotation_who(note["source"]), int(note["value"])]
		"positionBuy":
			return "%s took a position of %d" % [_annotation_who(note["source"]), int(note["value"])]
		"positionSell":
			return "%s cashed out %d" % [_annotation_who(note["source"]), int(note["value"])]
		"dump":
			return "%s dumped %d" % [_annotation_who(note["source"]), int(note["value"])]
		"buy":
			return "%s bought up %d" % [_annotation_who(note["source"]), int(note["value"])]
		"spike":
			return "Spike, +£%d" % int(note["value"])
		_:
			return "Crash, −£%d" % absi(int(note["value"]))


# "You" for the player, a faction's name for a faction, else "Someone".
func _annotation_who(source: String) -> String:
	if source == "player":
		return "You"
	if GameData.FACTIONS.has(source):
		return GameData.FACTIONS[source]["name"]
	return "Someone"


# ── News ────────────────────────────────────────────────────────────────


func _build_headline_card(section: String, featured: bool) -> Control:
	var barometer: Dictionary = GameState.state["barometer"]
	var active_state: String = barometer[section]
	var state_data: Dictionary = GameData.BAROMETER_STATES[section][active_state]
	var headline: String = state_data["headlines"][0]
	var category: String = GameData.BAROMETER_NEWS["categories"][section]
	var column := UI.vbox(0)
	column.add_child(_section_heading(category))
	var story := Button.new()
	story.name = "TickerStory_%s" % section
	story.text = ""
	story.custom_minimum_size.y = 212 if featured else 156
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.focus_mode = Control.FOCUS_NONE
	story.pressed.connect(func(): PhoneNav.select_axis(section))
	var style := StyleBoxFlat.new()
	style.bg_color = NEWS_PAPER if featured else NEWS_BG
	style.border_color = NEWS_RED if featured else NEWS_RULE
	style.border_width_top = 4 if featured else 1
	style.border_width_bottom = 0 if featured else 1
	for state_name in ["normal", "hover", "pressed", "focus"]:
		story.add_theme_stylebox_override(state_name, style)
	var copy := UI.vbox(5)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story.add_child(copy)
	UI.anchor_full_rect(copy)
	copy.offset_left = 14 if featured else 0
	copy.offset_right = -14 if featured else 0
	copy.offset_top = 12
	copy.offset_bottom = -10
	var eyebrow := _news_text("%s · %s" % [SECTION_LABELS[section].to_upper(), String(state_data["label"]).to_upper()], 10, NEWS_RED if featured else Color("#d4939f"))
	copy.add_child(eyebrow)
	copy.add_child(_news_text(headline, 23 if featured else 17, NEWS_PAPER_INK if featured else NEWS_INK, true))
	copy.add_child(_news_text(state_data["description"], 12, Color("#504347") if featured else NEWS_MUTED))
	var hint_state = Barometer.trend_hint_state(section)
	if hint_state != null:
		var hint_label: String = GameData.BAROMETER_STATES[section][hint_state]["label"]
		copy.add_child(_news_text("Rumblings: %s building." % hint_label, 11, NEWS_RED if featured else Color("#d4939f")))
	column.add_child(story)
	return column


func _section_heading(title: String, detail: String = "") -> Control:
	var row := UI.hbox(8)
	row.add_child(_news_text(title.to_upper(), 11, NEWS_INK))
	if detail != "":
		var rhs := _news_text(detail, 10, NEWS_MUTED)
		rhs.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(rhs)
	return _news_margins(row, 0, 18, 0, 9)


func _news_text(value: String, size: int, colour: Color, serif: bool = false) -> Label:
	var label := UI.label(value)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	if serif:
		label.add_theme_font_override("font", _serif_font())
	return label


func _serif_font() -> Font:
	if _serif == null:
		_serif = SystemFont.new()
		_serif.font_names = SERIF_NAMES
	return _serif


func _news_rule(colour: Color, height: int) -> Control:
	var rule := ColorRect.new()
	rule.color = colour
	rule.custom_minimum_size.y = height
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule


func _news_margins(child: Control, left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.add_child(child)
	return margin


func _build_axis_detail(content: VBoxContainer, section: String) -> void:
	content.add_child(UI.button("‹ Back to Ticker", func(): PhoneNav.back_to_ticker()))
	content.add_child(UI.heading(SECTION_LABELS[section]))

	var barometer: Dictionary = GameState.state["barometer"]
	var active_state: String = barometer[section]
	var state_data: Dictionary = GameData.BAROMETER_STATES[section][active_state]

	var summary := UI.card()
	summary["content"].add_child(UI.heading(state_data["label"], 14))
	summary["content"].add_child(UI.muted_label(state_data["description"]))
	for key in state_data["effects"].keys():
		var v = state_data["effects"][key]
		if key == "itemDemand":
			for recipe_key in v.keys():
				summary["content"].add_child(UI.muted_label("%s demand %s" % [GameData.RECIPES[recipe_key]["name"], _signed(v[recipe_key])]))
		else:
			summary["content"].add_child(UI.muted_label("%s %s" % [key, _signed(v)]))
	content.add_child(summary["panel"])

	content.add_child(UI.heading("All states", 14))
	for state_id in GameData.BAROMETER_STATES[section].keys():
		content.add_child(_build_state_row(section, state_id, active_state))

	content.add_child(_build_influence_actions_card(section))


func _build_state_row(section: String, state_id: String, active_state: String) -> Control:
	var barometer: Dictionary = GameState.state["barometer"]
	var other_state: Dictionary = GameData.BAROMETER_STATES[section][state_id]
	var progress: int = barometer["progress"].get(section, {}).get(state_id, 0)

	var c := UI.card()
	c["content"].add_child(UI.label("%s — %d%%" % [other_state["label"], progress]))
	c["content"].add_child(UI.bar(progress, 100.0))

	if state_id != active_state:
		var holdings := { "cash": GameState.state["player"]["cash"] }
		var row := UI.hbox()
		var push_button := UI.button(UI.format_cost_label({ "label": "Push", "resource": "cash", "amount": Barometer.MANUAL_ACTION_COST }, holdings), func(): Barometer.manual_push(section, state_id))
		push_button.disabled = not Barometer.can_push_pull(section, state_id, "push") or GameState.state["player"]["cash"] < Barometer.MANUAL_ACTION_COST
		row.add_child(push_button)
		var pull_button := UI.button(UI.format_cost_label({ "label": "Pull", "resource": "cash", "amount": Barometer.MANUAL_ACTION_COST }, holdings), func(): Barometer.manual_pull(section, state_id))
		pull_button.disabled = not Barometer.can_push_pull(section, state_id, "pull") or GameState.state["player"]["cash"] < Barometer.MANUAL_ACTION_COST
		row.add_child(pull_button)
		c["content"].add_child(row)

	return c["panel"]


func _build_influence_actions_card(section: String) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.heading("Influence actions", 14))
	c["content"].add_child(UI.muted_label("Data only until M4 — shown greyed with their costs."))

	var any_action := false
	for action in GameData.BAROMETER_ACTIONS:
		if action["section"] != section:
			continue
		any_action = true
		var cost_parts: Array[String] = []
		var cost: Dictionary = action["cost"]
		for key in cost.keys():
			cost_parts.append("%s %s" % [str(cost[key]), key])
		c["content"].add_child(UI.label(action["label"]))
		c["content"].add_child(UI.muted_label(action["description"]))
		c["content"].add_child(UI.muted_label("Cost: %s" % ", ".join(cost_parts)))
		var b := UI.button(action["label"], func(): pass)
		b.disabled = true
		c["content"].add_child(b)

	if not any_action:
		c["content"].add_child(UI.muted_label("None for this axis yet."))

	return c["panel"]


func _signed(v: float) -> String:
	return ("+" if v > 0 else "") + str(v)
