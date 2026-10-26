class_name EventScreen
extends Control

const VN_TEXT_FRAME_HEIGHT := 236.0
const VN_BOTTOM_MARGIN := 8.0  # outer frame padding, also the image/text gap
const ACTION_SEPARATION := 8
const CONTEXT_BUTTON_SIZE := 44.0
const CONTEXT_MODAL_MAX_WIDTH := 340.0
const PULSE_SECONDS := 0.7
const REVEAL_SPIN_SECONDS := 0.5
const REVEAL_FADE_SECONDS := 0.25
const REVEAL_FADE_QUICK := 0.1

const _CALC_GOLD_FALLBACK := Color("#d4af52")
const _CALC_GOLD_LIGHT_FALLBACK := Color("#f2dfa0")
const _INK_COLOR := Color(0.101961, 0.101961, 0.101961, 1)
const _FRAME_COLOR := Color(0.07, 0.07, 0.08, 1)
const _CREAM_COLOR := Color(0.956863, 0.949020, 0.929412, 1)

var _vn_frame: Control
var _vn_image_frame: Control
var _vn_texture: TextureRect
var _vn_blank_tag: Label
var _vn_card_box: VBoxContainer
var _vn_text_frame: VBoxContainer
var _vn_card_panel: PanelContainer
var _vn_text_scroll: ScrollContainer
var _vn_controls_row: BoxContainer
var _item_menu: Control
var _obs_sheet: Control
var _obs_revealing := false  # true while the sheet's row reveal plays
var _obs_tween: Tween
var _reveal_steps: Array = []  # rows still to reveal: {roll_line, text, final}
var _revealed_rolls := {}  # "obsId|ore|roll" keys already animated this screen
var _fade_options: Array = []  # option indices a read just unlocked; held invisible until the sheet closes
var _fade_nodes: Array = []  # the controls built for _fade_options on the current card
var _context_modal: Control
var _context_choice := -1  # option index whose ? modal is open, -1 when closed

func _ready() -> void:
	UI.anchor_full_rect(self)

	if not Events.has_live_definition():
		_build_unresolvable_exit()
		return

	_vn_frame = _build_vn_frame()
	add_child(_vn_frame)

	EventBus.state_changed.connect(_refresh)
	_refresh()

# No cards can render for an event id with no definition, so the screen shows
# only a way out.
func _build_unresolvable_exit() -> void:
	var margin := MarginContainer.new()
	UI.anchor_full_rect(margin)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	add_child(margin)
	var box := UI.vbox(10)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(box)
	# PROSE-REVIEW: unresolvable-event fallback copy.
	box.add_child(UI.muted_label("Nothing to see here."))
	var leave := UI.button("Leave", func(): Events.abandon())
	_style_action_button(leave)
	box.add_child(leave)

func _refresh() -> void:
	if GameState.state["event"] == null:
		return  # on_complete already navigated away; this node is about to be freed

	_close_item_menu()

	_refresh_vn_frame()
	_refresh_vn_card()
	_restore_context_modal()

func _populate_card_text(content: VBoxContainer, card: Dictionary) -> void:

	if card.get("label") != null:
		content.add_child(UI.muted_label(card["label"]))

	match card["type"]:
		"speaker":
			content.add_child(UI.heading(card["speaker"], 14))
			content.add_child(UI.label(card["text"]))
		"choice":
			if card.get("speaker") != null:
				content.add_child(UI.heading(card["speaker"], 14))
			content.add_child(UI.label(card["text"]))
		"resolution":
			# A check's outcome: a subtle muted marker above the text, no animation.
			if card.has("outcome"):
				content.add_child(UI.muted_label(outcome_marker(card)))
			content.add_child(UI.label(card["text"]))
		_:
			content.add_child(UI.label(card["text"]))

func _footer_box() -> BoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", ACTION_SEPARATION)
	return box

