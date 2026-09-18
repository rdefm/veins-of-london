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
	var rect: Rect2 = screen._diorama.region_rects()[zone_id]
	screen._on_diorama_gui_input(tap_at(rect.get_center()))


static func advance(node: Node, seconds: float) -> void:
	for i in range(int(ceil(seconds / 0.05))):
		node._process(0.05)
