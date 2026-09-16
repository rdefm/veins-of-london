class_name TouchScrollContainer
extends ScrollContainer


var _drag_index := -100  # touch index, or -1 for the mouse; -100 = no active drag
var _last_position: Vector2
var _touches: Dictionary[int, Vector2] = {}  # touch index -> current position, every active touch

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


func _apply_drag(position: Vector2) -> void:
	var delta := position - _last_position
	_last_position = position
	if horizontal_scroll_mode != SCROLL_MODE_DISABLED:
		scroll_horizontal -= int(delta.x)
	if vertical_scroll_mode != SCROLL_MODE_DISABLED:
		scroll_vertical -= int(delta.y)


func _end_drag() -> void:
	_drag_index = -100
