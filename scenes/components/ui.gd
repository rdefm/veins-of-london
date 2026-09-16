class_name UI
extends RefCounted



static func anchor_full_rect(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0


static func anchor_top_wide(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_WIDE)
	control.offset_left = 0
	control.offset_right = 0
	control.offset_top = 0
	control.offset_bottom = 0


static func anchor_bottom_wide(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	control.offset_left = 0
	control.offset_right = 0


static func anchor_below_bars(control: Control) -> void:
	anchor_full_rect(control)
	control.offset_top = top_bar_clearance()
	control.offset_bottom = -NavBar.BAR_HEIGHT


static func anchor_center(control: Control) -> void:
	control.set_anchors_preset(Control.PRESET_CENTER)
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0
	control.grow_horizontal = Control.GROW_DIRECTION_BOTH
	control.grow_vertical = Control.GROW_DIRECTION_BOTH


static func vbox(sep: int = 8) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", sep)
	return box


static func hbox(sep: int = 8) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", sep)
	return box


static func hflow(sep: int = 8) -> HFlowContainer:
	var box := HFlowContainer.new()
	box.add_theme_constant_override("h_separation", sep)
	box.add_theme_constant_override("v_separation", sep)
	return box


static func card() -> Dictionary:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var content := vbox(6)
	panel.add_child(content)
	return { "panel": panel, "content": content }


static func collapsible_section(title: String, expanded: bool, on_toggle: Callable = Callable()) -> Dictionary:
	var section := vbox(6)

	var content := vbox(6)
	content.visible = expanded

	var header := Button.new()
	header.clip_text = true
	header.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.text = _accordion_header_text(title, expanded)
	header.pressed.connect(func():
		content.visible = not content.visible
		header.text = _accordion_header_text(title, content.visible)
		if on_toggle.is_valid():
			on_toggle.call(content.visible)
	)

	section.add_child(header)
	section.add_child(content)

	return { "panel": section, "content": content }


static func _accordion_header_text(title: String, expanded: bool) -> String:
	return "%s %s" % [title, "▾" if expanded else "▸"]


static func heading(text: String, size: int = 20) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	return label


const MAX_LABEL_TEXT_WIDTH := 220.0

static func label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font: Font = _THEME.get_font("font", "Label")
	if font == null:
		font = ThemeDB.fallback_font
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _THEME.default_font_size).x
	l.custom_minimum_size.x = minf(text_width, MAX_LABEL_TEXT_WIDTH)
	return l


static func muted_label(text: String) -> Label:
	var l := label(text)
	l.add_theme_color_override("font_color", Color(0.541176, 0.541176, 0.541176, 1))
	return l


static func expand_fill(control: Control) -> Control:
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return control


static func tinted_label(text: String, colour: Color) -> Label:
	var l := label(text)
	l.add_theme_color_override("font_color", colour)
	return l


const MAX_BUTTON_TEXT_WIDTH := 220.0

const _THEME: Theme = preload("res://theme/main_theme.tres")


const SYMBOL_GLYPH_SIZE := 16.0
const _MUTED_COLOUR := Color(0.541176, 0.541176, 0.541176, 1)

static func symbol_row(parts: Array, opts: Dictionary = {}) -> Control:
	var heading_size: int = opts.get("heading_size", 0)
	var muted: bool = opts.get("muted", false)
	var colour: Color = _MUTED_COLOUR if muted else _THEME.get_color("font_color", "Label")
	var row := hbox(opts.get("sep", 4))
	for part in parts:
		row.add_child(_symbol_part(part, heading_size, colour))
	return row


static func _symbol_part(part: Variant, heading_size: int, colour: Color) -> Control:
	if part is Dictionary:
		var glyph := SymbolGlyph.new()
		glyph.symbol = part.get("symbol", "")
		glyph.draw_fallback = part.get("fallback", Callable())
		var glyph_size: float = SYMBOL_GLYPH_SIZE if heading_size <= 0 else float(heading_size) * 1.1
		glyph.custom_minimum_size = Vector2(glyph_size, glyph_size)
		glyph.font_size = heading_size if heading_size > 0 else 11
		glyph.glyph_radius = glyph_size * 0.34
		glyph.color = colour
		return glyph

	var text := String(part)
	if heading_size > 0:
		var h := heading(text, heading_size)
		h.add_theme_color_override("font_color", colour)
		return h
	var l := label(text)
	l.add_theme_color_override("font_color", colour)
	return l


static func symbol_button(parts: Array, callback: Callable) -> Button:
	var b := Button.new()
	b.pressed.connect(callback)
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	var inner := hbox(4)
	anchor_full_rect(inner)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font_colour: Color = _THEME.get_color("font_color", "Button")
	for part in parts:
		var child := _symbol_part(part, 0, font_colour)
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		child.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if child is Label:
			child.autowrap_mode = TextServer.AUTOWRAP_OFF
			child.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inner.add_child(child)
	b.add_child(inner)

	var style := _THEME.get_stylebox("normal", "Button")
	var font: Font = _THEME.get_font("font", "Button")
	if font == null:
		font = ThemeDB.fallback_font
	var content_width := float(4 * maxi(parts.size() - 1, 0))
	for part in parts:
		if part is Dictionary:
			content_width += SYMBOL_GLYPH_SIZE
		else:
			content_width += font.get_string_size(String(part), HORIZONTAL_ALIGNMENT_LEFT, -1, _THEME.default_font_size).x
	b.custom_minimum_size.x = minf(content_width + style.get_minimum_size().x, MAX_BUTTON_TEXT_WIDTH)

	return b


static func option_button(items: Array) -> OptionButton:
	var o := OptionButton.new()
	for item in items:
		o.add_item(item)
	return o


static func button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.pressed.connect(callback)

	var style := _THEME.get_stylebox("normal", "Button")
	var font: Font = _THEME.get_font("font", "Button")
	if font == null:
		font = ThemeDB.fallback_font
	var text_width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _THEME.default_font_size).x
	b.custom_minimum_size.x = minf(text_width + style.get_minimum_size().x, MAX_BUTTON_TEXT_WIDTH)

	return b


