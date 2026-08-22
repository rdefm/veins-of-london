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
var _touches: Dictionary[int, Vector2] = {}  # touch index -> current position, every active touch

# Bugfixes ticket 48: MapCanvas.mouse_filter is PASS (see its own _ready()
# comment), which bubbles every touch event up here regardless of whether
# MapCanvas called accept_event() during its own two-finger pinch handling —
# that accept_event() call was found to be inert. Without this, a pinch's
# first-landed finger (already tracked as a single-finger drag from before
# the second finger joined) kept driving _apply_drag() on every frame
# throughout the whole pinch, fighting MapCanvas's own anchor-preserving
# pinch scroll for the same scroll_horizontal/scroll_vertical and producing
# exactly the "jumps around all over the map" pinch-zoom jitter that ticket
# reported (worse at speed: bigger per-event deltas from this stray
# incremental scroll). Fix: track every active touch here too, and end this
# container's own drag the moment a second finger joins, so a pinch is left
# entirely to MapCanvas until back down to one finger.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() >= 2:
				_end_drag()
			elif _drag_index == -100:
				_start_drag(event.index, event.position)
		else:
			_touches.erase(event.index)
			if event.index == _drag_index:
				_end_drag()
			elif _touches.size() == 1 and _drag_index == -100:
				# A pinch just ended with one finger still down and moving --
				# resume single-finger drag-to-scroll from its current
				# position instead of stranding panning until the next fresh
				# touch-down.
				var remaining_index: int = _touches.keys()[0]
				_start_drag(remaining_index, _touches[remaining_index])
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
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
