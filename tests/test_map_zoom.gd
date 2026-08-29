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

	# Bugfixes ticket 89: the floating +/- zoom buttons' fixed per-tap step
	# (MapCanvas.step_zoom). "roughly 5-8 taps" to cross the whole MIN..MAX
	# range is the ticket's own acceptance target -- assert the tap count
	# itself, not the literal STEP value, so this stays meaningful if STEP
	# gets retuned on-device (it's flagged **needs visual sign-off**).
	run_case("step_is_positive_and_smaller_than_the_full_zoom_range", func():
		assert_true(MapZoom.STEP > 0.0)
		assert_true(MapZoom.STEP < MapZoom.MAX - MapZoom.MIN)
	)

	run_case("step_crosses_the_full_min_to_max_range_in_roughly_5_to_8_taps", func():
		var taps := ceili((MapZoom.MAX - MapZoom.MIN) / MapZoom.STEP)
		assert_true(taps >= 5 and taps <= 8, "expected 5-8 taps to cross the full range, got %d" % taps)
	)

	# ── step_target (bugfixes ticket 89: floating +/- zoom buttons) ───────
	# Pure target-zoom math -- see MapCanvas.step_zoom() for the Node/Tween
	# side (animates to this target via pan_to()), not asserted against
	# directly here, same split every other MapZoom seam in this file uses.

	run_case("step_target_zoom_in_adds_step_to_the_current_zoom", func():
		assert_almost_eq(MapZoom.step_target(1.0, 1), 1.0 + MapZoom.STEP, 0.0001)
	)

	run_case("step_target_zoom_out_subtracts_step_from_the_current_zoom", func():
		assert_almost_eq(MapZoom.step_target(1.0, -1), 1.0 - MapZoom.STEP, 0.0001)
	)

	run_case("step_target_zoom_in_clamps_to_max_instead_of_overshooting", func():
		var near_max := MapZoom.MAX - (MapZoom.STEP / 2.0)  # a half-step short of MAX
		assert_almost_eq(MapZoom.step_target(near_max, 1), MapZoom.MAX, 0.0001)
	)

	run_case("step_target_zoom_out_clamps_to_min_instead_of_undershooting", func():
		var near_min := MapZoom.MIN + (MapZoom.STEP / 2.0)  # a half-step short of MIN
		assert_almost_eq(MapZoom.step_target(near_min, -1), MapZoom.MIN, 0.0001)
	)

	run_case("step_target_zoom_in_already_at_max_stays_at_max", func():
		assert_almost_eq(MapZoom.step_target(MapZoom.MAX, 1), MapZoom.MAX, 0.0001)
	)

	run_case("step_target_zoom_out_already_at_min_stays_at_min", func():
		assert_almost_eq(MapZoom.step_target(MapZoom.MIN, -1), MapZoom.MIN, 0.0001)
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
