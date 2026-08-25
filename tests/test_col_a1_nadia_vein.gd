extends "res://tests/test_base.gd"

# collective1-12, spec.md §6.9: S9 (col_a1_nadia_vein), Nadia's ask -- seed
# her a vein instead of endlessly supplying loose ore. Drives the real event
# JSON card-by-card, same idiom tests/test_col_a1_nadia_meet.gd uses for S8,
# plus the action-bar button (ContactCards.build_nadia_vein_ask_action(),
# wired into phone.gd's _build_action_bar) that's this scene's delivery, and
# the col_a1_nadia_vein objective its on_complete activates.


func _play_event(event_id: String) -> void:
	Events.start_event(event_id)
	for i in range(GameData.EVENTS[event_id]["cards"].size()):
		Events.advance()


func run() -> void:
	# ── delivery: the action-bar button, enabled by colA1NadiaSupplied ─────

	run_case("build_nadia_vein_ask_action_is_null_before_colA1NadiaSupplied", func():
		GameState.reset()
		assert_true(ContactCards.build_nadia_vein_ask_action() == null)
	)

	run_case("build_nadia_vein_ask_action_surfaces_once_colA1NadiaSupplied_and_starts_the_event", func():
		GameState.reset()
		GameState.state["flags"]["colA1NadiaSupplied"] = true

		var b := ContactCards.build_nadia_vein_ask_action() as Button
		assert_true(b != null)

		b.pressed.emit()
		assert_eq(GameState.state["event"]["eventId"], "col_a1_nadia_vein")
	)

	run_case("build_nadia_vein_ask_action_is_null_again_once_colA1NadiaAskSeen", func():
		GameState.reset()
		GameState.state["flags"]["colA1NadiaSupplied"] = true
		GameState.state["flags"]["colA1NadiaAskSeen"] = true
		assert_true(ContactCards.build_nadia_vein_ask_action() == null)
	)

	# ── on_complete: veinSaleUnlocked + colA1NadiaAskSeen, and the objective ──

	run_case("on_complete_unlocks_vein_sale_and_sets_colA1NadiaAskSeen", func():
		GameState.reset()
		GameState.state["flags"]["colA1NadiaSupplied"] = true
		assert_true(not GameState.state["flags"]["veinSaleUnlocked"])

		_play_event("col_a1_nadia_vein")

		assert_true(GameState.state["flags"]["veinSaleUnlocked"])
		assert_true(GameState.state["flags"]["colA1NadiaAskSeen"])
		# Regression (bugfix: an on_complete missing a "set_screen" op leaves
		# the EventScreen stuck on a dead Continue button, per tests/
		# test_col_a1_tuition.gd's S1 comment): must navigate back to Nadia's
		# conversation, where the action-bar button was tapped from.
		assert_eq(GameState.state["currentScreen"], "phone")
	)

	run_case("on_complete_activates_col_a1_nadia_vein_objective", func():
		GameState.reset()
		GameState.state["flags"]["colA1NadiaSupplied"] = true
		assert_true(not GameState.state["objectives"].get("col_a1_nadia_vein", {}).get("active", false))

		_play_event("col_a1_nadia_vein")
		Objectives.refresh()

		assert_true(GameState.state["objectives"]["col_a1_nadia_vein"]["active"], "colA1NadiaAskSeen is col_a1_nadia_vein's activateFlag")
	)

	run_case("on_complete_moves_no_relation", func():
		GameState.reset()
		GameState.state["flags"]["colA1NadiaSupplied"] = true
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		_play_event("col_a1_nadia_vein")

		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before)
	)

	# ── col_a1_nadia_vein objective definition ──────────────────────────────

	run_case("col_a1_nadia_vein_is_defined_per_spec_6_9", func():
		var def: Dictionary = GameData.OBJECTIVES["col_a1_nadia_vein"]
		assert_eq(def["type"], "vein_sold_to_faction")
		assert_eq(def["params"], { "factionId": "collective", "oreType": "emotion" })
		assert_eq(def["activateFlag"], "colA1NadiaAskSeen")
		assert_eq(def["completeFlag"], "colA1NadiaVeinSold")
	)
