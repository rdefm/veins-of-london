class_name MapBubble
extends Control


signal option_selected(option_id: String)
signal closed()

const ICON_SIZE := 20.0
const ACTION_WIDTH := 88.0
const ACTION_ICON_SIZE := 56.0

var _dim: ColorRect
var _panel: PanelContainer
var _content: VBoxContainer

var _anchor: Vector2 = Vector2.ZERO
var _bounds_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	UI.anchor_full_rect(self)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0)  # transparent -- the diagram must stay fully visible, this only exists to catch the outside tap
	UI.anchor_full_rect(_dim)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.visible = false
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", MapCardStyle.card_panel())
	add_child(_panel)

	_content = UI.vbox(4)
	_panel.add_child(_content)


func open(anchor: Vector2, options: Array, bounds_size: Vector2 = Vector2.ZERO, horizontal_actions: bool = false) -> void:
	_anchor = anchor
	_bounds_size = bounds_size if bounds_size != Vector2.ZERO else size
	_rebuild(options, horizontal_actions)
	visible = true
	_dim.visible = true
	_panel.visible = true
	_reposition()


func close() -> void:
	if not visible:
		return
	visible = false
	_dim.visible = false
	_panel.visible = false
	closed.emit()


func _on_dim_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		close()


func _rebuild(options: Array, horizontal_actions: bool = false) -> void:
	for child in _content.get_children():
		child.free()
	if horizontal_actions:
		var actions := UI.hbox(8)
		for option in options:
			actions.add_child(_build_action_column(option))
		_content.add_child(actions)
		return
	for option in options:
		_content.add_child(_build_option_row(option))


func _build_action_column(option: Dictionary) -> Control:
	var id: String = option.get("id", "")
	var label_text: String = option.get("label", "")
	var draw_icon: Callable = option.get("icon", Icons.draw_hamburger)
	var disabled: bool = option.get("disabled", false)
	var reason: String = option.get("reason", "")

	var column := UI.vbox(4)
	column.custom_minimum_size.x = ACTION_WIDTH
	column.alignment = BoxContainer.ALIGNMENT_BEGIN

	var button := Button.new()
	button.custom_minimum_size = Vector2(ACTION_ICON_SIZE, ACTION_ICON_SIZE)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.disabled = disabled
	button.pressed.connect(func(): _select(id))
	for state in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state, MapCardStyle.action_circle_style(state))
	var glyph := UI.icon_glyph_control(draw_icon, 1.25, MapCardStyle.DIM if disabled else MapCardStyle.INK)
	UI.anchor_full_rect(glyph)
	button.add_child(glyph)
	column.add_child(button)

	var label := UI.label(label_text)
	label.custom_minimum_size.x = ACTION_WIDTH
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", MapCardStyle.DIM if disabled else MapCardStyle.INK)
	column.add_child(label)
	if disabled and reason != "":
		var reason_label := UI.muted_label(reason)
		reason_label.custom_minimum_size.x = ACTION_WIDTH
		reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(reason_label)
	return column


func _build_option_row(option: Dictionary) -> Control:
	var id: String = option.get("id", "")
	var label_text: String = option.get("label", "")
	var icon: Variant = option.get("icon")
	var disabled: bool = option.get("disabled", false)
	var reason: String = option.get("reason", "")

	var row := UI.vbox(2)

	var b: Button
	if icon is Callable:
		b = _build_icon_label_button(label_text, icon, func(): _select(id))
	else:
		b = UI.button(label_text, func(): _select(id))
	b.disabled = disabled
	row.add_child(b)

	if disabled and reason != "":
		row.add_child(UI.muted_label(reason))

	return row


func _build_icon_label_button(label_text: String, draw_icon: Callable, callback: Callable) -> Button:
	var b := Button.new()
	b.pressed.connect(callback)
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	var inner := UI.hbox(6)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var glyph := UI.icon_glyph_control(draw_icon, 1.0)
	glyph.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	inner.add_child(glyph)

	var text_label := UI.label(label_text)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(text_label)

	b.add_child(inner)
	return b


func _select(option_id: String) -> void:
	close()
	option_selected.emit(option_id)


func _reposition() -> void:
	_apply_position()
	_apply_position.call_deferred()


func _apply_position() -> void:
	_panel.size = _panel.get_combined_minimum_size()
	_panel.position = BubbleLayout.popup_position(_anchor, _panel.size, _bounds_size)
