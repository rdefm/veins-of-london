extends "res://tests/test_base.gd"

# PhoneNav — Phone tab drill-down state (M1-LONDON.md D4/D4.5: home
# launcher -> app -> Ticker axis detail).


func run() -> void:
	run_case("new_game_starts_on_the_home_launcher", func():
		GameState.reset()
		assert_eq(GameState.state["phoneNav"]["app"], "home", "phoneNav.app should default to home")
		assert_eq(GameState.state["phoneNav"]["selectedAxis"], null, "phoneNav.selectedAxis should default to null")
	)

	run_case("open_app_sets_app_and_emits", func():
		GameState.reset()
		var received := [false]
		var on_changed := func(): received[0] = true
		EventBus.state_changed.connect(on_changed)
		PhoneNav.open_app("notes")
		EventBus.state_changed.disconnect(on_changed)

		assert_eq(GameState.state["phoneNav"]["app"], "notes", "app should update")
		assert_true(received[0], "state_changed should fire")
	)

	run_case("open_app_clears_any_stale_selected_axis", func():
		GameState.reset()
		PhoneNav.select_axis("economic")
		PhoneNav.open_app("notes")
		assert_eq(GameState.state["phoneNav"]["selectedAxis"], null, "switching app should clear selectedAxis")
	)

	run_case("go_home_resets_app_and_axis", func():
		GameState.reset()
		PhoneNav.select_axis("social")
		PhoneNav.go_home()
		assert_eq(GameState.state["phoneNav"]["app"], "home", "go_home should reset app to home")
		assert_eq(GameState.state["phoneNav"]["selectedAxis"], null, "go_home should clear selectedAxis")
	)

	run_case("select_axis_opens_ticker_on_the_given_axis", func():
		GameState.reset()
		PhoneNav.select_axis("political")
		assert_eq(GameState.state["phoneNav"]["app"], "ticker", "select_axis should switch to the ticker app")
		assert_eq(GameState.state["phoneNav"]["selectedAxis"], "political", "selectedAxis should be set")
	)

	run_case("back_to_ticker_clears_axis_but_stays_on_ticker", func():
		GameState.reset()
		PhoneNav.select_axis("political")
		PhoneNav.back_to_ticker()
		assert_eq(GameState.state["phoneNav"]["app"], "ticker", "should remain on the ticker app")
		assert_eq(GameState.state["phoneNav"]["selectedAxis"], null, "selectedAxis should clear")
	)
