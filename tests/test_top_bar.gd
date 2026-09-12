extends "res://tests/test_base.gd"

# field-kit-chrome ticket 02 (docs/ui-vision.md §5): no test file existed
# for TopBar before this ticket. TopBar.new()/_ready() is safe to call
# directly without adding it to a live scene tree, same reasoning
# tests/test_bag_drawer.gd/test_map_controls.gd already rely on for
# BagDrawer/MapControls.


func run() -> void:
	run_case("the_status_line_reports_day_time_block_progress_and_cash", func():
		GameState.reset()
		GameState.state["world"]["day"] = 3
		GameState.state["world"]["timeBlock"] = 1
		GameState.state["world"]["timeBlocksDone"] = ["morning"]
		GameState.state["player"]["cash"] = 240

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._status_line_text(), "D3 AFT £240")

		bar.free()
	)

	run_case("the_status_board_reserves_the_bag_buttons_footprint_and_the_status_text_fits_before_it", func():
		GameState.reset()
		# A generous but realistic worst case (3-digit day, 5-digit cash) --
		# bugfixes ticket 01's fix is the compact format buying back width,
		# not the reserved-right clip alone, so this asserts the text
		# actually fits rather than relying on truncation.
		GameState.state["world"]["day"] = 150
		GameState.state["world"]["timeBlock"] = 1
		GameState.state["player"]["cash"] = 99999

		var bar := TopBar.new()
		bar._ready()

		assert_eq(bar._board.reserved_right, UI.ICON_BUTTON_SIZE + TopBar._SIDE_MARGIN * 2.0, "the bag button's own footprint is kept clear of status text")

		var viewport_width := 390.0
		var text_width: float = DotMatrixFont.text_width(bar._status_line_text(), TopBar.STATUS_DOT_SIZE, DotMatrixBoard.CHAR_GAP)
		assert_true(DotMatrixBoard.SIDE_PADDING + text_width <= viewport_width - bar._board.reserved_right, "the full status string fits before the reserved bag-button zone on a 390-wide viewport")

		bar.free()
	)

	run_case("the_status_board_updates_on_state_changed", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 10

		var bar := TopBar.new()
		bar._ready()
		assert_eq(bar._board.target_text(), bar._status_line_text().to_upper())

		GameState.state["player"]["cash"] = 500
		EventBus.state_changed.emit()

		assert_eq(bar._board.target_text(), bar._status_line_text().to_upper(), "the board redraws with the new cash figure")
		assert_true(bar._board.target_text().find("500") != -1)

		bar.free()
	)

	run_case("safe_area_offsets_are_reapplied_on_every_refresh_not_just_ready", func():
		# Bugfixes ticket [pending]: TopBar used to compute offset_top/
		# offset_bottom exactly once, in _ready() -- since it's built once for
		# the whole app session (Main.gd), any drift in what
		# UI.safe_area_top_inset()/top_bar_clearance() reports after that
		# first call (seen on-device: the bar sitting too low, and
		# NotificationToast's rows -- which DO re-derive the same value on
		# every refresh -- overlapping up into it) never got corrected. This
		# guards the fix: _refresh() (wired to EventBus.state_changed, same
		# as NotificationToast's own) must re-apply both offsets every time,
		# not just leave whatever _ready() set.
		GameState.reset()

		var bar := TopBar.new()
		bar._ready()
		assert_eq(bar.offset_top, UI.safe_area_top_inset())
		assert_eq(bar.offset_bottom, UI.top_bar_clearance())

		# Simulate the offsets having drifted stale (e.g. a safe-area value
		# that changed after _ready() ran) -- a real _refresh() must stomp
		# these back to the current UI.* values, not leave them alone.
		bar.offset_top = 999.0
		bar.offset_bottom = 999.0
		EventBus.state_changed.emit()

		assert_eq(bar.offset_top, UI.safe_area_top_inset(), "offset_top is re-derived on every refresh, same as NotificationToast")
		assert_eq(bar.offset_bottom, UI.top_bar_clearance(), "offset_bottom is re-derived on every refresh, same as NotificationToast")

		bar.free()
	)

	run_case("the_bag_button_opens_the_bag_and_never_navigates", func():
		GameState.reset()

		var bar := TopBar.new()
		bar._ready()

		assert_eq(GameState.state["bagDrawerOpen"], false, "sanity: starts closed")

		var got_screen_change := [false]
		var on_screen_changed := func(_screen): got_screen_change[0] = true
		EventBus.screen_changed.connect(on_screen_changed)
		bar._bag_button.pressed.emit()
		EventBus.screen_changed.disconnect(on_screen_changed)

		assert_eq(GameState.state["bagDrawerOpen"], true, "tapping the bag button opens the drawer")
		assert_true(not got_screen_change[0], "opening the bag never navigates")

		bar.free()
	)

	run_case("the_bag_icon_renders_the_boards_lit_amber_not_the_theme_default", func():
		# Bugfixes ticket 101: the icon rendered near-black against the
		# board's black background because the old fix -- an
		# add_theme_color_override("font_color", ...) set on _bag_button --
		# never reached the drawn glyph, a separate child _IconGlyph Control
		# (Godot 4 theme overrides don't cascade to children). Guards that
		# the glyph itself now carries the board's lit amber directly.
		GameState.reset()

		var bar := TopBar.new()
		bar._ready()

		var glyph: Control = bar._bag_button.get_child(0)
		assert_eq(glyph.colour_override, DotMatrixBoard.LIT_COLOR, "the bag icon glyph is forced to the board's lit amber")

		bar.free()
	)
