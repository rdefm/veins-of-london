# BizBrief's short-pay sub-view (spec §Short-pay flow, Menu): a keep checklist
# of the pending shortfall's guards grouped by post (HQ, each vein, Reserve),
# each row with the guard's wage, and a running total against what the player
# can pay. The ticked guard ids are view state held here, defaulting to every
# guard kept; Confirm only calls GuardUpkeep.confirm_shortfall(). Needs no
# Security Office.
#
# PROSE-REVIEW: every string in this file.
extends RefCounted

const NAVY := Color("#101923")
const CARD := Color("#1b2a38")
const LINE := Color("#354454")
const PAPER := Color("#fbfaf6")
const MUTED := Color("#a9b5bd")
const SIGNAL := Color("#e9353c")

var _keep: Array = []
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
	var guards := GuardUpkeep.short_pay_guards()
	if int(shortfall["day"]) != _seeded_day:
		_seeded_day = int(shortfall["day"])
		_keep = guards.map(func(g): return g["id"])
	page.add_child(UI.muted_label("Tick who stays. The rest walk when you confirm. Decide by %s or they choose for you." % Calendar.format_day(int(shortfall["deadline"]))))
	var c := UI.card()
	c["content"].add_child(UI.heading("Guards by post", 15))
	for place_id in _post_order(guards):
		c["content"].add_child(UI.muted_label(GuardUpkeep.place_label(place_id)))
		for g in guards:
			if g["post"] == place_id:
				c["content"].add_child(_build_guard_row(g, refresh))
	page.add_child(c["panel"])
	page.add_child(_build_totals(refresh))
	_style(page)


# The posts the guards sit at: HQ, player veins in list order, then Reserve.
func _post_order(guards: Array) -> Array:
	var posts := {}
	for g in guards:
		posts[g["post"]] = true
	var order := []
	for place_id in [Muscle.POST_HOME] + GameState.state["player"]["veins"].map(func(v): return v["id"]) + [Muscle.POST_RESERVE]:
		if posts.has(place_id):
			order.append(place_id)
	return order


func _build_guard_row(g: Dictionary, refresh: Callable) -> Control:
	var gid: String = g["id"]
	var keeping := _keep.has(gid)
	var row := UI.button("%s %s · L%d · £%d/wk" % ["☑" if keeping else "☐", Muscle.short_name(g), int(g["level"]), Muscle.wage(g)], func(): _toggle(gid, refresh))
	row.name = "KeepGuard_%s" % gid
	return row


func _toggle(id: String, refresh: Callable) -> void:
	if _keep.has(id):
		_keep.erase(id)
	else:
		_keep.append(id)
	refresh.call()


func _build_totals(refresh: Callable) -> Control:
	var quote := GuardUpkeep.short_pay_quote(_keep)
	var cash := int(GameState.state["player"]["cash"])
	var cash_needed := int(quote["cashNeeded"])
	var c := UI.card()
	c["content"].add_child(UI.heading("This week's payment", 15))
	c["content"].add_child(UI.label("Keeping £%d of £%d you can pay" % [int(quote["cost"]), int(quote["reserve"]) + cash]))
	c["content"].add_child(UI.label("Reserve £%d · From your cash £%d (you have £%d)" % [int(quote["reserve"]), cash_needed, cash]))
	var short := cash < cash_needed
	c["content"].add_child(UI.action_button("Confirm", func(): _confirm(refresh), short, "£%d short. Untick someone." % (cash_needed - cash)))
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
