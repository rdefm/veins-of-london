extends "res://tests/test_base.gd"


func run() -> void:
	run_case("push_appends_a_notification_with_id_text_seen_and_day", func():
		GameState.reset()
		GameState.state["world"]["day"] = 4
		var n := Notify.push("Day 4: -£50 living costs.")
		assert_eq(GameState.state["notifications"].size(), 1, "one notification after one push")
		assert_eq(GameState.state["notifications"][0]["text"], "Day 4: -£50 living costs.", "pushed text stored")
		assert_true(n.has("id") and n["id"] != "", "returned notification has a non-empty id")
		assert_eq(n["seen"], false, "a freshly pushed notification starts unseen")
		assert_eq(n["day"], 4, "the notification records the current world day")
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

	run_case("dismiss_marks_seen_but_never_deletes_the_entry", func():
		GameState.reset()
		var a := Notify.push("First.")
		var b := Notify.push("Second.")
		Notify.dismiss(a["id"])

		assert_eq(GameState.state["notifications"].size(), 2, "dismiss never removes an entry from the log")
		assert_eq(GameState.state["notifications"][0]["seen"], true, "the dismissed entry is marked seen")
		assert_eq(GameState.state["notifications"][1]["id"], b["id"], "the other entry is untouched")
		assert_eq(GameState.state["notifications"][1]["seen"], false, "the other entry stays unseen")
	)

	run_case("dismiss_unknown_id_is_a_no_op", func():
		GameState.reset()
		Notify.push("Only one.")
		Notify.dismiss("not-a-real-id")
		assert_eq(GameState.state["notifications"].size(), 1, "dismissing an unknown id changes nothing")
		assert_eq(GameState.state["notifications"][0]["seen"], false, "the real entry stays unseen")
	)

	run_case("log_is_capped_at_50_entries_evicting_the_oldest", func():
		GameState.reset()
		for i in range(55):
			Notify.push("Notification %d." % i)

		var notifications: Array = GameState.state["notifications"]
		assert_eq(notifications.size(), Notify.LOG_CAP, "the log never grows past the cap")
		assert_eq(notifications[0]["text"], "Notification 5.", "the 5 oldest entries were evicted to make room")
		assert_eq(notifications[notifications.size() - 1]["text"], "Notification 54.", "the newest entry is retained")
	)

	run_case("snapshot_rewind_round_trip_forgets_notifications_for_events_that_no_longer_happened", func():
		GameState.reset()
		Notify.push("Before the snapshot.")
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)

		Notify.push("After the snapshot — should vanish on rewind.")
		assert_eq(GameState.state["notifications"].size(), 2, "sanity: both pushes landed before rewinding")

		# Simulates the whole-state restore Events.rewind() performs
		# (systems/events.gd's rewind(): `GameState.state = snap`) — proves
		# the notifications array is plain data that round-trips cleanly
		# through deep_copy with no Node/Timer/Callable smuggled in.
		GameState.state = GameState.deep_copy(snapshot)

		assert_eq(GameState.state["notifications"].size(), 1, "the rewound state forgets the post-snapshot notification")
		assert_eq(GameState.state["notifications"][0]["text"], "Before the snapshot.", "the pre-snapshot notification survives the round trip")
	)
