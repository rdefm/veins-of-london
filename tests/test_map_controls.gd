extends "res://tests/test_base.gd"

# MapControls' filter drawer — map-filters ticket 04 (Faction isolate).
# MapControls.new() is safe to call _ready() on directly without adding it
# to a live scene tree: neither _ready() nor anything it calls (UI.*,
# TouchScrollContainer, PanelContainer/ColorRect/VBoxContainer construction)
# touches get_tree()/get_viewport(), same reasoning tests/test_map_canvas.gd
# already relies on for MapCanvas. _ready() is called as a plain method here
# (not fired by the engine's own add_child lifecycle), which is fine since
# nothing in it depends on that lifecycle actually having run.
#
# This file exists specifically to cover the drawer-level "Faction" row +
# sub-picker flow (open/select/clear) that tests/test_map_style.gd (pure
# re-styling maths) and tests/test_map_canvas.gd (field wiring) don't reach —
# a prior version of _build_faction_rows() disabled the Faction row itself
# once a faction was selected, which made the row (and therefore its
# "Clear (show all)" option) permanently unreachable; case 4 below is the
# regression test for that.


func run() -> void:
	run_case("fresh_drawer_defaults_to_ownership_with_no_faction_selected_and_picker_closed", func():
		var controls := MapControls.new()
		controls._ready()

		assert_eq(controls._filter_mode, "ownership")
		assert_eq(controls._selected_faction_id, "")
		assert_true(not controls._faction_picker_open)

		controls.free()
	)

	run_case("toggling_the_faction_row_opens_and_closes_the_picker_without_touching_filter_mode", func():
		var controls := MapControls.new()
		controls._ready()

		controls._toggle_faction_picker()
		assert_true(controls._faction_picker_open)
		assert_eq(controls._filter_mode, "ownership", "opening the picker doesn't itself pick a filter")

		controls._toggle_faction_picker()
		assert_true(not controls._faction_picker_open)

		controls.free()
	)

	run_case("selecting_a_faction_sets_faction_mode_and_pushes_it_to_map_canvas", func():
		var controls := MapControls.new()
		var canvas := MapCanvas.new()
		controls.map_canvas = canvas
		controls._ready()

		controls._select_faction("firm")

		assert_eq(controls._filter_mode, "faction")
		assert_eq(controls._selected_faction_id, "firm")
		assert_true(not controls._faction_picker_open, "picking a faction closes the sub-picker, same as picking any other row")
		assert_eq(canvas.filter_mode, "faction", "the pick is pushed straight through to map_canvas")
		assert_eq(canvas.selected_faction_id, "firm")

		controls.free()
		canvas.free()
	)

	# Regression test: _build_faction_rows() used to disable the Faction row
	# itself whenever filter_mode == "faction" (mirroring how the other 5
	# rows disable when they're the active mode) -- but since the Faction
	# row is the *only* way to reopen its own picker, that made "Clear (show
	# all)" unreachable the instant a faction was picked (_faction_picker_
	# open is false again by then, so the disable condition stayed true
	# forever). The row must stay tappable regardless of filter_mode.
	run_case("the_faction_row_stays_tappable_after_a_faction_is_selected", func():
		var controls := MapControls.new()
		controls._ready()

		controls._select_faction("guild")

		var faction_row: Button = null
		for child in controls._list.get_children():
			if child is Button and String(child.text).begins_with("Faction"):
				faction_row = child
				break
		assert_true(faction_row != null, "the rebuilt drawer still has a Faction row after a pick")
		assert_true(not faction_row.disabled, "the Faction row must stay tappable so the picker (and Clear) can be reopened")

		controls.free()
	)

	run_case("clear_all_returns_to_the_previously_active_top_level_mode_with_no_faction_highlighted", func():
		var controls := MapControls.new()
		var canvas := MapCanvas.new()
		controls.map_canvas = canvas
		controls._ready()

		controls._select_filter("growth")
		controls._select_faction("network")
		assert_eq(controls._filter_mode, "faction")

		controls._clear_faction_filter()

		assert_eq(controls._filter_mode, "growth", "clear/all restores whatever top-level mode was active before Faction was entered")
		assert_eq(controls._selected_faction_id, "", "no faction stays highlighted after clearing")
		assert_eq(canvas.filter_mode, "growth")
		assert_eq(canvas.selected_faction_id, "")

		controls.free()
		canvas.free()
	)

	run_case("clear_all_falls_back_to_ownership_when_no_other_top_level_mode_was_ever_picked", func():
		var controls := MapControls.new()
		controls._ready()

		controls._select_faction("conclave")
		controls._clear_faction_filter()

		assert_eq(controls._filter_mode, "ownership", "Ownership is the documented default when nothing else was active first")

		controls.free()
	)

	# bugfixes-50: pacing is persisted now (MapEvents/GameState), unlike
	# filter_mode -- _ready() mirrors whatever map_canvas already read back
	# from state (see map_canvas.gd's own _ready()) into this drawer's label
	# state, so the drawer opens on the real current choice instead of always
	# showing the hardcoded default.
	run_case("ready_mirrors_map_canvas_persisted_pacing_into_the_drawer_label_state", func():
		GameState.reset()
		MapEvents.set_pacing_mode("sequential")

		var canvas := MapCanvas.new()
		canvas._ready()  # picks up "sequential" from GameState, same as a real Map screen visit

		var controls := MapControls.new()
		controls.map_canvas = canvas
		controls._ready()

		assert_eq(controls._pacing_mode, "sequential", "the drawer's own mirror matches whatever map_canvas already read back from state")

		controls.free()
		canvas.free()
	)

	run_case("dark_map_toggle_shows_the_saved_value_and_sets_it_through_preferences", func():
		GameState.reset()
		var controls := MapControls.new()
		controls._ready()

		var toggle := _dark_toggle(controls)
		assert_true(toggle != null, "the drawer has a Dark map toggle")
		assert_true(not toggle.button_pressed, "off by default")

		toggle.button_pressed = true  # fires toggled, as a tap would
		assert_true(MapPalette.is_dark(), "toggling on sets meta.mapDarkMode")

		controls._rebuild()
		assert_true(_dark_toggle(controls).button_pressed, "a rebuilt drawer shows the current value")

		controls.free()
		GameState.reset()
	)

	run_case("drawer_sits_between_the_top_board_and_the_nav_dock", func():
		GameState.reset()
		var controls := MapControls.new()
		controls._ready()

		assert_eq(controls._panel.offset_top, UI.top_bar_clearance(), "the drawer starts below the top board")
		assert_eq(controls._panel.offset_bottom, -NavBar.BAR_HEIGHT, "the drawer ends above the nav dock")

		controls.free()
	)

	run_case("map_top_row_starts_below_the_top_board", func():
		GameState.reset()
		var screen := MapScreen.new()
		screen._ready()

		var margin := screen._diagram_layer.get_child(0) as MarginContainer
		assert_true(margin.get_theme_constant("margin_top") >= UI.top_bar_clearance(), "the hamburger/title row clears the top board")

		screen.free()
		GameState.reset()
	)


func _dark_toggle(controls: MapControls) -> CheckButton:
	for child in controls._list.get_children():
		if child is CheckButton and not child.is_queued_for_deletion() and child.text == GameData.MAP_PALETTE["darkModeLabel"]:
			return child
	return null
