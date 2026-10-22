class_name MoveBook
extends RefCounted

# The Move Book (Profile app): one collapsible row per levelled move for an
# owner, built from MoveLevels.book(). Collapsed: name, level badge, mini
# track, next-unlock teaser. Open: level track with each level's stat, the
# Feint word row, the two unlock cards, the XP line. The action red marks
# only the next stop / next unlock (docs/ui-vision.md §6).

const HEAD_CHEVRON := "▸"
const HEAD_CHEVRON_OPEN := "▾"
const TAG_GOT := "◆ "
const TAG_OTHER := "◇ "
const LOCKED_ALPHA := 0.62


# Pill row of owner tabs: `owners` is [{ id, label }]; `on_pick` gets the id.
static func owner_tabs(owners: Array, selected: String, on_pick: Callable) -> Control:
	var row := UI.hbox(4)
	for owner in owners:
		var tab := MapCardStyle.option_row(str(owner["label"]), on_pick.bind(owner["id"]), owner["id"] == selected)
		row.add_child(tab)
	return row


# The owner's move rows; `open_move` is the expanded move id ("" = none),
# `on_toggle` is called with a row's move id.
static func rows(owner: String, open_move: String, on_toggle: Callable) -> Control:
	var column := UI.vbox(8)
	for row in MoveLevels.book(owner):
		column.add_child(_move_panel(row, row["id"] == open_move, on_toggle))
	return column


static func _move_panel(row: Dictionary, is_open: bool, on_toggle: Callable) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MapCardStyle.inset_panel())
	var column := UI.vbox(10)
	panel.add_child(column)
	column.add_child(_head(row, is_open, on_toggle))
	if is_open:
		column.add_child(_body(row))
	return panel


# The tappable header: ignoring labels over a flat TapButton so the whole
# row taps (and still scrolls) like any card.
static func _head(row: Dictionary, is_open: bool, on_toggle: Callable) -> Control:
	var stack := MarginContainer.new()
	var content := UI.vbox(4)
	var top := UI.hbox(8)
	top.add_child(MapCardStyle.label(str(row["name"]), 15, MapCardStyle.ink()))
	top.add_child(_badge(str(row["badge"]), row["isMax"]))
	top.add_child(UI.expand_fill(Control.new()))
	top.add_child(MoveTrack.make(row, true))
	top.add_child(MapCardStyle.label(HEAD_CHEVRON_OPEN if is_open else HEAD_CHEVRON, 12, MapCardStyle.muted()))
	content.add_child(top)
	content.add_child(UI.expand_fill(MapCardStyle.label(str(row["teaser"]), 12, MapCardStyle.dim())))
	_ignore_mouse(content)
	stack.add_child(content)
	var tap := TapButton.new()
	tap.flat = true
	tap.pressed.connect(on_toggle.bind(row["id"]))
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		tap.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	stack.add_child(tap)
	return stack


static func _badge(text: String, outlined: bool) -> Control:
	var style := MapCardStyle.skin(Color(0, 0, 0, 0) if outlined else MapCardStyle.ink(), 5, outlined)
	style.border_color = MapCardStyle.ink()
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", style)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.add_child(MapCardStyle.label(text, 11, MapCardStyle.ink() if outlined else MapCardStyle.paper()))
	return pill


static func _body(row: Dictionary) -> Control:
	var column := UI.vbox(10)
	column.add_child(MapCardStyle.section_label(str(row["stat"]), 12))
	column.add_child(MoveTrack.make(row, false))
	column.add_child(_stop_row(row["stops"], func(stop): return "LV%d" % stop["level"], func(stop): return str(stop["text"])))
	var word_row: Dictionary = row["wordRow"]
	if not word_row.is_empty():
		column.add_child(MapCardStyle.section_label(str(word_row["stat"]), 12))
		var words: Array = word_row["words"]
		column.add_child(_stop_row(row["stops"], Callable(), func(stop): return str(words[int(stop["level"]) - 1])))
	for unlock in row["unlocks"]:
		column.add_child(_unlock_card(unlock))
	column.add_child(UI.expand_fill(MapCardStyle.section_label(str(row["xpLine"]), 12)))
	return column


# Five equal columns, one per stop, matching MoveTrack's full layout; the
# current level's value sits in an ink box.
static func _stop_row(stops: Array, head_text: Callable, value_text: Callable) -> Control:
	var line := UI.hbox(0)
	for stop in stops:
		var cell := UI.vbox(2)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.alignment = BoxContainer.ALIGNMENT_BEGIN
		if head_text.is_valid():
			cell.add_child(_centred(head_text.call(stop), 10, MapCardStyle.ink() if stop["current"] else MapCardStyle.dim()))
		var colour := MapCardStyle.ink() if stop["reached"] else MapCardStyle.muted()
		if stop["current"]:
			var box := PanelContainer.new()
			box.add_theme_stylebox_override("panel", _value_box())
			box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			box.add_child(_centred(value_text.call(stop), 13, MapCardStyle.paper()))
			cell.add_child(box)
		else:
			cell.add_child(_centred(value_text.call(stop), 13, colour))
		line.add_child(cell)
	return line


static func _value_box() -> StyleBoxFlat:
	var style := MapCardStyle.skin(MapCardStyle.ink(), 4, false)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


static func _centred(text: String, size: int, colour: Color) -> Label:
	var l := MapCardStyle.label(text, size, colour)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.custom_minimum_size.x = 0
	return l


# earned: ink outline; next: action-red outline and tint; locked: faded.
static func _unlock_card(unlock: Dictionary) -> Control:
	var state := str(unlock["state"])
	var edge := MapCardStyle.line()
	var fill := Color(0, 0, 0, 0)
	var tag_colour := MapCardStyle.muted()
	match state:
		"earned":
			edge = MapCardStyle.ink()
			tag_colour = MapCardStyle.ink()
		"next":
			edge = MapCardStyle.action()
			fill = Color(MapCardStyle.action(), 0.12)
			tag_colour = MapCardStyle.action()
	var style := MapCardStyle.skin(fill, 9)
	style.border_color = edge
	style.set_border_width_all(2 if state != "locked" else 1)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", style)
	var column := UI.vbox(3)
	card.add_child(column)
	column.add_child(UI.expand_fill(MapCardStyle.label((TAG_GOT if state == "earned" else TAG_OTHER) + str(unlock["tag"]), 11, tag_colour)))
	column.add_child(UI.expand_fill(MapCardStyle.label(str(unlock["what"]), 13, MapCardStyle.ink())))
	column.add_child(UI.expand_fill(MapCardStyle.label(str(unlock["how"]), 11, MapCardStyle.dim())))
	if state == "locked":
		card.modulate.a = LOCKED_ALPHA
	return card


static func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)
