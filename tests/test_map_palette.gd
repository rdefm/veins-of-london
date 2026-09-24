extends "res://tests/test_base.gd"

# MapPalette + data/map_palette.json (M1.5 §Map palette): token resolution
# in both modes, faction/ore dark-override fallback, and load validation.


func run() -> void:
	run_case("every_token_resolves_in_both_modes", func():
		var light: Dictionary = GameData.MAP_PALETTE["light"]
		var dark: Dictionary = GameData.MAP_PALETTE["dark"]
		assert_true(not light.is_empty(), "the light set defines tokens")
		for key in light:
			assert_eq(MapPalette.colour_in(key, false), Color(light[key]), "light '%s'" % key)
			assert_eq(MapPalette.colour_in(key, true), Color(dark[key]), "dark '%s'" % key)
	)

	run_case("light_set_keeps_the_pre_palette_map_colours", func():
		assert_eq(MapPalette.light("paper"), Color(1.0, 1.0, 1.0), "diagram paper stays white")
		assert_eq(MapPalette.light("stopFill"), Color(1.0, 1.0, 1.0), "stop centres stay white")
		assert_eq(MapPalette.light("ink"), Color("#1a1a1a"))
		assert_eq(MapPalette.light("glyph"), Color("#1a1a1a"))
		assert_eq(MapPalette.light("muted"), Color("#8a8a8a"))
		assert_eq(MapPalette.light("border"), Color("#d4cfc4"))
		assert_almost_eq(MapPalette.light("river").a, 0.6, 0.001, "river is the border tone at 60%")
		assert_eq(MapPalette.light("player"), Color("#c8873a"))
		assert_eq(MapPalette.light("danger"), Color("#9b2335"))
		assert_eq(MapPalette.light("cardPaper"), Color("#f0eee6"), "cards keep their own paper tone")
		assert_eq(MapPalette.light("chromePaper"), Color("#faf8f3"), "legend/zoom chrome keeps its own paper tone")
	)

	run_case("colour_follows_the_saved_map_dark_mode_flag", func():
		var meta: Dictionary = GameState.state["meta"]
		var had_flag := meta.has("mapDarkMode")
		var prior: Variant = meta.get("mapDarkMode")
		var saved_dark: Dictionary = GameData.MAP_PALETTE["dark"].duplicate()
		GameData.MAP_PALETTE["dark"]["paper"] = "#101418"

		meta["mapDarkMode"] = false
		assert_eq(MapPalette.colour("paper"), MapPalette.light("paper"), "flag off -> light set")
		meta["mapDarkMode"] = true
		assert_eq(MapPalette.colour("paper"), Color("#101418"), "flag on -> dark set")

		GameData.MAP_PALETTE["dark"] = saved_dark
		if had_flag:
			meta["mapDarkMode"] = prior
		else:
			meta.erase("mapDarkMode")
	)

	run_case("faction_and_ore_colours_fall_back_to_their_data_colour", func():
		for faction_id in GameData.FACTIONS:
			var data_colour := Color(GameData.FACTIONS[faction_id]["colour"])
			assert_eq(MapPalette.faction_colour_in(faction_id, false), data_colour, faction_id)
			if not GameData.MAP_PALETTE["darkOverrides"]["factions"].has(faction_id):
				assert_eq(MapPalette.faction_colour_in(faction_id, true), data_colour, "%s: no dark override -> data colour" % faction_id)
		for ore_type in GameData.ORE_TYPES:
			var data_colour := Color(GameData.ORE_TYPES[ore_type]["colour"])
			assert_eq(MapPalette.ore_colour_in(ore_type, false), data_colour, ore_type)
			if not GameData.MAP_PALETTE["darkOverrides"]["oreTypes"].has(ore_type):
				assert_eq(MapPalette.ore_colour_in(ore_type, true), data_colour, "%s: no dark override -> data colour" % ore_type)
	)

	run_case("a_dark_override_applies_in_dark_mode_only", func():
		var overrides: Dictionary = GameData.MAP_PALETTE["darkOverrides"]
		var saved: Dictionary = overrides.duplicate(true)
		overrides["factions"]["firm"] = "#e06070"
		overrides["oreTypes"]["emotion"] = "#d080b0"

		assert_eq(MapPalette.faction_colour_in("firm", true), Color("#e06070"))
		assert_eq(MapPalette.faction_colour_in("firm", false), Color(GameData.FACTIONS["firm"]["colour"]), "light mode ignores dark overrides")
		assert_eq(MapPalette.ore_colour_in("emotion", true), Color("#d080b0"))
		assert_eq(MapPalette.ore_colour_in("emotion", false), Color(GameData.ORE_TYPES["emotion"]["colour"]))

		GameData.MAP_PALETTE["darkOverrides"] = saved
	)

	# ── validation ──────────────────────────────────────────────────────

	run_case("real_map_palette_validates", func():
		var errors := _map_palette_errors(GameData.snapshot())
		assert_true(errors.is_empty(), "map_palette.json should validate: %s" % str(errors))
	)

	run_case("invalid_colour_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["map_palette"]["dark"]["ink"] = "not-a-colour"
		assert_true(_has_error(_map_palette_errors(corrupted), "map_palette.dark.ink"), "an unparseable token value is flagged")
	)

	run_case("light_dark_key_mismatch_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["map_palette"]["dark"].erase("paper")
		corrupted["map_palette"]["light"]["extra"] = "#123456"
		var errors := _map_palette_errors(corrupted)
		assert_true(_has_error(errors, "'paper'"), "a token missing from dark is flagged")
		assert_true(_has_error(errors, "'extra'"), "a token missing from light is flagged")
	)

	run_case("dark_override_for_unknown_id_or_bad_colour_fails", func():
		var corrupted: Dictionary = GameData.snapshot().duplicate(true)
		corrupted["map_palette"]["darkOverrides"]["factions"]["nobody"] = "#ffffff"
		corrupted["map_palette"]["darkOverrides"]["oreTypes"]["time"] = "#zzzzzz"
		var errors := _map_palette_errors(corrupted)
		assert_true(_has_error(errors, "'nobody' is not a known id"), "unknown faction id is flagged")
		assert_true(_has_error(errors, "darkOverrides.oreTypes.time"), "bad override colour is flagged")
	)


func _map_palette_errors(tables: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for e in GameData.validate_tables(tables):
		if e.begins_with("map_palette"):
			errors.append(e)
	return errors


func _has_error(errors: Array[String], fragment: String) -> bool:
	for e in errors:
		if e.contains(fragment):
			return true
	return false
