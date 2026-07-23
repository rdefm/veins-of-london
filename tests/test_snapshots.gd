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
