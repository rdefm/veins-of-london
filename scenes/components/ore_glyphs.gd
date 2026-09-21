class_name OreGlyphs
extends RefCounted


const SHAPES := {
	"time": "hourglass",
	"physics": "bolt",
	"life": "sprout",
	"fate": "die",
	"emotion": "heart",
}


static func font_covers_all_symbols(font: Font) -> bool:
	for ore_id in GameData.ORE_TYPES.keys():
		var symbol: String = GameData.ORE_TYPES[ore_id].get("symbol", "")
		if symbol.is_empty() or not font.has_char(symbol.unicode_at(0)):
			return false
	return true


static func draw(target: Object, center: Vector2, ore_type: String, colour: Color, radius: float = 5.5) -> void:
	match SHAPES.get(ore_type, ""):
		"hourglass":
			_draw_hourglass(target, center, colour, radius)
		"bolt":
			_draw_bolt(target, center, colour, radius)
		"sprout":
			_draw_sprout(target, center, colour, radius)
		"die":
			_draw_die(target, center, colour, radius)
		"heart":
			_draw_heart(target, center, colour, radius)


static func _draw_hourglass(target: Object, c: Vector2, colour: Color, r: float) -> void:
	var edge := r * 0.68
	var cap_y := r * 0.78
	var width := maxf(1.0, r * 0.24)
	target.draw_line(c + Vector2(-edge, -cap_y), c + Vector2(edge, -cap_y), colour, width, true)
	target.draw_line(c + Vector2(-edge, cap_y), c + Vector2(edge, cap_y), colour, width, true)
	target.draw_line(c + Vector2(-edge, -cap_y), c, colour, width, true)
	target.draw_line(c + Vector2(edge, -cap_y), c, colour, width, true)
	target.draw_line(c, c + Vector2(-edge, cap_y), colour, width, true)
	target.draw_line(c, c + Vector2(edge, cap_y), colour, width, true)


static func _draw_bolt(target: Object, c: Vector2, colour: Color, r: float) -> void:
	target.draw_colored_polygon(PackedVector2Array([
		c + Vector2(0.18, -0.86) * r,
		c + Vector2(-0.58, 0.02) * r,
		c + Vector2(-0.08, 0.02) * r,
		c + Vector2(-0.24, 0.86) * r,
		c + Vector2(0.62, -0.18) * r,
		c + Vector2(0.10, -0.18) * r,
	]), colour)


static func _draw_sprout(target: Object, c: Vector2, colour: Color, r: float) -> void:
	var width := maxf(1.0, r * 0.24)
	var junction := c + Vector2(0.0, -r * 0.02)
	target.draw_line(junction, c + Vector2(0.0, r * 0.72), colour, width, true)
	target.draw_line(c + Vector2(-r * 0.34, r * 0.72), c + Vector2(r * 0.34, r * 0.72), colour, width, true)
	target.draw_colored_polygon(PackedVector2Array([
		junction,
		c + Vector2(-0.28, -0.56) * r,
		c + Vector2(-0.72, -0.72) * r,
		c + Vector2(-0.66, -0.28) * r,
		c + Vector2(-0.20, 0.08) * r,
	]), colour)
	target.draw_colored_polygon(PackedVector2Array([
		junction,
		c + Vector2(0.28, -0.56) * r,
		c + Vector2(0.72, -0.72) * r,
		c + Vector2(0.66, -0.28) * r,
		c + Vector2(0.20, 0.08) * r,
	]), colour)


static func _draw_die(target: Object, c: Vector2, colour: Color, r: float) -> void:
	var half := r * 0.72
	var width := maxf(1.0, r * 0.24)
	target.draw_rect(Rect2(c - Vector2(half, half), Vector2(half, half) * 2.0), colour, false, width, true)
	var dot_r := maxf(0.7, r * 0.13)
	var pip_offset := half * 0.52
	for offset in [Vector2(-pip_offset, -pip_offset), Vector2(pip_offset, -pip_offset), Vector2.ZERO, Vector2(-pip_offset, pip_offset), Vector2(pip_offset, pip_offset)]:
		target.draw_circle(c + offset, dot_r, colour, true, -1.0, true)


static func _draw_heart(target: Object, c: Vector2, colour: Color, r: float) -> void:
	target.draw_colored_polygon(PackedVector2Array([
		c + Vector2(0.0, -0.38) * r,
		c + Vector2(-0.20, -0.68) * r,
		c + Vector2(-0.52, -0.70) * r,
		c + Vector2(-0.76, -0.42) * r,
		c + Vector2(-0.74, -0.08) * r,
		c + Vector2(-0.54, 0.22) * r,
		c + Vector2(0.0, 0.78) * r,
		c + Vector2(0.54, 0.22) * r,
		c + Vector2(0.74, -0.08) * r,
		c + Vector2(0.76, -0.42) * r,
		c + Vector2(0.52, -0.70) * r,
		c + Vector2(0.20, -0.68) * r,
	]), colour)
