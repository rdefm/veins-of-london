extends "res://tests/test_base.gd"

# collective1-15, spec.md §6.13: S13, the Archie/Des decoy -- optional,
# missable, player-pried only. Delivered from Archie's existing contact card
# (ContactCards.build_archie_pry_action()), not a text. "Leave it" ends the
# 3-card col_a1_archie_pry event where it stands; "Push" sets
# colA1AskedAboutDebt and chains straight into col_a1_archie_pry_debt (cards
# 4-8) via the new "start_event" op, since advance()'s cardIndex has no
# branching of its own and the two branches are different lengths.


func _play_event(event_id: String) -> void:
	Events.start_event(event_id)
	for i in range(GameData.EVENTS[event_id]["cards"].size()):
		Events.advance()


# Drives col_a1_archie_pry up to (not including) its choice card.
func _play_to_choice() -> void:
	Events.start_event("col_a1_archie_pry")
	Events.advance()  # narration -> Archie
	Events.advance()  # Archie -> choice
	assert_eq(GameState.state["event"]["cardIndex"], 2, "sanity: on the choice card")


func run() -> void:
	# ── delivery: the action-bar button, not a pendingMessages entry ───────

	run_case("build_archie_pry_action_is_null_before_colA1ArchiePryAvailable", func():
		GameState.reset()
		assert_true(ContactCards.build_archie_pry_action() == null)
	)

	run_case("build_archie_pry_action_surfaces_once_colA1ArchiePryAvailable_and_starts_the_event", func():
		GameState.reset()
		GameState.state["flags"]["colA1ArchiePryAvailable"] = true

		var b := ContactCards.build_archie_pry_action() as Button
		assert_true(b != null)

		b.pressed.emit()
		assert_eq(GameState.state["event"]["eventId"], "col_a1_archie_pry")
	)

	run_case("build_archie_pry_action_is_null_once_colA1AskedAboutDebt", func():
		GameState.reset()
		GameState.state["flags"]["colA1ArchiePryAvailable"] = true
		GameState.state["flags"]["colA1AskedAboutDebt"] = true
		assert_true(ContactCards.build_archie_pry_action() == null)
	)

	run_case("build_archie_pry_action_is_null_once_colA1Complete_even_if_never_pushed", func():
		GameState.reset()
		GameState.state["flags"]["colA1ArchiePryAvailable"] = true
		GameState.state["flags"]["colA1Complete"] = true
		assert_true(ContactCards.build_archie_pry_action() == null)
	)

	# ── "Leave it": no flag, event ends where it stands ─────────────────────

	run_case("leave_it_sets_no_flag_and_ends_the_event_after_its_own_card", func():
		GameState.reset()
		_play_to_choice()

		Events.choose(0)  # Leave it
		var cards: Array = Events.revealed_cards()
		assert_eq(cards.size(), 4, "narration + Archie + choice card + its synthetic resolution card, revealed so far")
		assert_eq(cards[3]["text"], "You leave it. He looks briefly grateful and then annoyed with himself for looking grateful.")

		Events.advance()  # Continue past the resolved (and last) choice card
		assert_true(GameState.state["event"] == null, "the event ends here for Leave it -- cards 4-8 must never be reached")
		assert_true(not GameState.state["flags"].get("colA1AskedAboutDebt", false))
		# Regression (bugfix: an on_complete missing a "set_screen" op leaves
		# the EventScreen stuck on a dead Continue button, per tests/
		# test_col_a1_tuition.gd's S1 comment): must navigate back to
		# Archie's card, where the action-bar button was tapped from.
		assert_eq(GameState.state["currentScreen"], "contacts")
	)

	run_case("leave_it_leaves_the_action_bar_button_available_for_a_later_visit", func():
		GameState.reset()
		GameState.state["flags"]["colA1ArchiePryAvailable"] = true
		_play_to_choice()
		Events.choose(0)  # Leave it
		Events.advance()

		assert_true(ContactCards.build_archie_pry_action() != null, "missable, not one-shot -- the player can come back and push later")
	)

	# ── "Push": flag set immediately, chains straight into the debt reveal ──

	run_case("push_sets_colA1AskedAboutDebt_immediately_and_chains_into_the_debt_event", func():
		GameState.reset()
		_play_to_choice()

		Events.choose(1)  # Push
		assert_true(GameState.state["flags"]["colA1AskedAboutDebt"], "set the moment Push is chosen, not on completion")
		assert_eq(GameState.state["event"]["eventId"], "col_a1_archie_pry_debt", "hands off immediately -- no separate resolution card for Push")
		assert_eq(GameState.state["event"]["cardIndex"], 0)
	)

	run_case("the_debt_event_plays_all_five_cards_through_to_its_own_on_complete", func():
		GameState.reset()
		_play_to_choice()
		Events.choose(1)  # Push -> col_a1_archie_pry_debt

		for i in range(GameData.EVENTS["col_a1_archie_pry_debt"]["cards"].size()):
			Events.advance()

		assert_true(GameState.state["event"] == null, "the debt event completes normally")
		assert_true(GameState.state["flags"]["colA1AskedAboutDebt"])
		# Regression: on_complete must navigate off the event screen (see the
		# "Leave it" case above).
		assert_eq(GameState.state["currentScreen"], "contacts")
	)

	run_case("push_hides_the_action_bar_button_once_the_debt_event_completes", func():
		GameState.reset()
		GameState.state["flags"]["colA1ArchiePryAvailable"] = true
		_play_to_choice()
		Events.choose(1)  # Push -> col_a1_archie_pry_debt
		for i in range(GameData.EVENTS["col_a1_archie_pry_debt"]["cards"].size()):
			Events.advance()

		assert_true(ContactCards.build_archie_pry_action() == null, "the explanation only needs giving once")
	)

	# ── content sanity (PROSE-REVIEW: card text is drafted, not approved) ──

	run_case("col_a1_archie_pry_debt_names_the_exact_amount_and_date", func():
		var cards: Array = GameData.EVENTS["col_a1_archie_pry_debt"]["cards"]
		assert_true(cards[0]["text"].contains("Four hundred and twenty"))
		assert_true(cards[0]["text"].contains("Fourteenth of March, 2019"))
	)

	run_case("col_a1_archie_pry_debt_never_mentions_the_falcon_keyring_or_football_beyond_the_tag_line", func():
		# §4.7: keyring, football and the debt must not land in the same
		# scene -- this event is the debt scene, so it may carry the
		# "Crystal Palace" tag line (per spec) but nothing about the keyring.
		var cards: Array = GameData.EVENTS["col_a1_archie_pry_debt"]["cards"]
		for card in cards:
			assert_true(not card["text"].to_lower().contains("keyring"))
			assert_true(not card["text"].to_lower().contains("falcon"))
	)
