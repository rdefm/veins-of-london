extends "res://tests/test_base.gd"

# state_changed and notification_pushed are exercised via systems/notify.gd
# in test_notify.gd; this covers the two signals that carry a payload.


func run() -> void:
	run_case("screen_changed_carries_the_screen_name", func():
		# Capture a single-element array, not a plain var: GDScript lambdas
		# capture outer locals by value, so `received = screen` inside the
		# lambda would rebind only the lambda's own private copy. Mutating
		# an array element works because the array itself is captured by
		# reference to the same object.
		var received := [""]
		var on_screen := func(screen: String): received[0] = screen
		EventBus.screen_changed.connect(on_screen)
		EventBus.screen_changed.emit("veins")
		EventBus.screen_changed.disconnect(on_screen)
		assert_eq(received[0], "veins", "screen_changed should pass the screen id through")
	)

	run_case("day_ticked_carries_the_day_number", func():
		var received := [-1]
		var on_day := func(day: int): received[0] = day
		EventBus.day_ticked.connect(on_day)
		EventBus.day_ticked.emit(4)
		EventBus.day_ticked.disconnect(on_day)
		assert_eq(received[0], 4, "day_ticked should pass the new day through")
	)
