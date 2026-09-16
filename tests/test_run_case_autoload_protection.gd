extends "res://tests/test_base.gd"

# bugfixes ticket 124: regression coverage for the fix to ticket 122's
# segfault. run_case()'s ticket-116 teardown
# (_disconnect_and_free_new_eventbus_connections) must never disconnect or
# queue_free() a project autoload, even when that autoload's own
# _ready()-time EventBus connection "looks new" to the before/after
# snapshot diff -- which is exactly what happened live when GameState's
# connection first appeared mid-case
# (122-diagnose-full-suite-segfault_COMPLETED.md's Findings). This drives
# that exact condition directly, rather than relying on some test file
# happening to be first in the whole process to flush an engine frame --
# ticket 124's own test_runner.gd fix means that's no longer even true in
# normal run order, so a run-order-dependent regression test would stop
# exercising anything.


func run() -> void:
	run_case("run_case_teardown_never_frees_the_live_gamestate_autoload_even_if_its_ready_time_connection_looks_new", func():
		var gamestate_id_before := GameState.get_instance_id()

		var before := _snapshot_eventbus_connections()
		var without_gamestate: Array[Callable] = []
		for c in before["shared_stock_increased"]:
			if c.get_object() != GameState:
				without_gamestate.append(c)
		before["shared_stock_increased"] = without_gamestate

		_disconnect_and_free_new_eventbus_connections(before)

		# Identity, not just non-null: a queue_free()'d Node can still read
		# as non-null and even keep its old instance id for a few lines
		# (ticket 122's own segfault only ever surfaced *later*, on some
		# unrelated access) -- is_instance_valid() is the actual freed-check.
		assert_true(is_instance_valid(GameState), "the live GameState autoload must survive run_case()'s teardown")
		assert_eq(GameState.get_instance_id(), gamestate_id_before, "GameState must still be the exact same singleton instance, not a same-shaped replacement")
		# A freed GameState would raise "previously freed" script errors
		# here -- proof it's still the same functional singleton every
		# system and screen reads/writes through, not just a valid object.
		GameState.reset()
		assert_true(GameState.state.has("player"), "GameState must still be usable after teardown")
	)
