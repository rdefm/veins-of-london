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
