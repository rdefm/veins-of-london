extends "res://tests/test_base.gd"

# collective1-11, spec.md §6.8: S8 (col_a1_nadia_meet), Nadia's introduction
# -- the consignment. Drives the real event JSON card-by-card, same idiom
# tests/test_col_a1_des_report.gd uses for S7, plus the action-bar button
# (ContactCards.build_nadia_meet_action(), wired into phone.gd's
# _build_action_bar) that's this scene's delivery, and the col_a1_nadia_
# supply objective its on_complete activates.


# Drives an event up to (not including) its choice card.
func _play_to_choice(event_id: String) -> int:
	Events.start_event(event_id)
	var cards: Array = GameData.EVENTS[event_id]["cards"]
	var choice_index := -1
	for i in range(cards.size()):
		if cards[i]["type"] == "choice":
			choice_index = i
			break
	for i in range(choice_index):
		Events.advance()
	return choice_index


func _finish_after_choice(event_id: String, choice_index: int) -> void:
	var remaining: int = GameData.EVENTS[event_id]["cards"].size() - choice_index
	for i in range(remaining):
		Events.advance()


# col_a1_nadia_meet's single choice card carries no effects either way (both
# branches are cosmetic dialogue only, per spec §6.8) -- this plays the whole
# event through choice 0 ("I can get you thirty") for cases that only care
# about on_complete, same as test_col_a1_weather.gd's choice-driving idiom.
func _play_through_choice(event_id: String) -> void:
	var choice_index := _play_to_choice(event_id)
	Events.choose(0)
	_finish_after_choice(event_id, choice_index)


func run() -> void:
	# ── delivery: the action-bar button, available from S4 (nadia unlocked) ──

	run_case("build_nadia_meet_action_is_a_button_before_colA1NadiaMet", func():
		GameState.reset()
		var b := ContactCards.build_nadia_meet_action() as Button
		assert_true(b != null)
		assert_eq(b.text, "Go and see Nadia")

		b.pressed.emit()
		assert_eq(GameState.state["event"]["eventId"], "col_a1_nadia_meet")
	)

	run_case("build_nadia_meet_action_is_null_once_colA1NadiaMet", func():
		GameState.reset()
		GameState.state["flags"]["colA1NadiaMet"] = true
		assert_true(ContactCards.build_nadia_meet_action() == null)
	)

	# ── both choice branches lead to the same next card, no state effects ──

	run_case("both_choice_branches_leave_relation_and_objectives_untouched_and_reach_the_same_next_card", func():
		for choice_index_to_pick in [0, 1]:
			GameState.reset()
			var relation_before: int = GameState.state["factions"]["collective"]["relation"]

			var choice_index := _play_to_choice("col_a1_nadia_meet")
			Events.choose(choice_index_to_pick)
			assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before, "choice %d must not move relation" % choice_index_to_pick)

			Events.advance()  # past the resolved choice card, onto the next authored card
			var next_card: Dictionary = Events.current_card()
			assert_eq(next_card["speaker"], "Nadia")
			assert_true(next_card["text"].contains("I don't know who's holding what"), "choice %d should still land on the information-thesis line" % choice_index_to_pick)

			_finish_after_choice("col_a1_nadia_meet", choice_index + 1)
			assert_true(GameState.state["flags"]["colA1NadiaMet"])
	)

	# ── on_complete: colA1NadiaMet activates col_a1_nadia_supply ───────────

	run_case("on_complete_sets_colA1NadiaMet_and_activates_col_a1_nadia_supply", func():
		GameState.reset()
		assert_true(not GameState.state["objectives"].get("col_a1_nadia_supply", {}).get("active", false))

		_play_through_choice("col_a1_nadia_meet")

		assert_true(GameState.state["flags"]["colA1NadiaMet"])
		Objectives.refresh()
		assert_true(GameState.state["objectives"]["col_a1_nadia_supply"]["active"], "colA1NadiaMet is col_a1_nadia_supply's activateFlag")
		# Regression (bugfix: an on_complete missing a "set_screen" op leaves
		# the EventScreen stuck on a dead Continue button, per tests/
		# test_col_a1_tuition.gd's S1 comment): must navigate back to Nadia's
		# conversation, where the action-bar button was tapped from.
		assert_eq(GameState.state["currentScreen"], "phone")
	)

	run_case("on_complete_moves_no_relation_and_creates_no_sites", func():
		GameState.reset()
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]
		var sites_before: Array = GameState.state["world"]["sites"].duplicate(true)

		_play_through_choice("col_a1_nadia_meet")

		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before)
		assert_eq(GameState.state["world"]["sites"], sites_before)
	)

	# ── col_a1_nadia_supply objective definition ────────────────────────────

	run_case("col_a1_nadia_supply_is_defined_per_spec_6_8", func():
		var def: Dictionary = GameData.OBJECTIVES["col_a1_nadia_supply"]
		assert_eq(def["type"], "traded_with_faction")
		assert_eq(def["params"], { "factionId": "collective", "oreType": "emotion", "qty": 30, "minTransactions": 3 })
		assert_eq(def["activateFlag"], "colA1NadiaMet")
		assert_eq(def["completeFlag"], "colA1NadiaSupplied")
	)

	# ── §6.8: completes through any of the three Collective doors ──────────

	run_case("col_a1_nadia_supply_completes_regardless_of_which_collective_door_the_trades_go_through", func():
		GameState.reset()
		_play_through_choice("col_a1_nadia_meet")  # sets colA1NadiaMet -> activates the objective
		Objectives.refresh()
		assert_true(GameState.state["objectives"]["col_a1_nadia_supply"]["active"])

		GameState.state["player"]["orichalchum"]["emotion"] = 60

		GameState.state["sellState"]["ore_emotion"] = 10
		Collective.complete_trade("des")
		assert_true(not GameState.state["flags"].get("colA1NadiaSupplied", false), "one trade, qty met but minTransactions not yet")

		GameState.state["sellState"]["ore_emotion"] = 10
		Collective.complete_trade("hakim")
		assert_true(not GameState.state["flags"].get("colA1NadiaSupplied", false), "two trades, still short of minTransactions 3")

		GameState.state["sellState"]["ore_emotion"] = 10
		Collective.complete_trade("nadia")
		assert_true(GameState.state["flags"]["colA1NadiaSupplied"], "three trades across three different doors, all feeding the one Collective faction meter")
	)
