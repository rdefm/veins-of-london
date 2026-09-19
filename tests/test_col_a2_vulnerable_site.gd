extends "res://tests/test_base.gd"

const EventPlay := preload("res://tests/support/event_play.gd")

# collective-act2 04, spec.md §6.6: T6 (col_a2_vulnerable_site), Act 2's
# second Phase 1 choice. Unlike T5 it needs no scripted site -- "Permanent
# lookout" reuses the resources->securityBias mechanism per plans/
# COLLECTIVE-QUESTLINE.md §8.2 verbatim (funnel player cash into
# state.factions.collective.resources via the existing generic "add" op,
# no new formula), so the pin is gated on colA2Stage alone, same as T5's.


func _pin_ids() -> Array:
	var ids: Array = []
	for pin in MapPins.active_contact_pins():
		ids.append(pin["eventId"])
	return ids


func run() -> void:
	# ── delivery: Whitechapel map pin, gated on colA2Stage / hides once resolved ──

	run_case("col_a2_vulnerable_site_pin_is_gated_on_colA2Stage_and_hides_once_resolved", func():
		GameState.reset()
		assert_true(not _pin_ids().has("col_a2_vulnerable_site"), "hidden before colA2Stage")

		GameState.state["flags"]["colA2Stage"] = "call"
		var pins := MapPins.active_contact_pins()
		assert_true(_pin_ids().has("col_a2_vulnerable_site"), "shown once colA2Stage is set")
		for pin in pins:
			if pin["eventId"] == "col_a2_vulnerable_site":
				assert_eq(pin["district"], "whitechapel")

		EventPlay.play_event_with_choices("col_a2_vulnerable_site", [0])
		assert_true(GameState.state["flags"]["colA2VulnerableSiteDone"])
		assert_true(not _pin_ids().has("col_a2_vulnerable_site"), "hidden again once colA2VulnerableSiteDone")
	)

	# ── Permanent lookout branch: cash -> factions.collective.resources ────

	run_case("lookout_branch_spends_player_cash_into_collective_resources", func():
		GameState.reset()
		GameState.state["flags"]["colA2Stage"] = "call"
		GameState.state["player"]["cash"] = 1000
		var cash_before: int = GameState.state["player"]["cash"]
		var resources_before: int = GameState.state["factions"]["collective"]["resources"]

		EventPlay.play_event_with_choices("col_a2_vulnerable_site", [0])  # Fund a lookout

		assert_eq(GameState.state["player"]["cash"], cash_before - 150)
		assert_eq(GameState.state["factions"]["collective"]["resources"], resources_before + 150)
		assert_eq(GameState.state["methodLog"]["a2VulnerableSite"], "lookout")
	)

	# ── Stay soft and fast branch: no structural change ─────────────────────

	run_case("soft_branch_leaves_cash_and_collective_resources_untouched", func():
		GameState.reset()
		GameState.state["flags"]["colA2Stage"] = "call"
		GameState.state["player"]["cash"] = 1000
		var cash_before: int = GameState.state["player"]["cash"]
		var resources_before: int = GameState.state["factions"]["collective"]["resources"]

		EventPlay.play_event_with_choices("col_a2_vulnerable_site", [1])  # Stay soft and fast

		assert_eq(GameState.state["player"]["cash"], cash_before)
		assert_eq(GameState.state["factions"]["collective"]["resources"], resources_before)
		assert_eq(GameState.state["methodLog"]["a2VulnerableSite"], "soft")
	)

	run_case("on_complete_always_sets_colA2VulnerableSiteDone_and_returns_to_the_map", func():
		for choice_index in [0, 1]:
			GameState.reset()
			GameState.state["flags"]["colA2Stage"] = "call"
			GameState.state["player"]["cash"] = 1000

			EventPlay.play_event_with_choices("col_a2_vulnerable_site", [choice_index])

			assert_true(GameState.state["flags"]["colA2VulnerableSiteDone"])
			assert_eq(GameState.state["currentScreen"], "map")
			assert_true(GameState.state["event"] == null)
	)
