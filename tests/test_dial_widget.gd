extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")

# combat-presentation ticket 03, docs/combat-animation-vision.md §2.5: the
# Dial widget's own selection/trigger logic, tested independently of the
# round-fight screen's wiring (tests/test_combat_rounds.gd). Same "test the
# logic, not the gesture plumbing" split TurnOrderStrip's own tests use -- handle_select/
# handle_trigger are public exactly so these cases don't have to simulate
# InputEvents.
#
# combat-presentation ticket 18 (human direction, 2026-09-09): handle_rotate()
# (relative, wrapping cycle) is replaced by handle_select(index) (direct,
# tap-one-of-4-screws selection) -- see dial_widget.gd's own top comment.

func run() -> void:
	# ui-chrome-pass ticket 03: the confirmed-by-screenshot bug this ticket
	# fixes was WIDGET_SIZE (formerly VISIBLE_BOX_SIZE) being smaller than the
	# rendered art, cropping it down to a small headshot -- guard that it
	# never regresses back to a box narrower/shorter than the render it's
	# meant to fully contain, and that the four screw hit-targets (which used
	# to sit right at the crop's own edge) all land safely inside the box.
	run_case("widget_size_fully_contains_the_rendered_umbrella_with_no_cropping", func():
		# ticket 108: WIDGET_SIZE.x is checked against RENDERED_WIDTH, not
		# HANDLE_DISPLAY_SIZE -- this widget now deliberately crops the source
		# texture's own blank native margin (CROP_NATIVE_X's own comment), so
		# HANDLE_DISPLAY_SIZE (a full 500-native-unit span) is no longer the
		# rendered width. RENDERED_WIDTH is what actually gets drawn on
		# screen, and the box must still fully contain THAT without cropping.
		assert_true(DialWidget.WIDGET_SIZE.x >= DialWidget.RENDERED_WIDTH, "the box must be at least as wide as the rendered (cropped) art -- narrower crops the sides off again")
		assert_true(DialWidget.WIDGET_SIZE.y >= DialWidget.HANDLE_DISPLAY_SIZE, "the box must be at least as tall as the rendered art -- shorter crops the top/bottom off again")

		var widget := DialWidget.new()
		widget.configure(Fixtures.dial(["blast", "shield", "blackHole", "healingBurst"]), 0, Callable())

		# The whole HIT RECT (not just the dot's own centre point) must sit
		# inside the box -- code-review finding, 2026-09-11: the topmost
		# screw's centre alone can pass this check while its tap-rect still
		# pokes out past y=0 (unreachable there -- _gui_input() only ever
		# sees positive local coordinates), silently shrinking that screw's
		# real tap target. See TOP_PADDING's own comment for the fix this
		# guards against regressing.
		for i in range(DialWidget.MAX_DOTS):
			var rect: Rect2 = widget._dot_rect(i)
			assert_true(rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= DialWidget.WIDGET_SIZE.x and rect.end.y <= DialWidget.WIDGET_SIZE.y, "screw %d's whole tap-rect must land inside the widget's own box, not just its centre -- got %s, box %s" % [i, rect, DialWidget.WIDGET_SIZE])

		var button_rect: Rect2 = widget._button_rect()
		assert_true(button_rect.position.x >= 0.0 and button_rect.position.y >= 0.0 and button_rect.end.x <= DialWidget.WIDGET_SIZE.x and button_rect.end.y <= DialWidget.WIDGET_SIZE.y, "the trigger switch's whole tap-rect must land inside the widget's own box too")
	)

	run_case("configure_clamps_a_stale_selected_index_to_the_current_list_size", func():
		var widget := DialWidget.new()
		widget.configure(Fixtures.dial(["blast"]), 5, Callable())

		assert_eq(widget.current_index(), 0, "only one Complication is loaded -- a stale index 5 must clamp down")
	)

	run_case("handle_select_reports_the_tapped_index_via_the_callback", func():
		var widget := DialWidget.new()
		var received: Array = []
		widget.configure(Fixtures.dial(["blast", "shield", "blackHole"]), 0, func(i): received.append(i))

		widget.handle_select(2)

		assert_eq(received, [2])
		assert_eq(widget.current_index(), 0, "handle_select() only reports through the callback -- like TurnOrderStrip.handle_tap(), it never mutates its own selection; the caller (CombatCommandDock) owns persisting it via a fresh configure()")
	)

	run_case("handle_select_reports_regardless_of_which_screw_it_is_relative_to_the_current_one", func():
		var widget := DialWidget.new()
		var received: Array = []
		widget.configure(Fixtures.dial(["blast", "shield", "blackHole"]), 2, func(i): received.append(i))

		widget.handle_select(0)

		assert_eq(received, [0], "a direct tap jumps straight to whichever screw was tapped, not a relative step")
	)

	run_case("handle_select_is_a_no_op_past_the_end_of_the_loaded_list", func():
		var widget := DialWidget.new()
		var received: Array = []
		widget.configure(Fixtures.dial(["blast"]), 0, func(i): received.append(i))

		widget.handle_select(1)

		assert_eq(widget.current_index(), 0)
		assert_eq(received.size(), 0, "nothing loaded into that screw -- the callback should not fire")
	)

	run_case("handle_select_is_a_no_op_for_a_negative_index", func():
		var widget := DialWidget.new()
		var received: Array = []
		widget.configure(Fixtures.dial(["blast", "shield"]), 0, func(i): received.append(i))

		widget.handle_select(-1)

		assert_eq(received.size(), 0)
	)

	run_case("handle_trigger_hands_the_selected_index_to_on_cast", func():
		GameState.reset()
		GameState.state["player"]["dial"] = Fixtures.dial(["blast", "shield"], 3, 5)
		var cast: Array = []
		var widget := DialWidget.new()
		widget.configure(GameState.state["player"]["dial"], 1, Callable(), func(i): cast.append(i))
		widget.handle_trigger()
		assert_eq(cast, [1], "the selected index")
		assert_eq(GameState.state["player"]["dial"]["currentCharge"], 3, "the widget spends nothing itself")
		widget.free()
	)