static func action_button(text: String, callback: Callable, disabled: bool = false, reason: String = "") -> Control:
	var row := vbox(2)
	var b := button(text, callback)
	b.disabled = disabled
	row.add_child(b)
	if disabled and reason != "":
		row.add_child(muted_label(reason))
	return row


const ICON_BUTTON_SIZE := 40.0
const ICON_GLYPH_SCALE := 1.4

static func icon_button(draw_icon: Callable, callback: Callable, colour_override: Variant = null) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(ICON_BUTTON_SIZE, ICON_BUTTON_SIZE)
	b.pressed.connect(callback)

	var glyph := icon_glyph_control(draw_icon, ICON_GLYPH_SCALE, colour_override)
	anchor_full_rect(glyph)
	b.add_child(glyph)

	return b


static func icon_glyph_control(draw_icon: Callable, glyph_scale: float = ICON_GLYPH_SCALE, colour_override: Variant = null) -> Control:
	var glyph := _IconGlyph.new()
	glyph.draw_icon = draw_icon
	glyph.glyph_scale = glyph_scale
	glyph.colour_override = colour_override
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return glyph


class _IconGlyph extends Control:
	var draw_icon: Callable
	var glyph_scale: float = ICON_GLYPH_SCALE
	var colour_override: Variant = null

	func _draw() -> void:
		if draw_icon.is_valid():
			var colour: Color = colour_override if colour_override != null else get_theme_color("font_color", "Button")
			draw_icon.call(self, size / 2.0, colour, glyph_scale)


static func back_button(target_screen: String) -> Button:
	return button("‹ Back", func(): Nav.go_to(target_screen))


static func back_to_home_button() -> Button:
	return button("‹ Back", func(): PhoneNav.route_home())


const BUBBLE_WIDTH := 260.0

static func message_bubble(text: String, from_player: bool) -> Control:
	var row := hbox()
	if from_player:
		row.alignment = BoxContainer.ALIGNMENT_END
	var bubble := card()
	var text_label := label(text)
	text_label.custom_minimum_size.x = BUBBLE_WIDTH
	bubble["content"].add_child(text_label)
	row.add_child(bubble["panel"])
	return row


