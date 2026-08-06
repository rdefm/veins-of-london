extends "res://tests/test_base.gd"

# OreGlyphs (M1.5 N6 asset 3) — the pure logic: which shape each ore id
# maps to, and the font-coverage check that justifies this module's
# existence. The draw_* functions themselves are immediate-mode
# CanvasItem drawing and aren't exercised here, same convention Icons'
# tests follow.


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
