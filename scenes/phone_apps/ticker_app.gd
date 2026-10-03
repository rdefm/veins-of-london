# The Ticker: News tab (one headline card per barometer axis, opening a
# state article and same-axis Influence sheet; tappable read-only wires)
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
const MARKET_BRIEF_BG := Color("#313135")
const MARKET_ROW_HOVER := Color("#303034")
const MARKET_PRICE := Color("#e8b7bf")
const DETAIL_NOTE_INK := Color("#d6d6d8")
const DETAIL_RULE := Color("#48484c")
const SERIF_NAMES: PackedStringArray = ["Georgia", "Times New Roman", "Noto Serif", "DejaVu Serif", "serif"]
const SANS_NAMES: PackedStringArray = ["Arial", "Helvetica", "Noto Sans", "DejaVu Sans", "sans-serif"]

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
var _sans: SystemFont = null
var _sans_bold: FontVariation = null
var _open_wire: Dictionary = {}
var _influence_open := false


func build(content: VBoxContainer) -> void:
	var selected_axis = GameState.state["phoneNav"].get("selectedAxis")
	if selected_axis != null:
		_tab = NEWS_TAB
	if selected_axis == null and _open_wire.is_empty():
		_influence_open = false
	var page := _mount_news_root()
	if _tab == STOCK_TAB and not _selected_good.is_empty():
		_build_good_detail(page, _selected_good["kind"], _selected_good["type"])
		return
	if _tab == STOCK_TAB:
		_build_stock_market(page)
	else:
		_build_ticker(page)
		if selected_axis != null:
			_root.add_child(_build_influence_sheet(selected_axis) if _influence_open else _build_state_article(selected_axis))
		elif not _open_wire.is_empty():
			_root.add_child(_build_wire_article())


func teardown() -> void:
	if GameState.state["phoneNav"]["app"] != "ticker":
		_open_wire = {}
		_influence_open = false
	if _root != null:
		if _root.get_parent() != null:
			_root.get_parent().remove_child(_root)
		_root.queue_free()
		_root = null


func _mount_news_root() -> VBoxContainer:
	_root = Control.new()
	_root.name = "TickerRoot"
	shell.mount_custom_root(_root)
	var layout := UI.vbox(0)
	UI.anchor_full_rect(layout)
	_root.add_child(layout)
	layout.add_child(_build_news_header())
	var scroll := UI.scroll_container()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var surface := StyleBoxFlat.new()
	surface.bg_color = NEWS_BG
	scroll.add_theme_stylebox_override("panel", surface)
	layout.add_child(scroll)
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
	var back := _ticker_button("‹ Phone", func(): PhoneNav.go_home(), "plain")
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
		var button := _ticker_button(tab["title"], func(): _set_tab(tab["id"]), "plain")
		button.name = "TickerTab_%s" % tab["id"]
		button.add_theme_font_size_override("font_size", 14)
		button.custom_minimum_size.x = button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x + button.get_theme_stylebox("normal").get_minimum_size().x
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
	_open_wire = {}
	_influence_open = false
	if GameState.state["phoneNav"].get("selectedAxis") != null:
		PhoneNav.back_to_ticker()
		return
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
		var wire := Button.new()
		wire.name = "TickerWire"
		wire.flat = true
		wire.custom_minimum_size.y = 72
		wire.pressed.connect(func(): _open_wire_article(entry))
		var wire_copy := UI.vbox(4)
		wire_copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wire.add_child(wire_copy)
		UI.anchor_full_rect(wire_copy)
		wire_copy.add_child(_news_text(entry["text"], 14, NEWS_INK, true))
		wire_copy.add_child(_news_text(Calendar.format_day(int(entry["day"])), 11, NEWS_MUTED))
		column.add_child(wire)
		column.add_child(_news_margins(Control.new(), 0, 0, 0, 10))
	return _news_margins(column, 0, 25, 0, 0)


# ── Stock Market ────────────────────────────────────────────────────────

