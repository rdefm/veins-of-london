class_name SymbolGlyph
extends Control

# Bugfixes ticket 113: MapCanvas (_draw_ore_symbol, see ore_glyphs.gd's own
# header comment) is so far the only place in this codebase that works
# around the bundled engine font's missing glyph coverage -- every other
# screen still draws a symbol as a plain Label/draw_string, tofu'ing on any
# glyph the font doesn't cover (confirmed for the 5 ore symbols via
# OreGlyphs.font_covers_all_symbols(); ticket 114's sweep is expected to
# find more elsewhere). This Control is that same fallback, generalised:
# drop it in anywhere a Label would show a single symbol glyph, hand it a
# `draw_fallback` Callable shaped like OreGlyphs.draw/Icons.draw_* (fn(
# target, center, colour, radius) -> void), and it renders the real text
# glyph when the font covers `symbol` and the hand-drawn vector fallback
# otherwise -- the same decision MapCanvas already makes per-stop, now made
# once here instead of reimplemented by each call site. Wiring this into any
# actual menu screen is ticket 114's job, not this one's.
#
# The decision/dispatch logic is split into static funcs (covers()/
# draw_symbol()) precisely so it's testable the same "off-tree, DrawSpy
# double" way tests/test_ore_glyphs.gd and tests/test_icons.gd already test
# OreGlyphs.draw()/Icons.draw_* -- ThemeDB.fallback_font resolves fine
# without a live SceneTree (test_ore_glyphs.gd already calls it directly),
# so covers()/draw_symbol()/ore_fallback() are all exercised in tests/
# test_symbol_glyph.gd with no Control ever entering a tree. Only this
# Control's own _draw()/_ready() wiring (reading its own `size`, connecting
# to the real fallback font, actually rasterising) is left genuinely
# untestable off-tree -- same caveat MapCanvas's own _draw() already
# carries, documented rather than worked around.

@export var symbol: String = "":
	set(value):
		symbol = value
		queue_redraw()
@export var color: Color = Color.WHITE:
	set(value):
		color = value
		queue_redraw()
@export var font_size: int = 11:
	set(value):
		font_size = value
		queue_redraw()
@export var glyph_radius: float = 5.5:
	set(value):
		glyph_radius = value
		queue_redraw()

# The hand-drawn vector fallback to use when the font doesn't cover
# `symbol` -- same shape as OreGlyphs.draw/Icons.draw_*: fn(target: Object,
# center: Vector2, colour: Color, radius: float) -> void. Callers with an
# ore symbol can just use ore_fallback() below; anything else supplies its
# own. No default: a caller with nothing to fall back to should fail loudly
# (an empty Callable's .call() errors) rather than silently render nothing.
var draw_fallback: Callable


func _draw() -> void:
	draw_symbol(self, ThemeDB.fallback_font, size / 2.0, symbol, color, font_size, glyph_radius, draw_fallback)


# Pure dispatch: draws `symbol` as centred text via `target.draw_string` when
# `font` covers it, otherwise calls `draw_fallback(target, center, colour,
# radius)`. Centering formula matches map_canvas.gd's own
# _draw_centered_text exactly, so a symbol drawn through this helper lines
# up identically to the one MapCanvas already draws whenever the font does
# cover it.
static func draw_symbol(target: Object, font: Font, center: Vector2, symbol: String, colour: Color, font_size: int, radius: float, draw_fallback: Callable) -> void:
	if covers(font, symbol):
		var text_size := font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var baseline := center + Vector2(-text_size.x / 2.0, text_size.y * 0.35)
		target.draw_string(font, baseline, symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
	else:
		draw_fallback.call(target, center, colour, radius)


static func covers(font: Font, symbol: String) -> bool:
	return not symbol.is_empty() and font.has_char(symbol.unicode_at(0))


# Convenience for the concrete case this ticket names explicitly: the 5
# ore-type symbols, already covered by OreGlyphs (see that file's own header
# comment for why the vector shapes exist). Binds ore_type so a caller just
# wires the result in as `draw_fallback` rather than writing its own wrapper
# lambda around OreGlyphs.draw.
static func ore_fallback(ore_type: String) -> Callable:
	return func(target: Object, center: Vector2, colour: Color, radius: float) -> void:
		OreGlyphs.draw(target, center, ore_type, colour, radius)


# Ticket 114's sweep found the font gap isn't limited to the 5 ore symbols --
# every recipe/dial-movement/approach symbol (~19 more, data/recipes.json,
# data/dial.json, data/approaches.json) is uncovered too, and none of them
# has bespoke vector art the way OreGlyphs does per ore type. Commissioning
# ~19 distinct hand-drawn shapes was scoped out of this ticket (human call,
# 114 planning) in favour of one shared placeholder: a small filled diamond,
# distinct enough from OreGlyphs' 5 ore silhouettes that a player can still
# tell "an ore" from "something else" at a glance. Meets the ticket's actual
# bar -- no blank tofu box -- without per-glyph fidelity.
static func generic_fallback() -> Callable:
	return func(target: Object, center: Vector2, colour: Color, radius: float) -> void:
		target.draw_colored_polygon(PackedVector2Array([
			center + Vector2(0, -radius), center + Vector2(radius, 0),
			center + Vector2(0, radius), center + Vector2(-radius, 0),
		]), colour)
