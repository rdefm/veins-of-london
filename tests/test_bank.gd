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

		EventBus.flush_now()
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

	run_case("ids_are_unique_monotonic_counter_strings_with_no_clock", func():
		GameState.reset()
		for i in range(3):
			Bank.record(i, "T%d" % i)
		var log: Array = GameState.state["bankLog"]
		assert_eq(log[0]["id"], "bank-1")
		assert_eq(log[1]["id"], "bank-2")
		assert_eq(log[2]["id"], "bank-3")
		assert_eq(GameState.state["nextBankId"], 4, "counter advances once per record")
	)

	run_case("same_seed_same_records_give_identical_bank_logs", func():
		var runs := []
		for run_i in range(2):
			GameState.reset()
			Rng.set_seed(4242)
			for i in range(5):
				Bank.record(i * 10, "T%d" % i)
			runs.append(GameState.deep_copy(GameState.state["bankLog"]))
		assert_eq(runs[0], runs[1], "two seeded runs log byte-identical entries")
	)

	run_case("each_record_draws_exactly_one_rng_value_as_before", func():
		Rng.set_seed(777)
		for i in range(4):
			Rng.randi_range(1000, 999999)
		var expected := Rng.randi_range(0, 1000000)

		GameState.reset()
		Rng.set_seed(777)
		for i in range(4):
			Bank.record(1, "x")
		assert_eq(Rng.randi_range(0, 1000000), expected, "the RNG stream after N records is unchanged")
	)

	run_case("old_save_without_counter_never_reissues_an_existing_id", func():
		GameState.reset()
		var save: Dictionary = GameState.deep_copy(GameState.state)
		save.erase("nextBankId")
		save["bankLog"] = [
			{ "id": "123456789012345", "amount": 1, "label": "clock id", "day": 1 },
			{ "id": "bank-7", "amount": 2, "label": "counter id", "day": 1 },
		]
		GameState.state = SaveManager.backfill_defaults(save)
		Bank.record(3, "new")
		var ids := {}
		for entry in GameState.state["bankLog"]:
			assert_true(not ids.has(entry["id"]), "id %s is unique" % entry["id"])
			ids[entry["id"]] = true
		assert_eq(GameState.state["bankLog"][-1]["id"], "bank-8", "seeded past the highest saved counter id")
	)

	run_case("old_save_with_only_clock_ids_seeds_from_log_length", func():
		var log := [{ "id": "98765432100001", "amount": 1, "label": "a", "day": 1 }, { "id": "98765432100002", "amount": 1, "label": "b", "day": 1 }]
		assert_eq(Bank.next_id_after(log), 3)
		assert_eq(Bank.next_id_after([]), 1)
	)
