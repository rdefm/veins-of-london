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

	# 84-contacts-retire-messages-tile: select_conversation() is now the only
	# place a conversation is ever opened from, including from Contacts,
	# before a phone screen even exists to capture this itself -- so the
	# staged-reveal presentation's "how many were already read before this
	# open" computation moved here (state.phoneNav.revealFromIndex),
	# computed before mark_read() below erases the read/unread distinction.
	run_case("select_conversation_computes_revealFromIndex_from_unread_count_before_marking_read", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		Messages.append("des", "them", "Old.")
		Messages.mark_read("des")
		Messages.append("des", "them", "New one.")
		Messages.append("des", "them", "New two.")

		PhoneNav.select_conversation("des")

		assert_eq(GameState.state["phoneNav"]["revealFromIndex"], 1, "reveal index sits right before the 2 unread messages")
		assert_true(not Messages.has_unread("des"), "select_conversation still marks the thread read")
	)

	run_case("select_conversation_sets_revealFromIndex_to_the_full_thread_when_nothing_is_unread", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		Messages.append("des", "them", "Old.")
		Messages.mark_read("des")

		PhoneNav.select_conversation("des")

		assert_eq(GameState.state["phoneNav"]["revealFromIndex"], 1, "nothing unread -- the whole thread renders instantly")
	)

	# Ticket 12: route_home() is the shared "route to phone home" helper
	# every retired-`home`-screen call site uses (unlike nav_bar.gd's own
	# Phone-tab button, which has its own no-op-when-already-home path).
	run_case("route_home_navigates_to_phone_and_resets_phoneNav_to_home", func():
		GameState.reset()
		Nav.go_to("hq")
		PhoneNav.select_axis("social")
		PhoneNav.arm_new_game_confirm()

		PhoneNav.route_home()

		assert_eq(GameState.state["currentScreen"], "phone", "route_home should navigate to the phone screen")
		assert_eq(GameState.state["phoneNav"]["app"], "home", "route_home should land on the app grid")
		assert_eq(GameState.state["phoneNav"]["selectedAxis"], null, "route_home should clear selectedAxis")
		assert_eq(GameState.state["phoneNav"]["confirmingNewGame"], false, "route_home should clear confirmingNewGame")
	)