# The option step of a choice card: one full-width button per option (a gated
# option hidden or greyed with its reason), stacked in `box`.
func _fill_options(box: VBoxContainer) -> void:
	var choices: Array = Events.current_card()["choices"]
	var exit_index := Events.hub_exit_index()
	_fade_nodes.clear()
	for i in range(choices.size()):
		if i == exit_index:
			continue  # the hub's exit is the footer →
		var gate: Dictionary = Events.option_gate(i)
		var node: Control = null
		match gate["display"]:
			"show":
				if gate["asked"]:
					node = _build_asked_option(choices[i]["label"], i)
				else:
					node = _build_choice_button(choices[i]["label"], i)
			"disable":
				node = _build_disabled_option(choices[i]["label"], i)
		if node == null:
			continue
		if _fade_options.has(i):
			node.modulate.a = 0.0
			_fade_nodes.append(node)
		box.add_child(node)

# Indices of the current choice card's options that show right now.
static func shown_options() -> Array:
	var out: Array = []
	if not Events.is_choosing():
		return out
	for i in range(Events.current_card()["choices"].size()):
		if Events.option_gate(i)["display"] == "show":
			out.append(i)
	return out

# Fades in the options a read unlocked, once the sheet is gone.
func _reveal_unlocked_options() -> void:
	var nodes := _fade_nodes.filter(func(n: Control) -> bool: return is_instance_valid(n))
	_fade_options.clear()
	_fade_nodes.clear()
	for n: Control in nodes:
		if _reduced_motion():
			n.modulate.a = 1.0
			continue
		create_tween().bind_node(n).tween_property(n, "modulate:a", 1.0, REVEAL_FADE_SECONDS)

# The ore glyph(s) of the reads behind an option, overlaid at the button's left.
func _add_read_glyphs(b: Button, choice: Dictionary) -> void:
	var x := 8.0
	for ore: String in Observation.option_ores(choice):
		var glyph := SymbolGlyph.new()
		glyph.name = "ReadGlyph_%s" % ore
		glyph.symbol = GameData.ORE_TYPES[ore]["symbol"]
		glyph.draw_fallback = SymbolGlyph.ore_fallback(ore)
		glyph.custom_minimum_size = Vector2(UI.SYMBOL_GLYPH_SIZE, UI.SYMBOL_GLYPH_SIZE)
		glyph.glyph_radius = UI.SYMBOL_GLYPH_SIZE * 0.34
		glyph.color = MapPalette.ore_colour(ore)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(glyph)
		glyph.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT, Control.PRESET_MODE_KEEP_SIZE, int(x))
		x += UI.SYMBOL_GLYPH_SIZE + 4.0

# Fills the footer `box`: the Action icon on the left when anything is usable,
# → on the right except on the option step. Returns the controls added; empty
# means the footer collapses.
func _fill_footer(box: BoxContainer) -> Array:
	var controls: Array = []
	if has_action():
		controls.append(_build_action_button())
	if not Events.is_choosing():
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls.append(spacer)
		controls.append(_build_continue_button("→"))
	elif Events.hub_exit_available():
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls.append(spacer)
		var exit_index := Events.hub_exit_index()
		var b := UI.button("→", func(): Events.choose(exit_index))
		b.name = "HubExitButton"
		_style_action_button(b)
		controls.append(b)
	for c in controls:
		box.add_child(c)
	return controls

func _screen_width() -> float:
	if is_inside_tree():
		return get_viewport_rect().size.x
	return float(ProjectSettings.get_setting("display/window/size/viewport_width", 390))

# True when the Action popup has anything to list: an observation in effect or a usable item.
static func has_action() -> bool:
	return Observation.in_effect() != "" or EventItems.has_usable()

func _build_action_button() -> Button:
	var b := UI.icon_button(Icons.draw_bag, func(): pass)
	b.name = "ActionButton"
	b.tooltip_text = "Action"
	b.pressed.connect(func(): _toggle_item_menu(b))
	_style_action_button(b)
	if observe_pulsing():
		_apply_pulse(b)
	return b

