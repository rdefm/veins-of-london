extends "res://tests/test_base.gd"

# DepartureBoardCasing (ui-vision.md §5): the top board's code-drawn housing
# and its optional frame-bitmap slot.


func run() -> void:
	run_case("with_no_frame_bitmap_shipped_the_slot_falls_back_to_code", func():
		if ResourceLoader.exists(DepartureBoardCasing.FRAME_IMAGE_PATH):
			assert_true(DepartureBoardCasing.load_frame_style() != null, "a shipped bitmap loads as a nine-patch")
		else:
			assert_eq(DepartureBoardCasing.load_frame_style(), null)
	)

	run_case("fallback_draws_the_casing_fill_and_four_corner_bolts", func():
		var casing := DepartureBoardCasing.new()
		casing.size = Vector2(390, 80)

		var spy := DrawSpy.new()
		casing.render_fallback(spy)

		var fills: Array = spy.calls_matching("draw_rect").filter(func(c): return c["args"][0] == Rect2(Vector2.ZERO, casing.size))
		assert_eq(fills.size(), 1, "one full-bleed casing fill")
		var bolts: Array = spy.calls_matching("draw_circle").filter(func(c): return c["args"][2] == DepartureBoardCasing.BOLT_COLOR)
		assert_eq(bolts.size(), 4, "a bolt in each corner")

		casing.free()
	)

	run_case("the_face_sits_inside_the_frame_thickness", func():
		var face := DepartureBoardCasing.face_rect(Vector2(390, 80))
		var t := DepartureBoardCasing.FRAME_THICKNESS
		assert_eq(face, Rect2(Vector2(t, t), Vector2(390 - 2 * t, 80 - 2 * t)))
	)

	run_case("the_bezel_draws_a_rim_and_an_inner_shadow_on_the_face", func():
		var spy := DrawSpy.new()
		DepartureBoardCasing.render_bezel(spy, Rect2(5, 5, 380, 70))

		assert_eq(spy.calls_matching("draw_rect").size(), 1, "the rim")
		assert_eq(spy.calls_matching("draw_line").size(), DepartureBoardCasing.INNER_SHADOW_DEPTH * 2, "top and left shadow bands")
	)
