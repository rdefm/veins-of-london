class_name EventScreen
extends Control

const IMAGE_SLOT_HEIGHT := 170.0
const VN_TEXT_FRAME_HEIGHT := 236.0
const VN_BOTTOM_MARGIN := 16.0
const ACTION_SEPARATION := 8
const ACTION_BAR_HEIGHT := 48.0
# Horizontal gutters around a control row: the 16px screen margin each side,
# plus (VN only) the text card's own 16px content margin each side.
const SCREEN_GUTTER_H := 32.0
const VN_CARD_PADDING_H := 32.0

const _CALC_GOLD_FALLBACK := Color("#d4af52")
const _CALC_GOLD_LIGHT_FALLBACK := Color("#f2dfa0")
const _INK_COLOR := Color(0.101961, 0.101961, 0.101961, 1)

var _scroll: ScrollContainer
var _cards_box: VBoxContainer
var _action_bar: BoxContainer
var _image_frame: PanelContainer
var _image_texture: TextureRect
var _vn_mode: bool = false
var _vn_frame: Control
var _vn_image_frame: Control
var _vn_texture: TextureRect
var _vn_card_box: VBoxContainer
var _vn_text_frame: VBoxContainer
var _vn_card_panel: PanelContainer
var _vn_text_scroll: ScrollContainer
var _vn_controls_row: BoxContainer
var _item_menu: Control

func _ready() -> void:
	UI.anchor_full_rect(self)

	if not Events.has_live_definition():
		_build_unresolvable_exit()
		return

	_vn_mode = Events.is_vn_mode()

	if _vn_mode:
		_vn_frame = _build_vn_frame()
		add_child(_vn_frame)
	else:
		_image_frame = _build_image_frame()
		add_child(_image_frame)

		_scroll = UI.scroll_container()
		_scroll.offset_bottom = -64
		add_child(_scroll)

		var margin := MarginContainer.new()
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_top", 16)
		margin.add_theme_constant_override("margin_bottom", 16)
		_scroll.add_child(margin)

		_cards_box = UI.vbox(10)
		margin.add_child(_cards_box)
		_action_bar = _controls_box()
		_action_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_action_bar.offset_left = 16
		_action_bar.offset_right = -16
		add_child(_action_bar)

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

	if _vn_mode:
		_refresh_vn_frame()
		_refresh_vn_card()
		return

	for child in _action_bar.get_children():
		child.queue_free()

	for child in _cards_box.get_children():
		child.queue_free()
	for card in Events.revealed_cards():
		_cards_box.add_child(_build_card(card)["panel"])
	_refresh_image_slot()

	var controls: Array = _fill_controls(_action_bar, _screen_width() - SCREEN_GUTTER_H, "Continue →")
	var bar_height: float = maxf(ACTION_BAR_HEIGHT, _stack_height(controls) if _action_bar.vertical else 0.0)
	var bottom_inset := UI.safe_area_bottom_inset()
	_action_bar.offset_bottom = -8 - bottom_inset
	_action_bar.offset_top = -8 - bottom_inset - bar_height
	_scroll.offset_bottom = -bar_height - 16

	_scroll_to_bottom()

func _build_card(card: Dictionary) -> Dictionary:
	var c := UI.card()
	_style_card(c["panel"], card["type"])
	_populate_card_text(c["content"], card)
	return c

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

func _controls_box() -> BoxContainer:
	var box := BoxContainer.new()
	box.add_theme_constant_override("separation", ACTION_SEPARATION)
	return box

# Fills `box` with the Item button (when anything is usable) and either the
# choices or Continue. Choices stay in one row with Item when they all fit
# `available_width`; otherwise the box turns vertical, one full-width choice
# per line. Returns the controls added, in order.
func _fill_controls(box: BoxContainer, available_width: float, continue_text: String) -> Array:
	var controls: Array = []
	var item_button: Button = _build_item_button() if EventItems.has_usable() else null
	if item_button != null:
		controls.append(item_button)

	box.vertical = false
	if Events.is_awaiting_choice():
		var choices: Array = Events.current_card()["choices"]
		for i in range(choices.size()):
			controls.append(_build_choice_button(choices[i]["label"], i))
		var widths: Array = controls.map(func(c: Control) -> float: return c.get_combined_minimum_size().x)
		box.vertical = not fits_in_row(widths, ACTION_SEPARATION, available_width)
		if box.vertical and item_button != null:
			item_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	elif continue_text == "→":
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls.append(spacer)
		controls.append(_build_continue_button(continue_text))
	else:
		var continue_button := _build_continue_button(continue_text)
		continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls.append(continue_button)

	for c in controls:
		box.add_child(c)
	return controls

static func fits_in_row(widths: Array, separation: float, available_width: float) -> bool:
	var total: float = separation * maxf(widths.size() - 1, 0)
	for w in widths:
		total += w
	return total <= available_width

func _stack_height(controls: Array) -> float:
	var total: float = ACTION_SEPARATION * maxf(controls.size() - 1, 0)
	for c in controls:
		total += (c as Control).get_combined_minimum_size().y
	return total