# True while the observation in effect is unread or re-armed by Rewind.
static func observe_pulsing() -> bool:
	return Observation.is_unread() or Observation.is_armed()

static func _reduced_motion() -> bool:
	return bool(GameState.state["meta"].get("reducedMotion", false))

# Marks `ctrl` as pulsing: a looping glow/scale tween, or a static badge under
# reduced motion (ui-vision.md motion).
func _apply_pulse(ctrl: Control) -> void:
	ctrl.set_meta("pulsing", true)
	if _reduced_motion():
		var badge := Label.new()
		badge.name = "ObserveBadge"
		badge.text = "●"
		badge.add_theme_color_override("font_color", UI.action_colour())
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		ctrl.add_child(badge)
		return
	ctrl.resized.connect(func(): ctrl.pivot_offset = ctrl.size / 2.0)
	var tween := (Engine.get_main_loop() as SceneTree).create_tween().bind_node(ctrl).set_loops()
	tween.tween_property(ctrl, "modulate", Color(1.5, 1.5, 1.5, 1.0), PULSE_SECONDS)
	tween.parallel().tween_property(ctrl, "scale", Vector2(1.08, 1.08), PULSE_SECONDS)
	tween.tween_property(ctrl, "modulate", Color(1, 1, 1, 1), PULSE_SECONDS)
	tween.parallel().tween_property(ctrl, "scale", Vector2.ONE, PULSE_SECONDS)

func _toggle_item_menu(anchor: Button) -> void:
	if is_instance_valid(_item_menu):
		_close_item_menu()
		return
	_item_menu = Control.new()
	UI.anchor_full_rect(_item_menu)
	_item_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	_item_menu.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_close_item_menu()
	)

	var panel := PanelContainer.new()
	var list := UI.vbox(6)
	panel.add_child(list)
	if Observation.in_effect() != "":
		var observe := UI.button("Observe", _on_observe_picked)
		observe.name = "ObserveEntry"
		_style_action_button(observe)
		if observe_pulsing():
			_apply_pulse(observe)
		list.add_child(observe)
	for entry in EventItems.usable_entries():
		var id: String = entry["id"]
		var b := UI.button(item_entry_label(entry), func(): _on_item_picked(id))
		b.icon = ItemIcons.texture(entry["recipeKey"])
		b.expand_icon = true
		_style_action_button(b)
		list.add_child(b)
	_item_menu.add_child(panel)
	add_child(_item_menu)

	# Opens upward from the Item button, kept inside the screen's gutters.
	var panel_size: Vector2 = panel.get_combined_minimum_size()
	var anchor_pos: Vector2 = anchor.global_position - global_position
	var x: float = clampf(anchor_pos.x, 16.0, maxf(16.0, _screen_width() - 16.0 - panel_size.x))
	var y: float = maxf(UI.top_bar_clearance(), anchor_pos.y - panel_size.y - 8.0)
	panel.position = Vector2(x, y)

static func item_entry_label(entry: Dictionary) -> String:
	var count: int = entry["count"]
	if entry["source"] == "dial":
		return "%s · %d charge%s" % [entry["label"], count, "" if count == 1 else "s"]
	return "%s ×%d" % [entry["label"], count]

func _on_item_picked(id: String) -> void:
	_close_item_menu()
	EventItems.use(id)

func _on_observe_picked() -> void:
	_close_item_menu()
	var before := shown_options()
	var rows := Observation.read()
	_fade_options = shown_options().filter(func(i: int) -> bool: return not before.has(i))
	if not _fade_options.is_empty():
		_refresh()
	_open_observation_sheet(rows)

func _close_observation_sheet() -> void:
	_dismiss_observation_sheet()
	_reveal_unlocked_options()

