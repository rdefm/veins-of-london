class_name DrawSpy
extends RefCounted

# Ticket 35: a recording double for the `target: Object` draw params ticket
# 34's spike found map_canvas.gd/icons.gd/ore_glyphs.gd need (shadowing a
# native CanvasItem method is a hard GDScript compile error — see ticket
# 34's `## Answer` and its repro at
# .scratch/0-bugfixes/issues/repro_canvasitem_shadow.gd). A plain
# RefCounted works fine at those params precisely because they're typed
# `Object` now, not `CanvasItem` — this never touches a Viewport/CanvasItem
# at all, so it's fully headless with no GPU dependency.
#
# Method signatures below mirror the real CanvasItem.draw_* engine
# signatures exactly (same idiom the ticket-34 repro used) so a call site
# written against the real API records correctly regardless of how many of
# a call's trailing default args it actually supplies.

var calls: Array = []


func draw_circle(position: Vector2, radius: float, color: Color, filled: bool = true, width: float = -1.0, antialiased: bool = false) -> void:
	calls.append({ "method": "draw_circle", "args": [position, radius, color, filled, width, antialiased] })


func draw_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, point_count: int, color: Color, width: float = -1.0, antialiased: bool = false) -> void:
	calls.append({ "method": "draw_arc", "args": [center, radius, start_angle, end_angle, point_count, color, width, antialiased] })


func draw_rect(rect: Rect2, color: Color, filled: bool = true, width: float = -1.0, antialiased: bool = false) -> void:
	calls.append({ "method": "draw_rect", "args": [rect, color, filled, width, antialiased] })


func draw_colored_polygon(points: PackedVector2Array, color: Color, uvs: PackedVector2Array = PackedVector2Array(), texture: Texture2D = null) -> void:
	calls.append({ "method": "draw_colored_polygon", "args": [points, color, uvs, texture] })


func draw_line(from: Vector2, to: Vector2, color: Color, width: float = -1.0, antialiased: bool = false) -> void:
	calls.append({ "method": "draw_line", "args": [from, to, color, width, antialiased] })


func draw_string(font: Font, pos: Vector2, text: String, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1, font_size: int = 16, modulate: Color = Color.WHITE, justification_flags: int = 3, direction: int = 0, orientation: int = 0) -> void:
	calls.append({ "method": "draw_string", "args": [font, pos, text, alignment, width, font_size, modulate, justification_flags, direction, orientation] })


func calls_matching(method: String) -> Array:
	return calls.filter(func(c): return c["method"] == method)