func _build_stock_market(content: VBoxContainer) -> void:
	var copy: Dictionary = GameData.BAROMETER_NEWS["market"]
	content.add_child(_section_heading(copy["edition"], copy["editionDetail"]))
	var brief := PanelContainer.new()
	brief.name = "TickerMarketBrief"
	var style := StyleBoxFlat.new()
	style.bg_color = MARKET_BRIEF_BG
	style.border_color = NEWS_MUTED
	style.border_width_left = 2
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	brief.add_theme_stylebox_override("panel", style)
	var lines := UI.vbox(6)
	lines.add_child(_news_text(copy["demandWatch"], 11, NEWS_INK))
	var modifiers: Array = Market.demand_modifiers()
	if modifiers.is_empty():
		lines.add_child(_news_text(copy["noDemandModifiers"], 12, NEWS_MUTED))
	for mod in modifiers:
		lines.add_child(_news_text(_modifier_text(mod), 12, NEWS_MUTED))
	brief.add_child(lines)
	content.add_child(brief)

	content.add_child(_news_margins(_build_stock_filter(), 0, 16, 0, 0))
	content.add_child(_build_good_section("ore", "Ore"))
	content.add_child(_build_good_section("consumable", "Items"))


# One toggle per ore type plus "In stock"; ticked shows ●, unticked ○.
func _build_stock_filter() -> Control:
	var filter := UI.hflow()
	for ore_type in GameData.MARKET["goods"]["ore"]:
		var shown := not _hidden_types.has(ore_type)
		var toggle := _ticker_button("%s %s" % ["●" if shown else "○", GameData.ORE_TYPES[ore_type]["name"]], func(): _toggle_type(ore_type), "chip", false, shown)
		toggle.name = "TickerFilter_%s" % ore_type
		filter.add_child(toggle)
	var stock := _ticker_button("%s In stock" % ("●" if _in_stock_only else "○"), func(): _toggle_in_stock(), "chip", false, _in_stock_only)
	stock.name = "TickerFilter_in_stock"
	filter.add_child(stock)
	return filter


func _build_good_section(kind: String, title: String) -> Control:
	var copy: Dictionary = GameData.BAROMETER_NEWS["market"]
	var section := UI.vbox(0)
	section.name = "TickerSection_%s" % kind
	var header_row := UI.hbox(8)
	var header := _ticker_button("%s %s" % [title, "▸" if _collapsed.has(kind) else "▾"], func(): pass, "plain")
	header.name = "TickerSectionHeader_%s" % kind
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.custom_minimum_size.y = 42
	header_row.add_child(header)
	var meta := _news_text(copy["priceMove"], 10, NEWS_MUTED)
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.size_flags_horizontal = Control.SIZE_SHRINK_END
	header_row.add_child(meta)
	section.add_child(_news_margins(header_row, 0, 12, 0, 0))
	section.add_child(_news_rule(NEWS_RULE, 1))
	var rows := UI.vbox(0)
	rows.visible = not _collapsed.has(kind)
	section.add_child(rows)
	header.pressed.connect(func():
		rows.visible = not rows.visible
		_set_section_open(kind, rows.visible)
		header.text = "%s %s" % [title, "▾" if rows.visible else "▸"]
	)
	var goods := shown_goods(kind)
	if goods.is_empty():
		rows.add_child(_news_margins(_news_text(copy["emptyFilter"], 12, NEWS_MUTED), 0, 12, 0, 12))
	for good_type in goods:
		rows.add_child(_good_row(kind, good_type))
	return section


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


