extends "res://tests/test_base.gd"

# MapView — state.mapView persistence (53-map-auto-focus-and-zoom-
# persistence): whether the Network map has ever been opened before, plus
# the zoom/scroll MapCanvas last left it at.


func run() -> void:
	run_case("fresh_game_state_has_not_opened_the_map_yet", func():
		GameState.reset()
		assert_true(not MapView.has_opened_before(), "a brand-new save has never had its map opened")
		assert_almost_eq(MapView.zoom(), MapZoom.DEFAULT, 0.0001, "unopened default zoom is MapZoom.DEFAULT")
		assert_eq(MapView.scroll(), Vector2.ZERO, "unopened default scroll is the origin")
	)

	run_case("mark_opened_flips_has_opened_before", func():
		GameState.reset()
		MapView.mark_opened()
		assert_true(MapView.has_opened_before(), "mark_opened() should persist -- no later visit should re-trigger auto-focus")
	)

	run_case("save_view_persists_zoom_and_scroll_as_ints", func():
		GameState.reset()
		MapView.save_view(1.2, Vector2(345.0, 678.0))

		assert_almost_eq(MapView.zoom(), 1.2, 0.0001, "zoom should read back exactly what was saved")
		assert_eq(MapView.scroll(), Vector2(345, 678), "scroll should read back exactly what was saved")
		assert_eq(typeof(GameState.state["mapView"]["scrollX"]), TYPE_INT, "scrollX is stored as an int -- ScrollContainer.scroll_horizontal is int-typed")
		assert_eq(typeof(GameState.state["mapView"]["scrollY"]), TYPE_INT, "scrollY is stored as an int, same reason")
	)

	run_case("save_view_does_not_touch_everOpened", func():
		GameState.reset()
		MapView.mark_opened()
		MapView.save_view(0.9, Vector2(10, 10))
		assert_true(MapView.has_opened_before(), "persisting a camera position mid-visit must not un-mark first-open")
	)