func _screen_width() -> float:
	if is_inside_tree():
		return get_viewport_rect().size.x
	return float(ProjectSettings.get_setting("display/window/size/viewport_width", 390))

func _build_item_button() -> Button:
	var b := UI.button("Item", func(): pass)
	b.pressed.connect(func(): _toggle_item_menu(b))
	_style_action_button(b)
	return b

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

func _close_item_menu() -> void:
	if is_instance_valid(_item_menu):
		_item_menu.queue_free()
	_item_menu = null

# A plain option is one button. A check option shown as "odds"/"hint" is a
# row of the button (label suffixed with its odds or hint word) and an info
# control opening the modifiers sheet; "hidden" shows neither.
func _build_choice_button(label: String, choice_index: int) -> Control:
	var choice: Dictionary = Events.current_card()["choices"][choice_index]
	for effect in choice.get("effects", []):
		if effect.get("op", "") == "lose_time_block":
			label = UI.format_block_cost_label(label)
			break
	var odds: Dictionary = Events.check_odds(choice_index)
	var shown: bool = not odds.is_empty() and odds["show"] != "hidden"
	if shown:
		label = odds_label(label, odds)
	var b := UI.button(label, func(): Events.choose(choice_index))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(b)
	var option: Control = b
	if shown:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
		var info := UI.button(GameData.EVENT_CHECKS["infoGlyph"], func(): pass)
		info.clip_text = false
		info.pressed.connect(func(): _toggle_odds_sheet(info, odds))
		_style_action_button(info)
		row.add_child(info)
		option = row
	var toggles: Array = Events.item_toggles(choice_index)
	if toggles.is_empty():
		return option
	# Optional item toggles sit under the option they apply to.
	var stack := UI.vbox(4)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(option)
	for toggle in toggles:
		stack.add_child(_build_item_toggle(choice_index, toggle))
	return stack

func _build_item_toggle(choice_index: int, toggle: Dictionary) -> Button:
	var item: String = toggle["item"]
	var t := UI.button(item_toggle_label(toggle), func(): Events.toggle_item(choice_index, item))
	t.toggle_mode = true
	t.set_pressed_no_signal(toggle["on"])
	t.disabled = not toggle["held"]
	t.icon = ItemIcons.texture(item)
	t.expand_icon = true
	t.size_flags_horizontal = Control.SIZE_SHRINK_END
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
	return GameData.EVENT_CHECKS["outcomeMarkers"][card["outcome"]]

# "Label · 60%", or "Label · 2 tries · 55%" (per-attempt odds) for a
# multi-attempt check; hint mode swaps the percentage for the hint word.
static func odds_label(label: String, odds: Dictionary) -> String:
	if int(odds.get("attempts", 1)) > 1:
		label = GameData.EVENT_CHECKS["attemptsFormat"] % [label, odds["attempts"]]
	if odds["show"] == "hint":
		return GameData.EVENT_CHECKS["hintFormat"] % [label, odds["hint"]]
	return GameData.EVENT_CHECKS["oddsFormat"] % [label, roundi(odds["probability"] * 100.0)]

# One line per applied modifier with its signed delta; "odds" also leads
# with the base.
static func odds_sheet_lines(odds: Dictionary) -> Array:
	var lines: Array = []
	if odds["show"] == "odds":
		lines.append("%s %d%%" % [GameData.EVENT_CHECKS["baseLabel"], roundi(odds["base"] * 100.0)])
	for mod in odds["mods"]:
		lines.append("%+d%% %s" % [roundi(mod["delta"] * 100.0), mod["label"]])
	if odds["mods"].is_empty():
		lines.append(GameData.EVENT_CHECKS["noModifiers"])
	return lines

# Shares the Item menu's overlay slot, so only one popup is open at a time.
func _toggle_odds_sheet(anchor: Button, odds: Dictionary) -> void:
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
	var panel := UI.card()
	for line in odds_sheet_lines(odds):
		panel["content"].add_child(UI.label(line))
	_item_menu.add_child(panel["panel"])
	add_child(_item_menu)

	var sheet: Control = panel["panel"]
	var sheet_size: Vector2 = sheet.get_combined_minimum_size()
	var anchor_pos: Vector2 = anchor.global_position - global_position
	var x: float = clampf(anchor_pos.x + anchor.size.x - sheet_size.x, 16.0, maxf(16.0, _screen_width() - 16.0 - sheet_size.x))
	var y: float = maxf(UI.top_bar_clearance(), anchor_pos.y - sheet_size.y - 8.0)
	sheet.position = Vector2(x, y)

func _build_continue_button(text: String) -> Button:
	var b := UI.button(text, func(): Events.advance())
	_style_action_button(b)
	return b

