extends "res://tests/test_base.gd"


func run() -> void:
	run_case("go_to_sets_current_screen_and_emits", func():
		GameState.reset()
		# Array, not a plain var: GDScript lambdas capture outer locals by
		# value (see test_eventbus.gd's matching comment), so a plain var
		# assigned inside the lambda would never be visible out here.
		var received := [""]
		var on_screen := func(screen: String): received[0] = screen
		EventBus.screen_changed.connect(on_screen)
		Nav.go_to("veins")
		EventBus.screen_changed.disconnect(on_screen)

		assert_eq(GameState.state["currentScreen"], "veins", "currentScreen should update")
		assert_eq(received[0], "veins", "screen_changed should carry the new screen id")
	)
