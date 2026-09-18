extends "res://tests/test_base.gd"

const EventPlay := preload("res://tests/support/event_play.gd")

# collective-act2 02, spec.md §6.1-6.4: Phase 0 -- Act 2's mandatory linear
# opener (T1-T4). Drives Collective.maybe_trigger_act2_intro()'s delivery
# condition, then the real col_a2_intro/col_a2_shop/col_a2_pattern/
# col_a2_handler_deferred event JSON card-by-card, same idiom
# tests/test_col_a1_tuition.gd and tests/test_col_a1_closer.gd already use.


func run() -> void:
	# ── delivery: Collective.maybe_trigger_act2_intro() ────────────────────

	run_case("maybe_trigger_act2_intro_is_false_before_colA1Complete", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 30
		assert_true(not Collective.maybe_trigger_act2_intro())
		assert_true(Messages.pending_for("des").is_empty())
	)

	run_case("maybe_trigger_act2_intro_is_false_below_relation_25_even_with_colA1Complete", func():
		GameState.reset()
		GameState.state["flags"]["colA1Complete"] = true
		GameState.state["factions"]["collective"]["relation"] = 24
		assert_true(not Collective.maybe_trigger_act2_intro())
	)

	run_case("maybe_trigger_act2_intro_queues_the_des_text_once_every_condition_is_met", func():
		GameState.reset()
		GameState.state["flags"]["colA1Complete"] = true
		GameState.state["factions"]["collective"]["relation"] = 25

		assert_true(Collective.maybe_trigger_act2_intro())

		var pending: Array = Messages.pending_for("des")
		assert_eq(pending.size(), 1)
		assert_eq(pending[0]["kind"], "col_a2_intro")
		assert_true(Messages.has_unread("des"))
		assert_true(GameState.state["flags"]["colA2Started"])
	)

	run_case("maybe_trigger_act2_intro_does_not_double_queue_on_a_repeat_call", func():
		GameState.reset()
		GameState.state["flags"]["colA1Complete"] = true
		GameState.state["factions"]["collective"]["relation"] = 25
		Collective.maybe_trigger_act2_intro()

		assert_true(not Collective.maybe_trigger_act2_intro())
		assert_eq(Messages.pending_for("des").size(), 1)
	)

	run_case("events_advance_fires_act2_intro_the_moment_colA1Complete_is_set_via_on_complete", func():
		GameState.reset()
		GameState.state["factions"]["collective"]["relation"] = 37

		EventPlay.play_event_with_choices("col_a1_closer", [0, 0])  # Thank him, I'm in

		assert_true(GameState.state["flags"]["colA1Complete"])
		assert_eq(Messages.pending_for("des").size(), 1, "advance()'s on_complete boundary must trigger Act 2's intro automatically")
	)

	run_case("time_system_daily_tick_fires_act2_intro_as_a_backstop", func():
		GameState.reset()
		GameState.state["flags"]["colA1Complete"] = true
		GameState.state["factions"]["collective"]["relation"] = 25

		TimeSystem.daily_tick()

		assert_eq(Messages.pending_for("des").size(), 1)
	)

	# ── T1: col_a2_intro chains straight into T2 ────────────────────────────

	run_case("col_a2_intro_on_complete_chains_into_col_a2_shop", func():
		GameState.reset()
		EventPlay.play_event("col_a2_intro")
		assert_eq(GameState.state["event"]["eventId"], "col_a2_shop", "Phase 0 is linear and mandatory -- T1 should chain straight into T2")
	)

	# ── T2: col_a2_shop ──────────────────────────────────────────────────

	run_case("col_a2_shop_on_complete_sets_colA2ShopSeen_and_chains_into_col_a2_pattern", func():
		GameState.reset()
		EventPlay.play_event("col_a2_shop")
		assert_true(GameState.state["flags"]["colA2ShopSeen"])
		assert_eq(GameState.state["event"]["eventId"], "col_a2_pattern")
	)

	# ── T3: col_a2_pattern activates Phase 1 and chains into T4 ─────────────

	run_case("col_a2_pattern_on_complete_sets_colA2Stage_call_and_chains_into_handler_deferred", func():
		GameState.reset()
		EventPlay.play_event("col_a2_pattern")
		assert_eq(GameState.state["flags"]["colA2Stage"], "call")
		assert_eq(GameState.state["event"]["eventId"], "col_a2_handler_deferred")
	)

	# ── T4: col_a2_handler_deferred ends Phase 0 back on the phone ──────────

	run_case("col_a2_handler_deferred_on_complete_sets_the_flag_and_ends_the_chain", func():
		GameState.reset()
		EventPlay.play_event("col_a2_handler_deferred")
		assert_true(GameState.state["flags"]["colA2HandlerDeferred"])
		assert_true(GameState.state["event"] == null, "the chain ends here -- Phase 1 is player-ordered, not chained")
		assert_eq(GameState.state["currentScreen"], "phone")
	)

	# ── the full T1-T4 chain played straight through in one go ─────────────

	run_case("playing_col_a2_intro_straight_through_reaches_the_end_of_phase_0", func():
		GameState.reset()
		EventPlay.play_event("col_a2_intro")
		EventPlay.play_event("col_a2_shop")
		EventPlay.play_event("col_a2_pattern")
		EventPlay.play_event("col_a2_handler_deferred")

		assert_true(GameState.state["flags"]["colA2ShopSeen"])
		assert_eq(GameState.state["flags"]["colA2Stage"], "call")
		assert_true(GameState.state["flags"]["colA2HandlerDeferred"])
		assert_true(GameState.state["event"] == null)
	)
