extends "res://tests/test_base.gd"

# CardTheme (theme defaults = the map-card family, following the Map dark
# toggle) and the phone shell's card-chrome apps skipping the Phone-OS pass.


func run() -> void:
	run_case("theme_defaults_take_the_card_tokens_in_both_modes", func():
		var meta: Dictionary = GameState.state["meta"]
		var prior: Variant = meta.get("mapDarkMode", false)
		for dark in [false, true]:
			meta["mapDarkMode"] = dark
			var theme := Theme.new()
			CardTheme.apply(theme)
			var context := "dark" if dark else "light"
			assert_eq(theme.get_color("font_color", "Button"), MapPalette.colour_in("cardAction", dark), "%s: buttons are quiet action-accent text" % context)
			var normal: StyleBoxFlat = theme.get_stylebox("normal", "Button")
			assert_eq(normal.bg_color.a, 0.0, "%s: no button fill until pressed" % context)
			var panel: StyleBoxFlat = theme.get_stylebox("panel", "PanelContainer")
			assert_eq(panel.bg_color, MapPalette.colour_in("cardPaper", dark), "%s: panels are card paper" % context)
			var option: StyleBoxFlat = theme.get_stylebox("normal", "OptionButton")
			assert_eq(option.bg_color, MapPalette.colour_in("cardSage", dark), "%s: dropdowns are sage chips" % context)
			assert_eq(theme.get_color("font_color", "Label"), MapPalette.colour_in("cardInk", dark), "%s: labels are card ink" % context)
		meta["mapDarkMode"] = prior
	)

	run_case("saved_theme_resource_matches_the_light_card_theme", func():
		var meta: Dictionary = GameState.state["meta"]
		var prior: Variant = meta.get("mapDarkMode", false)
		meta["mapDarkMode"] = false
		var saved: Theme = preload("res://theme/main_theme.tres")
		assert_true(saved.get_color("font_color", "Button").is_equal_approx(MapPalette.light("cardAction")), "main_theme.tres buttons match CardTheme light")
		var panel: StyleBoxFlat = saved.get_stylebox("panel", "PanelContainer")
		assert_true(panel.bg_color.is_equal_approx(MapPalette.light("cardPaper")), "main_theme.tres panels match CardTheme light")
		meta["mapDarkMode"] = prior
	)

	run_case("card_chrome_phone_app_keeps_theme_buttons_not_phone_red_fill", func():
		GameState.reset()
		var app := DebugApp.new()
		assert_true(app.card_chrome(), "debug app opts into card chrome")
		var content := UI.vbox()
		app.build(content)
		ContactCards.apply_phone_surface_text(content)
		for b in content.find_children("", "Button", true, false):
			assert_true(not (b as Button).has_theme_stylebox_override("normal"), "%s keeps the theme style" % (b as Button).text)
		var heading: Label = content.get_child(1)
		assert_eq(heading.get_theme_color("font_color"), ContactCards.phone_colour("text"), "loose heading takes phone text colour")
		content.free()
		GameState.reset()
	)

	run_case("contacts_and_bespoke_apps_stay_on_the_phone_chrome_pass", func():
		assert_true(not PhoneApp.new().card_chrome(), "apps default to the Phone-OS pass")
		assert_true(not BizBriefApp.new().card_chrome(), "bespoke BizBrief keeps its own chrome")
	)
