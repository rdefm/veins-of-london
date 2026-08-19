extends "res://tests/test_base.gd"

# Bugfixes ticket 26: the persistent tube-map-style faction-colour key.
# MapLegend.new() is safe to call _ready() on directly without adding it to a
# live scene tree -- same reasoning tests/test_map_bubble.gd/test_map_controls.gd
# rely on for their own components: nothing _ready() touches (UI.*, GameData,
# PanelContainer/ColorRect/VBoxContainer/Label construction) depends on
# get_tree()/get_viewport() having run, and _reposition()'s
# get_combined_minimum_size() call is the exact same pattern map_bubble.gd's
# own _reposition() already exercises headless.


func run() -> void:
	run_case("lists_one_row_per_faction_in_GameData_order_with_matching_swatch_colour_and_shortName", func():
		var legend := MapLegend.new()
		legend._ready()

		var faction_ids := GameData.FACTIONS.keys()
		assert_eq(legend._rows.get_child_count(), faction_ids.size(), "one row per faction")

		for i in range(faction_ids.size()):
			var faction: Dictionary = GameData.FACTIONS[faction_ids[i]]
			var row: HBoxContainer = legend._rows.get_child(i)
			var swatch: ColorRect = row.get_child(0)
			var name_label: Label = row.get_child(1)

			assert_eq(swatch.color, Color(faction["colour"]), "%s swatch matches its line colour" % faction_ids[i])
			assert_eq(name_label.text, String(faction["shortName"]), "%s row is labelled with its shortName" % faction_ids[i])

		legend.free()
	)

	run_case("starts_expanded_with_all_rows_visible", func():
		var legend := MapLegend.new()
		legend._ready()

		assert_true(legend._expanded, "always-visible key -- open by default, not collapsed")
		assert_true(legend._rows.visible, "rows are shown when expanded")

		legend.free()
	)

	run_case("tapping_the_header_collapses_and_reopens_the_row_list", func():
		var legend := MapLegend.new()
		legend._ready()

		var header: Button = legend._panel.find_children("", "Button", true, false)[0]

		header.pressed.emit()
		assert_true(not legend._expanded, "first tap collapses")
		assert_true(not legend._rows.visible, "collapsing hides the faction rows so it can't crowd a small screen")

		header.pressed.emit()
		assert_true(legend._expanded, "second tap reopens")
		assert_true(legend._rows.visible, "reopening shows the faction rows again")

		legend.free()
	)

	run_case("panel_shrink_wraps_to_its_content_instead_of_collapsing_to_zero_size", func():
		var legend := MapLegend.new()
		legend._ready()

		assert_true(legend._panel.size.x > 0.0, "panel must have real width to be visible/tappable")
		assert_true(legend._panel.size.y > 0.0, "panel must have real height to be visible/tappable")

		legend.free()
	)
