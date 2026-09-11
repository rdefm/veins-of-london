extends "res://tests/test_base.gd"

# field-kit-chrome ticket 02 (docs/ui-vision.md §5): the shared dot-matrix
# board renderer behind top_bar.gd's status line and notification_toast.gd's
# rows. DotMatrixBoard.new()/set_lines() are safe to call without adding the
# node to a live scene tree -- _draw()/_process() are Godot callbacks the
# engine only invokes on a live tree, so nothing here needs that (same
# reasoning docs/adr's other headless-Control tests rely on); advance_scramble()
# is called directly rather than through _process() so the transition can be
# driven deterministically instead of waiting on real frames.


func run() -> void:
	run_case("line_builds_the_text_dot_size_dictionary_shape_set_lines_expects", func():
		assert_eq(DotMatrixBoard.line("Hello", 3.0), { "text": "Hello", "dot_size": 3.0 })
	)

	run_case("the_first_set_lines_call_lands_directly_on_the_given_text_with_nothing_to_scramble", func():
		var board := DotMatrixBoard.new()
		board.set_lines([DotMatrixBoard.line("Hello", 3.0)])

		assert_eq(board.target_text(), "HELLO", "text is upper-cased for the board -- real departure boards are caps-only")
		assert_eq(board.display_text(), "HELLO", "nothing to scramble from on the very first render")
		assert_true(not board._is_scrambling(), "no scramble is pending after the first call")

		board.free()
	)

	run_case("a_later_set_lines_call_scrambles_only_the_cells_that_actually_changed", func():
		var board := DotMatrixBoard.new()
		board.set_lines([{ "text": "AAAA", "dot_size": 3.0 }])
		board.set_lines([{ "text": "AABA", "dot_size": 3.0 }])

		assert_eq(board._scramble_seconds_left[0][0], 0.0, "unchanged leading A doesn't restart scrambling")
		assert_eq(board._scramble_seconds_left[0][1], 0.0, "unchanged second A doesn't restart scrambling")
		assert_true(board._scramble_seconds_left[0][2] > 0.0, "the character that actually changed (A -> B) is scrambling")
		assert_eq(board._scramble_seconds_left[0][3], 0.0, "unchanged trailing A doesn't restart scrambling")
		assert_eq(board.target_text(), "AABA", "the resolved target text is already the new value mid-scramble")

		board.free()
	)

	run_case("re_setting_the_exact_same_text_scrambles_nothing", func():
		var board := DotMatrixBoard.new()
		board.set_lines([{ "text": "Same", "dot_size": 3.0 }])
		board.set_lines([{ "text": "Same", "dot_size": 3.0 }])

		assert_true(not board._is_scrambling(), "no cell scrambles when the text hasn't changed")
		assert_eq(board.display_text(), "SAME")

		board.free()
	)

	run_case("advancing_scramble_past_its_full_duration_settles_every_cell_on_the_target_character", func():
		var board := DotMatrixBoard.new()
		board.set_lines([{ "text": "AAAA", "dot_size": 3.0 }])
		board.set_lines([{ "text": "ZZZZ", "dot_size": 3.0 }])
		assert_true(board._is_scrambling(), "sanity: the full-line change starts a scramble")

		board.advance_scramble(DotMatrixBoard.SCRAMBLE_DURATION + 1.0)

		assert_eq(board.display_text(), "ZZZZ", "every cell has settled on its target character")
		assert_true(not board._is_scrambling(), "the scramble is over")

		board.free()
	)

	run_case("required_size_grows_with_character_count_dot_size_and_line_count", func():
		var board := DotMatrixBoard.new()
		board.set_lines([])
		assert_eq(board.required_size(), Vector2.ZERO, "no lines means no footprint")

		var one_line := DotMatrixBoard.new()
		one_line.set_lines([{ "text": "AB", "dot_size": 2.0 }])
		var two_lines := DotMatrixBoard.new()
		two_lines.set_lines([{ "text": "AB", "dot_size": 2.0 }, { "text": "C", "dot_size": 1.0 }])

		assert_true(two_lines.required_size().y > one_line.required_size().y, "a second line adds to the board's total height")

		var bigger_dots := DotMatrixBoard.new()
		bigger_dots.set_lines([{ "text": "AB", "dot_size": 4.0 }])
		assert_true(bigger_dots.required_size().x > one_line.required_size().x, "a larger dot_size widens the same text")
		assert_true(bigger_dots.required_size().y > one_line.required_size().y, "a larger dot_size also grows the line's height")

		board.free()
		one_line.free()
		two_lines.free()
		bigger_dots.free()
	)

	run_case("render_draws_a_full_bleed_background_rect_plus_one_call_per_character_cell", func():
		var board := DotMatrixBoard.new()
		board.set_lines([{ "text": "AB", "dot_size": 3.0 }])
		board.size = board.required_size()

		var spy := DrawSpy.new()
		board.render(spy)

		var rects: Array = spy.calls_matching("draw_rect")
		var bg_calls: Array = rects.filter(func(c): return c["args"][0] == Rect2(Vector2.ZERO, board.size) and c["args"][1] == DotMatrixBoard.BG_COLOR)
		assert_eq(bg_calls.size(), 1, "exactly one full-bleed background rect is drawn")

		var dot_calls := rects.size() - 1
		assert_eq(dot_calls, 2 * DotMatrixFont.GLYPH_W * DotMatrixFont.GLYPH_H, "2 characters worth of dots are drawn")

		board.free()
	)
