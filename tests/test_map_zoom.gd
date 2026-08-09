extends "res://tests/test_base.gd"

# MapZoom — pure zoom-level clamping and screen->logical conversion backing
# the Network diagram's pinch-to-zoom (see MapCanvas._update_pinch).


func run() -> void:
	run_case("clamp_zoom_leaves_an_in_range_value_untouched", func():
		assert_almost_eq(MapZoom.clamp_zoom(0.7), 0.7, 0.0001)
	)

	run_case("clamp_zoom_floors_at_min", func():
		assert_almost_eq(MapZoom.clamp_zoom(0.1), MapZoom.MIN, 0.0001)
	)

	run_case("clamp_zoom_ceils_at_max", func():
		assert_almost_eq(MapZoom.clamp_zoom(5.0), MapZoom.MAX, 0.0001)
	)

	run_case("to_logical_divides_by_zoom", func():
		var logical := MapZoom.to_logical(Vector2(100, 200), 0.5)
		assert_almost_eq(logical.x, 200.0, 0.0001)
		assert_almost_eq(logical.y, 400.0, 0.0001)
	)

	run_case("to_logical_is_identity_at_zoom_1", func():
		var logical := MapZoom.to_logical(Vector2(42, 84), 1.0)
		assert_almost_eq(logical.x, 42.0, 0.0001)
		assert_almost_eq(logical.y, 84.0, 0.0001)
	)

	run_case("default_zoom_is_within_min_and_max", func():
		assert_true(MapZoom.DEFAULT >= MapZoom.MIN and MapZoom.DEFAULT <= MapZoom.MAX)
	)

	# Map-filters ticket 02: DEFAULT moved from the old zoomed-to-fit 0.5,
	# past EVENT_ZOOM (0.8), so the map opens well zoomed in rather than
	# showing the whole Network at once.
	run_case("default_zoom_moved_well_past_the_old_zoomed_to_fit_value", func():
		assert_true(MapZoom.DEFAULT > 0.5 and MapZoom.DEFAULT >= MapZoom.EVENT_ZOOM)
	)

	run_case("event_zoom_is_within_min_and_max", func():
		assert_true(MapZoom.EVENT_ZOOM >= MapZoom.MIN and MapZoom.EVENT_ZOOM <= MapZoom.MAX)
	)

	# ── scroll_target (pan-to-point, map-animations ticket 01) ────────────

	run_case("scroll_target_centres_the_point_when_there_is_room_to_spare", func():
		var target := MapZoom.scroll_target(Vector2(500, 500), 1.0, Vector2(200, 200), Vector2(2000, 2000))
		assert_almost_eq(target.x, 400.0, 0.0001)  # 500 - 200/2
		assert_almost_eq(target.y, 400.0, 0.0001)
	)

	run_case("scroll_target_clamps_to_zero_near_the_top_left_edge", func():
		var target := MapZoom.scroll_target(Vector2(10, 10), 1.0, Vector2(200, 200), Vector2(2000, 2000))
		assert_almost_eq(target.x, 0.0, 0.0001)
		assert_almost_eq(target.y, 0.0, 0.0001)
	)

	run_case("scroll_target_clamps_to_max_scroll_near_the_bottom_right_edge", func():
		var target := MapZoom.scroll_target(Vector2(1990, 1990), 1.0, Vector2(200, 200), Vector2(2000, 2000))
		assert_almost_eq(target.x, 1800.0, 0.0001)  # 2000 - 200
		assert_almost_eq(target.y, 1800.0, 0.0001)
	)

	run_case("scroll_target_applies_zoom_to_the_point_before_centring", func():
		var target := MapZoom.scroll_target(Vector2(500, 500), 0.5, Vector2(100, 100), Vector2(1000, 1000))
		assert_almost_eq(target.x, 200.0, 0.0001)  # 500*0.5 - 100/2
		assert_almost_eq(target.y, 200.0, 0.0001)
	)

	run_case("scroll_target_clamps_to_zero_when_content_is_smaller_than_the_viewport", func():
		var target := MapZoom.scroll_target(Vector2(50, 50), 1.0, Vector2(400, 400), Vector2(200, 200))
		assert_almost_eq(target.x, 0.0, 0.0001)
		assert_almost_eq(target.y, 0.0, 0.0001)
	)