func _style_card(panel: PanelContainer, card_type: String) -> void:
	if card_type != "tension" and card_type != "craft":
		return

	var box := StyleBoxFlat.new()
	box.corner_radius_top_left = 10
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_right = 10
	box.corner_radius_bottom_left = 10
	box.content_margin_left = 16.0
	box.content_margin_top = 16.0
	box.content_margin_right = 16.0
	box.content_margin_bottom = 16.0
	box.border_width_left = 4

	if card_type == "tension":
		box.bg_color = Color(0.980392, 0.972549, 0.952941, 1)
		box.border_color = MapPalette.light("danger")
	else:  # craft
		box.bg_color = _calc_gold_light()
		box.border_color = _calc_gold()

	panel.add_theme_stylebox_override("panel", box)

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
func _build_image_frame() -> PanelContainer:
	var frame := PanelContainer.new()
	frame.set_anchors_preset(Control.PRESET_TOP_WIDE)
	frame.offset_left = 16
	frame.offset_right = -16
	frame.offset_top = UI.top_bar_clearance()
	frame.offset_bottom = UI.top_bar_clearance()  # zero height until an image is shown
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_contents = true
	frame.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = _INK_COLOR
	frame.add_theme_stylebox_override("panel", style)

	_image_texture = TextureRect.new()
	_image_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_image_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	frame.add_child(_image_texture)

	return frame

func _refresh_image_slot() -> void:
	var image_path: Variant = Events.current_image_path()
	var showing: bool = image_path != null and typeof(image_path) == TYPE_STRING and ResourceLoader.exists(image_path)

	if showing:
		_image_texture.texture = load(image_path)
	else:
		_image_texture.texture = null

	_image_frame.visible = showing
	var top: float = UI.top_bar_clearance()
	_image_frame.offset_top = top
	_image_frame.offset_bottom = top + IMAGE_SLOT_HEIGHT if showing else top
	_scroll.offset_top = top + (IMAGE_SLOT_HEIGHT if showing else 0.0)
func _build_vn_frame() -> Control:
	var frame := Control.new()
	UI.anchor_full_rect(frame)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.clip_contents = true

	_vn_image_frame = Control.new()
	_vn_image_frame.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_vn_image_frame.anchor_bottom = 1.0
	_vn_image_frame.offset_bottom = -VN_TEXT_FRAME_HEIGHT - VN_BOTTOM_MARGIN
	_vn_image_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vn_image_frame.clip_contents = true
	frame.add_child(_vn_image_frame)

	_vn_texture = TextureRect.new()
	UI.anchor_full_rect(_vn_texture)
	_vn_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vn_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vn_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_vn_image_frame.add_child(_vn_texture)

	_vn_card_box = UI.vbox(0)
	_vn_card_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_vn_card_box.offset_left = 16.0
	_vn_card_box.offset_right = -16.0
	_vn_card_box.offset_top = -VN_TEXT_FRAME_HEIGHT - VN_BOTTOM_MARGIN
	_vn_card_box.offset_bottom = -VN_BOTTOM_MARGIN
	_vn_card_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(_vn_card_box)
	_vn_text_frame = _vn_card_box

	return frame
func _refresh_vn_frame() -> void:
	var top: float = UI.top_bar_clearance()
	var bottom_inset: float = UI.safe_area_bottom_inset()
	_vn_frame.offset_top = top
	_vn_frame.offset_bottom = -8.0 - bottom_inset
func _refresh_vn_card() -> void:
	for child in _vn_card_box.get_children():
		child.queue_free()

	var image_path: Variant = Events.current_image_path()
	var showing: bool = image_path != null and typeof(image_path) == TYPE_STRING and ResourceLoader.exists(image_path)
	_vn_texture.texture = load(image_path) if showing else null

	var card: Dictionary = Events.revealed_cards().back()
	var built := UI.card()
	_style_card(built["panel"], card["type"])
	_vn_card_panel = built["panel"]
	_vn_card_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_vn_text_scroll = UI.scroll_container()
	_vn_text_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_vn_text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_vn_text_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var prose := UI.vbox(8)
	prose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_populate_card_text(prose, card)
	_vn_text_scroll.add_child(prose)
	built["content"].add_child(_vn_text_scroll)

	_vn_controls_row = _controls_box()
	var controls: Array = _fill_controls(_vn_controls_row, _screen_width() - SCREEN_GUTTER_H - VN_CARD_PADDING_H, "→")
	built["content"].add_child(_vn_controls_row)
	_vn_card_box.add_child(_vn_card_panel)

	# A stacked choice column grows the text panel upward by the extra rows,
	# so the prose viewport keeps its usual height.
	var extra: float = 0.0
	if _vn_controls_row.vertical:
		var row_height: float = 0.0
		for c in controls:
			row_height = maxf(row_height, (c as Control).get_combined_minimum_size().y)
		extra = maxf(0.0, _stack_height(controls) - row_height)
	_vn_card_box.offset_top = -VN_TEXT_FRAME_HEIGHT - VN_BOTTOM_MARGIN - extra
	_vn_image_frame.offset_bottom = _vn_card_box.offset_top

func _scroll_to_bottom() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_instance_valid(_scroll):
		return
	var vscroll := _scroll.get_v_scroll_bar()
	_scroll.scroll_vertical = int(vscroll.max_value)
