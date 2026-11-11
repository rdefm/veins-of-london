class_name GuardHireModal
extends RefCounted

# "guard_hire" modal: the weekly board. One card per slot (name, level, wage,
# a row per trait) with a Hire button; a hired slot stays a dashed placeholder
# until the next Monday roll.
#
# PROSE-REVIEW: the board strings.


static func build(container: VBoxContainer, _data: Dictionary) -> void:
	container.add_child(UI.heading("Hire board", 20))
	container.add_child(UI.label("New board %s" % Calendar.format_day(Home.next_bill_day())))
	container.add_child(UI.muted_label("Hiring pays this week's share of the wage today. New guards start in Reserve."))
	var cards := Muscle.board()
	for i in cards.size():
		container.add_child(_card(i, cards[i]))
	container.add_child(MapCardStyle.footer([MapCardStyle.text_button("Close", func(): Modal.close())]))


static func _card(index: int, g: Variant) -> Control:
	var c := MapCardStyle.card(12, 0.0)
	var box: VBoxContainer = c["content"]
	if g == null:
		var slot := MapCardStyle.label("Hired — refills Monday", 13, MapCardStyle.dim())
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(slot)
		var panel: PanelContainer = c["panel"]
		panel.name = "HiredSlot_%d" % index
		panel.draw.connect(func(): GuardWidgets.draw_dashed_outline(panel))
		return panel
	var head := UI.hbox(8)
	head.add_child(MapCardStyle.label(Muscle.full_name(g), 15, MapCardStyle.ink()))
	head.add_child(GuardWidgets.level_badge(g))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	head.add_child(_wage_block(g))
	box.add_child(head)
	if bool(g.get("returning", false)):
		box.add_child(MapCardStyle.label("↺ Worked for you before", 12, MapCardStyle.dim()))
	for t in g["traits"]:
		box.add_child(GuardWidgets.trait_row(t))
	var reason := Muscle.hire_block_reason(index)
	var first: String = String(g["name"]).split(" ")[0]
	box.add_child(MapCardStyle.action_button("Hire %s" % first, func(): Muscle.hire(index), reason != "", reason))
	return c["panel"]


# "£N/wk"; when traits change it, the base level wage is struck through first.
static func _wage_block(g: Dictionary) -> Control:
	var wage := Muscle.wage(g)
	var base := Muscle.level_wage(int(g["level"]))
	var row := UI.hbox(4)
	if wage != base:
		var struck := RichTextLabel.new()
		struck.bbcode_enabled = true
		struck.fit_content = true
		struck.scroll_active = false
		struck.autowrap_mode = TextServer.AUTOWRAP_OFF
		struck.mouse_filter = Control.MOUSE_FILTER_IGNORE
		struck.add_theme_font_size_override("normal_font_size", 12)
		struck.add_theme_color_override("default_color", MapCardStyle.dim())
		struck.text = "[s]£%d[/s]" % base
		struck.custom_minimum_size = Vector2(36, 0)
		row.add_child(struck)
	row.add_child(MapCardStyle.label("£%d/wk" % wage, 14, MapCardStyle.ink()))
	return row
