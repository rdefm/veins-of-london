extends "res://tests/test_base.gd"

# 2-network-map-districts T01: district hex re-tiling. Verifies
# data/map_layout.json's districts now form a true edge-to-edge hex grid
# (flat-top hexagons, circumradius 110px) instead of the old hand-placed,
# overlapping one -- geometrically, not by eyeballing. Reads the real
# GameData.MAP_LAYOUT (boot-loaded from the JSON), not a fixture, since this
# ticket is entirely about that data's own correctness.

const HEX_RADIUS := 110.0
# Distance between centres of two edge-sharing regular hexagons = 2 * apothem
# = radius * sqrt(3), independent of orientation.
var NEIGHBOUR_DISTANCE := HEX_RADIUS * sqrt(3.0)
const DIST_EPS := 1.0

# Every edge-sharing pair in the new grid (systems/map_layout.gd's
# GameData.MAP_LAYOUT["districts"] order is irrelevant here -- this is just
# the adjacency graph the retiled anchors were placed on).
const ADJACENT_PAIRS := [
	["hampstead", "camden"],
	["camden", "kingscross"],
	["camden", "soho"],
	["camden", "city"],
	["kingscross", "city"],
	["kingscross", "shoreditch"],
	["soho", "city"],
	["city", "shoreditch"],
	["city", "battersea"],
	["shoreditch", "whitechapel"],
	["shoreditch", "battersea"],
	["whitechapel", "greenwich"],
]


func _anchor(district_id: String) -> Vector2:
	var a: Array = GameData.MAP_LAYOUT["districts"][district_id]["anchor"]
	return Vector2(a[0], a[1])


func run() -> void:
	run_case("neighbouring_districts_share_an_edge_exactly", func():
		for pair in ADJACENT_PAIRS:
			var dist: float = _anchor(pair[0]).distance_to(_anchor(pair[1]))
			assert_almost_eq(dist, NEIGHBOUR_DISTANCE, DIST_EPS, "%s-%s should be edge-adjacent (dist=%s)" % [pair[0], pair[1], dist])
	)

	run_case("no_two_districts_overlap", func():
		# Any two regular hexagons of the same size/orientation overlap iff
		# their centres are closer than radius*sqrt(3). True for every pair,
		# not just the adjacent ones -- catches diagonal/non-neighbour overlap too.
		var ids: Array = GameData.MAP_LAYOUT["districts"].keys()
		for i in ids.size():
			for j in range(i + 1, ids.size()):
				var dist: float = _anchor(ids[i]).distance_to(_anchor(ids[j]))
				assert_true(dist >= NEIGHBOUR_DISTANCE - DIST_EPS, "%s and %s overlap (dist=%s, min=%s)" % [ids[i], ids[j], dist, NEIGHBOUR_DISTANCE])
	)

	run_case("every_district_keeps_its_original_stopSlots_count", func():
		var expected_counts := {
			"hampstead": 4, "kingscross": 5, "camden": 6, "shoreditch": 5,
			"city": 4, "soho": 2, "whitechapel": 5, "battersea": 5, "greenwich": 5,
		}
		for district_id in expected_counts.keys():
			var slots: Array = GameData.MAP_LAYOUT["districts"][district_id]["stopSlots"]
			assert_eq(slots.size(), expected_counts[district_id], "%s stopSlots count regressed" % district_id)
	)

	run_case("every_stopSlot_sits_inside_its_districts_hexagon", func():
		# Apothem (centre-to-edge) is the safe inradius bound for "inside the
		# hexagon" regardless of angle -- radius*sqrt(3)/2.
		var apothem: float = HEX_RADIUS * sqrt(3.0) / 2.0
		for district_id in GameData.MAP_LAYOUT["districts"].keys():
			var district: Dictionary = GameData.MAP_LAYOUT["districts"][district_id]
			var anchor := _anchor(district_id)
			for slot in district["stopSlots"]:
				var slot_pos := Vector2(slot[0], slot[1])
				assert_true(anchor.distance_to(slot_pos) <= apothem, "%s stopSlot %s falls outside its hexagon" % [district_id, slot_pos])
	)

	run_case("old_camden_kingscross_overlap_point_now_resolves_to_exactly_one_district", func():
		# Pre-retiling anchors were camden (470,400) and kingscross (560,480),
		# only 120px apart against a 110px hex radius -- (515,440), their
		# midpoint, sat inside both old hexagons. It must now belong to exactly one.
		var districts_layout: Dictionary = GameData.MAP_LAYOUT["districts"]
		var old_overlap_point := Vector2(515, 440)
		var containing_count := 0
		for district_id in districts_layout.keys():
			var polygon := MapHitTest.to_vector2_array(districts_layout[district_id]["zonePolygon"])
			if Geometry2D.is_point_in_polygon(old_overlap_point, polygon):
				containing_count += 1
		assert_eq(containing_count, 1, "old overlap point should now belong to exactly one district's zone")
		assert_eq(MapHitTest.district_at(old_overlap_point, districts_layout), "camden")
	)

	run_case("homeAnchor_still_matches_shoreditch_anchor", func():
		var home: Array = GameData.MAP_LAYOUT["homeAnchor"]
		assert_eq(Vector2(home[0], home[1]), _anchor("shoreditch"), "shoreditch is home base -- homeAnchor must track its retiled anchor")
	)
