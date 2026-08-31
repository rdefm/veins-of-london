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


func run() -> void:
	run_case("renders_a_plus_and_a_minus_button", func():
		var buttons := MapZoomButtons.new()
		buttons.map_canvas = MapCanvas.new()
		buttons._ready()

		assert_eq(buttons._zoom_in_button.text, "+")
		assert_eq(buttons._zoom_out_button.text, "-")

		buttons.map_canvas.free()
		buttons.free()
	)

	run_case("pressing_plus_steps_the_canvas_zoom_in", func():
		var buttons := MapZoomButtons.new()
		buttons.map_canvas = MapCanvas.new()
		buttons.map_canvas.zoom_level = 1.0
		buttons._ready()

		buttons._zoom_in_button.pressed.emit()

		assert_true(buttons.map_canvas._active_tween != null, "pressing + must reach MapCanvas.step_zoom(), which kicks off pan_to()'s tween")

		buttons.map_canvas.free()
		buttons.free()
	)

	run_case("pressing_minus_steps_the_canvas_zoom_out", func():
		var buttons := MapZoomButtons.new()
		buttons.map_canvas = MapCanvas.new()
		buttons.map_canvas.zoom_level = 1.0
		buttons._ready()

		buttons._zoom_out_button.pressed.emit()

		assert_true(buttons.map_canvas._active_tween != null, "pressing - must reach MapCanvas.step_zoom(), which kicks off pan_to()'s tween")

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

	# Bugfixes ticket 99: the zoom-in "+" glyph used to render invisible --
	# root cause was this file's own custom_minimum_size = BUTTON_SIZE flatly
	# overwriting the width UI.button() had already computed to fit "+"
	# without clipping (10px glyph + the Button theme's 32px of content
	# margin = 42px needed; BUTTON_SIZE.x is only 40px, so clip_text's
	# OVERRUN_TRIM_ELLIPSIS silently trimmed it to nothing -- "-" only needs
	# 38px, which is why it stayed visible on an identically-styled button).
	# The fix takes the component-wise max instead of overwriting, so this
	# builds an independent reference button the same way UI.button() itself
	# would and asserts neither zoom button was ever shrunk narrower than
	# that reference -- this must fail under the old flat-overwrite code
	# (40 < 42 for "+") to be trusted as a real regression guard.
	run_case("neither_zoom_button_is_shrunk_narrower_than_its_own_glyph_needs_to_avoid_clipping", func():
		var reference_plus := UI.button("+", func(): pass)
		var reference_minus := UI.button("-", func(): pass)

		var buttons := MapZoomButtons.new()
		buttons.map_canvas = MapCanvas.new()
		buttons._ready()

		assert_true(buttons._zoom_in_button.custom_minimum_size.x >= reference_plus.custom_minimum_size.x, "the + button must be at least as wide as UI.button() itself computed for its own glyph, or clip_text clips it away")
		assert_true(buttons._zoom_out_button.custom_minimum_size.x >= reference_minus.custom_minimum_size.x, "the - button must be at least as wide as UI.button() itself computed for its own glyph")
		assert_true(buttons._zoom_in_button.custom_minimum_size.x >= MapZoomButtons.BUTTON_SIZE.x, "still at least the floating control's own square touch-target floor")
		assert_true(buttons._zoom_out_button.custom_minimum_size.x >= MapZoomButtons.BUTTON_SIZE.x, "still at least the floating control's own square touch-target floor")

		reference_plus.free()
		reference_minus.free()
		buttons.map_canvas.free()
		buttons.free()
	)
