class_name CardTheme
extends RefCounted

# Writes the map-card family (MapCardStyle, over the Map palette's card
# tokens) into a Theme as its defaults: quiet action-accent text buttons,
# sage dropdown/field chips, paper card panels, ink labels. Main applies it
# to theme/main_theme.tres at boot and again whenever the Map dark toggle
# flips, so every unstyled control follows the toggle.

const _BUTTON_STATES := ["normal", "hover", "pressed", "disabled"]
const _CHECK_STATES := ["normal", "hover", "pressed", "hover_pressed", "disabled"]


static func apply(theme: Theme) -> void:
	_apply_button(theme)
	_apply_option_button(theme)
	_apply_popup_menu(theme)
	_apply_line_edit(theme)
	_apply_check(theme, "CheckBox", "checkbox_checked_color", "checkbox_unchecked_color")
	_apply_check(theme, "CheckButton", "button_checked_color", "button_unchecked_color")
	_apply_panels(theme)
	_apply_bars(theme)
	theme.set_color("font_color", "Label", MapCardStyle.ink())


static func _apply_button(theme: Theme) -> void:
	var accent := MapCardStyle.action()
	var alphas := { "normal": 0.0, "hover": 0.14, "pressed": 0.22, "disabled": 0.0 }
	for state in _BUTTON_STATES:
		theme.set_stylebox(state, "Button", UI.action_button_style(accent, alphas[state]))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(key, "Button", accent)
	theme.set_color("font_disabled_color", "Button", MapCardStyle.dim())
	for key in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		theme.set_color(key, "Button", accent)


static func _chip(fill: Color, radius: int = 10) -> StyleBoxFlat:
	var style := MapCardStyle.skin(fill, radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


static func _apply_option_button(theme: Theme) -> void:
	var sage := MapCardStyle.sage()
	theme.set_stylebox("normal", "OptionButton", _chip(sage))
	theme.set_stylebox("hover", "OptionButton", _chip(sage.lightened(0.15)))
	theme.set_stylebox("pressed", "OptionButton", _chip(MapCardStyle.line()))
	theme.set_stylebox("disabled", "OptionButton", _chip(MapCardStyle.paper()))
	theme.set_stylebox("focus", "OptionButton", StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(key, "OptionButton", MapCardStyle.ink())
	theme.set_color("font_disabled_color", "OptionButton", MapCardStyle.dim())
	theme.set_constant("modulate_arrow", "OptionButton", 1)


static func _apply_popup_menu(theme: Theme) -> void:
	var panel := MapCardStyle.card_panel(12, 0.16)
	panel.content_margin_left = 6
	panel.content_margin_right = 6
	panel.content_margin_top = 6
	panel.content_margin_bottom = 6
	theme.set_stylebox("panel", "PopupMenu", panel)
	theme.set_stylebox("hover", "PopupMenu", MapCardStyle.skin(MapCardStyle.sage(), 8, false))
	for key in ["font_color", "font_hover_color", "font_accelerator_color"]:
		theme.set_color(key, "PopupMenu", MapCardStyle.ink())
	theme.set_color("font_disabled_color", "PopupMenu", MapCardStyle.dim())
	theme.set_color("font_separator_color", "PopupMenu", MapCardStyle.dim())


static func _apply_line_edit(theme: Theme) -> void:
	var field := _chip(MapCardStyle.sage(), 8)
	var focus := _chip(MapCardStyle.sage(), 8)
	focus.border_color = MapCardStyle.action()
	theme.set_stylebox("normal", "LineEdit", field)
	theme.set_stylebox("focus", "LineEdit", focus)
	theme.set_stylebox("read_only", "LineEdit", _chip(MapCardStyle.paper(), 8))
	theme.set_color("font_color", "LineEdit", MapCardStyle.ink())
	theme.set_color("font_uneditable_color", "LineEdit", MapCardStyle.dim())
	theme.set_color("font_placeholder_color", "LineEdit", MapCardStyle.dim())
	theme.set_color("caret_color", "LineEdit", MapCardStyle.ink())
	theme.set_color("selection_color", "LineEdit", Color(MapCardStyle.action(), 0.3))


static func _apply_check(theme: Theme, type: String, checked_key: String, unchecked_key: String) -> void:
	var clear := _chip(Color.TRANSPARENT)
	clear.set_border_width_all(0)
	for state in _CHECK_STATES:
		theme.set_stylebox(state, type, clear)
	theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	for key in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(key, type, MapCardStyle.ink())
	theme.set_color("font_disabled_color", type, MapCardStyle.dim())
	theme.set_color(checked_key, type, MapCardStyle.action())
	theme.set_color(unchecked_key, type, MapCardStyle.dim())


static func _apply_panels(theme: Theme) -> void:
	theme.set_stylebox("panel", "PanelContainer", MapCardStyle.card_panel(14, 0.08))
	theme.set_stylebox("panel", "Panel", MapCardStyle.card_panel(14, 0.08))


static func _apply_bars(theme: Theme) -> void:
	theme.set_stylebox("background", "ProgressBar", MapCardStyle.skin(MapCardStyle.sage(), 4, false))
	theme.set_stylebox("fill", "ProgressBar", MapCardStyle.skin(MapCardStyle.gold(), 4, false))
	var track := MapCardStyle.skin(MapCardStyle.line(), 3, false)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", MapCardStyle.skin(MapCardStyle.sage(), 3, false))
	theme.set_stylebox("grabber_area_highlight", "HSlider", MapCardStyle.skin(MapCardStyle.sage(), 3, false))
