extends "res://tests/test_base.gd"

const EventPlay := preload("res://tests/support/event_play.gd")

# collective-act2 12, spec.md §7.3: the Act 2 relation award table -- +4 per
# T8 mission (Collective.award_a2_missions()), +2 per alarm-defend win capped
# at +4/day (Collective.award_a2_defend_win()), the daily cap's reset on
# daily_tick -- plus T8's Nadia action-bar entry point (spec §6.8).
# T13's +15 is covered by tests/test_col_a2_retake.gd.


func _collective_relation() -> int:
	return GameState.state["factions"]["collective"]["relation"]


func _complete_mission(id: String) -> void:
	GameState.state["objectives"][id] = { "active": true, "complete": true, "progress": {} }


func _open_phase_1() -> void:
	GameState.state["flags"]["colA2HandlerDeferred"] = true


func run() -> void:
	# ── T8 missions: +4 each, once ─────────────────────────────────────────

	run_case("mission_award_is_four_per_completed_mission_and_skips_incomplete_ones", func():
		GameState.reset()
		_complete_mission("col_a2_nadia_supplies")
		GameState.state["objectives"]["col_a2_nadia_reseed"] = { "active": true, "complete": false, "progress": {} }
		var before := _collective_relation()

		Collective.award_a2_missions()

		assert_eq(_collective_relation(), before + Collective.A2_MISSION_RELATION)
		assert_eq(GameState.state["collective"]["a2MissionsAwarded"], ["col_a2_nadia_supplies"])
	)

	run_case("mission_award_is_idempotent", func():
		GameState.reset()
		_complete_mission("col_a2_nadia_supplies")
		Collective.award_a2_missions()
		var after_first := _collective_relation()

		Collective.award_a2_missions()
		Collective.award_a2_missions()

		assert_eq(_collective_relation(), after_first, "a mission pays out once, however often the boundary is crossed")
	)

	run_case("all_three_missions_total_twelve", func():
		GameState.reset()
		var before := _collective_relation()
		for id in Collective.CHECKPOINT_MISSIONS:
			_complete_mission(id)
		Collective.award_a2_missions()
		assert_eq(_collective_relation(), before + 12, "spec §7.3: +12 total")
	)

	run_case("checkpoint_boundary_pays_mission_awards_once_the_ledger_has_started", func():
		GameState.reset()
		_complete_mission("col_a2_nadia_reseed")
		var before := _collective_relation()

		Collective.maybe_trigger_a2_checkpoint()
		assert_eq(_collective_relation(), before, "nothing before colA2LedgerStarted")

		GameState.state["flags"]["colA2LedgerStarted"] = true
		Collective.maybe_trigger_a2_checkpoint()
		assert_eq(_collective_relation(), before + Collective.A2_MISSION_RELATION)
	)

	# ── alarm-defend wins: +2, capped +4/day ───────────────────────────────

	run_case("defend_award_is_two_per_win_capped_at_four_a_day", func():
		GameState.reset()
		_open_phase_1()
		var before := _collective_relation()

		Collective.award_a2_defend_win()
		assert_eq(_collective_relation(), before + 2)
		Collective.award_a2_defend_win()
		assert_eq(_collective_relation(), before + 4)
		Collective.award_a2_defend_win()
		assert_eq(_collective_relation(), before + 4, "the third win of the day pays nothing")
	)

	run_case("defend_award_cap_resets_on_daily_tick", func():
		GameState.reset()
		_open_phase_1()
		Collective.award_a2_defend_win()
		Collective.award_a2_defend_win()

		TimeSystem.daily_tick()
		var before := _collective_relation()
		Collective.award_a2_defend_win()
		assert_eq(_collective_relation(), before + 2, "a fresh day, a fresh cap")
	)

	run_case("defend_award_only_pays_during_phases_1_and_2", func():
		GameState.reset()
		var before := _collective_relation()
		Collective.award_a2_defend_win()
		assert_eq(_collective_relation(), before, "nothing before T4 resolves")

		_open_phase_1()
		GameState.state["flags"]["networkHandlerUnlocked"] = true
		Collective.award_a2_defend_win()
		assert_eq(_collective_relation(), before, "nothing once T12 opens Phase 3")
	)

	run_case("resolve_defend_outcome_pays_on_a_win_only", func():
		GameState.reset()
		_open_phase_1()
		var outcome := { "attackerId": "firm", "veinId": "v_none", "siteId": "s_none", "success": true }
		var before := _collective_relation()

		GameState.state["world"]["activeDefendRaid"] = outcome.duplicate()
		Raiding.resolve_defend_outcome(true)
		assert_eq(_collective_relation(), before + 2)

		GameState.state["world"]["activeDefendRaid"] = outcome.duplicate()
		Raiding.resolve_defend_outcome(false)
		assert_eq(_collective_relation(), before + 2, "a lost defend pays nothing")
	)

	# ── save/load ───────────────────────────────────────────────────────────

	run_case("a2MissionsAwarded_backfills_for_saves_missing_the_key", func():
		var save: Dictionary = GameState.new_game_state()
		save["collective"].erase("a2MissionsAwarded")
		var backfilled: Dictionary = SaveManager.backfill_defaults(save)
		assert_eq(backfilled["collective"]["a2MissionsAwarded"], [])
	)

	# ── T8 entry point: Nadia's action bar ─────────────────────────────────

	run_case("nadia_ledger_action_opens_after_t4_and_closes_once_t8_plays", func():
		GameState.reset()
		assert_true(ContactCards.build_nadia_ledger_action() == null, "closed before Phase 0 ends")

		_open_phase_1()
		var action := ContactCards.build_nadia_ledger_action()
		assert_true(action != null, "open once T4 resolves")
		action.free()

		EventPlay.play_event("col_a2_nadia_ledger")
		assert_true(ContactCards.build_nadia_ledger_action() == null, "closed once the ledger's started")
	)
