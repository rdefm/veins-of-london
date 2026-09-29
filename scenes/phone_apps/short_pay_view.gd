# BizBrief's short-pay sub-view (spec §Short-pay flow, Menu): a keep stepper
# (0..guards) for HQ and each guarded vein in the pending guard shortfall,
# with the live total cost, reserve and cash needed on top. Keep counts are
# view state held here, defaulting to every guard kept; Confirm only calls
# GuardUpkeep.confirm_shortfall().
#
# PROSE-REVIEW: every string in this file.
extends RefCounted

var _keep := {}
# The shortfall day _keep was seeded for; a new shortfall reseeds it.
var _seeded_day := -1


func build(content: VBoxContainer, refresh: Callable) -> void:
	content.add_child(UI.button("‹ BizBrief", func(): PhoneNav.close_bizbrief_view()))
	content.add_child(UI.heading("Guard wages short"))
	var shortfall: Dictionary = GuardUpkeep.pending_shortfall()
	var places := GuardUpkeep.short_pay_places()
	if int(shortfall["day"]) != _seeded_day:
		_seeded_day = int(shortfall["day"])
		_keep = places.duplicate()
	content.add_child(UI.muted_label("Choose who stays. The rest walk when you confirm. Decide by %s or they choose for you." % Calendar.format_day(int(shortfall["deadline"]))))
	var c := UI.card()
	for place_id in places:
		c["content"].add_child(_build_place_row(place_id, int(places[place_id]), refresh))
	content.add_child(c["panel"])
	content.add_child(_build_totals(refresh))


func _build_place_row(place_id: String, guards: int, refresh: Callable) -> Control:
	var keeping := clampi(int(_keep.get(place_id, 0)), 0, guards)
	var row := UI.hbox()
	row.add_child(UI.expand_fill(UI.label("%s · %d guard%s" % [GuardUpkeep.place_label(place_id), guards, "" if guards == 1 else "s"])))
	var less := UI.button("−", func(): _set_keep(place_id, keeping - 1, refresh))
	less.disabled = keeping <= 0
	row.add_child(less)
	row.add_child(UI.label("Keep %d" % keeping))
	var more := UI.button("+", func(): _set_keep(place_id, keeping + 1, refresh))
	more.disabled = keeping >= guards
	row.add_child(more)
	return row


func _set_keep(place_id: String, count: int, refresh: Callable) -> void:
	_keep[place_id] = count
	refresh.call()


func _build_totals(refresh: Callable) -> Control:
	var quote := GuardUpkeep.short_pay_quote(_keep)
	var cash := int(GameState.state["player"]["cash"])
	var cash_needed := int(quote["cashNeeded"])
	var c := UI.card()
	c["content"].add_child(UI.label("This week £%d · Reserve £%d" % [int(quote["cost"]), int(quote["reserve"])]))
	c["content"].add_child(UI.label("From your cash £%d (you have £%d)" % [cash_needed, cash]))
	var short := cash < cash_needed
	c["content"].add_child(UI.action_button("Confirm", func(): _confirm(refresh), short, "£%d short. Keep fewer guards." % (cash_needed - cash)))
	return c["panel"]


func _confirm(refresh: Callable) -> void:
	if GuardUpkeep.confirm_shortfall(_keep)["ok"]:
		PhoneNav.close_bizbrief_view()
	else:
		refresh.call()
