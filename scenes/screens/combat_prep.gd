class_name CombatPrepScreen
extends PanelContainer

# Pre-fight preparation sheet, on the Trade sheet's chrome (sell_menu_view.gd):
# header, participant list with equipped units, footer with Cancel / Fight.
# Reads state.combatPrep; Fight and Cancel call CombatPrep.

const BG := Color("#222226")
const SURFACE := Color("#2c2c31")
const LINE := Color("#47474d")
const TEXT := Color("#ededee")
const MUTED := Color("#a6a7ab")
const BUTTON_BG := Color("#3b3b40")

var _picking_slot := -1


func _ready() -> void:
	UI.anchor_full_rect(self)
	offset_top = UI.top_bar_clearance() + 8
	EventBus.state_changed.connect(_render)
	_render()


func _render() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var prep := CombatPrep.pending()
	if prep.is_empty():
		return
	add_theme_stylebox_override("panel", _style(BG, 0))
	var layout := UI.vbox(0)
	add_child(layout)
	_build_header(layout, prep)
	var scroll := TouchScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	scroll.add_child(margin)
	var body := UI.vbox(8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(body)
	var warned := CombatPrep.loadout_warning_names(prep)
	if not warned.is_empty():
		body.add_child(_loadout_warning(warned))
	if str(prep["kind"]) == CombatPrep.KIND_SPAR:
		body.add_child(_rack_panel(prep))
	var options := CombatPrep.recruit_options(prep)
	if not options.is_empty():
		body.add_child(_recruit_panel(prep, options))
	for row in CombatPrep.participants(prep):
		body.add_child(_participant_row(row))
	_build_footer(layout, prep)


func _build_header(layout: VBoxContainer, prep: Dictionary) -> void:
	var panel := _surface(SURFACE, 14)
	layout.add_child(panel)
	var content := UI.vbox(8)
	panel.add_child(content)
	var headings := UI.vbox(2)
	content.add_child(headings)
	headings.add_child(_label("%s / PREPARE" % CombatPrep.title(prep).to_upper(), 11, MUTED))
	headings.add_child(_label("Get ready", 22, TEXT))
	# PROSE-REVIEW: prep screen notes.
	var note := "No way out of this one." if prep["forced"] else "Nothing is spent until you fight."
	content.add_child(_label(note, 12, MUTED))


func _loadout_warning(names: Array) -> Control:
	var panel := _surface(SURFACE, 12)
	var box := UI.vbox(6)
	panel.add_child(box)
	# PROSE-REVIEW: empty-slot warning.
	box.add_child(_label("Empty slots, and kit in the bag: %s." % ", ".join(names), 12, MUTED))
	box.add_child(_button("Change loadout", CombatPrep.change_loadout, Color.TRANSPARENT, 44))
	return panel


# Spar practice rack: tap a slot to open its picker -- your own unit (or
# empty) plus each rack item (T1, free, gone after the fight). `_picking_slot`
# is the open picker's slot, -1 when closed.
func _rack_panel(prep: Dictionary) -> Control:
	var panel := _surface(SURFACE, 12)
	var box := UI.vbox(6)
	panel.add_child(box)
	# PROSE-REVIEW: practice rack heading, hint and slot labels.
	box.add_child(_label("PRACTICE RACK", 11, MUTED))
	box.add_child(_label("Tap a slot to swap in rack kit. Free, tier 1, gone after the fight. Your own kit stays in the bag.", 12, MUTED))
	var rack := Sparring.clean_rack(prep["args"].get("rack", {}))
	for i in range(Loadout.slot_count()):
		var current := str(rack.get(i, ""))
		var text := "Slot %d: " % (i + 1)
		text += "%s (practice)" % GameData.RECIPES[current]["name"] if current != "" else _own_slot_text(i)
		var slot_button := _button(text, _toggle_picker.bind(i), UI.action_colour() if current != "" else Color.TRANSPARENT, 44)
		if current != "":
			_set_icon(slot_button, current)
		box.add_child(slot_button)
		if _picking_slot == i:
			box.add_child(_rack_picker(i, current))
	return panel


# Picker list for slot `index`: the own-unit option, then every rack item.
# The current pick is ticked and filled.
func _rack_picker(index: int, current: String) -> Control:
	var panel := _surface(BG, 6)
	var list := UI.vbox(4)
	panel.add_child(list)
	list.add_child(_picker_row(index, "", _own_slot_text(index), current))
	for recipe_key in Sparring.rack_items():
		var row := _picker_row(index, recipe_key, str(GameData.RECIPES[recipe_key]["name"]), current)
		_set_icon(row, recipe_key)
		list.add_child(row)
	return panel


func _picker_row(index: int, recipe_key: String, text: String, current: String) -> Button:
	var picked := recipe_key == current
	var row := _button(("✓ " if picked else "") + text, _pick_rack.bind(index, recipe_key), UI.action_colour() if picked else Color.TRANSPARENT, 44)
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return row


# PROSE-REVIEW: own-unit / empty option label.
func _own_slot_text(index: int) -> String:
	var own: Variant = Loadout.slot(index)
	if own is Dictionary:
		return "%s · tier %d (yours)" % [GameData.RECIPES[own["recipe"]]["name"], int(own["tier"])]
	return "Empty"


func _set_icon(button: Button, recipe_key: String) -> void:
	var icon := ItemIcons.texture(recipe_key)
	if icon == null:
		return
	button.icon = icon
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 28)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _toggle_picker(index: int) -> void:
	_picking_slot = -1 if _picking_slot == index else index
	_render()


