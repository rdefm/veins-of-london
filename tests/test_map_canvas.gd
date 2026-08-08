extends "res://tests/test_base.gd"

# Map-animations ticket 02: MapCanvas's seed/claim ring animation is Node/
# Tween-driven, same as ticket 01's DiscoverRipple, so it isn't exercised
# here (see tests/test_map_events.gd's own note on why Node-side playback
# stays outside the headless suite). What IS covered: _vein_ring_style(),
# the one pure seam the animation and the ordinary static draw both call to
# get a vein's ring colour/width — this is what guarantees the arc-sweep
# animation's end state is byte-for-byte the same as what _draw_vein_stop/
# _draw_faction_stop draw at rest, rather than a parallel formula that could
# drift from it. MapCanvas.new() is safe to call this on directly: it never
# touches get_tree()/get_viewport(), only `filter_mode` and GameData.


static func _vein(ore_type: String, level: int) -> Dictionary:
	return { "oreType": ore_type, "level": level }


func run() -> void:
	# A fresh MapCanvas.new() per case, freed at the end of each — never
	# added to the tree (this file only calls the one pure seam that never
	# touches get_tree()/get_viewport()), so nothing frees it automatically.
	run_case("vein_ring_style_matches_MapStyle_directly_in_ownership_mode", func():
		var canvas := MapCanvas.new()
		canvas.filter_mode = "ownership"
		var vein := _vein("time", 3)

		var style: Dictionary = canvas._vein_ring_style(vein, MapCanvas.PLAYER_COLOUR, MapCanvas.VEIN_STOP_STROKE)

		var expected_colour := MapStyle.vein_ring_colour("ownership", MapCanvas.PLAYER_COLOUR, Color(GameData.ORE_TYPES["time"]["colour"]), 3)
		var expected_width := MapStyle.vein_ring_width("ownership", 3, MapCanvas.VEIN_STOP_STROKE)
		assert_eq(style["colour"], expected_colour, "ownership mode: ring colour is the owner colour, same as the static draw")
		assert_eq(style["width"], expected_width, "ownership mode: ring width is the base stroke, same as the static draw")
		canvas.free()
	)

	run_case("vein_ring_style_matches_MapStyle_directly_in_type_and_strength_modes", func():
		var canvas := MapCanvas.new()
		var vein := _vein("fate", 5)

		canvas.filter_mode = "type"
		var type_style: Dictionary = canvas._vein_ring_style(vein, MapCanvas.PLAYER_COLOUR, MapCanvas.VEIN_STOP_STROKE)
		assert_eq(type_style["colour"], Color(GameData.ORE_TYPES["fate"]["colour"]), "type mode: ring recolours by ore, same as the static draw")

		canvas.filter_mode = "strength"
		var strength_style: Dictionary = canvas._vein_ring_style(vein, MapCanvas.PLAYER_COLOUR, MapCanvas.VEIN_STOP_STROKE)
		var expected_width := MapStyle.vein_ring_width("strength", 5, MapCanvas.VEIN_STOP_STROKE)
		assert_eq(strength_style["width"], expected_width, "strength mode: ring thickens by level, same as the static draw")
		canvas.free()
	)

	run_case("vein_ring_style_works_with_a_faction_owner_colour_and_the_faction_base_width", func():
		var canvas := MapCanvas.new()
		canvas.filter_mode = "ownership"
		var vein := _vein("physics", 1)
		var faction_colour := Color(GameData.FACTIONS["firm"]["colour"])

		var style: Dictionary = canvas._vein_ring_style(vein, faction_colour, MapCanvas.FACTION_STOP_STROKE)

		assert_eq(style["colour"], faction_colour, "ownership mode: faction ring colour is the faction's own colour")
		assert_eq(style["width"], MapCanvas.FACTION_STOP_STROKE, "level 1 + ownership mode: width is just the faction base stroke")
		canvas.free()
	)
