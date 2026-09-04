extends "res://tests/test_base.gd"

# Bugfixes ticket 113 — SymbolGlyph's pure decision/dispatch logic
# (covers()/draw_symbol()/ore_fallback()), exercised off-tree the same
# DrawSpy-double way tests/test_ore_glyphs.gd and tests/test_icons.gd
# already test OreGlyphs.draw()/Icons.draw_*. Only the Control's own
# _draw()/_ready() wiring (reading its own `size`, connecting to the real
# fallback font inside a live tree) is left untested here — see
# symbol_glyph.gd's own header comment for why that's the documented,
# deliberately-uncovered seam.


func run() -> void:
	run_case("covers_is_true_for_a_glyph_the_bundled_font_actually_has", func():
		# "A" is plain ASCII -- covered by every font this engine ships,
		# bundled fallback font included.
		assert_true(SymbolGlyph.covers(ThemeDB.fallback_font, "A"))
	)

	run_case("covers_is_false_for_an_ore_symbol_the_bundled_font_lacks", func():
		# Same underlying gap ore_glyphs.gd's own
		# bundled_font_does_not_cover_any_ore_symbol case documents -- reuse
		# one real ore symbol here rather than a made-up unicode char so this
		# stays honest about what's actually being fallen back from.
		var symbol: String = GameData.ORE_TYPES["time"]["symbol"]
		assert_true(not SymbolGlyph.covers(ThemeDB.fallback_font, symbol))
	)

	run_case("covers_is_false_for_an_empty_symbol", func():
		assert_true(not SymbolGlyph.covers(ThemeDB.fallback_font, ""))
	)

	run_case("draw_symbol_draws_real_text_when_the_font_covers_the_symbol_and_never_calls_the_fallback", func():
		var spy := DrawSpy.new()
		var fallback_called := [false]
		var fallback := func(_target: Object, _center: Vector2, _colour: Color, _radius: float) -> void:
			fallback_called[0] = true

		SymbolGlyph.draw_symbol(spy, ThemeDB.fallback_font, Vector2(10, 10), "A", Color.WHITE, 11, 5.5, fallback)

		assert_eq(spy.calls_matching("draw_string").size(), 1, "covered symbol draws real text")
		assert_true(not fallback_called[0], "fallback must not run when the font already covers the symbol")
	)

	run_case("draw_symbol_calls_the_fallback_and_draws_no_text_when_the_font_lacks_the_symbol", func():
		var spy := DrawSpy.new()
		var symbol: String = GameData.ORE_TYPES["time"]["symbol"]
		var center := Vector2(3.0, 4.0)
		var colour := Color.RED
		var radius := 7.0
		var captured: Array = []
		var fallback := func(target: Object, c: Vector2, col: Color, r: float) -> void:
			captured.append({ "target": target, "center": c, "colour": col, "radius": r })

		SymbolGlyph.draw_symbol(spy, ThemeDB.fallback_font, center, symbol, colour, 11, radius, fallback)

		assert_eq(spy.calls_matching("draw_string").size(), 0, "uncovered symbol must not draw text")
		assert_eq(captured.size(), 1)
		assert_eq(captured[0]["target"], spy, "fallback receives the same draw target")
		assert_eq(captured[0]["center"], center)
		assert_eq(captured[0]["colour"], colour)
		assert_eq(captured[0]["radius"], radius)
	)

	run_case("ore_fallback_returns_a_callable_that_delegates_to_ore_glyphs_draw_for_the_bound_ore_type", func():
		var spy := DrawSpy.new()
		var fallback := SymbolGlyph.ore_fallback("time")

		fallback.call(spy, Vector2(1, 2), Color.WHITE, 5.5)

		# OreGlyphs.draw("time", ...) draws the hourglass shape: two
		# triangles -- same assertion tests/test_ore_glyphs.gd's own
		# draw_time case makes, proving ore_fallback really reaches
		# OreGlyphs.draw rather than some other shape.
		assert_eq(spy.calls_matching("draw_colored_polygon").size(), 2, "top and bottom triangle of the hourglass")
	)

	run_case("ore_fallback_binds_the_ore_type_it_was_built_with_not_whatever_is_passed_later", func():
		var spy := DrawSpy.new()
		var fallback := SymbolGlyph.ore_fallback("physics")

		fallback.call(spy, Vector2(0, 0), Color.WHITE, 5.5)

		# physics (bolt) draws exactly one polygon, unlike time's two --
		# confirms the bound ore_type, not some default, drove the shape.
		assert_eq(spy.calls_matching("draw_colored_polygon").size(), 1)
	)

	run_case("draw_symbol_through_ore_fallback_end_to_end_falls_back_to_the_correct_ore_shape", func():
		var spy := DrawSpy.new()
		var ore: Dictionary = GameData.ORE_TYPES["fate"]

		SymbolGlyph.draw_symbol(spy, ThemeDB.fallback_font, Vector2(3, 4), ore["symbol"], Color.WHITE, 11, 5.5, SymbolGlyph.ore_fallback("fate"))

		# fate (die5) draws one frame rect + five pips -- same shape
		# test_ore_glyphs.gd's own draw_fate case checks, now reached through
		# the full covers()-fails -> draw_fallback() path this ticket adds.
		assert_eq(spy.calls_matching("draw_rect").size(), 1)
		assert_eq(spy.calls_matching("draw_circle").size(), 5)
	)

	# generic_fallback() -- ticket 114's placeholder for the ~19 recipe/
	# dial-movement/approach symbols that have no bespoke OreGlyphs shape of
	# their own (human scope decision, see symbol_glyph.gd's own comment).

	run_case("generic_fallback_draws_a_single_diamond_polygon", func():
		var spy := DrawSpy.new()
		var fallback := SymbolGlyph.generic_fallback()

		fallback.call(spy, Vector2(2, 3), Color.WHITE, 5.5)

		assert_eq(spy.calls_matching("draw_colored_polygon").size(), 1, "one filled diamond shape")
	)

	run_case("generic_fallback_diamond_is_centred_and_sized_from_the_given_radius", func():
		var spy := DrawSpy.new()
		var centre := Vector2(10, 10)
		var radius := 6.0

		SymbolGlyph.generic_fallback().call(spy, centre, Color.WHITE, radius)

		var points: PackedVector2Array = spy.calls_matching("draw_colored_polygon")[0]["args"][0]
		assert_eq(points.size(), 4, "a diamond has 4 vertices")
		for p in points:
			assert_true(absf(p.distance_to(centre) - radius) < 0.001, "every vertex must sit exactly `radius` from centre")
	)

	run_case("draw_symbol_through_generic_fallback_end_to_end_draws_the_diamond_when_the_font_lacks_the_symbol", func():
		var spy := DrawSpy.new()
		var symbol: String = GameData.RECIPES["timePearl"]["symbol"]

		SymbolGlyph.draw_symbol(spy, ThemeDB.fallback_font, Vector2(3, 4), symbol, Color.WHITE, 11, 5.5, SymbolGlyph.generic_fallback())

		assert_eq(spy.calls_matching("draw_string").size(), 0, "uncovered recipe symbol must not draw text")
		assert_eq(spy.calls_matching("draw_colored_polygon").size(), 1, "falls back to the generic diamond")
	)
