extends "res://tests/test_base.gd"

# field-kit-chrome ticket 02: the hardcoded 5x7 bitmap-font table backing
# the merged status-bar/notification dot-matrix board (docs/ui-vision.md
# §5). draw_char()'s actual dot output is exercised via
# tests/support/draw_spy.gd, the same recording-double pattern
# tests/test_ore_glyphs.gd uses for the same "target: Object, no live
# Viewport needed" reason.


func run() -> void:
	run_case("every_glyph_is_a_5_wide_by_7_tall_grid", func():
		for ch in DotMatrixFont.GLYPHS.keys():
			var rows: Array = DotMatrixFont.GLYPHS[ch]
			assert_eq(rows.size(), DotMatrixFont.GLYPH_H, "glyph %s row count" % ch)
			for row in rows:
				assert_eq(String(row).length(), DotMatrixFont.GLYPH_W, "glyph %s row width" % ch)
	)

	run_case("rows_for_is_case_insensitive", func():
		assert_eq(DotMatrixFont.rows_for("a"), DotMatrixFont.rows_for("A"), "lowercase resolves to the same glyph as uppercase")
	)

	run_case("rows_for_falls_back_to_a_blank_cell_for_an_uncovered_character", func():
		# Real notification prose occasionally carries an emoji (systems/
		# events.gd's "📰 BREAKING", systems/combat.gd's "⟲ Time unspools...")
		# -- this must never crash or throw, just draw nothing for that cell.
		var rows: Array = DotMatrixFont.rows_for("📰")
		for row in rows:
			assert_eq(String(row), "00000", "an uncovered character draws as a fully blank cell")
	)

	run_case("rows_for_an_empty_string_is_also_a_blank_cell", func():
		var rows: Array = DotMatrixFont.rows_for("")
		assert_eq(rows.size(), DotMatrixFont.GLYPH_H)
	)

	run_case("random_scramble_char_always_returns_one_lit_glyph_and_never_space", func():
		for i in 50:
			var ch := DotMatrixFont.random_scramble_char()
			assert_true(DotMatrixFont.GLYPHS.has(ch), "scramble char %s is a real glyph" % ch)
			assert_true(ch != " ", "scrambling never lands on a blank space glyph")
	)

	run_case("draw_char_draws_exactly_35_dots_split_lit_vs_dim_by_the_glyphs_own_1s_and_0s", func():
		var spy := DrawSpy.new()
		DotMatrixFont.draw_char(spy, Vector2.ZERO, "A", 3.0, Color.WHITE, Color.BLACK)

		var rects: Array = spy.calls_matching("draw_rect")
		assert_eq(rects.size(), DotMatrixFont.GLYPH_W * DotMatrixFont.GLYPH_H, "one draw_rect per dot in the 5x7 grid")

		var lit_count := 0
		for rows in DotMatrixFont.GLYPHS["A"]:
			lit_count += String(rows).count("1")

		var lit_rects := rects.filter(func(c): return c["args"][1] == Color.WHITE)
		var dim_rects := rects.filter(func(c): return c["args"][1] == Color.BLACK)
		assert_eq(lit_rects.size(), lit_count, "lit dot count matches the glyph's own 1s")
		assert_eq(dim_rects.size(), rects.size() - lit_count, "every other dot is drawn dim, not skipped")
	)

	run_case("text_width_grows_with_character_count_and_dot_size", func():
		var one_char := DotMatrixFont.text_width("A", 3.0, 2.0)
		var two_chars := DotMatrixFont.text_width("AB", 3.0, 2.0)
		assert_eq(one_char, 5.0 * 3.0, "a single character has no trailing gap")
		assert_eq(two_chars, one_char * 2.0 + 2.0, "each extra character adds its own width plus one gap")
		assert_eq(DotMatrixFont.text_width("", 3.0, 2.0), 0.0, "empty text has zero width")
	)