func _pick_rack(index: int, recipe_key: String) -> void:
	_picking_slot = -1
	CombatPrep.set_rack_slot(index, recipe_key)


# Recruit picker: tick to bring, ▲▼ to reorder. Order is fight order; anyone
# past the first friendly place waits in the reinforcement queue.
func _recruit_panel(prep: Dictionary, options: Array) -> Control:
	var panel := _surface(SURFACE, 12)
	var box := UI.vbox(6)
	panel.add_child(box)
	# PROSE-REVIEW: recruit picker heading and hint.
	box.add_child(_label("RECRUITS", 11, MUTED))
	box.add_child(_label("Order is fight order. Past the front line, they wait their turn.", 12, MUTED))
	var chosen := CombatPrep.chosen_recruits(str(prep["kind"]), prep["args"])
	for contact_id in options:
		var picked := chosen.has(contact_id)
		var line := UI.hbox(8)
		box.add_child(line)
		var toggle := _button(("✓ " if picked else "") + Contacts.display_name(contact_id), CombatPrep.toggle_recruit.bind(contact_id), UI.action_colour() if picked else Color.TRANSPARENT, 44)
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(toggle)
		if picked:
			var up := _button("▲", CombatPrep.move_recruit.bind(contact_id, -1), Color.TRANSPARENT, 44)
			up.custom_minimum_size.x = 44
			up.disabled = chosen.find(contact_id) == 0
			line.add_child(up)
			var down := _button("▼", CombatPrep.move_recruit.bind(contact_id, 1), Color.TRANSPARENT, 44)
			down.custom_minimum_size.x = 44
			down.disabled = chosen.find(contact_id) == chosen.size() - 1
			line.add_child(down)
	return panel


func _participant_row(row: Dictionary) -> Control:
	var panel := _surface(SURFACE, 12)
	var box := UI.vbox(6)
	panel.add_child(box)
	var top := UI.hbox(8)
	box.add_child(top)
	var name_label := _label(str(row["name"]), 14, TEXT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	var role := { "you": "YOU", "ally": "ALLY", "foe": "OPPOSITION" }.get(row["role"], "") as String
	top.add_child(_label(role if str(row["note"]) == "" else "%s %s" % [role, row["note"]], 11, MUTED, false))
	if row["role"] == "foe":
		return panel
	box.add_child(_divider())
	var units: Array = row["units"]
	if units.is_empty():
		# PROSE-REVIEW: empty loadout line.
		box.add_child(_label("Nothing equipped.", 12, MUTED))
	for unit in units:
		box.add_child(_unit_line(unit))
	return panel


func _unit_line(unit: Dictionary) -> Control:
	var line := UI.hbox(8)
	var recipe_key := str(unit["recipe"])
	var icon := ItemIcons.texture(recipe_key)
	if icon != null:
		var rect := TextureRect.new()
		rect.texture = icon
		rect.custom_minimum_size = Vector2(28, 28)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		line.add_child(rect)
	var tier := int(unit["tier"])
	var tier_text := "untiered" if tier <= 0 else "tier %d" % tier
	var practice := " · practice" if unit.get("rack", false) else ""
	var text := _label("%s · %s%s" % [GameData.RECIPES[recipe_key]["name"], tier_text, practice], 13, TEXT)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(text)
	return line


func _build_footer(layout: VBoxContainer, prep: Dictionary) -> void:
	var panel := _surface(SURFACE, 12)
	layout.add_child(panel)
	var actions := UI.hbox(8)
	panel.add_child(actions)
	if not prep["forced"]:
		actions.add_child(_button("Cancel", _on_cancel, Color.TRANSPARENT, 44))
	var fight := _button("Fight", _on_fight, UI.action_colour(), 48)
	fight.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(fight)


func _on_cancel() -> void:
	CombatPrep.cancel()


func _on_fight() -> void:
	var result := CombatPrep.commit()
	if not result.get("ok", false) and result.has("reason"):
		Notify.push(str(result["reason"]))


func _label(value: String, font_size: int, colour: Color, wrap: bool = true) -> Label:
	var label := Label.new()
	label.text = value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _button(value: String, callback: Callable, fill: Color, height: float) -> Button:
	var button := TapButton.new()
	button.text = value
	button.custom_minimum_size.y = height
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.pressed.connect(callback)
	button.add_theme_stylebox_override("normal", _style(fill, 9))
	button.add_theme_stylebox_override("hover", _style(BUTTON_BG if fill.a < 0.01 else fill.lightened(0.10), 9))
	button.add_theme_stylebox_override("pressed", _style(fill.darkened(0.12), 9))
	button.add_theme_stylebox_override("disabled", _style(BUTTON_BG.darkened(0.25), 9))
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", TEXT)
	button.add_theme_color_override("font_pressed_color", TEXT)
	button.add_theme_color_override("font_disabled_color", MUTED)
	return button


func _surface(fill: Color, margin: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS  # drags must reach the scroller
	panel.add_theme_stylebox_override("panel", _style(fill, margin))
	return panel


func _style(fill: Color, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	style.set_corner_radius_all(8)
	return style


func _divider() -> ColorRect:
	var line := ColorRect.new()
	line.color = LINE
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line
