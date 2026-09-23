extends "res://tests/test_base.gd"

const EventPlay := preload("res://tests/support/event_play.gd")

# collective-act2 07, spec.md §6.9: T9 (col_a2_checkpoint) is texted by
# Nadia once all three T8 missions complete, or CHECKPOINT_FALLBACK_DAYS
# after the ledger started, whichever first.


func _complete(ids: Array) -> void:
	for id in ids:
		GameState.state["objectives"][id] = { "active": true, "complete": true, "progress": {} }


func _checkpoint_pending_count() -> int:
	var count := 0
	for entry in Messages.pending_for("nadia"):
		if entry["kind"] == "col_a2_checkpoint":
			count += 1
	return count


func run() -> void:
	run_case("ledger_completion_stamps_ledger_started_day_without_firing", func():
		GameState.reset()
		GameState.state["world"]["day"] = 7

		EventPlay.play_event("col_a2_nadia_ledger")

		assert_eq(GameState.state["collective"]["ledgerStartedDay"], 7)
		assert_eq(_checkpoint_pending_count(), 0, "no mission done, no days passed -- too early")
	)

	run_case("does_nothing_before_the_ledger_has_started", func():
		GameState.reset()
		_complete(Collective.CHECKPOINT_MISSIONS)

		assert_true(not Collective.maybe_trigger_a2_checkpoint())
		assert_eq(GameState.state["collective"]["ledgerStartedDay"], null)
	)

	run_case("fires_once_all_three_missions_are_complete", func():
		GameState.reset()
		GameState.state["flags"]["colA2LedgerStarted"] = true
		GameState.state["collective"]["ledgerStartedDay"] = GameState.state["world"]["day"]
		_complete(["col_a2_nadia_reseed", "col_a2_nadia_supplies"])

		assert_true(not Collective.maybe_trigger_a2_checkpoint(), "two of three, same day -- not yet")

		_complete(["col_a2_nadia_defend"])
		assert_true(Collective.maybe_trigger_a2_checkpoint())
		assert_eq(_checkpoint_pending_count(), 1)
	)

	run_case("two_of_three_fires_on_the_day_threshold", func():
		GameState.reset()
		GameState.state["flags"]["colA2LedgerStarted"] = true
		GameState.state["collective"]["ledgerStartedDay"] = 10
		_complete(["col_a2_nadia_reseed", "col_a2_nadia_supplies"])

		GameState.state["world"]["day"] = 10 + Collective.CHECKPOINT_FALLBACK_DAYS - 1
		assert_true(not Collective.maybe_trigger_a2_checkpoint(), "a day short of the threshold")

		GameState.state["world"]["day"] = 10 + Collective.CHECKPOINT_FALLBACK_DAYS
		assert_true(Collective.maybe_trigger_a2_checkpoint(), "threshold reached -- fires without the third mission")
	)

	run_case("does_not_double_queue_or_refire_mid_event_or_after_seen", func():
		GameState.reset()
		GameState.state["flags"]["colA2LedgerStarted"] = true
		GameState.state["collective"]["ledgerStartedDay"] = GameState.state["world"]["day"]
		_complete(Collective.CHECKPOINT_MISSIONS)

		assert_true(Collective.maybe_trigger_a2_checkpoint())
		assert_true(not Collective.maybe_trigger_a2_checkpoint(), "already pending")
		assert_eq(_checkpoint_pending_count(), 1)

		var entry: Dictionary = Messages.pending_for("nadia")[0]
		Messages.resolve_pending(entry["id"])
		Events.start_event(entry["kind"], entry["payload"])
		assert_true(not Collective.maybe_trigger_a2_checkpoint(), "event already running")

		EventPlay.play_event("col_a2_checkpoint")
		assert_true(GameState.state["flags"]["colA2CheckpointSeen"])
		assert_eq(GameState.state["currentScreen"], "phone")
		assert_true(not Collective.maybe_trigger_a2_checkpoint(), "seen -- never again")
		assert_eq(_checkpoint_pending_count(), 0)
	)
