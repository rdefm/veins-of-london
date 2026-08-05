extends "res://tests/test_base.gd"

# PaperTexture (M1.5 N6 asset 1) — generate_tile_image() is the only pure,
# testable surface (the ImageTexture wrapper and MapCanvas's tiled draw
# aren't exercised headlessly, same convention as Icons/OreGlyphs).


func run() -> void:
	run_case("tile_is_the_declared_size", func():
		var image := PaperTexture.generate_tile_image()
		assert_eq(image.get_width(), PaperTexture.TILE_SIZE)
		assert_eq(image.get_height(), PaperTexture.TILE_SIZE)
	)

	run_case("same_seed_is_deterministic", func():
		var a := PaperTexture.generate_tile_image(7)
		var b := PaperTexture.generate_tile_image(7)
		assert_eq(a.get_data(), b.get_data())
	)

	run_case("every_pixel_stays_within_the_declared_grain_and_foxing_bounds", func():
		var image := PaperTexture.generate_tile_image()
		var max_shift: float = PaperTexture.GRAIN_STRENGTH + PaperTexture.FOXING_STRENGTH
		var ok := true
		for y in PaperTexture.TILE_SIZE:
			for x in PaperTexture.TILE_SIZE:
				var px := image.get_pixel(x, y)
				if absf(px.r - PaperTexture.BASE_COLOUR.r) > max_shift + 0.001 \
						or absf(px.g - PaperTexture.BASE_COLOUR.g) > max_shift + 0.001 \
						or absf(px.b - PaperTexture.BASE_COLOUR.b) > max_shift + 0.001:
					ok = false
		assert_true(ok, "every pixel should stay a subtle grain/foxing shift away from the base cream colour, per N6's 'subtle' foxing/grain")
	)
