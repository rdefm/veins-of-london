class_name TapButton
extends Button

# Tappable card inside a scroll surface. Presses are never accepted, so they
# bubble to the TouchScrollContainer; `pressed` fires only on a release that
# stayed within TAP_SLOP of the press.

const TAP_SLOP := 12.0

var _press_position: Vector2
var _pressing := false
var _dragged := false
var _native_guard := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	focus_mode = Control.FOCUS_NONE
	# Button's native handler ignores drags and double-emits `pressed`; the tap logic below
	# is the only emitter (see _native_guard).
	button_mask = 0
	# toggle_mode only so set_pressed_no_signal() shows the pressed style while held.
	toggle_mode = true


func _gui_input(event: InputEvent) -> void:
	if disabled and not _native_guard:
		return
	# The emulated twin never presses or releases (the real touch does), but its
	# motion is the only drag signal that reaches a button inside a scroller.
	if TouchInput.is_emulated_mouse(event) and not event is InputEventMouseMotion:
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
			set_pressed_no_signal(true)
		elif _pressing:
			_pressing = false
			set_pressed_no_signal(false)
			# Button's own handler runs right after this one on the same touch release
			# and would emit a second `pressed` (drag or not); disabled makes it bail.
			_native_guard = true
			disabled = true
			_release_native_guard.call_deferred()
			if not _dragged and _press_position.distance_to(position) < TAP_SLOP:
				pressed.emit()
	elif is_motion and _pressing and _press_position.distance_to(position) >= TAP_SLOP:
		_dragged = true
		set_pressed_no_signal(false)


func _release_native_guard() -> void:
	if _native_guard:
		_native_guard = false
		disabled = false

