class_name MapCardStyle
extends RefCounted

# Shared paper-card look for map-tab popups (station/vein bubbles, the vein
# detail sheet). One stylebox recipe over the Map palette's card tokens
# (MapPalette, data/map_palette.json) so a new map popup opts in here
# instead of re-declaring its own colours.

static func paper() -> Color:
	return MapPalette.colour("cardPaper")


static func ink() -> Color:
	return MapPalette.colour("cardInk")


static func dim() -> Color:
	return MapPalette.colour("cardDim")


# Theme-grey reason/hint text (UI.muted_label's colour in light).
static func muted() -> Color:
	return MapPalette.colour("cardMuted")


# Map-card action accent: ui_action_red in light, a lighter dark-only variant
# that keeps >=4.5:1 on dark cardPaper.
static func action() -> Color:
	return MapPalette.colour("cardAction")


static func line() -> Color:
	return MapPalette.colour("cardLine")


static func gold() -> Color:
	return MapPalette.colour("cardGold")


static func sage() -> Color:
	return MapPalette.colour("cardSage")


static func skin(fill: Color, radius: int, border: bool = true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1 if border else 0)
	style.border_color = line()
	return style


# Full popup/card panel: paper fill, rounded border and a soft drop shadow.
static func card_panel(radius: int = 18, shadow_alpha: float = 0.16) -> StyleBoxFlat:
	var style := skin(paper(), radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = Color(MapPalette.colour("shadow"), shadow_alpha)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 10)
	return style


# Round action-icon button states shared by the map bubbles' Harvest/
# Cultivate-style circular actions.
static func action_circle_style(state: String) -> StyleBoxFlat:
	var fill := sage()
	match state:
		"hover":
			fill = fill.lightened(0.15)
		"pressed":
			fill = line()
		"disabled":
			fill = paper()
	return skin(fill, 22)


# Nested section card inside a card_panel (site rows, vein/faction cards).
static func inset_panel() -> StyleBoxFlat:
	var style := skin(Color(sage(), 0.45), 12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func label(text: String, size: int, colour: Color) -> Label:
	var l := UI.label(text)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	return l


# Map-card text button: action accent when live, dim() when disabled. Call after
# `disabled` is set.
static func style_button(b: Button) -> Button:
	UI.style_action_button(b, dim() if b.disabled else action())
	return b


# Recolours a UI.symbol_row / symbol_button's labels and glyphs to `colour`.
static func tint_symbols(root: Control, colour: Color) -> Control:
	for child in root.get_children():
		if child is Label:
			child.add_theme_color_override("font_color", colour)
		elif child is SymbolGlyph:
			child.color = colour
		elif child is Container:
			tint_symbols(child, colour)
	return root


static func style_bar(bar: ProgressBar) -> ProgressBar:
	bar.add_theme_stylebox_override("background", skin(sage(), 4, false))
	bar.add_theme_stylebox_override("fill", skin(gold(), 4, false))
	return bar


# Map-card version of UI.action_button: styled button plus a dim() reason line
# when disabled.
static func action_button(text: String, callback: Callable, disabled: bool = false, reason: String = "") -> Control:
	var row := UI.vbox(2)
	var b := UI.button(text, callback)
	b.disabled = disabled
	row.add_child(style_button(b))
	if disabled and reason != "":
		row.add_child(label(reason, 12, dim()))
	return row
