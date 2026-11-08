extends "res://tests/test_base.gd"

const WIDTH := 300.0
const TOP := 50


func run() -> void:
	run_case("cutoff_drag_commits_once_on_release", func():
		var bar := _bar(-1, 10)
		var commits: Array = []
		bar.cutoff_committed.connect(func(cutoff: int): commits.append(cutoff))
		_mouse(bar, true, bar._value_x(10) + 2.0)
		_move(bar, bar._value_x(30) + 2.0)
		assert_eq(bar.cutoff, 30)
		assert_eq(commits, [], "no commit mid-drag")
		_move(bar, 0.0)
		assert_eq(bar.cutoff, 0, "runs the full bar to Sell all")
		_move(bar, WIDTH)
		assert_eq(bar.cutoff, TOP)
		_mouse(bar, false, WIDTH)
		assert_eq(commits, [TOP])
		bar.free()
	)

	run_case("make_to_is_a_read_only_tick_by_default", func():
		var bar := _bar(20, 30)
		assert_true(not bar.make_to_editable)
		var commits: Array = []
		bar.make_to_committed.connect(func(v: int): commits.append(v))
		_mouse(bar, true, bar._value_x(20))
		_move(bar, bar._value_x(5))
		_mouse(bar, false, bar._value_x(5))
		assert_eq(bar.make_to, 20, "tick never moves")
		assert_eq(bar.cutoff, 5, "the press went to the Sell-above handle instead")
		assert_eq(commits, [])
		bar.free()
	)

	run_case("editable_make_to_and_cutoff_drag_independently_and_may_cross", func():
		var bar := _bar(10, 20, true)
		var makes: Array = []
		var cutoffs: Array = []
		bar.make_to_committed.connect(func(v: int): makes.append(v))
		bar.cutoff_committed.connect(func(v: int): cutoffs.append(v))
		_mouse(bar, true, bar._value_x(10))
		_move(bar, bar._value_x(35))
		assert_eq([bar.make_to, bar.cutoff], [35, 20], "Make to passes Sell above, nothing is pushed")
		_mouse(bar, false, bar._value_x(35))
		assert_eq(makes, [35])
		_mouse(bar, true, bar._value_x(20))
		_move(bar, bar._value_x(5))
		assert_eq([bar.make_to, bar.cutoff], [35, 5])
		_mouse(bar, false, bar._value_x(5))
		assert_eq(cutoffs, [5])
		bar.free()
	)

	run_case("a_press_grabs_the_nearest_handle_and_splits_a_tie_by_side", func():
		var bar := _bar(10, 40, true)
		assert_eq(bar._pick_handle(bar._value_x(12)), StockBar.Handle.MAKE)
		assert_eq(bar._pick_handle(bar._value_x(38)), StockBar.Handle.CUTOFF)
		for value in [0, 25, TOP]:
			var same := _bar(value, value, true)
			var x := same._value_x(value)
			assert_eq(same._pick_handle(x - 3.0), StockBar.Handle.MAKE, "left of the pair at %d" % value)
			assert_eq(same._pick_handle(x + 3.0), StockBar.Handle.CUTOFF, "right of the pair at %d" % value)
			same.free()
		bar.free()
	)

	run_case("a_press_with_no_movement_commits_nothing", func():
		var bar := _bar(10, 20, true)
		var commits: Array = []
		bar.make_to_committed.connect(func(v: int): commits.append(v))
		bar.cutoff_committed.connect(func(v: int): commits.append(v))
		_mouse(bar, true, bar._value_x(20) + 5.0)
		_mouse(bar, false, bar._value_x(20) + 5.0)
		assert_eq(commits, [])
		assert_eq([bar.make_to, bar.cutoff], [10, 20], "grabbing off-centre doesn't jump the handle")
		bar.free()
	)

	run_case("locked_cutoff_never_grabs_and_a_fully_locked_bar_grabs_nothing", func():
		var bar := _bar(10, 20, true)
		bar.cutoff_locked = true
		assert_eq(bar._pick_handle(bar._value_x(20)), StockBar.Handle.MAKE, "only Make to still moves")
		bar.make_to_editable = false
		assert_eq(bar._pick_handle(bar._value_x(20)), StockBar.Handle.NONE)
		_mouse(bar, true, bar._value_x(20))
		_move(bar, bar._value_x(40))
		_mouse(bar, false, bar._value_x(40))
		assert_eq([bar.make_to, bar.cutoff], [10, 20])
		bar.free()
	)

	run_case("no_make_to_hides_the_marker_and_negative_stock_hides_the_tick", func():
		var bar := _bar(-1, 20)
		assert_eq(bar.make_to, -1)
		assert_true(not bar.make_to_editable, "nothing to edit without a Make-to value")
		bar.configure(TOP, -1, 20, 20, -1, false)
		assert_eq(bar.stock, -1, "a negative stock draws no tick")
		bar.free()
	)

	run_case("pip_names_the_cutoff_and_words_both_ends_of_the_bar", func():
		var bar := _bar(-1, 10)
		assert_eq(bar.pip_text(), "10")
		_mouse(bar, true, bar._value_x(10) + 2.0)
		_move(bar, 0.0)
		assert_eq(bar.pip_text(), StockBar.SELL_ALL_TEXT, "follows the drag to the left end")
		_move(bar, WIDTH)
		assert_eq(bar.pip_text(), StockBar.SELL_NONE_TEXT, "and to the right end")
		bar.free()
	)

	run_case("the_pip_row_sits_above_the_bar", func():
		var bar := _bar(-1, 10)
		assert_eq(bar.custom_minimum_size.y, StockBar.PIP_HEIGHT + StockBar.BAR_HEIGHT)
		bar.free()
	)


func _bar(make_to: int, cutoff: int, editable: bool = false) -> StockBar:
	var bar := StockBar.new()
	bar.configure(TOP, make_to, cutoff, cutoff, 0, false, editable)
	bar.size = Vector2(WIDTH, StockBar.BAR_HEIGHT)
	return bar


func _mouse(bar: StockBar, pressed: bool, x: float) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = Vector2(x, StockBar.BAR_HEIGHT / 2.0)
	bar._gui_input(event)


func _move(bar: StockBar, x: float) -> void:
	var event := InputEventMouseMotion.new()
	event.position = Vector2(x, StockBar.BAR_HEIGHT / 2.0)
	bar._gui_input(event)
