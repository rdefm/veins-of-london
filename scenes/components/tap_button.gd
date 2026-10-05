class_name TapButton
extends Button

# Tappable card inside a scroll surface. Presses are never accepted, so they
# bubble to the TouchScrollContainer; `pressed` fires only on a release that
# stayed within TAP_SLOP of the press.

const TAP_SLOP := 12.0

var _press_position: Vector2
var _pressing := false
var _dragged := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return
	var position := Vector2.ZERO
	var pressed_now := false
	var is_press_event := false
	var is_motion := false
	if event is InputEventScreenTouch:
		position = event.position
		pressed_now = event.pressed
		is_press_event = true
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		position = event.position
		pressed_now = event.pressed
		is_press_event = true
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		position = event.position
		is_motion = true
	if is_press_event:
		if pressed_now:
			_pressing = true
			_dragged = false
			_press_position = position
		elif _pressing:
			_pressing = false
			if not _dragged and _press_position.distance_to(position) < TAP_SLOP:
				pressed.emit()
	elif is_motion and _pressing and _press_position.distance_to(position) >= TAP_SLOP:
		_dragged = true
