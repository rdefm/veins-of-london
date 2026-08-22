extends "res://tests/test_base.gd"

# TouchScrollContainer — bugfixes ticket 48 (fix erratic pinch-zoom). See the
# root-cause comment on _gui_input() in touch_scroll_container.gd itself for
# why a second finger landing has to end this container's own drag.
#
# These cases exercise _gui_input() directly (same style as
# tests/test_map_canvas.gd's touch cases) and assert on the internal drag-
# tracking state (_drag_index, _last_position, _touches) rather than actual
# scroll pixel values, since a real scrollable range needs a live, laid-out
# scene tree that these headless unit cases don't otherwise need.


func _touch(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event


func _drag(index: int, position: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	return event


func run() -> void:
	run_case("a_single_finger_touch_down_starts_a_drag", func():
		var c := TouchScrollContainer.new()
		c._gui_input(_touch(0, Vector2(10, 10), true))
		assert_eq(c._drag_index, 0)
		c.free()
	)

	run_case("a_second_finger_landing_ends_the_drag_so_the_pinch_is_left_to_mapcanvas", func():
		var c := TouchScrollContainer.new()
		c._gui_input(_touch(0, Vector2(10, 10), true))
		c._gui_input(_touch(1, Vector2(50, 50), true))
		assert_eq(c._drag_index, -100, "a second finger joining must hand the gesture over to MapCanvas's own pinch handling")
		c.free()
	)

	run_case("drag_events_during_a_two_finger_touch_cannot_move_the_drag_index_finger", func():
		var c := TouchScrollContainer.new()
		c._gui_input(_touch(0, Vector2(10, 10), true))
		c._gui_input(_touch(1, Vector2(50, 50), true))
		c._gui_input(_drag(0, Vector2(200, 200)))
		c._gui_input(_drag(1, Vector2(300, 300)))
		assert_eq(c._drag_index, -100, "drag events for either pinch finger must not resume this container's own single-finger scroll mid-pinch")
		c.free()
	)

	run_case("lifting_the_second_finger_of_a_pinch_resumes_drag_from_the_remaining_finger", func():
		var c := TouchScrollContainer.new()
		c._gui_input(_touch(0, Vector2(0, 0), true))
		c._gui_input(_touch(1, Vector2(50, 50), true))
		c._gui_input(_drag(0, Vector2(10, 10)))
		c._gui_input(_drag(1, Vector2(110, 110)))
		c._gui_input(_touch(1, Vector2(110, 110), false))
		assert_eq(c._drag_index, 0, "the surviving finger (index 0) should resume driving the drag")
		assert_eq(c._last_position, Vector2(10, 10), "resume must start from the surviving finger's current position, not a stale one, or the next drag event would jump")
		c.free()
	)

	run_case("lifting_the_original_drag_finger_of_a_pinch_still_resumes_with_the_other_finger", func():
		var c := TouchScrollContainer.new()
		c._gui_input(_touch(0, Vector2(0, 0), true))
		c._gui_input(_touch(1, Vector2(50, 50), true))
		c._gui_input(_drag(0, Vector2(10, 10)))
		c._gui_input(_drag(1, Vector2(110, 110)))
		c._gui_input(_touch(0, Vector2(10, 10), false))
		assert_eq(c._drag_index, 1, "the surviving finger (index 1, not the one that originally started the drag) should resume driving the drag")
		assert_eq(c._last_position, Vector2(110, 110))
		c.free()
	)

	run_case("lifting_the_only_finger_of_a_plain_single_finger_drag_just_ends_it", func():
		var c := TouchScrollContainer.new()
		c._gui_input(_touch(0, Vector2(0, 0), true))
		c._gui_input(_touch(0, Vector2(0, 0), false))
		assert_eq(c._drag_index, -100)
		c.free()
	)

	run_case("mouse_drag_is_unaffected_by_touch_tracking", func():
		var c := TouchScrollContainer.new()
		var mouse_down := InputEventMouseButton.new()
		mouse_down.button_index = MOUSE_BUTTON_LEFT
		mouse_down.pressed = true
		mouse_down.position = Vector2(5, 5)
		c._gui_input(mouse_down)
		assert_eq(c._drag_index, -1)

		var mouse_up := InputEventMouseButton.new()
		mouse_up.button_index = MOUSE_BUTTON_LEFT
		mouse_up.pressed = false
		mouse_up.position = Vector2(5, 5)
		c._gui_input(mouse_up)
		assert_eq(c._drag_index, -100)
		c.free()
	)
