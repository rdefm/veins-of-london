extends "res://tests/test_base.gd"


func run() -> void:
	run_case("shapes_are_exactly_the_five_approved_canonical_silhouettes", func():
		assert_eq(OreGlyphs.SHAPES, {
			"time": "hourglass",
			"physics": "bolt",
			"life": "sprout",
			"fate": "die",
			"emotion": "heart",
		})
		assert_eq(OreGlyphs.SHAPES.size(), GameData.ORE_TYPES.size())
	)

	run_case("bundled_font_does_not_cover_any_ore_symbol", func():
		assert_true(not OreGlyphs.font_covers_all_symbols(ThemeDB.fallback_font), "the vector set must remain the map's renderer")
	)

	run_case("every_ore_type_has_a_non_empty_symbol", func():
		for ore_id in GameData.ORE_TYPES.keys():
			assert_true(not String(GameData.ORE_TYPES[ore_id].get("symbol", "")).is_empty(), ore_id)
	)

	run_case("draw_time_builds_a_capped_hourglass_with_a_shared_centre_waist", func():
		var spy := DrawSpy.new()
		var centre := Vector2(3.0, 4.0)
		OreGlyphs.draw(spy, centre, "time", Color.WHITE)

		var lines: Array = spy.calls_matching("draw_line")
		assert_eq(lines.size(), 6, "two caps and four sloping sides")
		assert_eq(lines.filter(func(call): return call["args"][0] == centre or call["args"][1] == centre).size(), 4, "all four sides meet at the exact glyph centre")
	)

	run_case("draw_physics_builds_one_six_point_lightning_bolt", func():
		var spy := DrawSpy.new()
		OreGlyphs.draw(spy, Vector2.ZERO, "physics", Color.WHITE)

		var polygons: Array = spy.calls_matching("draw_colored_polygon")
		assert_eq(polygons.size(), 1)
		assert_eq((polygons[0]["args"][0] as PackedVector2Array).size(), 6)
	)

	run_case("draw_life_builds_two_opposed_leaves_on_a_stem_and_base", func():
		var spy := DrawSpy.new()
		var centre := Vector2(10.0, 20.0)
		OreGlyphs.draw(spy, centre, "life", Color.WHITE)

		var polygons: Array = spy.calls_matching("draw_colored_polygon")
		assert_eq(polygons.size(), 2, "two solid leaves")
		assert_true(_average_x(polygons[0]["args"][0]) < centre.x, "left leaf sits left of the stem")
		assert_true(_average_x(polygons[1]["args"][0]) > centre.x, "right leaf sits right of the stem")
		var lines: Array = spy.calls_matching("draw_line")
		assert_eq(lines.size(), 2, "one upright stem and one horizontal base")
		assert_eq(lines[0]["args"][0].x, centre.x, "stem begins on the glyph's centre axis")
		assert_eq(lines[0]["args"][1].x, centre.x, "stem ends on the glyph's centre axis")
	)

	run_case("draw_fate_builds_a_five_pip_die", func():
		var spy := DrawSpy.new()
		var centre := Vector2(3.0, 4.0)
		OreGlyphs.draw(spy, centre, "fate", Color.WHITE)

		assert_eq(spy.calls_matching("draw_rect").size(), 1, "one die frame")
		var pips: Array = spy.calls_matching("draw_circle")
		assert_eq(pips.size(), 5)
		assert_true(pips.any(func(call): return call["args"][0] == centre), "five face includes a centre pip")
	)

	run_case("draw_emotion_builds_one_symmetric_heart_with_a_notch_and_point", func():
		var spy := DrawSpy.new()
		var centre := Vector2(3.0, 4.0)
		OreGlyphs.draw(spy, centre, "emotion", Color.WHITE)

		var polygons: Array = spy.calls_matching("draw_colored_polygon")
		assert_eq(polygons.size(), 1)
		var points: PackedVector2Array = polygons[0]["args"][0]
		assert_eq(points.size(), 12)
		assert_eq(points[0].x, centre.x, "top notch stays on centre axis")
		assert_eq(points[6].x, centre.x, "bottom point stays on centre axis")
		assert_true(points[0].y > points[1].y and points[0].y > points[11].y, "notch sits below both lobes")
		assert_true(points[6].y > centre.y, "heart point faces down")
	)

	run_case("all_five_glyphs_fit_inside_every_map_canvas_marker_size", func():
		var marker_sizes := [
			{ "marker_radius": MapCanvas.FACTION_STOP_RADIUS, "glyph_radius": 5.5 },
			{ "marker_radius": MapCanvas.VEIN_STOP_RADIUS, "glyph_radius": 5.5 * MapCanvas.STOP_ICON_GROWTH },
		]
		for sizing in marker_sizes:
			for ore_id in OreGlyphs.SHAPES.keys():
				var spy := DrawSpy.new()
				OreGlyphs.draw(spy, Vector2.ZERO, ore_id, Color.WHITE, sizing["glyph_radius"])
				assert_true(_maximum_extent(spy) <= sizing["marker_radius"], "%s fits marker r%s" % [ore_id, sizing["marker_radius"]])
	)

	run_case("unknown_ore_id_draws_nothing", func():
		var spy := DrawSpy.new()
		OreGlyphs.draw(spy, Vector2.ZERO, "unknown", Color.WHITE)
		assert_true(spy.calls.is_empty())
	)


func _average_x(points: PackedVector2Array) -> float:
	var total := 0.0
	for point in points:
		total += point.x
	return total / points.size()


func _maximum_extent(spy: DrawSpy) -> float:
	var extent := 0.0
	for call in spy.calls:
		match call["method"]:
			"draw_colored_polygon":
				for point in call["args"][0]:
					extent = maxf(extent, point.length())
			"draw_line":
				var half_width: float = call["args"][3] * 0.5
				extent = maxf(extent, call["args"][0].length() + half_width)
				extent = maxf(extent, call["args"][1].length() + half_width)
			"draw_rect":
				var rect: Rect2 = call["args"][0]
				var half_width: float = call["args"][3] * 0.5
				for point in [rect.position, rect.end, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y)]:
					extent = maxf(extent, point.length() + half_width)
			"draw_circle":
				extent = maxf(extent, call["args"][0].length() + call["args"][1])
	return extent