func _dismiss_observation_sheet() -> void:
	_stop_reveal()
	if is_instance_valid(_obs_sheet):
		_obs_sheet.queue_free()
	_obs_sheet = null

# Bottom sheet: scene title, then one row per listed ore from Observation rows.
func _open_observation_sheet(rows: Array) -> void:
	_dismiss_observation_sheet()
	_obs_sheet = Control.new()
	_obs_sheet.name = "ObservationSheet"
	UI.anchor_full_rect(_obs_sheet)
	_obs_sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	_obs_sheet.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			if _obs_revealing:
				_skip_reveal()
			else:
				_close_observation_sheet()
	)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.anchor_full_rect(dim)
	_obs_sheet.add_child(dim)

	var panel := UI.card()
	var sheet: PanelContainer = panel["panel"]
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	sheet.anchor_left = 0.0
	sheet.anchor_right = 1.0
	sheet.anchor_top = 1.0
	sheet.anchor_bottom = 1.0
	sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	sheet.offset_left = 8.0
	sheet.offset_right = -8.0
	sheet.offset_bottom = -(8.0 + UI.safe_area_bottom_inset())
	var content: VBoxContainer = panel["content"]
	content.add_child(UI.heading(observation_sheet_title(), 16))
	_reveal_steps.clear()
	var obs_id := Observation.in_effect()
	for row in rows:
		content.add_child(_build_observation_row(row, _row_is_new(obs_id, row)))
	var close := UI.button("Close", _close_observation_sheet)
	_style_action_button(close)
	content.add_child(close)
	_obs_sheet.add_child(sheet)
	add_child(_obs_sheet)
	_play_reveal()

# A row animates the first time its roll is shown; a re-roll animates only the
# improved rows. Reopening a seen row is instant.
func _row_is_new(obs_id: String, row: Dictionary) -> bool:
	var key := "%s|%s|%d" % [obs_id, row["ore"], row["last"]]
	var seen: bool = _revealed_rolls.has(key)
	_revealed_rolls[key] = true
	return not seen and (not row["rerolled"] or row["improved"])

# Sequenced reveal: d100 spin, roll line, pips, then the text fades in. Reduced
# motion skips the spin and fades quickly.
func _play_reveal() -> void:
	if _reveal_steps.is_empty():
		return
	if not is_inside_tree():
		_skip_reveal()
		return
	_obs_revealing = true
	var reduced := _reduced_motion()
	_obs_tween = create_tween()
	for step in _reveal_steps:
		var roll_line: Button = step["roll_line"]
		var text: Control = step["text"]
		if not reduced:
			_obs_tween.tween_method(func(_t: float): roll_line.text = "Rolled %d" % randi_range(1, 100), 0.0, 1.0, REVEAL_SPIN_SECONDS)
		_obs_tween.tween_callback(func(): roll_line.text = step["final"])
		_obs_tween.tween_property(text, "modulate:a", 1.0, REVEAL_FADE_QUICK if reduced else REVEAL_FADE_SECONDS)
	_obs_tween.finished.connect(_finish_reveal)

func _finish_reveal() -> void:
	_obs_revealing = false
	_obs_tween = null

# Tap during the reveal: jump every pending row to its end state.
func _skip_reveal() -> void:
	_stop_reveal()
	for step in _reveal_steps:
		if is_instance_valid(step["roll_line"]):
			step["roll_line"].text = step["final"]
		if is_instance_valid(step["text"]):
			step["text"].modulate.a = 1.0

func _stop_reveal() -> void:
	if _obs_tween != null and _obs_tween.is_valid():
		_obs_tween.kill()
	_obs_tween = null
	_obs_revealing = false

static func observation_sheet_title() -> String:
	var label: Variant = Events.current_card().get("label")
	return String(label) if label != null else "Observe"

static func tier_pips(level: int, tiers: int) -> String:
	return "●".repeat(level) + "○".repeat(tiers - level)

