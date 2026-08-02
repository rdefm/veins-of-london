extends "res://tests/test_base.gd"

# D4.4's global bag drawer toggle. Mirrors test_modal.gd's shape.


func run() -> void:
	run_case("open_sets_bagDrawerOpen_and_emits", func():
		GameState.reset()
		var received := [false]
		var on_change := func(): received[0] = true
		EventBus.state_changed.connect(on_change)
		Bag.open()
		EventBus.state_changed.disconnect(on_change)

		assert_eq(GameState.state["bagDrawerOpen"], true, "bagDrawerOpen set")
		assert_true(received[0], "state_changed should fire")
	)

	run_case("close_clears_bagDrawerOpen", func():
		GameState.reset()
		Bag.open()
		Bag.close()
		assert_eq(GameState.state["bagDrawerOpen"], false, "bagDrawerOpen cleared")
	)

	run_case("new_game_state_starts_closed", func():
		GameState.reset()
		assert_eq(GameState.state["bagDrawerOpen"], false, "closed by default")
	)
