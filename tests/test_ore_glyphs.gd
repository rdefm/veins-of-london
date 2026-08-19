extends "res://tests/test_base.gd"

# OreGlyphs (M1.5 N6 asset 3) — the pure logic: which shape each ore id
# maps to, and the font-coverage check that justifies this module's
# existence.
#
# Ticket 35: draw() and every shape it dispatches to (_draw_hourglass/
# _draw_bolt/_draw_star4/_draw_die5/_draw_asterisk8) are also now exercised
# for real, via tests/support/draw_spy.gd — the same `target: Object`
# recording double tests/test_icons.gd uses, standing in for the `target:
# CanvasItem` params ticket 34's spike found had to be retyped (shadowing a
# native CanvasItem method is a hard GDScript compile error; see ticket 34's
# `## Answer`).


func run() -> void:
	run_case("shapes_cover_every_canonical_ore_type_exactly", func():
		var ore_ids: Array = GameData.ORE_TYPES.keys()
		assert_eq(OreGlyphs.SHAPES.size(), ore_ids.size())
		for ore_id in ore_ids:
			assert_true(OreGlyphs.SHAPES.has(ore_id), ore_id)
	)

	# Documents the actual reason this module exists: the engine's own
	# bundled fallback font (the only font this project ships or
	# overrides anywhere) has no glyph for any of the 5 ore symbols. If a
	# future engine/theme change ever starts covering them, this
	# assertion is the signal to revisit whether OreGlyphs' vector
	# fallback is still needed.
	run_case("bundled_font_does_not_cover_any_ore_symbol", func():
		assert_true(not OreGlyphs.font_covers_all_symbols(ThemeDB.fallback_font), "if this now passes, the engine's bundled font gained coverage - see scenes/components/ore_glyphs.gd")
	)

	run_case("every_ore_type_has_a_non_empty_symbol", func():
		for ore_id in GameData.ORE_TYPES.keys():
			assert_true(not String(GameData.ORE_TYPES[ore_id].get("symbol", "")).is_empty(), ore_id)
	)

	run_case("draw_time_draws_two_triangles_meeting_at_the_hourglass_waist", func():
		var spy := DrawSpy.new()
		OreGlyphs.draw(spy, Vector2(1, 2), "time", Color.WHITE)
		assert_eq(spy.calls_matching("draw_colored_polygon").size(), 2, "top and bottom triangle")
	)

	run_case("draw_physics_draws_one_zigzag_bolt_polygon", func():
		var spy := DrawSpy.new()
		OreGlyphs.draw(spy, Vector2(1, 2), "physics", Color.WHITE)
		assert_eq(spy.calls_matching("draw_colored_polygon").size(), 1)
	)

	run_case("draw_life_draws_one_star4_polygon", func():
		var spy := DrawSpy.new()
		OreGlyphs.draw(spy, Vector2(1, 2), "life", Color.WHITE)
		assert_eq(spy.calls_matching("draw_colored_polygon").size(), 1)
	)

	# fate (die5) is the one shape whose centre pip (offset (0,0)) records a
	# draw_circle at the *exact*, unmodified centre point passed to draw() --
	# the same fact tests/test_map_canvas.gd's stop-centering cases lean on
	# to close ticket 27's "and centered" gap for the live (font-uncovered)
	# ore-glyph path.
	run_case("draw_fate_draws_a_frame_rect_and_five_pips_including_one_exactly_on_centre", func():
		var spy := DrawSpy.new()
		var centre := Vector2(3.0, 4.0)

		OreGlyphs.draw(spy, centre, "fate", Color.WHITE)

		assert_eq(spy.calls_matching("draw_rect").size(), 1, "one square die frame")
		var pips: Array = spy.calls_matching("draw_circle")
		assert_eq(pips.size(), 5, "four corner pips plus the centre pip")
		assert_true(pips.any(func(c): return c["args"][0] == centre), "the centre pip is drawn exactly on the glyph's own centre point")
	)

	run_case("draw_emotion_draws_four_lines_through_the_centre", func():
		var spy := DrawSpy.new()
		OreGlyphs.draw(spy, Vector2(1, 2), "emotion", Color.WHITE)
		assert_eq(spy.calls_matching("draw_line").size(), 4, "4 lines = 8 spokes, each line covering two opposite spokes")
	)
