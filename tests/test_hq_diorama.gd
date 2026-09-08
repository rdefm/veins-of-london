extends "res://tests/test_base.gd"

# hq-diorama ticket 01 acceptance: data/hq_visuals.json's schema round-trips
# through GameData, HqDiorama draws a labelled placeholder box for every
# region with an empty "image" (and skips it once art exists), the debug
# overlay only draws when toggled on, and region_rects() never hardcodes a
# zone id -- it reflects whatever the manifest happens to hold.


func _bedsit_plate() -> Dictionary:
	return GameData.HQ_VISUALS["rooms"]["bedsit"].duplicate(true)


func run() -> void:
	run_case("build_sizes_the_control_to_the_plates_width_and_height", func():
		var diorama := HqDiorama.new()
		diorama.build(_bedsit_plate())
		assert_eq(diorama.size, Vector2(390, 660), "control size should match the plate's width/height")
		diorama.free()
	)

	run_case("region_rects_returns_every_region_generically_no_hardcoded_roster", func():
		var plate: Dictionary = {
			"image": "",
			"fallbackColor": "timber_dark",
			"width": 100,
			"height": 100,
			"regions": {
				"madeUpZoneId": { "x": 10, "y": 20, "width": 50, "height": 60, "label": "Made-up zone", "image": "" },
			},
		}
		var diorama := HqDiorama.new()
		diorama.build(plate)
		var rects: Dictionary = diorama.region_rects()
		assert_true(rects.has("madeUpZoneId"), "a region id never seen before should still come back out of region_rects() -- the reader must not hardcode a roster")
		assert_eq(rects["madeUpZoneId"], Rect2(10, 20, 50, 60), "region rect should match the manifest's own x/y/width/height")
		diorama.free()
	)

	run_case("empty_image_region_draws_a_labelled_placeholder_box", func():
		var diorama := HqDiorama.new()
		diorama.build(_bedsit_plate())
		var spy := DrawSpy.new()
		diorama._draw_placeholder_box(spy, Rect2(10, 20, 100, 44), "Dial")
		var fills: Array = spy.calls_matching("draw_rect")
		assert_eq(fills.size(), 2, "placeholder box draws a filled rect and a border rect")
		assert_eq(fills[0]["args"][0], Rect2(10, 20, 100, 44), "the filled rect matches the region's own rect")
		var labels: Array = spy.calls_matching("draw_string")
		assert_true(labels.any(func(c): return c["args"][2] == "Dial"), "the placeholder box draws the region's label as text")
		diorama.free()
	)

	run_case("region_with_no_art_produced_yet_gets_a_placeholder_not_a_blank_space", func():
		# hq-diorama ticket 10 landed real bedsit art for every region
		# except oreStore (docs/hq-diorama-vision.md §10 -- no fixture was
		# ever drawn for it), so that's the one zone still expected to fall
		# back to the placeholder box; a region with real art (e.g.
		# "security") should load as a sprite instead.
		var diorama := HqDiorama.new()
		diorama.build(_bedsit_plate())
		assert_true(not diorama._region_sprites.has("oreStore"), "oreStore has no art yet in the real manifest, so it should fall back to the placeholder box, not a TextureRect")
		assert_true(diorama._region_sprites.has("security"), "security has real art in the real manifest, so it should load as a sprite, not a placeholder box")
		diorama.free()
	)

	run_case("debug_overlay_toggle_controls_whether_debug_region_draws", func():
		var diorama := HqDiorama.new()
		diorama.build(_bedsit_plate())
		assert_true(not diorama.is_debug_overlay_enabled(), "debug overlay should default to off")

		diorama.set_debug_overlay_enabled(true)
		assert_true(diorama.is_debug_overlay_enabled(), "set_debug_overlay_enabled(true) should flip the toggle on")

		var spy := DrawSpy.new()
		diorama._draw_debug_region(spy, Rect2(0, 0, 50, 50), "dial")
		var outlines: Array = spy.calls_matching("draw_rect")
		assert_true(outlines.any(func(c): return c["args"][0] == Rect2(0, 0, 50, 50) and c["args"][2] == false), "debug region draws an unfilled outline rect")
		var labels: Array = spy.calls_matching("draw_string")
		assert_true(labels.any(func(c): return c["args"][2] == "dial"), "debug region draws the region's own id as text")

		diorama.set_debug_overlay_enabled(false)
		assert_true(not diorama.is_debug_overlay_enabled(), "set_debug_overlay_enabled(false) should flip the toggle back off, at runtime")
		diorama.free()
	)

	run_case("empty_fallback_color_falls_back_to_the_manifest_palette_fallback_fill", func():
		# The real bedsit plate has real room art since ticket 10, so it no
		# longer exercises this fallback path -- a synthetic image:""
		# plate (same shape the region_rects test above already uses)
		# stands in for a plate that hasn't got its art yet.
		var plate: Dictionary = {
			"image": "",
			"fallbackColor": "timber_dark",
			"width": 100,
			"height": 100,
			"regions": {},
		}
		var diorama := HqDiorama.new()
		diorama.build(plate)
		var expected: Color = GameData.PALETTE.get("timber_dark", Color.BLACK)
		assert_eq(diorama._background_fill.color, expected, "with no room image, the background fill should read the manifest's own fallbackColor from data/palette.json")
		assert_true(diorama._background_fill.visible, "the fallback fill should be visible when there's no room image")
		assert_true(not diorama._background_texture.visible, "the texture layer should stay hidden when there's no room image")
		diorama.free()
	)

	run_case("real_room_image_uses_the_texture_layer_not_the_fallback_fill", func():
		# hq-diorama ticket 10: the real bedsit plate now has real art, so
		# the opposite branch of build()'s image/fallback fork should fire.
		var diorama := HqDiorama.new()
		diorama.build(_bedsit_plate())
		assert_true(diorama._background_texture.visible, "with a real room image, the texture layer should be visible")
		assert_true(not diorama._background_fill.visible, "the fallback fill should stay hidden when there's a real room image")
		diorama.free()
	)
