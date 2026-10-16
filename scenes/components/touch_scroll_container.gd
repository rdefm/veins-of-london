class_name TouchScrollContainer
extends ScrollContainer


var _drag_index := -100  # touch index, or -1 for the mouse; -100 = no active drag
var _last_position: Vector2
var _touches: Dictionary[int, Vector2] = {}  # touch index -> current position, every active touch

# Fling: a single-finger release keeps scrolling at the finger's last velocity,
# decaying with FLING_FRICTION, like a native phone list. Opt-in per container.
const FLING_FRICTION := 4.0  # velocity *= exp(-FLING_FRICTION * seconds)
const FLING_MIN_SPEED := 60.0  # px/s: slower releases (and the fling's tail) just stop
const FLING_MAX_SPEED := 4000.0
const FLING_STALE_USEC := 100000  # finger held still this long before lifting: no fling
var momentum := false
var clock: Callable = Time.get_ticks_usec  # injectable for tests
var _velocity := Vector2.ZERO  # px/s, smoothed while dragging, then the fling's speed
var _last_sample_usec := 0
var _fling_remainder := Vector2.ZERO  # sub-pixel scroll carried between frames

func _init() -> void:
	# Bars are display-only: a finger landing on one would drag the bar (content
	# moves opposite the finger) instead of the content.
	get_v_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_h_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_stop_fling()
			_touches[event.index] = event.position
			if _touches.size() >= 2:
				_end_drag()
			elif _drag_index == -100:
				_start_drag(event.index, event.position)
		else:
			_touches.erase(event.index)
			if event.index == _drag_index:
				_release_drag()
			elif _touches.size() == 1 and _drag_index == -100:
				var remaining_index: int = _touches.keys()[0]
				_start_drag(remaining_index, _touches[remaining_index])
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if event.index == _drag_index:
			_apply_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _drag_index == -100:
				_stop_fling()
				_start_drag(-1, event.position)
		elif _drag_index == -1:
			_release_drag()
	elif event is InputEventMouseMotion and _drag_index == -1:
		_apply_drag(event.position)


func _start_drag(index: int, position: Vector2) -> void:
	_drag_index = index
	_last_position = position
	_velocity = Vector2.ZERO
	_last_sample_usec = clock.call()


func _apply_drag(position: Vector2) -> void:
	var delta := position - _last_position
	_last_position = position
	var now: int = clock.call()
	var dt := float(now - _last_sample_usec) / 1000000.0
	_last_sample_usec = now
	if dt > 0.0:
		_velocity = _velocity.lerp(delta / dt, 0.6)
	_scroll_by(delta)


func _scroll_by(delta: Vector2) -> void:
	if horizontal_scroll_mode != SCROLL_MODE_DISABLED:
		scroll_horizontal -= int(delta.x)
	if vertical_scroll_mode != SCROLL_MODE_DISABLED:
		scroll_vertical -= int(delta.y)


func _end_drag() -> void:
	_drag_index = -100


# The drag finger lifted with no other finger down (not a pinch hand-over).
func _release_drag() -> void:
	_end_drag()
	if horizontal_scroll_mode == SCROLL_MODE_DISABLED:
		_velocity.x = 0.0
	if vertical_scroll_mode == SCROLL_MODE_DISABLED:
		_velocity.y = 0.0
	if not momentum or int(clock.call()) - _last_sample_usec > FLING_STALE_USEC:
		return
	_velocity = _velocity.limit_length(FLING_MAX_SPEED)
	if _velocity.length() >= FLING_MIN_SPEED:
		_fling_remainder = Vector2.ZERO
		set_process(true)


func _process(delta: float) -> void:
	var before := Vector2(scroll_horizontal, scroll_vertical)
	var step := _velocity * delta + _fling_remainder
	var whole := Vector2(int(step.x), int(step.y))
	_fling_remainder = step - whole
	_scroll_by(whole)
	_velocity *= exp(-FLING_FRICTION * delta)
	var hit_edge := whole != Vector2.ZERO and Vector2(scroll_horizontal, scroll_vertical) == before
	if hit_edge or _velocity.length() < FLING_MIN_SPEED:
		_stop_fling()


func _stop_fling() -> void:
	_velocity = Vector2.ZERO
	set_process(false)
