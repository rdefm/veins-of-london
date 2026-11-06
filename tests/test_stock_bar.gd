extends "res://tests/test_base.gd"

const WIDTH := 300.0
const TOP := 50


func run() -> void:
	run_case("keep_drag_fills_rightward_and_commits_once_on_release", func():
		var bar := _bar(0, TOP)
		var commits: Array = []
		bar.keep_committed.connect(func(keep: int): commits.append(keep))
		_mouse(bar, true, bar._value_x(0) - 2.0)
		_move(bar, bar._value_x(20) - 2.0)
		assert_eq(bar.keep, 20)
		assert_eq(commits, [], "no commit mid-drag")
		_mouse(bar, false, bar._value_x(20) - 2.0)
		assert_eq(commits, [20])
		bar.free()
	)

	run_case("cutoff_drag_moves_left_and_stops_at_keep", func():
		var bar := _bar(10, TOP)
		var commits: Array = []
		bar.cutoff_committed.connect(func(cutoff: int): commits.append(cutoff))
		_mouse(bar, true, bar._value_x(TOP) + 2.0)
		_move(bar, bar._value_x(30) + 2.0)
		assert_eq(bar.cutoff, 30)
		_move(bar, 0.0)
		assert_eq(bar.cutoff, 10, "can't pass Keep")
		_mouse(bar, false, 0.0)
		assert_eq(commits, [10])
		bar.free()
	)

	run_case("keep_pushes_the_cutoff_then_returns_it_if_dragged_back", func():
		var bar := _bar(10, 20)
		_mouse(bar, true, bar._value_x(10) - 2.0)
		_move(bar, bar._value_x(35) - 2.0)
		assert_eq([bar.keep, bar.cutoff], [35, 35], "pushed along")
		_move(bar, bar._value_x(15) - 2.0)
		assert_eq([bar.keep, bar.cutoff], [15, 20], "the push isn't final until release")
		bar.free()
	)

	run_case("a_press_with_no_movement_commits_nothing", func():
		var bar := _bar(10, 20)
		var commits: Array = []
		bar.keep_committed.connect(func(keep: int): commits.append(keep))
		bar.cutoff_committed.connect(func(cutoff: int): commits.append(cutoff))
		_mouse(bar, true, bar._value_x(10) - 5.0)
		_mouse(bar, false, bar._value_x(10) - 5.0)
		assert_eq(commits, [])
		assert_eq([bar.keep, bar.cutoff], [10, 20], "grabbing off-centre doesn't jump the handle")
		bar.free()
	)

	run_case("handles_at_the_same_value_stay_separately_grabbable", func():
		for value in [0, 25, TOP]:
			var bar := _bar(value, value)
			var keep_rect: Rect2 = bar._handle_rect(StockBar.Handle.KEEP)
			var cutoff_rect: Rect2 = bar._handle_rect(StockBar.Handle.CUTOFF)
			assert_true(not keep_rect.intersects(cutoff_rect), "side by side at %d" % value)
			assert_eq(keep_rect.size.x, StockBar.HANDLE_WIDTH)
			assert_true(keep_rect.position.x >= 0.0 and cutoff_rect.end.x <= WIDTH, "both on the bar at %d" % value)
			assert_eq(bar._pick_handle(keep_rect.get_center().x), StockBar.Handle.KEEP)
			assert_eq(bar._pick_handle(cutoff_rect.get_center().x), StockBar.Handle.CUTOFF)
			bar.free()
	)

	run_case("locked_cutoff_never_grabs_but_keep_still_pushes_it", func():
		var bar := _bar(10, 20)
		bar.cutoff_locked = true
		assert_eq(bar._pick_handle(bar._value_x(20) + 2.0), StockBar.Handle.KEEP)
		_mouse(bar, true, bar._value_x(10) - 2.0)
		_move(bar, bar._value_x(30) - 2.0)
		assert_eq([bar.keep, bar.cutoff], [30, 30])
		bar.free()
	)

	run_case("a_stored_cutoff_under_keep_shows_at_keep", func():
		var bar := _bar(20, 5)
		assert_eq(bar.cutoff, 20)
		bar.free()
	)


func _bar(keep: int, cutoff: int) -> StockBar:
	var bar := StockBar.new()
	bar.configure(TOP, keep, cutoff, keep, 0, false)
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
