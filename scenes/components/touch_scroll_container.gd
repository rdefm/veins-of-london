class_name TouchScrollContainer
extends ScrollContainer

# Godot's ScrollContainer has no built-in touch/finger drag-to-scroll — only
# mouse wheel, a trackpad pan gesture, and dragging the rendered scrollbar
# thumb work out of the box. Found via on-device playtest: swiping anywhere
# over a screen's content did nothing, only dragging the scrollbar thumb
# itself worked. This subclass adds manual single-finger (or left-mouse-
# button, for desktop testing) drag-to-scroll on top of everything
# ScrollContainer already does natively: GDScript's _gui_input() is a
# notification layered on top of the engine's own internal input handling,
# not a replacement of it (confirmed the hard way — `super._gui_input()` is
# a parse error here: "hasn't been defined", since the built-in behaviour
# isn't implemented as a GDScript-callable virtual at all), so wheel/pan-
# gesture/scrollbar-thumb scrolling all keep working unmodified alongside
# this.
#
# UI.scroll_container() builds this instead of a bare ScrollContainer, so
# every screen built through UI.screen_body() (nearly all of them) picks
# this up automatically. The Network diagram's own pan/zoom ScrollContainer
# (scenes/screens/map.gd's _build_diagram_layer) uses it directly for the
# same reason — MapCanvas inside it only ever consumes an event itself
# (accept_event()) during an active two-finger pinch, so a single finger's
# drag still bubbles up here and pans normally.

var _drag_index := -100  # touch index, or -1 for the mouse; -100 = no active drag
var _last_position: Vector2


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _drag_index == -100:
				_start_drag(event.index, event.position)
		elif event.index == _drag_index:
			_end_drag()
	elif event is InputEventScreenDrag:
		if event.index == _drag_index:
			_apply_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _drag_index == -100:
				_start_drag(-1, event.position)
		elif _drag_index == -1:
			_end_drag()
	elif event is InputEventMouseMotion and _drag_index == -1:
		_apply_drag(event.position)


func _start_drag(index: int, position: Vector2) -> void:
	_drag_index = index
	_last_position = position


# Moves by the incremental delta since the last event, not a fixed jump —
# this is also what makes a near-motionless tap-through (e.g. pressing a
# button inside the scroll area) a no-op here rather than needing its own
# movement-tolerance check.
func _apply_drag(position: Vector2) -> void:
	var delta := position - _last_position
	_last_position = position
	if horizontal_scroll_mode != SCROLL_MODE_DISABLED:
		scroll_horizontal -= int(delta.x)
	if vertical_scroll_mode != SCROLL_MODE_DISABLED:
		scroll_vertical -= int(delta.y)


func _end_drag() -> void:
	_drag_index = -100