# One tappable, divided price row: symbol and type opposite the live quote.
func _good_row(kind: String, good_type: String) -> Control:
	var move := Market.day_move(kind, good_type)
	var b := Button.new()
	b.name = "TickerGood_%s_%s" % [kind, good_type]
	b.custom_minimum_size.y = 64
	b.pressed.connect(func(): _select_good(kind, good_type))
	var normal := StyleBoxFlat.new()
	normal.bg_color = NEWS_BG
	normal.border_color = NEWS_RULE
	normal.border_width_bottom = 1
	normal.content_margin_left = 0
	normal.content_margin_right = 0
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = MARKET_ROW_HOVER
	for state_name in ["normal", "pressed", "focus"]:
		b.add_theme_stylebox_override(state_name, normal)
	b.add_theme_stylebox_override("hover", hover)
	var inner := UI.hbox(10)
	UI.anchor_full_rect(inner)
	b.add_child(inner)
	inner.offset_left = 4
	inner.offset_right = -4
	var symbol := UI.symbol_row([_good_symbol(kind, good_type)], { "color": NEWS_INK })
	symbol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inner.add_child(symbol)
	var identity := UI.vbox(3)
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	identity.add_child(_news_text(_good_name(kind, good_type), 15, NEWS_INK))
	var copy: Dictionary = GameData.BAROMETER_NEWS["market"]
	identity.add_child(_news_text(copy["oreType"] if kind == "ore" else copy["itemType"], 11, NEWS_MUTED))
	inner.add_child(identity)
	var quote := UI.vbox(3)
	quote.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var price := _news_text(UI.price_text(kind, Market.quote(kind, good_type)), 15, MARKET_PRICE)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quote.add_child(price)
	var delta := _news_text("— £0" if move == 0 else PriceMove.text(move, true), 11, PriceMove.colour(move, NEWS_MUTED))
	delta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quote.add_child(delta)
	inner.add_child(quote)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in inner.find_children("*", "Control", true, false):
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _build_good_detail(content: VBoxContainer, kind: String, good_type: String) -> void:
	var copy: Dictionary = GameData.BAROMETER_NEWS["market"]["detail"]
	var back := _ticker_button(copy["back"], func(): _select_good_list(), "plain")
	back.custom_minimum_size.y = 44
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	content.add_child(back)
	var eyebrow := _detail_text(copy["oreEyebrow"] if kind == "ore" else copy["itemEyebrow"], 11, NEWS_MUTED)
	eyebrow.name = "TickerDetailEyebrow"
	content.add_child(_news_margins(eyebrow, 0, 12, 0, 0))
	var title_row := UI.hbox(10)
	var symbol := UI.symbol_row([_good_symbol(kind, good_type)], { "heading_size": 24, "color": NEWS_INK })
	symbol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(symbol)
	var title := _detail_text(_good_name(kind, good_type), 24, NEWS_INK)
	title.name = "TickerDetailName"
	title_row.add_child(title)
	content.add_child(_news_margins(title_row, 0, 8, 0, 10))
	var move := Market.day_move(kind, good_type)
	var price_row := UI.hflow(14)
	price_row.add_theme_constant_override("v_separation", 2)
	price_row.name = "TickerDetailQuoteRow"
	var current_price := _detail_text(UI.price_text(kind, Market.quote(kind, good_type)), 30, MARKET_PRICE)
	current_price.name = "TickerDetailPrice"
	current_price.autowrap_mode = TextServer.AUTOWRAP_OFF
	current_price.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	price_row.add_child(current_price)
	var delta := _news_text(copy["flatMove"] if move == 0 else copy["moveToday"] % PriceMove.text(move, true), 12, PriceMove.colour(move, NEWS_MUTED))
	delta.name = "TickerDetailMove"
	delta.autowrap_mode = TextServer.AUTOWRAP_OFF
	delta.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	delta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price_row.add_child(delta)
	content.add_child(price_row)

	var series: Dictionary = Market.price_series(kind, good_type)
	var days: Array[int] = series["days"]
	var notes: Array = Market.annotations_for(kind, good_type)
	var markers: Array = []
	var marker_indices := {}
	var marked_count := 0
	for note in notes:
		var index := days.find(int(note["day"]))
		if index >= 0:
			marked_count += 1
			if marker_indices.has(index):
				var marker: Dictionary = markers[marker_indices[index]]
				marker["count"] = int(marker["count"]) + 1
			else:
				marker_indices[index] = markers.size()
				markers.append({ "index": index, "colour_id": ANNOTATION_COLOURS[note["kind"]], "count": 1 })
	var day_count: String = copy["oneDay"] if days.size() == 1 else copy["days"] % days.size()
	content.add_child(_news_margins(_detail_heading(copy["priceHistory"], day_count), 0, 27, 0, 9))
	content.add_child(_news_rule(NEWS_RULE, 1))
	if days.is_empty():
		content.add_child(_news_margins(_news_text(copy["noHistory"], 12, NEWS_MUTED), 0, 20, 0, 20))
	else:
		var chart: LineChart = LineChartScript.new()
		chart.name = "TickerPriceChart"
		content.add_child(chart.setup(series["values"], days, "calc_gold_light", "£").with_primary_colour(MARKET_PRICE).with_markers(markers).with_inspection())
		var selected := _news_text(copy["selectedQuote"] % [days[-1], UI.price_text(kind, int(series["values"][-1]))], 13, NEWS_INK)
		selected.name = "TickerSelectedQuote"
		chart.point_selected.connect(func(index: int):
			selected.text = copy["selectedQuote"] % [days[index], UI.price_text(kind, int(series["values"][index]))]
		)
		content.add_child(_news_margins(selected, 0, 10, 0, 0))
		var hint: String = copy["chartHint"] if markers.is_empty() else copy["eventHint"] % marked_count
		content.add_child(_news_margins(_news_text(hint, 11, NEWS_MUTED), 0, 5, 0, 13))
	content.add_child(_news_rule(NEWS_RULE, 1))

	content.add_child(_news_margins(_detail_heading(copy["marketNotes"], copy["recordedEvents"]), 0, 28, 0, 9))
	content.add_child(_news_rule(DETAIL_RULE, 1))
	if notes.is_empty():
		content.add_child(_news_margins(_news_text(copy["noEvents"], 12, NEWS_MUTED), 0, 12, 0, 12))
	for i in range(notes.size() - 1, -1, -1):
		var note: Dictionary = notes[i]
		var note_row := UI.hbox(12)
		var note_day := _news_text(copy["noteDay"] % int(note["day"]), 11, NEWS_MUTED)
		note_day.custom_minimum_size.x = 48
		note_day.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		note_row.add_child(note_day)
		note_row.add_child(_news_text(_annotation_text(note), 12, DETAIL_NOTE_INK))
		content.add_child(_news_margins(note_row, 0, 11, 0, 11))
		content.add_child(_news_rule(DETAIL_RULE, 1))
	content.add_child(_news_margins(_news_text(copy["quoteCaveat"], 11, NEWS_MUTED), 0, 18, 0, 0))

	var demand := UI.vbox(7)
	if kind == "ore":
		demand.add_child(_detail_heading(copy["demandDrivenBy"]))
		var drivers: Array = Market.ore_demand_drivers(good_type)
		if drivers.is_empty():
			demand.add_child(_news_text(copy["noOreShortage"], 12, NEWS_MUTED))
		for driver in drivers:
			demand.add_child(_news_text(copy["oreShortage"] % [GameData.RECIPES[driver["recipeKey"]]["name"], int(driver["shortage"])], 12, NEWS_MUTED))
	else:
		demand.add_child(_detail_heading(copy["tickerDemand"]))
		var any_mod := false
		for mod in Market.demand_modifiers():
			if mod["target"] == "all" or mod["target"] == good_type:
				any_mod = true
				demand.add_child(_news_text(_modifier_text(mod), 12, NEWS_MUTED))
		if any_mod:
			demand.add_child(_news_text(copy["netDemand"] % Barometer.get_item_demand_mult(good_type), 12, NEWS_INK))
		else:
			demand.add_child(_news_text(copy["noTickerDemand"], 12, NEWS_MUTED))
	content.add_child(_news_margins(demand, 0, 24, 0, 0))


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


