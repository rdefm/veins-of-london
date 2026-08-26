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

	run_case("elbow_path_switches_orientation_to_avoid_another_owners_stop", func():
		# diag-first's first leg (0,0)->(40,40) (see the river test above)
		# passes exactly through (20,20) -- put another owner's stop there so
		# the naive diag-first elbow would visually overlap it. diag-last's
		# corner (60,0) never comes near (20,20) on either leg, so it should
		# be picked instead, matching the river-avoidance pattern exactly.
		var obstacle_stops := [{ "pos": Vector2(20, 20), "radius": 10.0 }]
		var path := MapRouting.elbow_path(Vector2(0, 0), Vector2(100, 40), [], obstacle_stops)
		assert_eq(path[1], Vector2(60, 0), "diag-first overlaps the obstacle stop, diag-last doesn't -> picks diag-last")
	)

	run_case("elbow_path_ignores_stops_outside_the_avoidance_radius", func():
		# (25,20) sits just off diag-first's first leg (0,0)->(40,40) -- close
		# enough to matter with a generous radius, but a tight 1px radius
		# doesn't reach it, so diag-first should stay untouched.
		var narrow_stop := [{ "pos": Vector2(25, 20), "radius": 1.0 }]
		var path := MapRouting.elbow_path(Vector2(0, 0), Vector2(100, 40), [], narrow_stop)
		assert_eq(path[1], Vector2(40, 40), "obstacle stop's own radius doesn't reach either leg -> no orientation change")
	)

	run_case("elbow_path_defaults_to_diag_first_when_no_leg_nears_the_obstacle_stop", func():
		var obstacle_stops := [{ "pos": Vector2(500, 500), "radius": 10.0 }]
		var path := MapRouting.elbow_path(Vector2(0, 0), Vector2(100, 40), [], obstacle_stops)
		assert_eq(path[1], Vector2(40, 40), "obstacle stop nowhere near either orientation -> stays diag-first")
	)

	run_case("build_line_routes_around_another_owners_stop", func():
		# build_line only elbow-connects stops to each other (ordered[i] ->
		# ordered[i+1]) -- `start` merely seeds the nearest-neighbour walk, it
		# is never itself an endpoint of the drawn path (see the multi-stop
		# test above: 3 stops -> only 2 elbow segments, not 3). So the
		# obstacle here must sit on the leg between the two STOPS, and `start`
		# just needs to be nearer s1 so nearest_neighbour_order visits it first.
		var stops := [
			{ "id": "s1", "pos": Vector2(0, 0) },
			{ "id": "s2", "pos": Vector2(100, 40) },
		]
		var obstacle_stops := [{ "pos": Vector2(20, 20), "radius": 10.0 }]
		var line := MapRouting.build_line(Vector2(-10, -10), stops, [], obstacle_stops)
		assert_eq(line[1], Vector2(60, 0), "build_line threads obstacle_stops into its elbow_path calls")
	)

	# ── ticket 74: line-to-line spacing + the hard no-stop-crossing fallback ──

	run_case("elbow_path_switches_orientation_to_keep_clearance_from_another_owners_line", func():
		# Same geometry as elbow_path_picks_diag_last_when_only_diag_first_
		# crosses above, but the obstacle is a whole other-owner LINE rather
		# than a stop, and it doesn't literally cross diag-first's diagonal
		# leg ((0,0)->(40,40)) -- it runs right alongside it, closer than the
		# required clearance. diag-first's leg1 passes through (20,20), and
		# this vertical obstacle line sits exactly on top of that point (x=20,
		# y 10..30), so its distance to leg1 is 0 -- well inside an 8px
		# clearance. diag-last's legs ((0,0)->(60,0) at y=0, (60,0)->(100,40))
		# never come within 10px of x=20, so an 8px clearance leaves it clear.
		var obstacle_line := PackedVector2Array([Vector2(20, 10), Vector2(20, 30)])
		var path := MapRouting.elbow_path(Vector2(0, 0), Vector2(100, 40), [], [], [obstacle_line], 8.0)
		assert_eq(path[1], Vector2(60, 0), "diag-first runs closer than line_clearance to the other owner's line, diag-last doesn't -> picks diag-last")
	)

	run_case("elbow_path_ignores_other_owners_lines_when_line_clearance_is_zero", func():
		# Same obstacle line as above, but line_clearance defaults to 0.0 --
		# the ticket 74 line-spacing feature must be opt-in via a positive
		# clearance, never silently active, so every pre-ticket-74 call site
		# (river/stop avoidance only) keeps its exact prior behaviour.
		var obstacle_line := PackedVector2Array([Vector2(20, 10), Vector2(20, 30)])
		var path := MapRouting.elbow_path(Vector2(0, 0), Vector2(100, 40), [], [], [obstacle_line])
		assert_eq(path[1], Vector2(40, 40), "no line_clearance given -> obstacle_lines are ignored, stays diag-first")
	)

	run_case("crossed_obstacles_finds_the_stop_that_survives_both_elbow_orientations", func():
		# The ticket 74 amendment's motivating gap: elbow_path's own
		# diag-first/diag-last choice can still both fail. from=(0,0),
		# to=(100,20): diag-first corner (20,20), diag-last corner (80,0).
		# An obstacle at (90,10) with radius 10 sits 10px from diag-first's
		# leg2 ((20,20)->(100,20), a flat y=20 run) AND 0px from diag-last's
		# leg2 ((80,0)->(100,20), which passes exactly through it) -- neither
		# orientation clears it.
		var from := Vector2(0, 0)
		var to := Vector2(100, 20)
		var obstacle := { "id": "v1", "pos": Vector2(90, 10), "radius": 10.0 }

		var corner_first := MapRouting.elbow_corner_diag_first(from, to)
		var corner_last := MapRouting.elbow_corner_diag_last(from, to)
		assert_eq(corner_first, Vector2(20, 20))
		assert_eq(corner_last, Vector2(80, 0))
		assert_true(not MapRouting.crossed_obstacles(from, corner_first, to, [obstacle]).is_empty(), "diag-first still crosses the obstacle")
		assert_true(not MapRouting.crossed_obstacles(from, corner_last, to, [obstacle]).is_empty(), "diag-last still crosses the obstacle too -- routing alone has no orientation left to try")

		# elbow_path's own documented behaviour when both orientations cross
		# is unchanged by ticket 74 -- it still falls back to diag-first
		# rather than resolving the crossing itself. Resolving it is
		# MapCanvas._apply_crossing_nudges' job (see the nudge_position
		# cases below), deliberately kept out of MapRouting's pure routing
		# API since it has to mutate a *stop's* position, not just choose a
		# path.
		var path := MapRouting.elbow_path(from, to, [], [obstacle])
		assert_eq(path[1], corner_first, "both orientations cross -> elbow_path's fallback is still diag-first, unchanged")
	)

	run_case("nudge_position_pushes_the_obstacle_just_clear_of_the_crossing_leg", func():
		# Same both-cross scenario as above. diag-first's fallback path is
		# used (from, (20,20), to); crossed_obstacles reports the obstacle
		# crosses via leg2 ((20,20)->(100,20)) at a 10px distance -- nudging
		# it should push it perpendicular to that leg by just enough to clear
		# radius(10) + margin(2) = 12px, i.e. 2px further than it already is.
		var from := Vector2(0, 0)
		var corner := Vector2(20, 20)
		var to := Vector2(100, 20)
		var obstacle := { "id": "v1", "pos": Vector2(90, 10), "radius": 10.0 }

		var new_pos := MapRouting.nudge_position(obstacle, from, corner, to, 2.0, 16.0)
		assert_eq(new_pos, Vector2(90, 8), "pushed 2px further along the leg's own normal -- exactly enough to clear radius+margin, well within the 16px cap")

		var nudged := obstacle.duplicate()
		nudged["pos"] = new_pos
		assert_true(MapRouting.crossed_obstacles(from, corner, to, [obstacle]).size() == 1, "sanity: the original position is still reported as crossed")
		assert_true(MapRouting.crossed_obstacles(from, corner, to, [nudged]).is_empty(), "the nudged position no longer crosses either leg of the same elbow -- the guarantee actually holds once applied")
	)

	run_case("nudge_position_clears_both_legs_when_the_obstacle_sits_near_the_corner", func():
		# An obstacle close enough to the corner to threaten BOTH legs at
		# once (d_a=4 to leg (a,corner), d_b=0 to leg (corner,b) -- closer to
		# leg b, so a single "push away from the nearest leg only" pass
		# would clear leg b but could easily leave leg a still crossing).
		# nudge_position must guarantee both, not just whichever leg it
		# started nearest to.
		var a := Vector2(0, 0)
		var corner := Vector2(20, 20)
		var b := Vector2(100, 20)
		var obstacle := { "pos": Vector2(24, 20), "radius": 10.0 }

		var new_pos := MapRouting.nudge_position(obstacle, a, corner, b, 2.0, 16.0)
		assert_true(new_pos.distance_to(obstacle["pos"]) <= 16.0, "total displacement stays within the cap")

		var nudged := obstacle.duplicate()
		nudged["pos"] = new_pos
		assert_true(not MapRouting.crossed_obstacles(a, corner, b, [obstacle]).is_empty(), "sanity: the original position crosses (close to both legs at once)")
		assert_true(MapRouting.crossed_obstacles(a, corner, b, [nudged]).is_empty(), "the nudge clears BOTH legs, not just whichever one it started nearest to")
	)

	run_case("nudge_position_caps_at_max_offset_when_the_needed_push_would_exceed_it", func():
		# An obstacle dead-centre on the leg (distance 0) with a radius large
		# enough that radius+margin alone would need a bigger push than the
		# cap allows -- the nudge must still never exceed max_offset, even
		# though that means it may not fully clear an unrealistically large
		# obstacle (ticket 74: "a small, capped distance ... never a full
		# relayout"). Every obstacle this map actually draws stays well under
		# this in practice -- see MapCanvas.STOP_NUDGE_MAX_OFFSET's own
		# comment.
		var a := Vector2(0, 0)
		var b := Vector2(100, 0)
		var obstacle := { "pos": Vector2(50, 0), "radius": 50.0 }
		var new_pos := MapRouting.nudge_position(obstacle, a, Vector2(50, 0), b, 2.0, 16.0)
		assert_almost_eq(new_pos.distance_to(obstacle["pos"]), 16.0, 0.01, "push is capped at max_offset rather than the full radius+margin")
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

	# ── common_prefix_length / grow_segment (map-animations ticket 05) ────

	run_case("common_prefix_length_counts_matching_leading_points", func():
		var a := PackedVector2Array([Vector2(0, 0), Vector2(1, 1), Vector2(2, 2)])
		var b := PackedVector2Array([Vector2(0, 0), Vector2(1, 1), Vector2(9, 9)])
		assert_eq(MapRouting.common_prefix_length(a, b), 2)
	)

	run_case("common_prefix_length_is_the_shorter_arrays_size_when_it_is_a_prefix_of_the_other", func():
		var a := PackedVector2Array([Vector2(0, 0), Vector2(1, 1)])
		var b := PackedVector2Array([Vector2(0, 0), Vector2(1, 1), Vector2(2, 2)])
		assert_eq(MapRouting.common_prefix_length(a, b), 2)
	)

	run_case("common_prefix_length_zero_for_empty_or_wholly_different_arrays", func():
		assert_eq(MapRouting.common_prefix_length(PackedVector2Array(), PackedVector2Array([Vector2(1, 1)])), 0)
		assert_eq(MapRouting.common_prefix_length(PackedVector2Array([Vector2(5, 5)]), PackedVector2Array([Vector2(1, 1)])), 0)
	)

	run_case("grow_segment_returns_the_full_new_line_when_the_owner_has_no_existing_stops", func():
		var new_stop := { "id": "only", "pos": Vector2(100, 100) }
		var segment := MapRouting.grow_segment(Vector2(0, 0), [], new_stop)
		var expected := MapRouting.build_line(Vector2(0, 0), [new_stop])
		assert_eq(segment, expected, "no old line to diverge from -- the grown segment is the whole (single-stop) line, not a segment reaching back to the anchor")
	)

	run_case("grow_segment_is_the_new_tail_when_the_new_stop_is_appended_to_the_existing_walk", func():
		var old_stops := [{ "id": "a", "pos": Vector2(10, 0) }]
		var new_stop := { "id": "b", "pos": Vector2(100, 0) }
		var start := Vector2(0, 0)

		var old_line := MapRouting.build_line(start, old_stops)
		var new_line := MapRouting.build_line(start, [old_stops[0], new_stop])
		var segment := MapRouting.grow_segment(start, old_stops, new_stop)

		assert_eq(segment[0], old_line[old_line.size() - 1], "the grown segment starts exactly where the existing (still statically drawn) line already ends")
		assert_eq(segment[segment.size() - 1], new_line[new_line.size() - 1], "the grown segment ends exactly where the recomputed full line ends")
	)

	run_case("grow_segment_reconstructs_the_full_new_line_exactly_even_when_the_new_stop_reorders_the_whole_walk", func():
		# The new stop sits nearer the start than the existing stop does, so
		# nearest_neighbour_order() visits it FIRST once it's added -- a full
		# reorder, not a tail append. This is exactly the case a naive
		# "straight line to the new stop's own position" animation would get
		# wrong (see ticket 05's own review): grow_segment must still produce
		# something that, prepended with the untouched prefix of the old
		# line, reconstructs the new line exactly.
		var old_stops := [{ "id": "far", "pos": Vector2(200, 0) }]
		var new_stop := { "id": "near", "pos": Vector2(10, 0) }
		var start := Vector2(0, 0)

		var old_line := MapRouting.build_line(start, old_stops)
		var new_line := MapRouting.build_line(start, [old_stops[0], new_stop])
		var prefix := MapRouting.common_prefix_length(old_line, new_line)
		assert_eq(prefix, 0, "the new stop is visited first once added -- nothing of the old walk survives as a shared prefix")

		var segment := MapRouting.grow_segment(start, old_stops, new_stop)
		assert_eq(segment, new_line, "with no shared prefix, the whole new line is what 'grows in' -- still exactly matching build_line's own output")
	)
