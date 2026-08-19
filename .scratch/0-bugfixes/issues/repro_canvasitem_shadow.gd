extends SceneTree
# Repro for ticket 34: can a CanvasItem/Node2D subclass shadow the specific
# draw methods map_canvas.gd calls, so a caller holding a `target: CanvasItem`
# typed reference dispatches to the shadowed (recording) methods instead of
# the engine's real ones?
#
# Run: godot --headless -s .scratch/0-bugfixes/issues/repro_canvasitem_shadow.gd

class RecordingFake extends Node2D:
	var calls: Array[String] = []

	func draw_circle(position: Vector2, radius: float, color: Color, filled: bool = true, width: float = -1.0, antialiased: bool = false) -> void:
		calls.append("draw_circle")

	func draw_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, point_count: int, color: Color, width: float = -1.0, antialiased: bool = false) -> void:
		calls.append("draw_arc")

	func draw_rect(rect: Rect2, color: Color, filled: bool = true, width: float = -1.0, antialiased: bool = false) -> void:
		calls.append("draw_rect")

	func draw_colored_polygon(points: PackedVector2Array, color: Color, uvs: PackedVector2Array = PackedVector2Array(), texture: Texture2D = null) -> void:
		calls.append("draw_colored_polygon")

	func draw_line(from: Vector2, to: Vector2, color: Color, width: float = -1.0, antialiased: bool = false) -> void:
		calls.append("draw_line")

	func draw_string(font: Font, pos: Vector2, text: String, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1, font_size: int = 16, modulate: Color = Color.WHITE, justification_flags: int = 3, direction: int = 0, orientation: int = 0) -> void:
		calls.append("draw_string")


# Mirrors the shape of map_canvas.gd's `target: CanvasItem` params.
func _call_via_typed_param(target: CanvasItem) -> void:
	target.draw_circle(Vector2.ZERO, 5.0, Color.WHITE)
	target.draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 8, Color.WHITE)
	target.draw_rect(Rect2(Vector2.ZERO, Vector2(1, 1)), Color.WHITE)
	target.draw_colored_polygon(PackedVector2Array([Vector2.ZERO]), Color.WHITE)
	target.draw_line(Vector2.ZERO, Vector2.ONE, Color.WHITE)
	target.draw_string(ThemeDB.fallback_font, Vector2.ZERO, "x")


func _initialize() -> void:
	var fake := RecordingFake.new()
	_call_via_typed_param(fake)

	var expected: Array[String] = [
		"draw_circle", "draw_arc", "draw_rect",
		"draw_colored_polygon", "draw_line", "draw_string",
	]

	print("Recorded calls: %s" % [fake.calls])

	if fake.calls == expected:
		print("RESULT: SHADOWING WORKS")
	else:
		print("RESULT: SHADOWING FAILS")
		print("Expected: %s" % [expected])
		print("Got:      %s" % [fake.calls])

	fake.queue_free()
	quit(0)