func _detail_heading(title: String, detail: String = "") -> Control:
	var row := UI.hbox(8)
	var heading := _detail_text(title.to_upper(), 11, NEWS_INK)
	heading.name = "TickerDetailHeading_%s" % title.to_snake_case()
	row.add_child(heading)
	if detail != "":
		var rhs := _news_text(detail, 10, NEWS_MUTED)
		rhs.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(rhs)
	return row


func _detail_text(value: String, size: int, colour: Color) -> Label:
	var label := _news_text(value, size, colour)
	label.add_theme_font_override("font", _bold_sans_font())
	return label


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


# Ticker controls use local newsprint/market chrome instead of UI.button's
# shared amber theme. Every state is overridden so hover/disabled stay branded.
func _ticker_button(value: String, action: Callable, variant: String, paper: bool = false, selected: bool = true) -> Button:
	var button := Button.new()
	button.text = value
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.set_meta(ContactCards.OWN_STYLE_META, true)
	button.add_theme_font_override("font", _sans_font())
	button.pressed.connect(action)
	var normal := StyleBoxFlat.new()
	var hover := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	var disabled := StyleBoxFlat.new()
	var ink := NEWS_RED if paper else NEWS_INK
	var disabled_ink := NEWS_MUTED
	match variant:
		"chip":
			button.custom_minimum_size.y = 34
			button.add_theme_font_size_override("font_size", 12)
			ink = NEWS_INK if selected else NEWS_MUTED
			normal.bg_color = MARKET_BRIEF_BG
			normal.border_color = NEWS_RED if selected else NEWS_RULE
			normal.set_border_width_all(1)
			normal.set_content_margin_all(6)
			normal.content_margin_left = 9
			normal.content_margin_right = 9
			normal.set_corner_radius_all(4)
			hover = normal.duplicate() as StyleBoxFlat
			hover.bg_color = Color("#3c3c40")
			pressed = normal.duplicate() as StyleBoxFlat
			pressed.bg_color = NEWS_RED
			disabled = normal.duplicate() as StyleBoxFlat
			disabled.bg_color = NEWS_BG
		"action":
			button.custom_minimum_size.y = 44
			button.add_theme_font_size_override("font_size", 14)
			ink = NEWS_PAPER
			normal.bg_color = NEWS_RED
			normal.set_content_margin_all(9)
			normal.content_margin_left = 12
			normal.content_margin_right = 12
			normal.set_corner_radius_all(5)
			hover = normal.duplicate() as StyleBoxFlat
			hover.bg_color = Color("#b22d4a")
			pressed = normal.duplicate() as StyleBoxFlat
			pressed.bg_color = Color("#74182f")
			disabled = normal.duplicate() as StyleBoxFlat
			disabled.bg_color = Color("#c4b7b7") if paper else Color("#555055")
			disabled_ink = NEWS_PAPER_INK if paper else NEWS_INK
		_:
			button.custom_minimum_size.y = 36
			button.add_theme_font_size_override("font_size", 13)
			normal.bg_color = Color.TRANSPARENT
			normal.content_margin_left = 5
			normal.content_margin_right = 5
			normal.content_margin_top = 4
			normal.content_margin_bottom = 4
			hover = normal.duplicate() as StyleBoxFlat
			hover.bg_color = Color("#e9dadd") if paper else MARKET_ROW_HOVER
			pressed = hover.duplicate() as StyleBoxFlat
			disabled = normal.duplicate() as StyleBoxFlat
	for state_name in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state_name, { "normal": normal, "hover": hover, "pressed": pressed, "disabled": disabled }[state_name])
	var focus := normal.duplicate() as StyleBoxFlat
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = NEWS_RED
	focus.set_border_width_all(1)
	button.add_theme_stylebox_override("focus", focus)
	for colour_name in ["font_color", "font_hover_color"]:
		button.add_theme_color_override(colour_name, ink)
	button.add_theme_color_override("font_pressed_color", NEWS_PAPER if variant == "chip" else ink)
	button.add_theme_color_override("font_disabled_color", disabled_ink)
	# Clipped Button text contributes no intrinsic width. Reserve the full label
	# so FlowContainer chips and inline navigation cannot collapse to outlines.
	var font: Font = button.get_theme_font("font")
	var text_width: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
	button.custom_minimum_size.x = ceilf(text_width + normal.get_minimum_size().x)
	return button


