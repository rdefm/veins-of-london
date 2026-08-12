extends "res://tests/test_base.gd"


func run() -> void:
	run_case("push_respects_the_stack_ids_bound", func():
		var stack: Array = []
		Snapshots.push("combat", stack, { "n": 1 })
		Snapshots.push("combat", stack, { "n": 2 })
		Snapshots.push("combat", stack, { "n": 3 })
		assert_eq(stack.size(), 2, "combat stacks are bounded to 2")
		assert_eq(stack[0]["n"], 2, "oldest surviving entry should be the 2nd push, not the 1st")
		assert_eq(stack[1]["n"], 3, "newest entry should be the 3rd push")
	)

	run_case("push_deep_copies_so_later_mutation_does_not_leak_back", func():
		var stack: Array = []
		var original := { "nested": { "value": 1 } }
		Snapshots.push("combat", stack, original)
		original["nested"]["value"] = 999
		assert_eq(stack[0]["nested"]["value"], 1, "the stored snapshot should be independent of the source dict")
	)

	run_case("oldest_returns_the_first_entry_or_null_when_empty", func():
		var stack: Array = []
		assert_eq(Snapshots.oldest(stack), null, "oldest of an empty stack is null")
		Snapshots.push("event", stack, { "n": 1 })
		Snapshots.push("event", stack, { "n": 2 })
		assert_eq(Snapshots.oldest(stack)["n"], 1, "oldest should be the first pushed entry")
	)

	run_case("clear_empties_the_stack", func():
		var stack: Array = []
		Snapshots.push("combat", stack, { "n": 1 })
		Snapshots.clear(stack)
		assert_eq(stack, [], "clear should leave the stack empty")
	)

	run_case("unbounded_stack_id_keeps_everything", func():
		var stack: Array = []
		for i in range(20):
			Snapshots.push("some_unknown_id", stack, { "n": i })
		assert_eq(stack.size(), 20, "unrecognised stack ids should not be arbitrarily truncated")
	)

	run_case("player_bench_round_trips_through_a_snapshot_unchanged", func():
		GameState.reset()
		var bench: Dictionary = GameState.state["player"]["bench"]
		bench["surveyed"]["life+time"] = 3
		bench["cells"]["life+time|heat"] = { "state": "found", "misses": 2, "refine": 1 }
		bench["notes"]["life+time"] = [{ "day": 9, "approach": "heat", "outcome": "found" }]

		var stack: Array = []
		Snapshots.push("event", stack, GameState.state)

		# Mutate live state after the snapshot was taken — a later probe on
		# the same cell, say — to prove the restored copy is independent.
		bench["cells"]["life+time|heat"]["state"] = "hot"
		bench["cells"]["life+time|heat"]["misses"] = 99

		var restored: Dictionary = Snapshots.oldest(stack)
		var restored_cell: Dictionary = restored["player"]["bench"]["cells"]["life+time|heat"]
		assert_eq(restored_cell["state"], "found", "an already-discovered effect must not revert to untried or hot after a Rewind")
		assert_eq(restored_cell["misses"], 2, "the snapshot's misses count should be the value at push time, not the live one")
		assert_eq(restored["player"]["bench"]["surveyed"]["life+time"], 3, "the pairing's census should survive the round trip")
		assert_eq(restored["player"]["bench"]["notes"]["life+time"], [{ "day": 9, "approach": "heat", "outcome": "found" }], "note history should survive the round trip")
	)
