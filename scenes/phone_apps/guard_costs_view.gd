# BizBrief's Guard Costs sub-view (spec §Visibility): header with next
# Monday's guard bill and any pending shortfall, one chart line per place of
# actual guard payments per day over the guard cost history window, and a
# multi-select filter over HQ and veins. Places hidden by the filter are
# view state held here (default: none hidden); the view only reads state.
#
# PROSE-REVIEW: every string in this file.
extends RefCounted

const LineChartScript := preload("res://scenes/components/line_chart.gd")
# Chart line colours (data/palette.json ids), assigned by a place's position
# in GuardUpkeep.cost_places() so toggling the filter keeps each colour.
const PLACE_COLOUR_IDS := ["calc_gold", "pastel_blue", "brick_lit", "pastel_teal", "pastel_pink", "pastel_ochre", "pastel_sage", "sky_pale"]

var _hidden := {}


func build(content: VBoxContainer, refresh: Callable) -> void:
	content.add_child(UI.button("‹ BizBrief", func(): PhoneNav.close_bizbrief_view()))
	content.add_child(UI.heading("Guard Costs"))
	content.add_child(_build_header())
	content.add_child(_build_chart(refresh))


func _build_header() -> Control:
	var c := UI.card()
	c["content"].add_child(UI.label("Next Monday: £%d" % GuardUpkeep.next_monday_bill()))
	if GuardUpkeep.pending_shortfall() != null:
		var shortfall: Dictionary = GuardUpkeep.pending_shortfall()
		var quote := GuardUpkeep.short_pay_quote(GuardUpkeep.short_pay_places())
		c["content"].add_child(UI.tinted_label("Unpaid this week: £%d · reserve £%d · decide by %s" % [int(quote["cost"]), int(quote["reserve"]), Calendar.format_day(int(shortfall["deadline"]))], GameData.PALETTE.get("brick_lit", Color.WHITE)))
		c["content"].add_child(UI.button("Choose who stays ›", func(): PhoneNav.open_short_pay()))
	return c["panel"]


func _build_chart(refresh: Callable) -> Control:
	var c := UI.card()
	c["content"].add_child(UI.muted_label("Paid per day, last %d days" % int(GameData.GUARD_UPKEEP["guardCostHistoryDays"])))
	var places := GuardUpkeep.cost_places()
	var lines := chart_lines()
	if lines.is_empty():
		c["content"].add_child(UI.muted_label("Nothing selected."))
	else:
		var chart: LineChart = LineChartScript.new()
		chart.setup(lines[0]["values"], GuardUpkeep.history_window_days(), lines[0]["colour_id"], "£")
		c["content"].add_child(chart.with_series(lines.slice(1)))
	var filter := UI.hflow()
	for i in places.size():
		var place_id: String = places[i]
		var shown := not _hidden.has(place_id)
		var toggle := UI.button("%s %s" % ["●" if shown else "○", GuardUpkeep.place_label(place_id)], func(): _toggle(place_id, refresh))
		toggle.add_theme_color_override("font_color", GameData.PALETTE.get(_colour_id(i), Color.WHITE))
		filter.add_child(toggle)
	c["content"].add_child(filter)
	return c["panel"]


# The chart's lines for the places the filter shows:
# [{ placeId, values (per GuardUpkeep.history_window_days()), colour_id }].
func chart_lines() -> Array:
	var places := GuardUpkeep.cost_places()
	var lines: Array = []
	for i in places.size():
		if not _hidden.has(places[i]):
			lines.append({ "placeId": places[i], "values": GuardUpkeep.cost_series(places[i]), "colour_id": _colour_id(i) })
	return lines


func _colour_id(index: int) -> String:
	return PLACE_COLOUR_IDS[index % PLACE_COLOUR_IDS.size()]


func _toggle(place_id: String, refresh: Callable) -> void:
	toggle_place(place_id)
	refresh.call()


# Shows or hides one place's line.
func toggle_place(place_id: String) -> void:
	if _hidden.has(place_id):
		_hidden.erase(place_id)
	else:
		_hidden[place_id] = true
