# The Ticker: News tab (one headline card per barometer axis, drilling into
# an axis detail view with push/pull and greyed influence actions when
# state.phoneNav.selectedAxis is set, plus a faction-headline wires card)
# and Stock Market tab (London prices
# with ▲/▼ versus yesterday, active demand modifiers, and a per-good price
# chart with annotations). The tab and selected good are view state held
# here, not in state.phoneNav, so they reset with the screen.
class_name TickerApp
extends PhoneApp

const LineChartScript := preload("res://scenes/components/line_chart.gd")

const SECTION_LABELS := { "economic": "Economic", "social": "Social", "political": "Political" }
const NEWS_TAB := "news"
const STOCK_TAB := "stock"
const ANNOTATION_COLOURS := { "ticker": "pastel_ochre", "flood": "pastel_tan", "undercut": "pastel_tan", "deny": "pastel_sage", "stabiliseSell": "pastel_tan", "stabiliseBuy": "pastel_sage", "dump": "pastel_blue", "buy": "pastel_sage", "spike": "pastel_teal", "crash": "pastel_pink" }
const MUTED := Color("#999a9d")

var _tab := NEWS_TAB
# { kind, type } of the good whose chart is open, or empty for the list.
var _selected_good := {}


func build(content: VBoxContainer) -> void:
	var selected_axis = GameState.state["phoneNav"].get("selectedAxis")
	if selected_axis != null:
		_build_axis_detail(content, selected_axis)
		return
	if _tab == STOCK_TAB and not _selected_good.is_empty():
		_build_good_detail(content, _selected_good["kind"], _selected_good["type"])
		return
	content.add_child(back_button())
	content.add_child(UI.heading("The Ticker"))
	content.add_child(_build_tabs())
	if _tab == STOCK_TAB:
		_build_stock_market(content)
	else:
		_build_ticker(content)


func _build_tabs() -> Control:
	var tabs := UI.hbox()
	var news := UI.button("News", func(): _set_tab(NEWS_TAB))
	news.disabled = _tab == NEWS_TAB
	tabs.add_child(UI.expand_fill(news))
	var stock := UI.button("Stock Market", func(): _set_tab(STOCK_TAB))
	stock.disabled = _tab == STOCK_TAB
	tabs.add_child(UI.expand_fill(stock))
	return tabs


func _set_tab(tab: String) -> void:
	_tab = tab
	_selected_good = {}
	refresh()


func _select_good(kind: String, good_type: String) -> void:
	_selected_good = { "kind": kind, "type": good_type }
	refresh()


func _build_ticker(content: VBoxContainer) -> void:
	content.add_child(UI.muted_label("Push/pull costs £2000, once per state+direction per day."))

	for section in Barometer.SECTIONS:
		content.add_child(_build_headline_card(section))
	var wires := Barometer.headlines()
	if not wires.is_empty():
		content.add_child(_build_wires_card(wires))


# Faction headlines (vein takeovers and the like), newest first.
func _build_wires_card(wires: Array) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.muted_label("LONDON WIRES"))
	for entry in wires:
		c["content"].add_child(UI.label("%s · %s" % [Calendar.format_day(int(entry["day"])), entry["text"]]))
	return c["panel"]


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

	content.add_child(UI.heading("Ore", 14))
	for ore_type in GameData.MARKET["goods"]["ore"]:
		content.add_child(_good_row("ore", ore_type))
	content.add_child(UI.heading("Items", 14))
	for recipe_key in GameData.MARKET["goods"]["consumable"]:
		content.add_child(_good_row("consumable", recipe_key))


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


func _build_headline_card(section: String) -> Control:
	var barometer: Dictionary = GameState.state["barometer"]
	var active_state: String = barometer[section]
	var state_data: Dictionary = GameData.BAROMETER_STATES[section][active_state]
	var headline: String = state_data["headlines"][0]

	var c := UI.card()
	c["content"].add_child(UI.muted_label(SECTION_LABELS[section].to_upper()))
	var headline_label := UI.label(headline)
	headline_label.add_theme_font_size_override("font_size", 16)
	c["content"].add_child(headline_label)
	c["content"].add_child(UI.muted_label(state_data["description"]))

	var hint_state = Barometer.trend_hint_state(section)
	if hint_state != null:
		var hint_label: String = GameData.BAROMETER_STATES[section][hint_state]["label"]
		c["content"].add_child(UI.muted_label("Rumblings: %s building." % hint_label))

	c["content"].add_child(UI.button("Open →", func(): PhoneNav.select_axis(section)))
	return c["panel"]


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
