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
