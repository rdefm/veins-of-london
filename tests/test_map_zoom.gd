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

	# Bugfixes ticket 10: MAX was 1.0, leaving almost no zoom-in headroom
	# above DEFAULT (0.85) for reading closely-packed station clusters.
	# Assert the headroom itself, not the literal MAX, so this stays
	# meaningful if either constant gets retuned on-device.
	run_case("max_zoom_gives_real_headroom_above_default_for_reading_clusters", func():
		assert_true(MapZoom.MAX - MapZoom.DEFAULT >= 0.75)
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

	# ── scroll_target `anchor` (bugfixes ticket 23: pinch-zoom anchor point) ─
	# Pinch-zoom wants `point` to stay under a specific screen position (the
	# pinch midpoint's own place in the viewport), not jump to viewport
	# centre the way a tap-to-open pan_to() wants — that's what `anchor` is
	# for, and this is the "scroll-offset compensation during a pinch
	# centred away from the origin" coverage the ticket asks for.

	run_case("scroll_target_with_no_anchor_still_centres_the_point_exactly_like_before", func():
		var target := MapZoom.scroll_target(Vector2(500, 500), 1.0, Vector2(200, 200), Vector2(2000, 2000))
		assert_almost_eq(target.x, 400.0, 0.0001)
		assert_almost_eq(target.y, 400.0, 0.0001)
	)

	run_case("scroll_target_with_an_anchor_places_the_point_there_instead_of_centring", func():
		# Point sits 30px into the viewport from the current scroll offset
		# (the pinch midpoint's own on-screen position) instead of dead
		# centre -- scroll should land the point exactly there, not at
		# viewport_size/2.
		var target := MapZoom.scroll_target(Vector2(500, 500), 1.0, Vector2(200, 200), Vector2(2000, 2000), Vector2(30, 30))
		assert_almost_eq(target.x, 470.0, 0.0001)  # 500 - 30
		assert_almost_eq(target.y, 470.0, 0.0001)
	)

	run_case("scroll_target_anchor_still_applies_zoom_to_the_point_first", func():
		var target := MapZoom.scroll_target(Vector2(500, 500), 0.5, Vector2(100, 100), Vector2(1000, 1000), Vector2(40, 60))
		assert_almost_eq(target.x, 210.0, 0.0001)  # 500*0.5 - 40
		assert_almost_eq(target.y, 190.0, 0.0001)  # 500*0.5 - 60
	)

	run_case("scroll_target_anchor_away_from_origin_still_clamps_to_zero_near_the_top_left_edge", func():
		var target := MapZoom.scroll_target(Vector2(10, 10), 1.0, Vector2(200, 200), Vector2(2000, 2000), Vector2(150, 150))
		assert_almost_eq(target.x, 0.0, 0.0001)
		assert_almost_eq(target.y, 0.0, 0.0001)
	)

	run_case("scroll_target_anchor_away_from_origin_still_clamps_to_max_scroll_near_the_bottom_right_edge", func():
		var target := MapZoom.scroll_target(Vector2(1990, 1990), 1.0, Vector2(200, 200), Vector2(2000, 2000), Vector2(20, 20))
		assert_almost_eq(target.x, 1800.0, 0.0001)  # 2000 - 200
		assert_almost_eq(target.y, 1800.0, 0.0001)
	)

	# Simulates a full pinch step: a point that was sitting 130px into the
	# viewport at zoom 1.0 (scroll was 100 to get it there) should still sit
	# 130px into the viewport after zooming to 2.0 -- the anchor-preserving
	# maths _update_pinch() relies on to keep the pinch midpoint stationary.
	run_case("scroll_target_anchor_keeps_a_pinch_point_stationary_across_a_zoom_change", func():
		var old_scroll := Vector2(100, 100)
		var point := Vector2(230, 230)  # logical map px under the fingers at zoom 1.0
		var anchor := point * 1.0 - old_scroll  # viewport-relative position: 130, 130

		var new_scroll := MapZoom.scroll_target(point, 2.0, Vector2(400, 400), Vector2(4000, 4000), anchor)

		var viewport_relative_after := point * 2.0 - new_scroll
		assert_almost_eq(viewport_relative_after.x, anchor.x, 0.0001)
		assert_almost_eq(viewport_relative_after.y, anchor.y, 0.0001)
	)

	# ── fit_view (53-map-auto-focus-and-zoom-persistence: first-ever open) ──

	run_case("fit_view_uses_the_fallback_point_at_default_zoom_when_there_are_no_positions", func():
		var view := MapZoom.fit_view([], Vector2(400, 400), Vector2(4000, 4000), Vector2(1000, 1000))

		assert_almost_eq(view["zoom"], MapZoom.DEFAULT, 0.0001, "no veins yet -- nothing to fit around, so DEFAULT")
		var expected_scroll := MapZoom.scroll_target(Vector2(1000, 1000), MapZoom.DEFAULT, Vector2(400, 400), Vector2(4000, 4000) * MapZoom.DEFAULT)
		assert_eq(view["scroll"], expected_scroll, "centres the fallback point at DEFAULT zoom, same maths scroll_target itself uses")
	)

	run_case("fit_view_centres_on_a_single_vein_at_default_zoom", func():
		var view := MapZoom.fit_view([Vector2(500, 500)], Vector2(400, 400), Vector2(4000, 4000), Vector2(0, 0))

		assert_almost_eq(view["zoom"], MapZoom.DEFAULT, 0.0001, "a single point has no spread to fit -- zoom stays at DEFAULT, not maxed out")
		var expected_scroll := MapZoom.scroll_target(Vector2(500, 500), MapZoom.DEFAULT, Vector2(400, 400), Vector2(4000, 4000) * MapZoom.DEFAULT)
		assert_eq(view["scroll"], expected_scroll, "centred on the one vein")
	)

	run_case("fit_view_zooms_out_below_default_to_fit_a_wide_spread_of_veins", func():
		# A spread far wider than the viewport at DEFAULT zoom forces zoom
		# down so every vein stays framed.
		var positions := [Vector2(0, 500), Vector2(5000, 500)]
		var view := MapZoom.fit_view(positions, Vector2(400, 400), Vector2(8000, 8000), Vector2(0, 0))

		assert_true(view["zoom"] < MapZoom.DEFAULT, "a spread this wide at DEFAULT zoom would blow past the viewport -- must zoom out to fit it")
		assert_true(view["zoom"] >= MapZoom.MIN, "still clamped to the legal zoom range")
	)

	run_case("fit_view_never_zooms_in_past_default_for_a_tight_cluster", func():
		var positions := [Vector2(1000, 1000), Vector2(1005, 1002)]  # a few px apart
		var view := MapZoom.fit_view(positions, Vector2(400, 400), Vector2(4000, 4000), Vector2(0, 0))

		assert_almost_eq(view["zoom"], MapZoom.DEFAULT, 0.0001, "frame the veins, not zoom in as far as possible on a tight cluster")
	)

	run_case("fit_view_centres_the_bounding_box_midpoint_not_either_vein", func():
		var positions := [Vector2(200, 200), Vector2(600, 600)]
		var view := MapZoom.fit_view(positions, Vector2(1000, 1000), Vector2(4000, 4000), Vector2(0, 0))

		var expected_scroll := MapZoom.scroll_target(Vector2(400, 400), view["zoom"], Vector2(1000, 1000), Vector2(4000, 4000) * view["zoom"])
		assert_eq(view["scroll"], expected_scroll, "scroll centres the bounding box's own midpoint, (200,600)")
	)