static func roll_line_text(row: Dictionary) -> String:
	var pips := tier_pips(row["level"], row["tiers"])
	if not row["rerolled"]:
		return "Rolled %d · needed %d+   %s" % [row["roll"], row["needed"], pips]
	if row["improved"]:
		return "Rolled %d · improved · needed %d+   %s" % [row["last"], row["needed"], pips]
	return "Rolled %d · kept %d   %s" % [row["last"], row["roll"], pips]

# The mods that lowered the number needed, one per line ("Sense  +3%").
static func mods_breakdown_text(row: Dictionary) -> String:
	if row["mods"].is_empty():
		return GameData.EVENT_CHECKS["noModifiers"]
	return "
".join(row["mods"].map(func(m: Dictionary) -> String: return "%s  %+d%%" % [m["label"], roundi(float(m["delta"]) * 100.0)]))

func _build_observation_row(row: Dictionary, animate: bool = false) -> Control:
	var ore: String = row["ore"]
	var box := UI.hbox(8)
	box.name = "ObsRow_%s" % ore
	var glyph := SymbolGlyph.new()
	glyph.symbol = GameData.ORE_TYPES[ore]["symbol"]
	glyph.draw_fallback = SymbolGlyph.ore_fallback(ore)
	glyph.custom_minimum_size = Vector2(UI.SYMBOL_GLYPH_SIZE, UI.SYMBOL_GLYPH_SIZE)
	glyph.glyph_radius = UI.SYMBOL_GLYPH_SIZE * 0.34
	glyph.color = MapPalette.ore_colour(ore)
	box.add_child(glyph)
	var col := UI.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(col)
	var breakdown := UI.muted_label(mods_breakdown_text(row))
	breakdown.name = "ModBreakdown"
	breakdown.visible = false
	breakdown.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var roll_line := UI.button(roll_line_text(row), func(): breakdown.visible = not breakdown.visible)
	roll_line.name = "RollLine"
	roll_line.flat = true
	roll_line.alignment = HORIZONTAL_ALIGNMENT_LEFT
	roll_line.clip_text = false
	col.add_child(roll_line)
	col.add_child(breakdown)
	var text := UI.label(row["text"]) if row["hit"] else UI.muted_label(row["text"])
	text.name = "RowText"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(text)
	if animate:
		_reveal_steps.append({"roll_line": roll_line, "text": text, "final": roll_line.text})
		roll_line.text = "Rolled --"
		text.modulate.a = 0.0
	return box

func _close_item_menu() -> void:
	if is_instance_valid(_item_menu):
		_item_menu.queue_free()
	_item_menu = null

# A plain option is one button; a check option is a row of the button and a
# circled ? opening its context modal.
func _build_choice_button(label: String, choice_index: int) -> Control:
	var choice: Dictionary = Events.current_card()["choices"][choice_index]
	for effect in choice.get("effects", []):
		if effect.get("op", "") == "lose_time_block":
			label = UI.format_block_cost_label(label)
			break
	var b := UI.button(label, func(): Events.choose(choice_index))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(b)
	_add_read_glyphs(b, choice)
	if Events.check_odds(choice_index).is_empty():
		return b
	return _option_row(b, choice_index)

# A reselectable hub question already asked: greyed and ticked, still pressable.
func _build_asked_option(label: String, choice_index: int) -> Control:
	var b := UI.button("✓ " + label, func(): Events.choose(choice_index))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(b)
	b.modulate = Color(1, 1, 1, 0.55)
	return b

# A gated option shown "disable": a greyed button that commits nothing, with a
# ? whose modal gives the reason.
func _build_disabled_option(label: String, choice_index: int) -> Control:
	var b := UI.button(label, func(): pass)
	b.disabled = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(b)
	b.add_theme_color_override("font_disabled_color", Color(UI.action_colour(), 0.45))
	return _option_row(b, choice_index)