func _serif_font() -> Font:
	if _serif == null:
		_serif = SystemFont.new()
		_serif.font_names = SERIF_NAMES
	return _serif


func _sans_font() -> Font:
	if _sans == null:
		_sans = SystemFont.new()
		_sans.font_names = SANS_NAMES
	return _sans


func _bold_sans_font() -> Font:
	if _sans_bold == null:
		_sans_bold = FontVariation.new()
		_sans_bold.base_font = _sans_font()
		_sans_bold.variation_embolden = 0.8
	return _sans_bold


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


func _sheet(name: String, paper: bool, close_action: Callable) -> Dictionary:
	var overlay := Control.new()
	overlay.name = name
	UI.anchor_full_rect(overlay)
	var scrim := Button.new()
	scrim.name = "SheetScrim"
	scrim.flat = true
	UI.anchor_full_rect(scrim)
	scrim.pressed.connect(close_action)
	overlay.add_child(scrim)
	var panel := PanelContainer.new()
	UI.anchor_full_rect(panel)
	panel.anchor_top = 0.0 if paper else 0.09
	var style := StyleBoxFlat.new()
	style.bg_color = NEWS_PAPER if paper else Color("#303034")
	style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)
	var scroll := UI.scroll_container()
	panel.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_%s" % side, 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(margin)
	var body := UI.vbox(12)
	margin.add_child(body)
	return { "root": overlay, "body": body }


