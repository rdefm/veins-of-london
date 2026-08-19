extends "res://tests/test_base.gd"


func run() -> void:
	run_case("record_appends_an_entry_with_id_amount_label_and_day", func():
		GameState.reset()
		GameState.state["world"]["day"] = 4
		Bank.record(-50, "Living costs")

		var log: Array = GameState.state["bankLog"]
		assert_eq(log.size(), 1, "one entry after one record")
		assert_eq(log[0]["amount"], -50, "signed amount stored as given")
		assert_eq(log[0]["label"], "Living costs", "label stored as given")
		assert_eq(log[0]["day"], 4, "the entry records the current world day")
		assert_true(log[0].has("id") and log[0]["id"] != "", "entry has a non-empty id")
	)

	run_case("record_emits_state_changed", func():
		GameState.reset()
		var got_state_changed := [false]
		var on_state := func(): got_state_changed[0] = true
		EventBus.state_changed.connect(on_state)

		Bank.record(100, "Archie sale")

		EventBus.state_changed.disconnect(on_state)
		assert_true(got_state_changed[0], "state_changed should fire")
	)

	run_case("log_is_capped_at_50_entries_evicting_the_oldest", func():
		GameState.reset()
		for i in range(55):
			Bank.record(i, "Transaction %d" % i)

		var log: Array = GameState.state["bankLog"]
		assert_eq(log.size(), Bank.LOG_CAP, "the log never grows past the cap")
		assert_eq(log[0]["label"], "Transaction 5", "the 5 oldest entries were evicted to make room")
		assert_eq(log[log.size() - 1]["label"], "Transaction 54", "the newest entry is retained")
	)

	run_case("snapshot_rewind_round_trip_forgets_bank_entries_for_events_that_no_longer_happened", func():
		GameState.reset()
		Bank.record(10, "Before the snapshot.")
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)

		Bank.record(-10, "After the snapshot — should vanish on rewind.")
		assert_eq(GameState.state["bankLog"].size(), 2, "sanity: both records landed before rewinding")

		GameState.state = GameState.deep_copy(snapshot)

		assert_eq(GameState.state["bankLog"].size(), 1, "the rewound state forgets the post-snapshot entry")
		assert_eq(GameState.state["bankLog"][0]["label"], "Before the snapshot.", "the pre-snapshot entry survives the round trip")
	)
