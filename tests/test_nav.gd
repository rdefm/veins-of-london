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
		Nav.go_to("hq")
		EventBus.screen_changed.disconnect(on_screen)

		assert_eq(GameState.state["currentScreen"], "hq", "currentScreen should update")
		assert_eq(received[0], "hq", "screen_changed should carry the new screen id")
	)

	# 81-map-stuck-playback-flag: go_to() is now the earliest point that
	# clears a still-"playing" MapEvents queue, covering navigation-away-from-
	# "map" interruptions that fire synchronously mid-tween — e.g. DistrictDeck.
	# maybe_trigger() calling Events.start_event() -> go_to("event") as the very
	# last step of the same Sites.prospect()/attempt_seed() call that just
	# queued the animation still "playing" (see systems/map_events.gd's
	# abandon_playback() doc comment). Simulated here at the pure MapEvents
	# layer, same "Node/Tween playback isn't exercised headlessly" split
	# tests/test_map_events.gd's own abandon_playback cases already use — there's
	# no live MapCanvas in this test to have actually started the coroutine, but
	# MapEvents.begin_playback() sets the exact same "playing" state one would
	# have been left mid-tween.
	run_case("go_to_abandons_a_still_playing_map_animation_queue", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")
		MapEvents.queue_discover("camden", "s2")
		MapEvents.begin_playback()

		Nav.go_to("event")

		assert_true(not MapEvents.is_playing(), "leaving map mid-tween via go_to() should clear the guard immediately, not wait on MapCanvas's own deferred teardown")
		assert_eq(MapEvents.pending_site_ids(), ["s2"], "the interrupted event (s1) is consumed, same as abandon_playback() from _exit_tree; s2 still awaits its turn")
	)

	run_case("go_to_leaves_an_unstarted_map_queue_untouched", func():
		GameState.reset()
		MapEvents.queue_discover("shoreditch", "s1")

		Nav.go_to("hq")

		assert_true(not MapEvents.is_playing())
		assert_eq(MapEvents.pending_site_ids(), ["s1"], "nothing was in flight -- an unstarted queued event must not be eaten by an unrelated navigation")
	)
