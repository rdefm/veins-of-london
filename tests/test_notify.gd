extends "res://tests/test_base.gd"


func run() -> void:
	run_case("push_appends_a_notification_with_id_and_text", func():
		GameState.reset()
		var n := Notify.push("Day 4: -£50 living costs.")
		assert_eq(GameState.state["notifications"].size(), 1, "one notification after one push")
		assert_eq(GameState.state["notifications"][0]["text"], "Day 4: -£50 living costs.", "pushed text stored")
		assert_true(n.has("id") and n["id"] != "", "returned notification has a non-empty id")
	)

	run_case("push_emits_notification_pushed_and_state_changed", func():
		GameState.reset()
		# Arrays, not plain vars: GDScript lambdas capture outer locals by
		# value (see test_eventbus.gd's matching comment), so a plain var
		# flipped inside the lambda would never be visible out here.
		var got_notification_pushed := [false]
		var got_state_changed := [false]
		var on_notification := func(): got_notification_pushed[0] = true
		var on_state := func(): got_state_changed[0] = true
		EventBus.notification_pushed.connect(on_notification)
		EventBus.state_changed.connect(on_state)

		Notify.push("Test notification.")

		EventBus.notification_pushed.disconnect(on_notification)
		EventBus.state_changed.disconnect(on_state)

		assert_true(got_notification_pushed[0], "notification_pushed should fire")
		assert_true(got_state_changed[0], "state_changed should fire")
	)

	run_case("dismiss_removes_by_id", func():
		GameState.reset()
		var a := Notify.push("First.")
		var b := Notify.push("Second.")
		Notify.dismiss(a["id"])

		assert_eq(GameState.state["notifications"].size(), 1, "one notification remains")
		assert_eq(GameState.state["notifications"][0]["id"], b["id"], "the remaining one is the second push")
	)

	run_case("dismiss_unknown_id_is_a_no_op", func():
		GameState.reset()
		Notify.push("Only one.")
		Notify.dismiss("not-a-real-id")
		assert_eq(GameState.state["notifications"].size(), 1, "dismissing an unknown id changes nothing")
	)