# The option button with the circled ? at its right end.
func _option_row(b: Button, choice_index: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(b)
	row.add_child(_build_context_button(choice_index))
	return row

func _build_context_button(choice_index: int) -> Button:
	var q := UI.button(GameData.EVENT_CHECKS["contextGlyph"], func(): _open_context_modal(choice_index))
	q.name = "ContextButton"
	q.clip_text = false
	q.custom_minimum_size = Vector2(CONTEXT_BUTTON_SIZE, CONTEXT_BUTTON_SIZE)
	q.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_action_button(q)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := q.get_theme_stylebox(state) as StyleBoxFlat
		style.set_corner_radius_all(int(CONTEXT_BUTTON_SIZE / 2.0))
		style.set_content_margin_all(0.0)
	return q

func _build_item_toggle(choice_index: int, toggle: Dictionary) -> Button:
	var item: String = toggle["item"]
	var t := UI.button(item_toggle_label(toggle), func(): Events.toggle_item(choice_index, item))
	t.toggle_mode = true
	t.set_pressed_no_signal(toggle["on"])
	t.disabled = not toggle["held"]
	t.icon = ItemIcons.texture(item)
	t.expand_icon = true
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(t)
	t.add_theme_stylebox_override("hover_pressed", _action_button_style(UI.action_colour(), 0.30, 1.0))
	return t

static func item_toggle_label(toggle: Dictionary) -> String:
	if not toggle["held"]:
		return GameData.EVENT_CHECKS["itemToggleNoneHeld"] % toggle["name"]
	return GameData.EVENT_CHECKS["itemToggleFormat"] % [toggle["name"], roundi(toggle["delta"] * 100.0)]

# A multi-attempt check's resolution reads "N of M came off"; a single check
# uses the success/fail marker.
static func outcome_marker(card: Dictionary) -> String:
	if card.has("attempts"):
		return GameData.EVENT_CHECKS["attemptsMarkerFormat"] % [card["successes"], card["attempts"]]
	var marker: String = GameData.EVENT_CHECKS["outcomeMarkers"][card["outcome"]]
	if card.has("roll"):
		marker += GameData.EVENT_CHECKS["rollMarkerFormat"] % [card["roll"], card["needed"]]
	return marker

# A check's modal lines: "60% chance", tries when more than one, the base,
# then one signed line per applied modifier.
static func check_context_lines(odds: Dictionary) -> Array:
	var lines: Array = [GameData.EVENT_CHECKS["chanceFormat"] % roundi(odds["probability"] * 100.0)]
	if int(odds.get("attempts", 1)) > 1:
		lines.append(GameData.EVENT_CHECKS["attemptsFormat"] % odds["attempts"])
	lines.append("%s %d%%" % [GameData.EVENT_CHECKS["baseLabel"], roundi(odds["base"] * 100.0)])
	for mod in odds["mods"]:
		lines.append("%+d%% %s" % [roundi(mod["delta"] * 100.0), mod["label"]])
	if odds["mods"].is_empty():
		lines.append(GameData.EVENT_CHECKS["noModifiers"])
	return lines

func _open_context_modal(choice_index: int) -> void:
	_context_choice = choice_index
	_restore_context_modal()

func _close_context_modal() -> void:
	if is_instance_valid(_context_modal):
		_context_modal.queue_free()
	_context_modal = null
	_context_choice = -1

# Rebuilds the open ? modal after a refresh (a toggle changes the odds it
# shows); closes it if its option is off screen.
func _restore_context_modal() -> void:
	if is_instance_valid(_context_modal):
		_context_modal.queue_free()
	_context_modal = null
	if _context_choice < 0:
		return
	if not Events.is_choosing() or _context_choice >= Events.current_card()["choices"].size():
		_context_choice = -1
		return
	var choice: Dictionary = Events.current_card()["choices"][_context_choice]
	var gate: Dictionary = Events.option_gate(_context_choice)
	var odds: Dictionary = Events.check_odds(_context_choice)
	var locked: bool = gate["display"] == "disable"
	if gate["display"] == "hide" or (odds.is_empty() and not locked):
		_context_choice = -1
		return

	_context_modal = Control.new()
	_context_modal.name = "ContextModal"
	UI.anchor_full_rect(_context_modal)
	_context_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	_context_modal.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			_close_context_modal()
	)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.anchor_full_rect(dim)
	_context_modal.add_child(dim)
	var centre := CenterContainer.new()
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.anchor_full_rect(centre)
	_context_modal.add_child(centre)

	var panel := UI.card()
	var sheet: PanelContainer = panel["panel"]
	sheet.mouse_filter = Control.MOUSE_FILTER_STOP
	sheet.custom_minimum_size.x = minf(_screen_width() - 48.0, CONTEXT_MODAL_MAX_WIDTH)
	var content: VBoxContainer = panel["content"]
	content.add_child(UI.heading(choice["label"], 16))
	if locked:
		content.add_child(UI.label(gate["reason"]))
	elif not odds.is_empty():
		for line in check_context_lines(odds):
			content.add_child(UI.label(line))
		for toggle in Events.item_toggles(_context_choice):
			content.add_child(_build_item_toggle(_context_choice, toggle))
	var close := UI.button("Close", _close_context_modal)
	_style_action_button(close)
	content.add_child(close)
	centre.add_child(sheet)
	add_child(_context_modal)

