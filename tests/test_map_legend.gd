extends "res://tests/test_base.gd"


func run() -> void:
	run_case("starts_collapsed_with_only_header_and_closed_chevron_visible", func():
		var legend := MapLegend.new()
		legend._ready()

		assert_true(not legend._expanded, "new legend starts collapsed")
		assert_true(not legend._divider.visible, "divider is hidden while collapsed")
		assert_true(not legend._rows.visible, "rows are hidden while collapsed")
		assert_eq(legend._title.text, "Factions", "title remains visible")
		assert_eq(legend._chevron.text, "▸", "closed chevron points right")

		legend.free()
	)

	run_case("whole_header_toggles_content_chevron_and_shrink_wrapped_height", func():
		var legend := MapLegend.new()
		legend._ready()
		var collapsed_size := legend._panel.size

		legend._header.pressed.emit()
		assert_true(legend._expanded, "first header tap expands")
		assert_true(legend._divider.visible, "expanded card shows divider")
		assert_true(legend._rows.visible, "expanded card shows rows")
		assert_eq(legend._chevron.text, "▾", "open chevron points down")
		assert_true(legend._panel.size.y > collapsed_size.y, "expanded card grows to fit rows")

		var expanded_size := legend._panel.size
		legend._header.pressed.emit()
		assert_true(not legend._expanded, "second header tap collapses")
		assert_true(legend._panel.size.y < expanded_size.y, "collapsed card shrinks again")

		legend.free()
	)

	run_case("expanded_rows_follow_GameData_order_with_existing_colour_and_shortName", func():
		var legend := MapLegend.new()
		legend._ready()
		legend._header.pressed.emit()

		var faction_ids := GameData.FACTIONS.keys()
		assert_eq(legend._rows.get_child_count(), faction_ids.size(), "one row per faction")
		for i in range(faction_ids.size()):
			var faction: Dictionary = GameData.FACTIONS[faction_ids[i]]
			var row: HBoxContainer = legend._rows.get_child(i)
			var swatch: ColorRect = row.get_child(0)
			var name_label: Label = row.get_child(1)
			assert_eq(swatch.color, Color(faction["colour"]), "%s swatch colour" % faction_ids[i])
			assert_eq(name_label.text, String(faction["shortName"]), "%s shortName" % faction_ids[i])

		legend.free()
	)

	run_case("card_is_cream_charcoal_touch_sized_and_only_visible_bounds_capture_input", func():
		var legend := MapLegend.new()
		legend._ready()
		var card_style := legend._panel.get_theme_stylebox("panel") as StyleBoxFlat

		assert_eq(card_style.bg_color, MapLegend.CREAM, "cream card surface")
		assert_eq(card_style.border_color, MapLegend.BORDER, "subtle card border")
		assert_eq(legend._title.get_theme_color("font_color"), MapLegend.CHARCOAL, "charcoal header")
		assert_eq(legend._chevron.get_theme_color("font_color"), MapLegend.CHARCOAL, "charcoal chevron")
		assert_true(legend._header.size.y >= UI.ICON_BUTTON_SIZE, "header meets icon-button touch height")
		assert_eq(legend.mouse_filter, Control.MOUSE_FILTER_IGNORE, "root never blocks map")
		assert_eq(legend._panel.mouse_filter, Control.MOUSE_FILTER_IGNORE, "card decoration never blocks map")
		assert_eq(legend._rows.mouse_filter, Control.MOUSE_FILTER_IGNORE, "rows do not block map")
		assert_eq(legend._header.mouse_filter, Control.MOUSE_FILTER_STOP, "visible header is the only touch target")
		assert_true(legend._panel.size.x > 0.0 and legend._panel.size.y > 0.0, "card shrink-wraps to content")

		legend.free()
	)
