class_name OreGlyphs
extends RefCounted

# M1.5 N6 asset 3: "verify the bundled font covers ⧖ ↯ ✦ ⚄ ❋ on Android;
# if not, render them as tiny SVG-derived textures (add to icon set)."
# font_covers_all_symbols() below is that check, run headlessly against
# ThemeDB.fallback_font — the only font this project bundles or overrides
# anywhere (no .ttf/.otf ships in the repo, and theme/main_theme.tres sets
# no custom font), so the engine's own built-in fallback font is what
# actually renders on every export target, Android included. Run against
# this project's real GameData.ORE_TYPES symbols, it returns false: none
# of the 5 are covered. No SVG toolchain is available in this
# environment, so the fallback is hand-drawn `_draw()` vector glyphs
# instead — the same allowance N6 gives the icon set — one per ore id,
# silhouette-matched to its symbol. MapCanvas draws these instead of the
# ore["symbol"] text glyph wherever a stop needs one.
#
# This bug predates this ticket (ore symbols have been rendering as blank
# tofu on every stop since ticket 12) and isn't limited to the map — see
# map_canvas.gd's integration comment for what's in scope here vs. flagged
# for a follow-up.

const SHAPES := {
	"time": "hourglass",
	"physics": "bolt",
	"life": "star4",
	"fate": "die5",
	"emotion": "asterisk8",
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
		"star4":
			_draw_star4(target, center, colour, radius)
		"die5":
			_draw_die5(target, center, colour, radius)
		"asterisk8":
			_draw_asterisk8(target, center, colour, radius)


# time (⧖ hourglass): two triangles meeting at a waist.
static func _draw_hourglass(target: Object, c: Vector2, colour: Color, r: float) -> void:
	target.draw_colored_polygon(PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r), c]), colour)
	target.draw_colored_polygon(PackedVector2Array([c + Vector2(-r, r), c + Vector2(r, r), c]), colour)


# physics (↯ double-stroke arrow): a zigzag lightning bolt.
static func _draw_bolt(target: Object, c: Vector2, colour: Color, r: float) -> void:
	target.draw_colored_polygon(PackedVector2Array([
		c + Vector2(0.2, -1.0) * r, c + Vector2(-0.6, 0.1) * r, c + Vector2(0.0, 0.1) * r,
		c + Vector2(-0.2, 1.0) * r, c + Vector2(0.6, -0.1) * r, c + Vector2(0.0, -0.1) * r,
	]), colour)


# life (✦ four-pointed star): alternating outer/inner radius octagon.
static func _draw_star4(target: Object, c: Vector2, colour: Color, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var ang := TAU * i / 8.0
		var rad := r if i % 2 == 0 else r * 0.4
		pts.append(c + Vector2(cos(ang), sin(ang)) * rad)
	target.draw_colored_polygon(pts, colour)


# fate (⚄ die face 5): square frame + 4 corner pips + 1 centre pip.
static func _draw_die5(target: Object, c: Vector2, colour: Color, r: float) -> void:
	var half := r * 0.85
	target.draw_rect(Rect2(c - Vector2(half, half), Vector2(half, half) * 2.0), colour, false, 1.2)
	var dot_r := r * 0.16
	var offsets := [Vector2(-1, -1), Vector2(1, -1), Vector2(0, 0), Vector2(-1, 1), Vector2(1, 1)]
	for o in offsets:
		target.draw_circle(c + o * half * 0.6, dot_r, colour)


# emotion (❋ eight-spoked propeller asterisk): 4 lines through the centre.
static func _draw_asterisk8(target: Object, c: Vector2, colour: Color, r: float) -> void:
	for i in 4:
		var ang := PI / 4.0 * i
		var d := Vector2(cos(ang), sin(ang)) * r
		target.draw_line(c - d, c + d, colour, 1.4)
