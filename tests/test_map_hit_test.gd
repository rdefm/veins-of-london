extends "res://tests/test_base.gd"

# MapHitTest — pure tap-hit-testing math for the Network diagram (ticket 15):
# stop_at (stop/tick taps -> the whole matched stop) and district_at
# (label/zone taps -> district id).


func _stop(id: String, pos: Vector2, site_id: String) -> Dictionary:
	return { "id": id, "position": pos, "site": { "id": site_id } }


func run() -> void:
	# 10-map-interaction-model ticket 04: stop_at() returns the whole matched
	# stop (not just its site id, as its predecessor stop_site_at did) so the
	# station bubble can see which specific vein was tapped.
	run_case("stop_at_returns_the_whole_matched_stop_within_tap_radius", func():
		var stops := [_stop("v1", Vector2(100, 100), "site1")]
		var stop = MapHitTest.stop_at(Vector2(105, 100), stops)
		assert_eq(stop["id"], "v1")
		assert_eq(stop["site"]["id"], "site1")
	)

	run_case("stop_at_null_outside_every_stops_radius", func():
		var stops := [_stop("v1", Vector2(100, 100), "site1")]
		assert_eq(MapHitTest.stop_at(Vector2(1000, 1000), stops), null)
	)

	run_case("stop_at_null_for_empty_stops", func():
		assert_eq(MapHitTest.stop_at(Vector2(100, 100), []), null)
	)

	run_case("stop_at_picks_the_first_matching_stop_in_order", func():
		var stops := [_stop("v1", Vector2(100, 100), "first"), _stop("v2", Vector2(100, 100), "second")]
		assert_eq(MapHitTest.stop_at(Vector2(100, 100), stops)["id"], "v1")
	)

	var districts_layout := {
		"camden": { "labelAnchor": [200, 200], "zonePolygon": [[0, 0], [100, 0], [100, 100], [0, 100]] },
		"soho": { "labelAnchor": [500, 500], "zonePolygon": [[300, 300], [400, 300], [400, 400], [300, 400]] },
	}

	run_case("district_at_label_tap_returns_that_district", func():
		assert_eq(MapHitTest.district_at(Vector2(202, 200), districts_layout), "camden")
	)

	run_case("district_at_zone_polygon_tap_returns_that_district", func():
		assert_eq(MapHitTest.district_at(Vector2(50, 50), districts_layout), "camden", "inside camden's zonePolygon, far from any labelAnchor")
	)

	run_case("district_at_label_wins_over_an_underlying_polygon", func():
		# camden's polygon covers (50,50), but soho's label sits at that same
		# point and soho is iterated second -- label-pass must precede
		# polygon-pass for soho to win here regardless of dict order.
		var layout := {
			"camden": { "labelAnchor": [900, 900], "zonePolygon": [[0, 0], [100, 0], [100, 100], [0, 100]] },
			"soho": { "labelAnchor": [50, 50], "zonePolygon": [[300, 300], [400, 300], [400, 400], [300, 400]] },
		}
		assert_eq(MapHitTest.district_at(Vector2(50, 50), layout), "soho", "soho's label at (50,50) wins even though camden's polygon also covers that point")
	)

	run_case("district_at_null_outside_every_label_and_polygon", func():
		assert_eq(MapHitTest.district_at(Vector2(9999, 9999), districts_layout), null)
	)
