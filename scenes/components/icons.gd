class_name Icons
extends RefCounted

# M1.5 N6 asset 2: the 8 icon glyphs (home/pin/padlock/market/phone/bag/
# legend/news). No icon pack or AI image generation is available in this
# environment, and N6 explicitly allows drawing them as `_draw()` polygons
# instead of bitmap art — every draw_* here is a small single-colour,
# tintable vector shape. KINDS was originally the exhaustive, spec-fixed
# set N6 defined ("no additional/commissioned art introduced beyond this
# list"). Bugfixes ticket 13 adds a 9th, `hamburger`: the Map tab's top-bar
# menu button used the "☰" text glyph, which — like every other non-ASCII
# glyph in this project (see the "✉" pin comment in map_canvas.gd and the
# old "⌂" home glyph this file already replaced) — renders as nothing on
# the exported build's font. That's a real on-device bug, not a redesign,
# so the ticket treats it as an approved, deliberate exception to "exactly
# 8, nothing added" rather than scope creep.
#
# Every draw_* takes the CanvasItem currently mid-_draw() (the same
# target-param idiom map_canvas.gd already used for its pin/padlock
# shapes, since draw_* calls always apply to whichever CanvasItem is
# presently drawing), a centre point, a colour, and a uniform scale.
# draw_pin returns the marker head's centre so callers can layer another
# glyph on top of it, same contract the original pin-marker code had.

const KINDS := ["home", "pin", "padlock", "market", "phone", "bag", "legend", "news", "hamburger"]


static func is_valid_kind(kind: String) -> bool:
	return KINDS.has(kind)


# Classic teardrop marker (circle "head" + triangular point down to `pos`)
# — the generic points-of-interest glyph every map pin (home/contact/
# market alike) sits on. Moved here from map_canvas.gd's original T13
# _draw_pin_marker_shape, unchanged.
static func draw_pin(target: Object, pos: Vector2, colour: Color, scale: float = 1.0) -> Vector2:
	var head_radius := 9.0 * scale
	var head := pos + Vector2(0, -head_radius * 1.6)
	target.draw_colored_polygon(PackedVector2Array([
		head + Vector2(-head_radius * 0.7, head_radius * 0.6),
		head + Vector2(head_radius * 0.7, head_radius * 0.6),
		pos,
	]), colour)
	target.draw_circle(head, head_radius, colour)
	return head


# Simple house silhouette (square body + triangular roof) — replaces the
# "⌂" text glyph the home pin used to draw. The bundled engine font has
# no glyph for U+2302 (confirmed headlessly: ThemeDB.fallback_font.
# has_char() is false for it, same gap OreGlyphs documents for the ore
# symbols), so the old text draw was silently rendering as a blank tofu
# box on every device, not just Android — this is a real fix, not just
# an asset swap.
static func draw_home(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 5.0 * scale
	target.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-s, s),
		center + Vector2(s, s),
		center + Vector2(s, -s * 0.1),
		center + Vector2(0, -s * 1.2),
		center + Vector2(-s, -s * 0.1),
	]), colour)


# Shared by the vein-stop security badge and the (locked) market pin.
# Moved here from map_canvas.gd's original _draw_padlock_shape, unchanged.
static func draw_padlock(target: Object, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var body := Rect2(center + Vector2(-3, -1) * scale, Vector2(6, 5) * scale)
	target.draw_rect(body, colour, true)
	target.draw_arc(center + Vector2(0, -1) * scale, 3.0 * scale, PI, TAU, 8, colour, 1.5 * scale, true)


# Little market-stall silhouette (triangular awning over a counter).
# Produced per N6's asset list but not yet wired onto the live Soho
# market pin: map_canvas.gd deliberately draws a padlock there instead
# while the market is locked (N2/N4 — "padlock glyph instead of a
# symbol"), so this glyph is ready for M4's unlock rather than used now.
static func draw_market(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 6.0 * scale
	target.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-s, -s * 0.2),
		center + Vector2(s, -s * 0.2),
		center + Vector2(0, -s * 1.1),
	]), colour)
	target.draw_rect(Rect2(center + Vector2(-s * 0.7, -s * 0.1), Vector2(s * 1.4, s * 0.9)), colour, true)


# Handset silhouette (rounded rect body + a small nub). Produced per N6
# but not wired into the Phone nav tab in this ticket — that tab lives in
# nav_bar.gd, an M1 screen this M1.5 ticket doesn't touch (ADR 0001: M1.5
# owns the Network Map renderer only).
static func draw_phone(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 5.0 * scale
	target.draw_rect(Rect2(center - Vector2(s * 0.55, s), Vector2(s * 1.1, s * 2.0)), colour, false, 1.5 * scale)
	target.draw_rect(Rect2(center + Vector2(-s * 0.2, s * 0.7), Vector2(s * 0.4, s * 0.15)), colour, true)


# Bag silhouette (rectangular body + arched handle). Produced per N6;
# wired into map.gd's top-bar bag button by bugfixes ticket 13 (its "🎒"
# text glyph rendered as nothing on-device). The global TopBar's own bag
# button (top_bar.gd) pairs "🎒" with a visible "Bag" label, so it's
# unaffected by that bug and left as-is.
static func draw_bag(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 5.0 * scale
	target.draw_rect(Rect2(center + Vector2(-s, -s * 0.4), Vector2(s * 2, s * 1.6)), colour, false, 1.5 * scale)
	target.draw_arc(center + Vector2(0, -s * 0.4), s * 0.6, PI, TAU, 8, colour, 1.5 * scale, true)


# Circled question mark — produced per N6 but not wired into
# map_controls.gd's "?" legend button in this pass: that button's plain
# "?" text already renders correctly (ASCII, unlike the ore/pin glyphs —
# checked the same way), so there's no rendering bug to fix there, and
# swapping a working Button.text for a Texture-backed icon is a separate
# piece of work this ticket doesn't need to do.
static func draw_legend(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var r := 7.0 * scale
	target.draw_arc(center, r, 0, TAU, 24, colour, 1.5 * scale, true)
	target.draw_arc(center + Vector2(0, -r * 0.15), r * 0.45, PI * 1.1, PI * 2.6, 8, colour, 1.5 * scale, true)
	target.draw_circle(center + Vector2(0, r * 0.55), r * 0.12, colour)


# Little newspaper silhouette (rect frame + headline bars). Produced per
# N6 but not wired into the Phone Ticker app tile in this ticket, same
# reason as draw_phone/draw_bag above.
static func draw_news(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 6.0 * scale
	target.draw_rect(Rect2(center - Vector2(s, s * 0.8), Vector2(s * 2, s * 1.6)), colour, false, 1.5 * scale)
	for i in 3:
		var y := -s * 0.4 + i * (s * 0.5)
		target.draw_line(center + Vector2(-s * 0.6, y), center + Vector2(s * 0.6, y), colour, 1.2 * scale)


# Three stacked horizontal bars — bugfixes ticket 13's 9th icon, replacing
# the map top bar's "☰" (U+2630) text glyph. Same visual language as
# draw_news' headline bars, just evenly spaced and full-width since this
# one has to read as a menu button on its own, not sit inside a frame.
static func draw_hamburger(target: CanvasItem, center: Vector2, colour: Color, scale: float = 1.0) -> void:
	var s := 6.0 * scale
	for i in 3:
		var y := -s * 0.7 + i * (s * 0.7)
		target.draw_line(center + Vector2(-s, y), center + Vector2(s, y), colour, 1.5 * scale)