static func checklist_row(text: String, done: bool) -> Control:
	var row := hbox(6)
	var check_label := label("☑" if done else "☐")
	row.add_child(check_label)
	var text_label := label(text)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if done:
		text_label.add_theme_color_override("font_color", Color(0.541176, 0.541176, 0.541176, 1))
	row.add_child(text_label)
	return row


static func bar(value: float, max_value: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.min_value = 0
	b.max_value = max(max_value, 0.0001)
	b.value = value
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, 8)
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	return b


static func format_cost_label(cost: Dictionary, holdings: Dictionary) -> String:
	var resource: String = cost.get("resource", "")
	var amount: int = cost.get("amount", 0)
	var have: int = holdings.get(resource, 0)

	var amount_text: String
	if resource == "cash":
		amount_text = "£%d (have £%d)" % [amount, have]
	else:
		amount_text = "%d %s (have %d)" % [amount, resource, have]

	var label: String = cost.get("label", "")
	if label == "":
		return amount_text
	return "%s — %s" % [label, amount_text]


static func block_cost_suffix(action_blocks: int = 1) -> String:
	if action_blocks <= 0:
		return ""
	if GameState.state["world"]["timeBlock"] == GameData.TIME_BLOCKS.size() - 1 and not TimeSystem.is_time_exhausted():
		return GameData.DAY_CLOCK["finalBlock"]
	return GameData.DAY_CLOCK["blockSingular" if action_blocks == 1 else "blockPlural"] % action_blocks


static func format_block_cost_label(action_label: String, action_blocks: int = 1, available: bool = true) -> String:
	if not available or action_blocks <= 0 or TimeSystem.is_time_exhausted():
		return action_label
	return "%s — %s" % [action_label, block_cost_suffix(action_blocks)]


static func safe_area_insets() -> Dictionary:
	var zero := { "top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0 }

	var window_size := DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		return zero

	var loop := Engine.get_main_loop()
	if loop == null or not (loop is SceneTree):
		return zero
	var canvas_size: Vector2 = (loop as SceneTree).root.get_visible_rect().size

	var scale_x: float = canvas_size.x / float(window_size.x)
	var scale_y: float = canvas_size.y / float(window_size.y)

	var safe_area := DisplayServer.get_display_safe_area()
	return {
		"top": safe_area.position.y * scale_y,
		"bottom": (window_size.y - safe_area.position.y - safe_area.size.y) * scale_y,
		"left": safe_area.position.x * scale_x,
		"right": (window_size.x - safe_area.position.x - safe_area.size.x) * scale_x,
	}


static func safe_area_bottom_inset() -> float:
	return safe_area_insets()["bottom"]


static func safe_area_top_inset() -> float:
	return safe_area_insets()["top"]


static func top_bar_clearance() -> float:
	return TopBar.BAR_HEIGHT + safe_area_top_inset()


static func safe_area_debug_text() -> String:
	var window_size := DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		return "window 0x0 (no window open -- headless/desktop-without-window)"

	var loop := Engine.get_main_loop()
	var canvas_size := Vector2.ZERO
	if loop != null and loop is SceneTree:
		canvas_size = (loop as SceneTree).root.get_visible_rect().size

	var safe_area := DisplayServer.get_display_safe_area()
	var insets := safe_area_insets()

	return "window %dx%d\ncanvas %.0fx%.0f\nraw safe-area pos (%d,%d) size %dx%d\ninsets top=%.1f bottom=%.1f left=%.1f right=%.1f" % [
		window_size.x, window_size.y,
		canvas_size.x, canvas_size.y,
		safe_area.position.x, safe_area.position.y, safe_area.size.x, safe_area.size.y,
		insets["top"], insets["bottom"], insets["left"], insets["right"],
	]


static func scroll_container() -> ScrollContainer:
	var sc := TouchScrollContainer.new()
	anchor_full_rect(sc)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return sc


static func screen_body(root: Control) -> VBoxContainer:
	var sc := scroll_container()
	anchor_below_bars(sc)
	root.add_child(sc)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)  # breathing room only -- the scroll viewport itself (above) now clears the top bar
	margin.add_theme_constant_override("margin_bottom", 16)  # ditto, for the nav bar
	sc.add_child(margin)

	var content := vbox(12)
	margin.add_child(content)
	return content
