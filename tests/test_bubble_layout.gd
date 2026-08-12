extends "res://tests/test_base.gd"

# Pure clamping math for MapBubble's positioning (systems/bubble_layout.gd).


func run() -> void:
	run_case("anchor_well_inside_bounds_uses_the_default_offset_untouched", func():
		var pos := BubbleLayout.popup_position(Vector2(100, 100), Vector2(80, 60), Vector2(390, 844))
		assert_eq(pos, Vector2(100, 100) + BubbleLayout.DEFAULT_OFFSET, "nothing to clamp against, so the raw anchor+offset wins")
	)

	run_case("anchor_near_the_right_edge_clamps_the_popups_right_side_inside_bounds_with_margin", func():
		var bounds := Vector2(390, 844)
		var popup_size := Vector2(200, 60)
		var pos := BubbleLayout.popup_position(Vector2(380, 100), popup_size, bounds)
		assert_almost_eq(pos.x, bounds.x - popup_size.x - BubbleLayout.EDGE_MARGIN, 0.01, "popup's right edge stays EDGE_MARGIN inside the right bound")
		assert_true(pos.x + popup_size.x <= bounds.x, "never renders partially off the right edge")
	)

	run_case("anchor_near_the_bottom_edge_clamps_the_popups_bottom_side_inside_bounds_with_margin", func():
		var bounds := Vector2(390, 844)
		var popup_size := Vector2(120, 300)
		var pos := BubbleLayout.popup_position(Vector2(100, 820), popup_size, bounds)
		assert_almost_eq(pos.y, bounds.y - popup_size.y - BubbleLayout.EDGE_MARGIN, 0.01, "popup's bottom edge stays EDGE_MARGIN inside the bottom bound")
		assert_true(pos.y + popup_size.y <= bounds.y, "never renders partially off the bottom edge")
	)

	run_case("anchor_at_the_top_left_corner_still_respects_the_edge_margin_as_a_floor", func():
		var pos := BubbleLayout.popup_position(Vector2(-50, -50), Vector2(80, 60), Vector2(390, 844))
		assert_eq(pos, Vector2(BubbleLayout.EDGE_MARGIN, BubbleLayout.EDGE_MARGIN), "a negative/off-screen anchor clamps up to the margin floor, not further off-screen")
	)

	run_case("anchor_at_the_bottom_right_corner_clamps_both_axes_at_once", func():
		var bounds := Vector2(390, 844)
		var popup_size := Vector2(150, 100)
		var pos := BubbleLayout.popup_position(Vector2(500, 900), popup_size, bounds)
		assert_true(pos.x + popup_size.x <= bounds.x, "clamped on x")
		assert_true(pos.y + popup_size.y <= bounds.y, "clamped on y")
		assert_true(pos.x >= BubbleLayout.EDGE_MARGIN and pos.y >= BubbleLayout.EDGE_MARGIN, "never pushed past the margin floor either")
	)

	run_case("a_popup_bigger_than_the_bounds_pins_to_the_margin_instead_of_inverting", func():
		var bounds := Vector2(390, 844)
		var popup_size := Vector2(500, 900)  # degenerate: bigger than the whole screen
		var pos := BubbleLayout.popup_position(Vector2(100, 100), popup_size, bounds)
		assert_eq(pos, Vector2(BubbleLayout.EDGE_MARGIN, BubbleLayout.EDGE_MARGIN), "max clamp bound can't fall below the margin floor, so this pins there rather than the clamp range inverting")
	)

	run_case("a_custom_offset_is_honoured_when_there_is_nothing_to_clamp_against", func():
		var pos := BubbleLayout.popup_position(Vector2(100, 100), Vector2(40, 40), Vector2(390, 844), Vector2(-20, 5))
		assert_eq(pos, Vector2(80, 105), "callers can override the default down-right offset")
	)
