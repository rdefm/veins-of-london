class_name MapCardStyle
extends RefCounted

# Shared paper-card look for map-tab popups (station/vein bubbles, the vein
# detail sheet). One palette + stylebox recipe so a new map popup opts in
# here instead of re-declaring its own colours.

const PAPER := Color("#f0eee6")
const INK := Color("#252e30")
const DIM := Color("#65716c")
const LINE := Color("#c0c8bb")
const GOLD := Color("#957019")
const SAGE := Color("#dedfd3")


static func skin(fill: Color, radius: int, border: bool = true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.set_border_width_all(1 if border else 0)
	style.border_color = LINE
	return style


# Full popup/card panel: paper fill, rounded border and a soft drop shadow.
static func card_panel(radius: int = 18, shadow_alpha: float = 0.16) -> StyleBoxFlat:
	var style := skin(PAPER, radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = Color(0, 0, 0, shadow_alpha)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 10)
	return style


# Round action-icon button states shared by the map bubbles' Harvest/
# Cultivate-style circular actions.
static func action_circle_style(state: String) -> StyleBoxFlat:
	var fill := SAGE
	match state:
		"hover":
			fill = SAGE.lightened(0.15)
		"pressed":
			fill = LINE
		"disabled":
			fill = PAPER
	return skin(fill, 22)


# Nested section card inside a card_panel (site rows, vein/faction cards).
static func inset_panel() -> StyleBoxFlat:
	var style := skin(Color(SAGE.r, SAGE.g, SAGE.b, 0.45), 12)
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


# Map-card text button: action accent when live, DIM when disabled. Call after
# `disabled` is set.
static func style_button(b: Button) -> Button:
	UI.style_action_button(b, DIM if b.disabled else UI.action_colour())
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
	bar.add_theme_stylebox_override("background", skin(SAGE, 4, false))
	bar.add_theme_stylebox_override("fill", skin(GOLD, 4, false))
	return bar
