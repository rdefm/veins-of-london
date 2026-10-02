# BizBrief's short-pay sub-view (spec §Short-pay flow, Menu): a keep stepper
# (0..guards) for HQ and each guarded vein in the pending guard shortfall,
# with the live total cost, reserve and cash needed on top. Keep counts are
# view state held here, defaulting to every guard kept; Confirm only calls
# GuardUpkeep.confirm_shortfall().
#
# PROSE-REVIEW: every string in this file.
extends RefCounted

const NAVY := Color("#101923")
const CARD := Color("#1b2a38")
const LINE := Color("#354454")
const PAPER := Color("#fbfaf6")
const MUTED := Color("#a9b5bd")
const SIGNAL := Color("#e9353c")

var _keep := {}
# The shortfall day _keep was seeded for; a new shortfall reseeds it.
var _seeded_day := -1


func build(content: VBoxContainer, refresh: Callable) -> void:
	var surface := PanelContainer.new()
	surface.name = "BizBriefShortPay"
	var background := StyleBoxFlat.new()
	background.bg_color = NAVY
	background.set_content_margin_all(13)
	surface.add_theme_stylebox_override("panel", background)
	content.add_child(surface)
	var page := UI.vbox(10)
	surface.add_child(page)
	page.add_child(UI.button("‹ BizBrief", func(): PhoneNav.close_bizbrief_view()))
	page.add_child(UI.heading("Short Pay", 23))
	var shortfall: Dictionary = GuardUpkeep.pending_shortfall()
	var places := GuardUpkeep.short_pay_places()
	if int(shortfall["day"]) != _seeded_day:
		_seeded_day = int(shortfall["day"])
		_keep = places.duplicate()
	page.add_child(UI.muted_label("Choose who stays. The rest walk when you confirm. Decide by %s or they choose for you." % Calendar.format_day(int(shortfall["deadline"]))))
	var c := UI.card()
	c["content"].add_child(UI.heading("Guards by place", 15))
	for place_id in places:
		c["content"].add_child(_build_place_row(place_id, int(places[place_id]), refresh))
	page.add_child(c["panel"])
	page.add_child(_build_totals(refresh))
	_style(page)


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
	c["content"].add_child(UI.heading("This week's payment", 15))
	c["content"].add_child(UI.label("This week £%d · Reserve £%d" % [int(quote["cost"]), int(quote["reserve"])]))
	c["content"].add_child(UI.label("From your cash £%d (you have £%d)" % [cash_needed, cash]))
	var short := cash < cash_needed
	c["content"].add_child(UI.action_button("Confirm", func(): _confirm(refresh), short, "£%d short. Keep fewer guards." % (cash_needed - cash)))
	return c["panel"]


func _style(node: Node) -> void:
	if node is PanelContainer:
		var panel := node as PanelContainer
		if not panel.has_theme_stylebox_override("panel"):
			var box := StyleBoxFlat.new()
			box.bg_color = CARD
			box.border_color = LINE
			box.set_border_width_all(1)
			box.set_corner_radius_all(6)
			box.set_content_margin_all(12)
			panel.add_theme_stylebox_override("panel", box)
	elif node is Label:
		var label := node as Label
		label.add_theme_color_override("font_color", MUTED if label.get_theme_color("font_color").is_equal_approx(UI._MUTED_COLOUR) else PAPER)
		if label.has_theme_font_size_override("font_size") and label.get_theme_font_size("font_size") >= 15:
			var serif := SystemFont.new()
			serif.font_names = PackedStringArray(["Georgia", "Times New Roman", "Noto Serif", "DejaVu Serif", "serif"])
			label.add_theme_font_override("font", serif)
	elif node is Button:
		var button := node as Button
		var box := StyleBoxFlat.new()
		box.bg_color = SIGNAL if button.text == "Confirm" and not button.disabled else CARD
		box.border_color = SIGNAL if button.text == "Confirm" else LINE
		box.set_border_width_all(1)
		box.set_corner_radius_all(4)
		box.set_content_margin_all(8)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, box)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
			button.add_theme_color_override(state, PAPER if button.text == "Confirm" and not button.disabled else MUTED)
	for child in node.get_children():
		_style(child)


func _confirm(refresh: Callable) -> void:
	if GuardUpkeep.confirm_shortfall(_keep)["ok"]:
		PhoneNav.close_bizbrief_view()
	else:
		refresh.call()
