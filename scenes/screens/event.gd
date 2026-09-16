class_name EventScreen
extends Control

const IMAGE_SLOT_HEIGHT := 170.0
const VN_TEXT_FRAME_HEIGHT := 236.0
const VN_BOTTOM_MARGIN := 16.0

const _ACTION_COLOR_FALLBACK := Color("#c8102e")
const _CALC_GOLD_FALLBACK := Color("#d4af52")
const _CALC_GOLD_LIGHT_FALLBACK := Color("#f2dfa0")
const _INK_COLOR := Color(0.101961, 0.101961, 0.101961, 1)

var _scroll: ScrollContainer
var _cards_box: VBoxContainer
var _action_bar: HBoxContainer
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
var _vn_controls_row: HBoxContainer

func _ready() -> void:
	UI.anchor_full_rect(self)

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
		_action_bar = UI.hbox(8)
		_action_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_action_bar.offset_left = 16
		_action_bar.offset_right = -16
		var bottom_inset := UI.safe_area_bottom_inset()
		_action_bar.offset_top = -56 - bottom_inset
		_action_bar.offset_bottom = -8 - bottom_inset
		add_child(_action_bar)

	EventBus.state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if GameState.state["event"] == null:
		return  # on_complete already navigated away; this node is about to be freed

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

	if Events.can_rewind():
		_action_bar.add_child(_build_rewind_button())

	if Events.is_awaiting_choice():
		var choices: Array = Events.current_card()["choices"]
		for i in range(choices.size()):
			_action_bar.add_child(_build_choice_button(choices[i]["label"], i))
	else:
		var continue_button := _build_continue_button("Continue →")
		continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_action_bar.add_child(continue_button)

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
		_:
			content.add_child(UI.label(card["text"]))
func _build_rewind_button() -> Button:
	var b := UI.button("⟲ Rewind", func(): Events.rewind())
	_style_action_button(b)
	return b

func _build_choice_button(label: String, choice_index: int) -> Button:
	var choice: Dictionary = Events.current_card()["choices"][choice_index]
	for effect in choice.get("effects", []):
		if effect.get("op", "") == "lose_time_block":
			label = UI.format_block_cost_label(label)
			break
	var b := UI.button(label, func(): Events.choose(choice_index))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_action_button(b)
	return b

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
		box.border_color = MapStyle.DANGER_COLOUR
	else:  # craft
		box.bg_color = _calc_gold_light()
		box.border_color = _calc_gold()

	panel.add_theme_stylebox_override("panel", box)

func _calc_gold() -> Color:
	return GameData.PALETTE.get("calc_gold", _CALC_GOLD_FALLBACK)

func _calc_gold_light() -> Color:
	return GameData.PALETTE.get("calc_gold_light", _CALC_GOLD_LIGHT_FALLBACK)

func _action_color() -> Color:
	return GameData.PALETTE.get("ui_action_red", _ACTION_COLOR_FALLBACK)
func _style_action_button(b: Button) -> void:
	var accent := _action_color()
	b.add_theme_stylebox_override("normal", _action_button_style(accent, 0.12, 1.0))
	b.add_theme_stylebox_override("hover", _action_button_style(accent, 0.20, 1.0))
	b.add_theme_stylebox_override("pressed", _action_button_style(accent, 0.30, 1.0))
	b.add_theme_stylebox_override("disabled", _action_button_style(accent, 0.05, 0.4))
	b.add_theme_color_override("font_color", accent)
	b.add_theme_color_override("font_hover_color", accent)
	b.add_theme_color_override("font_pressed_color", accent)
	b.add_theme_color_override("font_disabled_color", accent)

func _action_button_style(accent: Color, fill_alpha: float, border_alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, fill_alpha)
	style.set_corner_radius_all(8)
	style.set_border_width_all(1.5)
	style.border_color = Color(accent.r, accent.g, accent.b, border_alpha)
	style.content_margin_left = 16.0
	style.content_margin_top = 10.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 10.0
	return style
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

	_vn_controls_row = _build_vn_controls_row()
	built["content"].add_child(_vn_controls_row)
	_vn_card_box.add_child(_vn_card_panel)
func _build_vn_controls_row() -> HBoxContainer:
	var row := UI.hbox(8)

	if Events.can_rewind():
		row.add_child(_build_rewind_button())

	if Events.is_awaiting_choice():
		var choices: Array = Events.current_card()["choices"]
		for i in range(choices.size()):
			row.add_child(_build_choice_button(choices[i]["label"], i))
	else:
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		row.add_child(_build_continue_button("→"))

	return row

func _scroll_to_bottom() -> void:
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_instance_valid(_scroll):
		return
	var vscroll := _scroll.get_v_scroll_bar()
	_scroll.scroll_vertical = int(vscroll.max_value)
