extends RefCounted

# Shared headless UI-input/time helpers for tests. Static; use via
# `const UiSim := preload("res://tests/support/ui_sim.gd")`.
#   synthetic_tap() -> InputEventScreenTouch   a pressed touch event with no position
#   tap_at(pos)                                a pressed touch event at pos
#   touch(index, pressed, pos)                 a touch event for finger index
#   drag(index, pos)                           a drag event for finger index
#   tap_zone(screen, zone_id)                  tap the centre of a diorama screen's region rect
#   advance(node, seconds)                     call node._process(0.05) enough times to cover seconds


static func synthetic_tap() -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	return event


static func tap_at(pos: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	event.position = pos
	return event


static func touch(index: int, pressed: bool, pos: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = pos
	return event


static func drag(index: int, pos: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = pos
	return event


static func tap_zone(screen, zone_id: String) -> void:
	screen._on_diorama_gui_input(tap_at(zone_point(screen._diorama, zone_id)))


# A point inside the zone's hit shape: its rect's centre, or for a traced
# polygon the centroid of its first triangle (inside even when concave).
static func zone_point(diorama: HqDiorama, zone_id: String) -> Vector2:
	var region: Dictionary = diorama._plate["regions"][zone_id]
	if not region.has("polygon"):
		return HqDiorama.region_rect(region).get_center()
	var points := HqDiorama.polygon_points(region["polygon"])
	var tri := Geometry2D.triangulate_polygon(points)
	return (points[tri[0]] + points[tri[1]] + points[tri[2]]) / 3.0


static func advance(node: Node, seconds: float) -> void:
	for i in range(int(ceil(seconds / 0.05))):
		node._process(0.05)