func _build_continue_button(text: String) -> Button:
	var b := UI.button(text, func(): Events.advance())
	_style_action_button(b)
	return b

func _style_card(panel: PanelContainer, card_type: String) -> void:
	var box := StyleBoxFlat.new()
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_right = 10
	box.corner_radius_bottom_left = 10
	box.content_margin_left = 16.0
	box.content_margin_top = 16.0
	box.content_margin_right = 16.0
	box.content_margin_bottom = 16.0

	if card_type == "tension":
		box.border_width_left = 4
		box.bg_color = Color(0.980392, 0.972549, 0.952941, 1)
		box.border_color = MapPalette.colour("danger")
	elif card_type == "craft":
		box.border_width_left = 4
		box.bg_color = _calc_gold_light()
		box.border_color = _calc_gold()
	else:
		box.bg_color = _CREAM_COLOR

	panel.add_theme_stylebox_override("panel", box)
	# Dark body text on the light panel; inherited by every Label inside it.
	var ink := Theme.new()
	ink.set_color("font_color", "Label", _INK_COLOR)
	panel.theme = ink

func _calc_gold() -> Color:
	return GameData.PALETTE.get("calc_gold", _CALC_GOLD_FALLBACK)

func _calc_gold_light() -> Color:
	return GameData.PALETTE.get("calc_gold_light", _CALC_GOLD_LIGHT_FALLBACK)

func _style_action_button(b: Button) -> void:
	var accent := UI.action_colour()
	b.add_theme_stylebox_override("normal", _action_button_style(accent, 0.12, 1.0))
	b.add_theme_stylebox_override("hover", _action_button_style(accent, 0.20, 1.0))
	b.add_theme_stylebox_override("pressed", _action_button_style(accent, 0.30, 1.0))
	b.add_theme_stylebox_override("disabled", _action_button_style(accent, 0.05, 0.4))
	b.add_theme_color_override("font_color", accent)
	b.add_theme_color_override("font_hover_color", accent)
	b.add_theme_color_override("font_pressed_color", accent)
	b.add_theme_color_override("font_disabled_color", accent)

func _action_button_style(accent: Color, fill_alpha: float, border_alpha: float) -> StyleBoxFlat:
	return UI.action_button_style(accent, fill_alpha, border_alpha, 16.0, 10.0)

