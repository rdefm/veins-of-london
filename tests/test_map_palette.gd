extends "res://tests/test_base.gd"

# MapPalette + data/map_palette.json (M1.5 §Map palette): token resolution
# in both modes, faction/ore dark-override fallback, the saved dark-mode
# preference, dark-set contrast, and load validation.

const Preferences := preload("res://systems/preferences.gd")


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

	# ── dark mode preference + dark set ─────────────────────────────────

	run_case("map_dark_mode_defaults_off", func():
		GameState.reset()
		assert_true(not MapPalette.is_dark(), "a fresh game draws the light diagram")
	)

	run_case("map_dark_mode_survives_save_and_load", func():
		GameState.reset()
		Preferences.set_map_dark_mode(true)
		assert_true(SaveManager.save_to_slot(93)["ok"])
		Preferences.set_map_dark_mode(false)
		assert_true(SaveManager.load_from_slot(93)["ok"])
		assert_true(MapPalette.is_dark(), "the saved preference comes back on load")
		SaveManager.delete_slot(93)
		GameState.reset()
	)

	run_case("dark_stop_centres_and_glyphs_match_light", func():
		assert_eq(MapPalette.colour_in("stopFill", true), Color(1.0, 1.0, 1.0), "stop centres stay white")
		assert_eq(MapPalette.colour_in("glyph", true), MapPalette.light("glyph"), "ore glyphs stay charcoal")
		assert_true(MapPalette.colour_in("paper", true).get_luminance() < 0.2, "dark paper is dark")
	)

	run_case("every_dark_line_arc_and_danger_colour_has_3_to_1_contrast", func():
		var paper := MapPalette.colour_in("paper", true)
		var checks: Dictionary = {}
		for key in ["player", "muted", "ink", "warded", "guarded", "danger"]:
			checks["token " + key] = MapPalette.colour_in(key, true)
		for faction_id in GameData.FACTIONS:
			checks["faction " + faction_id] = MapPalette.faction_colour_in(faction_id, true)
		for ore_type in GameData.ORE_TYPES:
			checks["ore " + ore_type] = MapPalette.ore_colour_in(ore_type, true)
		for label in checks:
			var ratio := _contrast(checks[label], paper)
			assert_true(ratio >= 3.0, "%s %s vs dark paper: %.2f:1" % [label, checks[label].to_html(false), ratio])
	)

	run_case("dark_card_text_and_action_colours_have_4_5_to_1_contrast_on_dark_card_paper", func():
		var card_paper := MapPalette.colour_in("cardPaper", true)
		for key in ["cardInk", "cardDim", "cardMuted", "cardAction", "danger"]:
			var ratio := _contrast(MapPalette.colour_in(key, true), card_paper)
			assert_true(ratio >= 4.5, "%s vs dark cardPaper: %.2f:1" % [key, ratio])
	)

	run_case("light_card_action_and_muted_keep_the_global_theme_hexes", func():
		assert_eq(MapPalette.light("cardAction"), UI.action_colour(), "light action stays ui_action_red")
		assert_eq(MapPalette.light("cardMuted").to_html(false), "8a8a8a", "light muted stays UI.muted_label's grey")
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


# WCAG 2 contrast ratio.
func _contrast(a: Color, b: Color) -> float:
	var la := _relative_luminance(a)
	var lb := _relative_luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _relative_luminance(c: Color) -> float:
	var lin := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * lin.call(c.r) + 0.7152 * lin.call(c.g) + 0.0722 * lin.call(c.b)


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
