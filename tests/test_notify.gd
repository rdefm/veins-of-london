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
		var got_notification_pushed := false
		var got_state_changed := false
		var on_notification := func(): got_notification_pushed = true
		var on_state := func(): got_state_changed = true
		EventBus.notification_pushed.connect(on_notification)
		EventBus.state_changed.connect(on_state)

		Notify.push("Test notification.")

		EventBus.notification_pushed.disconnect(on_notification)
		EventBus.state_changed.disconnect(on_state)

		assert_true(got_notification_pushed, "notification_pushed should fire")
		assert_true(got_state_changed, "state_changed should fire")
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