func _build_state_article(section: String) -> Control:
	var sheet := _sheet("TickerArticleSheet", true, func(): PhoneNav.back_to_ticker())
	var body: VBoxContainer = sheet["body"]
	var copy: Dictionary = GameData.BAROMETER_NEWS["article"]
	var state_id: String = GameState.state["barometer"][section]
	var state_data: Dictionary = GameData.BAROMETER_STATES[section][state_id]
	var masthead := UI.hbox()
	masthead.add_child(_news_text(GameData.BAROMETER_NEWS["masthead"], 18, NEWS_RED, true))
	masthead.add_child(_ticker_button(copy["back"], func(): PhoneNav.back_to_ticker(), "plain", true))
	masthead.add_child(_ticker_button(copy["close"], func(): PhoneNav.back_to_ticker(), "plain", true))
	body.add_child(masthead)
	body.add_child(_news_rule(NEWS_RED, 3))
	body.add_child(_news_text(GameData.BAROMETER_NEWS["categories"][section].to_upper(), 11, NEWS_RED))
	body.add_child(_news_text(state_data["headlines"][0], 26, NEWS_PAPER_INK, true))
	body.add_child(_news_text(state_data["label"], 16, NEWS_PAPER_INK, true))
	var impact := UI.vbox(5)
	impact.add_child(_news_text(copy["impactTitle"], 11, NEWS_RED))
	for line in _impact_lines(state_data["effects"]):
		impact.add_child(_news_text(line, 13, NEWS_PAPER_INK))
	body.add_child(impact)
	body.add_child(_news_text(GameData.BAROMETER_NEWS["byline"], 11, NEWS_RED))
	body.add_child(_news_rule(Color("#c4b7b7"), 1))
	body.add_child(_news_text(state_data["description"], 14, NEWS_PAPER_INK))
	var influence := _ticker_button(copy["influence"], func(): _open_influence(), "action", true)
	influence.name = "TickerInfluenceOpen"
	body.add_child(influence)
	return sheet["root"]


func _build_wire_article() -> Control:
	var sheet := _sheet("TickerWireArticleSheet", true, func(): _close_wire_article())
	var body: VBoxContainer = sheet["body"]
	var masthead := UI.hbox()
	masthead.add_child(_news_text(GameData.BAROMETER_NEWS["masthead"], 18, NEWS_RED, true))
	masthead.add_child(_ticker_button(GameData.BAROMETER_NEWS["article"]["back"], func(): _close_wire_article(), "plain", true))
	masthead.add_child(_ticker_button(GameData.BAROMETER_NEWS["article"]["close"], func(): _close_wire_article(), "plain", true))
	body.add_child(masthead)
	body.add_child(_news_rule(NEWS_RED, 3))
	body.add_child(_news_text(GameData.BAROMETER_NEWS["wires"].to_upper(), 11, NEWS_RED))
	body.add_child(_news_text(str(_open_wire.get("text", "")), 26, NEWS_PAPER_INK, true))
	if _open_wire.has("day"):
		body.add_child(_news_text(Calendar.format_day(int(_open_wire["day"])), 11, NEWS_RED))
	return sheet["root"]


func _build_influence_sheet(section: String) -> Control:
	var sheet := _sheet("TickerInfluenceSheet", false, func(): _close_influence())
	var body: VBoxContainer = sheet["body"]
	var copy: Dictionary = GameData.BAROMETER_NEWS["article"]
	var title := UI.hbox()
	title.add_child(_news_text(copy["influenceTitle"] % SECTION_LABELS[section], 20, NEWS_INK, true))
	title.add_child(_ticker_button(copy["back"], func(): _close_influence(), "plain"))
	title.add_child(_ticker_button(copy["close"], func(): _close_influence(), "plain"))
	body.add_child(title)
	body.add_child(_news_rule(NEWS_RED, 2))
	body.add_child(_news_text(copy["allStates"], 14, NEWS_INK))
	var active_state: String = GameState.state["barometer"][section]
	for state_id in GameData.BAROMETER_STATES[section].keys():
		body.add_child(_build_state_row(section, state_id, active_state))
	body.add_child(_build_influence_actions_card(section))
	return sheet["root"]


