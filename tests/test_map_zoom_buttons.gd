extends "res://tests/test_base.gd"

# Bugfixes ticket 89: the floating +/- zoom control over the Network
# diagram. MapZoomButtons.new() is safe to call _ready() on directly
# without adding it to a live scene tree -- same reasoning tests/
# test_map_legend.gd/test_map_controls.gd rely on for their own components:
# nothing _ready() touches (UI.*, PanelContainer/VBoxContainer/Button
# construction, reading map_canvas.zoom_level) depends on get_tree()/
# get_viewport() having run. map_canvas is a real MapCanvas.new() (also
# never added to a tree), same "assign then add" idiom map.gd itself uses
# (see map_zoom_buttons.gd's own class comment) -- pressing a button below
# calls straight through to MapCanvas.step_zoom(), whose own Node/Tween
# side is covered directly in tests/test_map_canvas.gd, not re-asserted
# here; what this file covers is that a press reaches step_zoom() at all,
# and that the buttons' own disabled state tracks zoom_level correctly.


class ZoomSpyCanvas extends MapCanvas:
	var requested_directions: Array[int] = []

	func step_zoom(direction: int) -> void:
		requested_directions.append(direction)


func run() -> void:
	run_case("renders_minus_then_plus_in_one_horizontal_pill", func():
		var buttons := MapZoomButtons.new()
		buttons.map_canvas = MapCanvas.new()
		buttons._ready()

		assert_true(buttons._box is HBoxContainer, "the two controls share one horizontal row")
		assert_eq(buttons._zoom_out_button.get_index(), 0, "minus is the left half")
		assert_eq(buttons._zoom_in_button.get_index(), 2, "plus follows the internal divider")
		assert_eq(buttons._zoom_out_button.text, "−")
		assert_eq(buttons._zoom_in_button.text, "+")
		assert_eq(buttons._zoom_out_button.get_parent(), buttons._zoom_in_button.get_parent(), "both halves belong to the same pill")

		buttons.map_canvas.free()
		buttons.free()
	)

	run_case("pill_uses_cream_charcoal_material_without_action_orange", func():
		var buttons := MapZoomButtons.new()
		buttons.map_canvas = MapCanvas.new()
		buttons._ready()

		var pill_style := buttons._pill.get_theme_stylebox("panel") as StyleBoxFlat
		var minus_style := buttons._zoom_out_button.get_theme_stylebox("normal") as StyleBoxFlat
		assert_eq(pill_style.bg_color, MapZoomButtons.CREAM)
		assert_eq(pill_style.border_color, MapZoomButtons.BORDER)
		assert_true(pill_style.shadow_size > 0, "cream surface has the requested subtle shadow")
		assert_eq(buttons._zoom_out_button.get_theme_color("font_color"), MapZoomButtons.CHARCOAL)
		assert_eq(buttons._zoom_in_button.get_theme_color("font_color"), MapZoomButtons.CHARCOAL)
		assert_eq(minus_style.bg_color, Color.TRANSPARENT, "normal halves do not inherit the global orange button fill")

		buttons.map_canvas.free()
		buttons.free()
	)

	run_case("pressing_plus_steps_the_canvas_zoom_in", func():
		var buttons := MapZoomButtons.new()
		buttons.map_canvas = ZoomSpyCanvas.new()
		buttons.map_canvas.zoom_level = 1.0
		buttons._ready()

		buttons._zoom_in_button.pressed.emit()

		assert_eq((buttons.map_canvas as ZoomSpyCanvas).requested_directions, [1], "plus must dispatch exactly +1")

		buttons.map_canvas.free()
		buttons.free()
	)

	run_case("pressing_minus_steps_the_canvas_zoom_out", func():
		var buttons := MapZoomButtons.new()
		buttons.map_canvas = ZoomSpyCanvas.new()
		buttons.map_canvas.zoom_level = 1.0
		buttons._ready()

		buttons._zoom_out_button.pressed.emit()

		assert_eq((buttons.map_canvas as ZoomSpyCanvas).requested_directions, [-1], "minus must dispatch exactly -1")

		buttons.map_canvas.free()
		buttons.free()
	)

	run_case("both_buttons_enabled_at_a_mid_range_zoom", func():
		var buttons := MapZoomButtons.new()
		buttons.map_canvas = MapCanvas.new()
		buttons.map_canvas.zoom_level = 1.0
		buttons._ready()

		assert_true(not buttons._zoom_in_button.disabled)
		assert_true(not buttons._zoom_out_button.disabled)

		buttons.map_canvas.free()
		buttons.free()
	)

	run_case("zoom_in_button_disables_at_max", func():
		var buttons := MapZoomButtons.new()
		buttons.map_canvas = MapCanvas.new()
		buttons.map_canvas.zoom_level = MapZoom.MAX
		buttons._ready()

		assert_true(buttons._zoom_in_button.disabled, "already at MAX -- + must not offer to zoom in further")
		assert_true(not buttons._zoom_out_button.disabled, "- is still valid at MAX")

		buttons.map_canvas.free()
		buttons.free()
	)

	run_case("zoom_out_button_disables_at_min", func():
		var buttons := MapZoomButtons.new()
		buttons.map_canvas = MapCanvas.new()
		buttons.map_canvas.zoom_level = MapZoom.MIN
		buttons._ready()

		assert_true(buttons._zoom_out_button.disabled, "already at MIN -- - must not offer to zoom out further")
		assert_true(not buttons._zoom_in_button.disabled, "+ is still valid at MIN")

		buttons.map_canvas.free()
		buttons.free()
	)

	# Bugfixes ticket 89: disabled state must track zoom_level live, not just
	# whatever it was at _ready() -- the other button can move zoom_level to a
	# bound after these buttons already exist. zoom_changed
	# is MapCanvas's own signal for this (see its class comment); emitting
	# it directly is enough to prove the connection without needing a real
	# Tween to actually run.
	run_case("disabled_state_updates_when_map_canvas_reports_a_zoom_change", func():
		var buttons := MapZoomButtons.new()
		buttons.map_canvas = MapCanvas.new()
		buttons.map_canvas.zoom_level = 1.0
		buttons._ready()

		assert_true(not buttons._zoom_in_button.disabled, "sanity: starts enabled at a mid-range zoom")

		buttons.map_canvas.zoom_level = MapZoom.MAX
		buttons.map_canvas.zoom_changed.emit(MapZoom.MAX)

		assert_true(buttons._zoom_in_button.disabled, "+ must disable once map_canvas reports it has reached MAX")

		buttons.map_canvas.free()
		buttons.free()
	)

	run_case("box_shrink_wraps_to_its_content_instead_of_collapsing_to_zero_size", func():
		var buttons := MapZoomButtons.new()
		buttons.map_canvas = MapCanvas.new()
		buttons._ready()

		assert_true(buttons._box.size.x > 0.0, "must have real width to be visible/tappable")
		assert_true(buttons._box.size.y > 0.0, "must have real height to be visible/tappable")

		buttons.map_canvas.free()
		buttons.free()
	)

	run_case("each_half_keeps_a_full_touch_target_and_visible_glyph", func():
		var buttons := MapZoomButtons.new()
		buttons.map_canvas = MapCanvas.new()
		buttons._ready()

		for button in [buttons._zoom_out_button, buttons._zoom_in_button]:
			assert_true(button.custom_minimum_size.x >= UI.ICON_BUTTON_SIZE, "each half is wide enough to tap")
			assert_true(button.custom_minimum_size.y >= UI.ICON_BUTTON_SIZE, "each half is tall enough to tap")
			assert_true(not button.clip_text, "glyphs must not be clipped")
			assert_true(button.text.length() > 0, "each half retains a visible glyph")

		buttons.map_canvas.free()
		buttons.free()
	)
