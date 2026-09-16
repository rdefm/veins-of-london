class_name SymbolGlyph
extends Control


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

var draw_fallback: Callable


func _draw() -> void:
	draw_symbol(self, ThemeDB.fallback_font, size / 2.0, symbol, color, font_size, glyph_radius, draw_fallback)


static func draw_symbol(target: Object, font: Font, center: Vector2, symbol: String, colour: Color, font_size: int, radius: float, draw_fallback: Callable) -> void:
	if covers(font, symbol):
		var text_size := font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var baseline := center + Vector2(-text_size.x / 2.0, text_size.y * 0.35)
		target.draw_string(font, baseline, symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
	else:
		draw_fallback.call(target, center, colour, radius)


static func covers(font: Font, symbol: String) -> bool:
	return not symbol.is_empty() and font.has_char(symbol.unicode_at(0))


static func ore_fallback(ore_type: String) -> Callable:
	return func(target: Object, center: Vector2, colour: Color, radius: float) -> void:
		OreGlyphs.draw(target, center, ore_type, colour, radius)


static func generic_fallback() -> Callable:
	return func(target: Object, center: Vector2, colour: Color, radius: float) -> void:
		target.draw_colored_polygon(PackedVector2Array([
			center + Vector2(0, -radius), center + Vector2(radius, 0),
			center + Vector2(0, radius), center + Vector2(-radius, 0),
		]), colour)