func _open_wire_article(entry: Dictionary) -> void:
	_open_wire = entry.duplicate(true)
	refresh()


func _close_wire_article() -> void:
	_open_wire = {}
	refresh()


func _open_influence() -> void:
	_influence_open = true
	refresh()


func _close_influence() -> void:
	_influence_open = false
	refresh()


func _impact_lines(effects: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var copy: Dictionary = GameData.BAROMETER_NEWS["article"]
	var demand_scale: float = 1.0 + float(Barometer.get_merged_effects().get("effectMod", 0.0))
	if effects.has("demandAll"):
		lines.append(copy["allItemDemand"] % _percent(float(effects["demandAll"]) * demand_scale))
	if effects.has("itemDemand"):
		for recipe_key in effects["itemDemand"].keys():
			lines.append(copy["itemDemand"] % [GameData.RECIPES[recipe_key]["name"], _percent(float(effects["itemDemand"][recipe_key]) * demand_scale)])
	if effects.has("mugChance"):
		lines.append(copy["mugChance"] % roundi(float(effects["mugChance"]) * 100.0))
	if effects.has("dailyCost"):
		lines.append(copy["dailyCost"] % roundi(float(effects["dailyCost"]) * 100.0))
	if effects.has("homeRaid"):
		lines.append(copy["homeRaid"] % roundi(float(effects["homeRaid"]) * 100.0))
	if effects.has("effectMod"):
		lines.append(copy["effectMod"] % roundi(float(effects["effectMod"]) * 100.0))
	if lines.is_empty():
		lines.append(copy["noEffect"])
	return lines


func _percent(fraction: float) -> String:
	var percent := snappedf(fraction * 100.0, 0.1)
	return "%+d%%" % roundi(percent) if is_equal_approx(percent, roundf(percent)) else "%+.1f%%" % percent


func _build_state_row(section: String, state_id: String, active_state: String) -> Control:
	var barometer: Dictionary = GameState.state["barometer"]
	var other_state: Dictionary = GameData.BAROMETER_STATES[section][state_id]
	var progress: int = barometer["progress"].get(section, {}).get(state_id, 0)

	var c := UI.card()
	c["content"].add_child(UI.label("%s — %d%%" % [other_state["label"], progress]))
	c["content"].add_child(UI.bar(progress, 100.0))

	if state_id != active_state:
		var holdings := { "cash": GameState.state["player"]["cash"] }
		var row := UI.hflow(6)
		var push_button := _ticker_button(UI.format_cost_label({ "label": "Push", "resource": "cash", "amount": Barometer.MANUAL_ACTION_COST }, holdings), func(): Barometer.manual_push(section, state_id), "action")
		push_button.name = "TickerPush_%s_%s" % [section, state_id]
		push_button.disabled = not Barometer.can_push_pull(section, state_id, "push") or GameState.state["player"]["cash"] < Barometer.MANUAL_ACTION_COST
		row.add_child(push_button)
		var pull_button := _ticker_button(UI.format_cost_label({ "label": "Pull", "resource": "cash", "amount": Barometer.MANUAL_ACTION_COST }, holdings), func(): Barometer.manual_pull(section, state_id), "action")
		pull_button.name = "TickerPull_%s_%s" % [section, state_id]
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
			cost_parts.append("£%d" % int(cost[key]) if key == "cash" else "%d %s" % [int(cost[key]), key])
		c["content"].add_child(UI.label(action["label"]))
		c["content"].add_child(UI.muted_label(action["description"]))
		c["content"].add_child(UI.muted_label("Cost: %s" % ", ".join(cost_parts)))
		var b := _ticker_button(action["label"], func(): pass, "action")
		b.name = "TickerM4_%s" % action["id"]
		b.disabled = true
		c["content"].add_child(b)

	if not any_action:
		c["content"].add_child(UI.muted_label("None for this axis yet."))

	return c["panel"]


func _signed(v: float) -> String:
	return ("+" if v > 0 else "") + str(v)