func _build_vn_frame() -> Control:
	var frame := Control.new()
	UI.anchor_full_rect(frame)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_contents = true

	var outer := Panel.new()
	UI.anchor_full_rect(outer)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outer_style := StyleBoxFlat.new()
	outer_style.bg_color = _FRAME_COLOR
	outer.add_theme_stylebox_override("panel", outer_style)
	frame.add_child(outer)

	_vn_image_frame = Control.new()
	_vn_image_frame.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_vn_image_frame.anchor_bottom = 1.0
	_vn_image_frame.offset_left = VN_BOTTOM_MARGIN
	_vn_image_frame.offset_right = -VN_BOTTOM_MARGIN
	_vn_image_frame.offset_top = VN_BOTTOM_MARGIN
	_vn_image_frame.offset_bottom = -VN_TEXT_FRAME_HEIGHT - 2.0 * VN_BOTTOM_MARGIN
	_vn_image_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vn_image_frame.clip_contents = true
	frame.add_child(_vn_image_frame)

	var blank_panel := Panel.new()
	UI.anchor_full_rect(blank_panel)
	blank_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var blank_style := StyleBoxFlat.new()
	blank_style.bg_color = Color(0, 0, 0, 0)
	blank_style.set_border_width_all(1)
	blank_style.border_color = _INK_COLOR
	blank_panel.add_theme_stylebox_override("panel", blank_style)
	_vn_image_frame.add_child(blank_panel)

	_vn_texture = TextureRect.new()
	UI.anchor_full_rect(_vn_texture)
	_vn_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vn_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vn_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_vn_image_frame.add_child(_vn_texture)

	_vn_blank_tag = UI.muted_label("")
	UI.anchor_full_rect(_vn_blank_tag)
	_vn_blank_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vn_blank_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_vn_blank_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vn_image_frame.add_child(_vn_blank_tag)

	_vn_card_box = UI.vbox(0)
	_vn_card_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_vn_card_box.offset_left = VN_BOTTOM_MARGIN
	_vn_card_box.offset_right = -VN_BOTTOM_MARGIN
	_vn_card_box.offset_top = -VN_TEXT_FRAME_HEIGHT - VN_BOTTOM_MARGIN
	_vn_card_box.offset_bottom = -VN_BOTTOM_MARGIN
	_vn_card_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_vn_card_box)
	_vn_text_frame = _vn_card_box

	return frame
func _refresh_vn_frame() -> void:
	var top: float = UI.top_bar_clearance()
	var bottom_inset: float = UI.safe_area_bottom_inset()
	_vn_frame.offset_left = 0.0
	_vn_frame.offset_right = 0.0
	_vn_frame.offset_top = top
	_vn_frame.offset_bottom = -bottom_inset
func _refresh_vn_card() -> void:
	for child in _vn_card_box.get_children():
		child.queue_free()

	var image_path: Variant = Events.current_image_path()
	var showing: bool = image_path != null and typeof(image_path) == TYPE_STRING and ResourceLoader.exists(image_path)
	_vn_texture.texture = load(image_path) if showing else null
	_vn_blank_tag.visible = not showing
	_vn_blank_tag.text = "%s · card %d" % [GameState.state["event"]["eventId"], int(GameState.state["event"]["cardIndex"]) + 1]

	var card: Dictionary = Events.revealed_cards().back()
	var built := UI.card()
	_style_card(built["panel"], card["type"])
	_vn_card_panel = built["panel"]
	_vn_card_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_vn_text_scroll = UI.scroll_container()
	_vn_text_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vn_text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_vn_text_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var body := UI.vbox(8)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if Events.is_choosing():
		_fill_options(body)
	else:
		_populate_card_text(body, card)
	_vn_text_scroll.add_child(body)
	built["content"].add_child(_vn_text_scroll)

	_vn_controls_row = _footer_box()
	if _fill_footer(_vn_controls_row).is_empty():
		_vn_controls_row.free()  # the footer collapses; the buttons take the full height
		_vn_controls_row = null
	else:
		built["content"].add_child(_vn_controls_row)
	_vn_card_box.add_child(_vn_card_panel)
