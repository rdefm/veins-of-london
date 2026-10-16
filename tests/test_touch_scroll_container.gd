extends "res://tests/test_base.gd"

const UiSim := preload("res://tests/support/ui_sim.gd")

# TouchScrollContainer — bugfixes ticket 48 (fix erratic pinch-zoom). See the
# root-cause comment on _gui_input() in touch_scroll_container.gd itself for
# why a second finger landing has to end this container's own drag.
#
# These cases exercise _gui_input() directly (same style as
# tests/test_map_canvas.gd's touch cases) and assert on the internal drag-
# tracking state (_drag_index, _last_position, _touches) rather than actual
# scroll pixel values, since a real scrollable range needs a live, laid-out
# scene tree that these headless unit cases don't otherwise need.


func run() -> void:
	run_case("scroll_bars_are_not_grabbable", func():
		var c := TouchScrollContainer.new()
		assert_eq(c.get_v_scroll_bar().mouse_filter, Control.MOUSE_FILTER_IGNORE)
		assert_eq(c.get_h_scroll_bar().mouse_filter, Control.MOUSE_FILTER_IGNORE)
		c.free()
	)

	run_case("a_single_finger_touch_down_starts_a_drag", func():
		var c := TouchScrollContainer.new()
		c._gui_input(UiSim.touch(0, true, Vector2(10, 10)))
		assert_eq(c._drag_index, 0)
		c.free()
	)

	run_case("a_second_finger_landing_ends_the_drag_so_the_pinch_is_left_to_mapcanvas", func():
		var c := TouchScrollContainer.new()
		c._gui_input(UiSim.touch(0, true, Vector2(10, 10)))
		c._gui_input(UiSim.touch(1, true, Vector2(50, 50)))
		assert_eq(c._drag_index, -100, "a second finger joining must hand the gesture over to MapCanvas's own pinch handling")
		c.free()
	)

	run_case("drag_events_during_a_two_finger_touch_cannot_move_the_drag_index_finger", func():
		var c := TouchScrollContainer.new()
		c._gui_input(UiSim.touch(0, true, Vector2(10, 10)))
		c._gui_input(UiSim.touch(1, true, Vector2(50, 50)))
		c._gui_input(UiSim.drag(0, Vector2(200, 200)))
		c._gui_input(UiSim.drag(1, Vector2(300, 300)))
		assert_eq(c._drag_index, -100, "drag events for either pinch finger must not resume this container's own single-finger scroll mid-pinch")
		c.free()
	)

	run_case("lifting_the_second_finger_of_a_pinch_resumes_drag_from_the_remaining_finger", func():
		var c := TouchScrollContainer.new()
		c._gui_input(UiSim.touch(0, true, Vector2(0, 0)))
		c._gui_input(UiSim.touch(1, true, Vector2(50, 50)))
		c._gui_input(UiSim.drag(0, Vector2(10, 10)))
		c._gui_input(UiSim.drag(1, Vector2(110, 110)))
		c._gui_input(UiSim.touch(1, false, Vector2(110, 110)))
		assert_eq(c._drag_index, 0, "the surviving finger (index 0) should resume driving the drag")
		assert_eq(c._last_position, Vector2(10, 10), "resume must start from the surviving finger's current position, not a stale one, or the next drag event would jump")
		c.free()
	)

	run_case("lifting_the_original_drag_finger_of_a_pinch_still_resumes_with_the_other_finger", func():
		var c := TouchScrollContainer.new()
		c._gui_input(UiSim.touch(0, true, Vector2(0, 0)))
		c._gui_input(UiSim.touch(1, true, Vector2(50, 50)))
		c._gui_input(UiSim.drag(0, Vector2(10, 10)))
		c._gui_input(UiSim.drag(1, Vector2(110, 110)))
		c._gui_input(UiSim.touch(0, false, Vector2(10, 10)))
		assert_eq(c._drag_index, 1, "the surviving finger (index 1, not the one that originally started the drag) should resume driving the drag")
		assert_eq(c._last_position, Vector2(110, 110))
		c.free()
	)

	run_case("lifting_the_only_finger_of_a_plain_single_finger_drag_just_ends_it", func():
		var c := TouchScrollContainer.new()
		c._gui_input(UiSim.touch(0, true, Vector2(0, 0)))
		c._gui_input(UiSim.touch(0, false, Vector2(0, 0)))
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

	# ── fling momentum (opt-in) ──────────────────────────────────────────────

	run_case("a_quick_release_flings_when_momentum_is_on", func():
		var c := _fling_container(true)
		_swipe(c, 0)
		assert_true(c.is_processing(), "a fast swipe keeps scrolling after the finger lifts")
		assert_true(c._velocity.y < -FLING_TEST_MIN, "fling continues in the finger's direction (upward swipe)")
		assert_eq(c._velocity.x, 0.0, "the disabled horizontal axis carries no fling")
		c.free()
	)

	run_case("no_fling_when_momentum_is_off", func():
		var c := _fling_container(false)
		_swipe(c, 0)
		assert_true(not c.is_processing(), "default containers stop dead on release")
		c.free()
	)

	run_case("no_fling_when_the_finger_rested_before_lifting", func():
		var c := _fling_container(true)
		_swipe(c, 500000)
		assert_true(not c.is_processing(), "a held-then-lifted finger is a placement, not a flick")
		c.free()
	)

	run_case("a_new_touch_stops_the_fling", func():
		var c := _fling_container(true)
		_swipe(c, 0)
		c._gui_input(UiSim.touch(0, true, Vector2(50, 50)))
		assert_true(not c.is_processing(), "touching a flinging list catches it")
		c.free()
	)

	run_case("the_fling_comes_to_rest", func():
		var c := _fling_container(true)
		_swipe(c, 0)
		for i in 300:
			if not c.is_processing():
				break
			c._process(1.0 / 60.0)
		assert_true(not c.is_processing(), "friction brings the fling to rest")
		c.free()
	)

	run_case("a_pinch_hand_over_never_flings", func():
		var c := _fling_container(true)
		c._gui_input(UiSim.touch(0, true, Vector2(50, 400)))
		c.clock = func(): return 16000
		c._gui_input(UiSim.drag(0, Vector2(50, 300)))
		c._gui_input(UiSim.touch(1, true, Vector2(100, 100)))
		assert_true(not c.is_processing(), "a second finger ends the drag without a fling")
		c.free()
	)


const FLING_TEST_MIN := 60.0


func _fling_container(momentum: bool) -> TouchScrollContainer:
	var c := TouchScrollContainer.new()
	c.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	c.momentum = momentum
	c.clock = func(): return 0
	return c


# Upward swipe, 100px per 16ms frame, lifting `rest_usec` after the last move.
func _swipe(c: TouchScrollContainer, rest_usec: int) -> void:
	c._gui_input(UiSim.touch(0, true, Vector2(50, 400)))
	var t := 0
	for y in [300, 200, 100]:
		t += 16000
		c.clock = func(): return t
		c._gui_input(UiSim.drag(0, Vector2(55, y)))
	c.clock = func(): return t + rest_usec
	c._gui_input(UiSim.touch(0, false, Vector2(55, 100)))
