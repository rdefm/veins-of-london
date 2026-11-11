class_name SecurityCosts
extends RefCounted

# Security screen's Costs tab: next Monday's guard bill, this week's wages and
# training spend, a Short Pay link while a shortfall is pending, a paid-per-day
# chart and one row per place (HQ, each vein, Reserve, training) that expands
# to its guards. Which rows are open is view state held by the screen; this
# only reads state.
#
# PROSE-REVIEW: every string in this file.

const LineChartScript := preload("res://scenes/components/line_chart.gd")
# Chart line colours (data/palette.json ids), by a place's position in
# GuardUpkeep.cost_places().
const PLACE_COLOUR_IDS := ["calc_gold", "pastel_blue", "brick_lit", "pastel_teal", "pastel_pink", "pastel_ochre", "pastel_sage", "sky_pale"]


# `expanded` is { place id: true } for the open rows; `toggle` is called with a
# place id when its row is tapped.
static func build(content: VBoxContainer, expanded: Dictionary, toggle: Callable) -> void:
	content.add_child(_build_summary())
	var chart := _build_chart()
	if chart != null:
		content.add_child(chart)
	var places := MapCardStyle.card(12)
	places["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	places["panel"].name = "CostsPlaces"
	content.add_child(places["panel"])
	places["content"].add_child(MapCardStyle.section_label("Paid this week, by place"))
	for place_id in GuardUpkeep.cost_places():
		for node in _build_place(place_id, expanded.has(place_id), toggle):
			places["content"].add_child(node)


static func _build_summary() -> Control:
	var c := MapCardStyle.card(12)
	c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c["panel"].name = "CostsSummary"
	var spend := GuardUpkeep.week_spend()
	c["content"].add_child(MapCardStyle.section_label("Next Monday bill"))
	c["content"].add_child(UI.heading("£%d" % GuardUpkeep.next_monday_bill(), 23))
	c["content"].add_child(UI.muted_label("This week: wages £%d · training £%d" % [int(spend["wages"]), int(spend["training"])]))
	var shortfall: Variant = GuardUpkeep.pending_shortfall()
	if shortfall != null:
		var quote := GuardUpkeep.short_pay_quote(GuardUpkeep.short_pay_guards().map(func(g): return g["id"]))
		c["content"].add_child(UI.tinted_label("Unpaid this week: £%d · reserve £%d · decide by %s" % [int(quote["cost"]), int(quote["reserve"]), Calendar.format_day(int(shortfall["deadline"]))], GameData.PALETTE.get("brick_lit", Color.WHITE)))
		c["content"].add_child(MapCardStyle.action_button("Choose who stays ›", func(): PhoneNav.open_short_pay()))
	return c["panel"]


# Paid per day over the history window, one line per place with any payment in
# it; null when there is none.
static func _build_chart() -> Control:
	var lines: Array = []
	var places := GuardUpkeep.cost_places()
	for i in places.size():
		var values := GuardUpkeep.cost_series(places[i])
		if values.any(func(v): return v > 0):
			lines.append({ "values": values, "colour_id": PLACE_COLOUR_IDS[i % PLACE_COLOUR_IDS.size()] })
	if lines.is_empty():
		return null
	var c := MapCardStyle.card(12)
	c["panel"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c["panel"].name = "CostsChart"
	c["content"].add_child(MapCardStyle.section_label("Paid per day, last %d days" % int(GameData.GUARD_UPKEEP["guardCostHistoryDays"])))
	var chart: LineChart = LineChartScript.new()
	chart.setup(lines[0]["values"], GuardUpkeep.history_window_days(), lines[0]["colour_id"], "£")
	c["content"].add_child(chart.with_series(lines.slice(1)))
	return c["panel"]


# A place's row, plus its guards when open. Rows with nothing to show (an
# empty post with no spend) still list so the layout doesn't shift.
static func _build_place(place_id: String, open: bool, toggle: Callable) -> Array:
	var nodes: Array = []
	var guards := Muscle.guards_at(place_id)
	var head := "%s %s · £%d" % ["▾" if open else "▸", GuardUpkeep.place_label(place_id), GuardUpkeep.place_week_spend(place_id)]
	if not guards.is_empty():
		head += " · %d guard%s" % [guards.size(), "" if guards.size() == 1 else "s"]
	var row := MapCardStyle.option_row(head, func(): toggle.call(place_id), open)
	row.name = "CostsRow_%s" % place_id
	nodes.append(row)
	if open:
		if place_id == GuardUpkeep.TRAINING_PLACE_ID:
			nodes.append(UI.muted_label("Paid per session, at once."))
		elif guards.is_empty():
			nodes.append(UI.muted_label("Nobody posted."))
		for g in guards:
			var label := UI.muted_label("%s · L%d · £%d/wk" % [Muscle.short_name(g), int(g["level"]), Muscle.wage(g)])
			label.name = "CostsGuard_%s" % g["id"]
			nodes.append(label)
	return nodes
