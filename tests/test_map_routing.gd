extends "res://tests/test_base.gd"

# MapRouting — pure octilinear geometry for the Network map (M1.5 N3):
# elbow-connector shape, river-crossing orientation choice, terminus stubs,
# nearest-neighbour ordering determinism.


func run() -> void:
	run_case("elbow_corner_diag_first_moves_diagonally_by_min_dx_dy", func():
		# from (0,0) to (100,40): min(|dx|,|dy|) = 40, so the diag-first
		# corner is 40 out along both axes, then straight the rest of dx.
		var corner := MapRouting.elbow_corner_diag_first(Vector2(0, 0), Vector2(100, 40))
		assert_eq(corner, Vector2(40, 40), "diag-first corner sits at (diag, diag) toward the target's sign")
	)

	run_case("elbow_corner_diag_first_handles_negative_direction", func():
		var corner := MapRouting.elbow_corner_diag_first(Vector2(100, 100), Vector2(20, 60))
		# dx=-80, dy=-40 -> diag=40 -> corner = (100-40, 100-40)
		assert_eq(corner, Vector2(60, 60), "diag-first corner respects negative dx/dy signs")
	)

	run_case("elbow_corner_diag_last_is_the_mirror_orientation", func():
		var corner := MapRouting.elbow_corner_diag_last(Vector2(0, 0), Vector2(100, 40))
		# diag=40 -> corner = to - (40,40) = (60, 0)
		assert_eq(corner, Vector2(60, 0), "diag-last corner sits diag-back from the target")
	)

	run_case("elbow_path_pure_diagonal_when_dx_equals_dy", func():
		var path := MapRouting.elbow_path(Vector2(0, 0), Vector2(50, 50))
		assert_eq(path.size(), 3, "elbow path always has 3 points (start, corner, end)")
		assert_eq(path[0], Vector2(0, 0))
		assert_eq(path[1], Vector2(50, 50))
		assert_eq(path[2], Vector2(50, 50))
	)

	run_case("elbow_path_defaults_to_diag_first_with_no_river", func():
		var path := MapRouting.elbow_path(Vector2(0, 0), Vector2(100, 40))
		assert_eq(path[1], Vector2(40, 40), "no river_path given -> always diag-first")
	)

	run_case("elbow_path_switches_orientation_to_avoid_the_river", func():
		# A horizontal river band at y=30..30 crossing straight through the
		# diag-first elbow's axis-aligned leg (y=40 from x=40..100 doesn't
		# cross y=30, so pick geometry where diag-first truly crosses).
		var river := [Vector2(-100, 20), Vector2(200, 20)]
		# diag-first corner (40,40): first leg (0,0)->(40,40) crosses y=20 (diagonal
		# rising through it); diag-last corner (60,0): first leg (0,0)->(60,0) is
		# flat along y=0, never reaches y=20, and second leg (60,0)->(100,40) does
		# cross y=20 -- so to get a clean "diag-first crosses, diag-last doesn't"
		# case, use a river band that only the diagonal-first leg touches.
		var path := MapRouting.elbow_path(Vector2(0, 0), Vector2(100, 40), river)
		# diag-first's first leg (0,0)->(40,40) crosses y=20 at x=20 (inside the
		# river's x-range) -> diag-first crosses. diag-last's corner is (60,0):
		# leg1 (0,0)->(60,0) is at y=0, never crosses y=20; leg2 (60,0)->(100,40)
		# crosses y=20 at x=80 (also inside range) -> diag-last ALSO crosses.
		# Both cross -> deterministic fallback to diag-first.
		assert_eq(path[1], Vector2(40, 40), "both orientations cross this river -> falls back to diag-first")
	)

	run_case("elbow_path_picks_diag_last_when_only_diag_first_crosses", func():
		# River band only near the start corner (0,0)-(40,40) region: a short
		# vertical segment at x=20 spanning y=10..30 crosses diag-first's
		# diagonal leg (which passes through (20,20)) but not diag-last's
		# flat-then-diagonal legs ((0,0)->(60,0) at y=0, (60,0)->(100,40)
		# which only reaches x=20 territory... it doesn't, since it starts at
		# x=60). So diag-last never comes near x=20.
		var river := [Vector2(20, 10), Vector2(20, 30)]
		var path := MapRouting.elbow_path(Vector2(0, 0), Vector2(100, 40), river)
		assert_eq(path[1], Vector2(60, 0), "diag-first crosses, diag-last doesn't -> picks diag-last")
	)

	run_case("segments_intersect_true_for_crossing_segments", func():
		assert_true(MapRouting.segments_intersect(Vector2(0, 0), Vector2(10, 10), Vector2(0, 10), Vector2(10, 0)), "an X crossing should intersect")
	)

	run_case("segments_intersect_false_for_parallel_segments", func():
		assert_true(not MapRouting.segments_intersect(Vector2(0, 0), Vector2(10, 0), Vector2(0, 5), Vector2(10, 5)), "parallel non-touching segments should not intersect")
	)

	run_case("terminus_stub_is_24px_through_the_point_at_45deg", func():
		var stub := MapRouting.terminus_stub(Vector2(100, 100))
		assert_eq(stub.size(), 2, "a stub is a 2-point segment")
		assert_almost_eq(stub[0].distance_to(stub[1]), 24.0, 0.01, "default stub length is 24px")
		var midpoint := (stub[0] + stub[1]) / 2.0
		assert_almost_eq(midpoint.x, 100.0, 0.01, "stub passes through the point")
		assert_almost_eq(midpoint.y, 100.0, 0.01, "stub passes through the point")
	)

	run_case("nearest_neighbour_order_walks_closest_first", func():
		var stops := [
			{ "id": "far", "pos": Vector2(100, 0) },
			{ "id": "near", "pos": Vector2(10, 0) },
			{ "id": "mid", "pos": Vector2(50, 0) },
		]
		var ordered := MapRouting.nearest_neighbour_order(Vector2(0, 0), stops)
		var ids: Array = []
		for s in ordered:
			ids.append(s["id"])
		assert_eq(ids, ["near", "mid", "far"], "greedy nearest-neighbour walk from the start point")
	)

	run_case("nearest_neighbour_order_is_deterministic_on_exact_ties", func():
		# Two stops equidistant from start (0,0): (10,0) and (0,10). Tie
		# broken by id ascending regardless of input array order.
		var stops_a := [
			{ "id": "b_stop", "pos": Vector2(0, 10) },
			{ "id": "a_stop", "pos": Vector2(10, 0) },
		]
		var stops_b := [
			{ "id": "a_stop", "pos": Vector2(10, 0) },
			{ "id": "b_stop", "pos": Vector2(0, 10) },
		]
		var ordered_a := MapRouting.nearest_neighbour_order(Vector2(0, 0), stops_a)
		var ordered_b := MapRouting.nearest_neighbour_order(Vector2(0, 0), stops_b)
		assert_eq(ordered_a[0]["id"], "a_stop", "id tie-break picks the lexicographically-smaller id first")
		assert_eq(ordered_a[0]["id"], ordered_b[0]["id"], "same result regardless of input array order -> deterministic given the same state")
	)

	run_case("build_line_empty_stops_returns_empty", func():
		var line := MapRouting.build_line(Vector2(0, 0), [])
		assert_eq(line.size(), 0, "no stops -> no line drawn")
	)

	run_case("build_line_single_stop_draws_a_terminus_stub", func():
		var line := MapRouting.build_line(Vector2(0, 0), [{ "id": "only", "pos": Vector2(100, 100) }])
		assert_eq(line.size(), 2, "a single-stop owner gets a 2-point terminus stub, not an elbow")
	)

	run_case("build_line_multi_stop_chains_elbows_without_duplicating_joints", func():
		var stops := [
			{ "id": "s1", "pos": Vector2(10, 0) },
			{ "id": "s2", "pos": Vector2(20, 10) },
			{ "id": "s3", "pos": Vector2(30, 30) },
		]
		var line := MapRouting.build_line(Vector2(0, 0), stops)
		# 3 stops -> 2 elbow segments -> start + 2*(corner,end) = 5 points,
		# not 6 (the shared joint between segments isn't duplicated).
		assert_eq(line.size(), 5, "consecutive elbow segments share their joint point")
	)
