extends "res://tests/test_base.gd"

# collective1-08, spec.md §4/§6.1-6.4: Act 1 Phase 1 -- the mandatory tuition
# chain (S1-S4). Drives the real col_a1_intro/col_a1_prospecting/
# col_a1_seeding/col_a1_hub event JSON card-by-card, same idiom
# tests/test_playthrough.gd already uses for archie_cultivation.


func _play_event(event_id: String) -> void:
	Events.start_event(event_id)
	for i in range(GameData.EVENTS[event_id]["cards"].size()):
		Events.advance()


# Finds the pending-message button ContactCards.build_archie_card() adds for
# a queued "archie" pendingMessages entry, by walking the returned Control
# tree the same way tests/test_contact_cards.gd inspects other buttons on
# this card -- no scene tree required, per that file's own precedent.
func _find_button(root: Control, text: String) -> Button:
	if root is Button and (root as Button).text == text:
		return root
	for child in root.get_children():
		if child is Control:
			var found := _find_button(child, text)
			if found != null:
				return found
	return null


func run() -> void:
	# ── S1 delivery: archie_cultivation queues the real pendingMessages road ──

	run_case("archie_cultivation_queues_a_pending_message_for_archie_carrying_col_a1_intro", func():
		GameState.reset()
		GameState.state["flags"]["archiePartnerSeen"] = true

		_play_event("archie_cultivation")

		var pending := Messages.pending_for("archie")
		assert_eq(pending.size(), 1, "archie_cultivation should queue exactly one pending entry for archie")
		assert_eq(pending[0]["kind"], "col_a1_intro", "the pending entry's kind is the event it should start")
		assert_true(Messages.has_any_unread(), "queuing appends an unread text -- the Messages tile should badge (spec §5.3)")

		var thread: Array = GameState.state["messages"]["archie"]
		assert_eq(thread[thread.size() - 1]["text"], "Come by the lock-up. Got someone you need to meet. Don't make a thing of it.")
	)

	run_case("archie_card_surfaces_the_pending_S1_button_and_pressing_it_resolves_and_starts_col_a1_intro", func():
		GameState.reset()
		GameState.state["flags"]["archiePartnerSeen"] = true
		_play_event("archie_cultivation")

		var card := ContactCards.build_archie_card()
		var button := _find_button(card, "💬 Archie texted — come to the lock-up")
		assert_true(button != null, "Archie's contacts card should surface the pending S1 text as a button")

		button.pressed.emit()

		assert_eq(GameState.state["event"]["eventId"], "col_a1_intro", "pressing the button should start col_a1_intro")
		assert_eq(Messages.pending_for("archie").size(), 0, "the pending entry should be resolved once its action is taken")
	)

	run_case("archie_card_shows_no_pending_button_before_archie_cultivation_fires", func():
		GameState.reset()
		var card := ContactCards.build_archie_card()
		assert_true(_find_button(card, "💬 Archie texted — come to the lock-up") == null, "no pending entry yet -- no button")
	)

	# ── S1: col_a1_intro ────────────────────────────────────────────────

	run_case("col_a1_intro_on_complete_unlocks_des_and_the_collective_lane_and_awards_relation", func():
		GameState.reset()
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		_play_event("col_a1_intro")

		assert_true(GameState.state["contacts"]["des"]["unlocked"], "des should be unlocked")
		assert_true(GameState.state["flags"]["colA1DesMet"])
		assert_true(GameState.state["flags"]["collectiveLaneUnlocked"])
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before + 3, "S1 awards +3 collective relation")
		assert_eq(GameState.state["flags"]["colA1Stage"], "tuition")
		# Regression (bugfix: col_a1_intro's Continue button did nothing once
		# the event finished): on_complete must navigate off the event screen,
		# not just leave state.event null with currentScreen still "event".
		assert_eq(GameState.state["currentScreen"], "contacts", "S1 -> Archie's card, where the pending text was tapped from")
	)

	# ── S2/S3: map pins, teach-don't-require ────────────────────────────

	run_case("col_a1_prospecting_pin_is_gated_on_colA1DesMet_and_hides_once_taught", func():
		GameState.reset()
		var pins := MapPins.active_contact_pins()
		var ids: Array = []
		for pin in pins:
			ids.append(pin["eventId"])
		assert_true(not ids.has("col_a1_prospecting"), "hidden before colA1DesMet")

		GameState.state["flags"]["colA1DesMet"] = true
		pins = MapPins.active_contact_pins()
		ids = []
		for pin in pins:
			ids.append(pin["eventId"])
		assert_true(ids.has("col_a1_prospecting"), "shown once colA1DesMet is true")

		_play_event("col_a1_prospecting")
		assert_true(GameState.state["flags"]["colA1ProspectingTaught"])

		pins = MapPins.active_contact_pins()
		ids = []
		for pin in pins:
			ids.append(pin["eventId"])
		assert_true(not ids.has("col_a1_prospecting"), "hidden again once taught")
	)

	run_case("col_a1_prospecting_does_not_force_a_real_prospect_action", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesMet"] = true
		var sites_before: int = GameState.state["world"]["sites"].size()

		_play_event("col_a1_prospecting")

		assert_eq(GameState.state["world"]["sites"].size(), sites_before, "the tutorial teaches, it doesn't call Sites.prospect()")
		# Regression: on_complete must navigate off the event screen (see S1's
		# comment above).
		assert_eq(GameState.state["currentScreen"], "map", "S2 -> the map pin it was tapped from")
	)

	run_case("col_a1_seeding_pin_is_gated_on_colA1ProspectingTaught_and_hides_once_taught", func():
		GameState.reset()
		var pins := MapPins.active_contact_pins()
		var ids: Array = []
		for pin in pins:
			ids.append(pin["eventId"])
		assert_true(not ids.has("col_a1_seeding"), "hidden before colA1ProspectingTaught")

		GameState.state["flags"]["colA1ProspectingTaught"] = true
		pins = MapPins.active_contact_pins()
		ids = []
		for pin in pins:
			ids.append(pin["eventId"])
		assert_true(ids.has("col_a1_seeding"), "shown once colA1ProspectingTaught is true")

		_play_event("col_a1_seeding")
		assert_true(GameState.state["flags"]["colA1SeedingTaught"])

		pins = MapPins.active_contact_pins()
		ids = []
		for pin in pins:
			ids.append(pin["eventId"])
		assert_true(not ids.has("col_a1_seeding"), "hidden again once taught")
	)

	run_case("col_a1_seeding_on_complete_queues_the_col_a1_hub_pending_message_for_des", func():
		GameState.reset()
		GameState.state["flags"]["colA1ProspectingTaught"] = true

		_play_event("col_a1_seeding")

		var pending := Messages.pending_for("des")
		assert_eq(pending.size(), 1)
		assert_eq(pending[0]["kind"], "col_a1_hub")
		var thread: Array = GameState.state["messages"]["des"]
		assert_eq(thread[thread.size() - 1]["text"], "When you've got a minute. Nothing urgent, but there are three things.")
		# Regression: on_complete must navigate off the event screen (see S1's
		# comment above).
		assert_eq(GameState.state["currentScreen"], "map", "S3 -> the map pin it was tapped from")
	)

	# ── S4: col_a1_hub ───────────────────────────────────────────────────

	run_case("col_a1_hub_on_complete_unlocks_nadia_and_hakim_and_activates_des_and_hakim_objectives", func():
		GameState.reset()

		_play_event("col_a1_hub")

		assert_true(GameState.state["contacts"]["nadia"]["unlocked"])
		assert_true(GameState.state["contacts"]["hakim"]["unlocked"])
		assert_eq(GameState.state["flags"]["colA1Stage"], "hub")
		assert_true(GameState.state["flags"]["colA1ArchiePryAvailable"])
		assert_true(GameState.state["flags"]["colA1HubReached"], "hub-reached flag gates S11's Whitechapel pin (ticket 13)")
		assert_true(GameState.state["flags"]["colA1DesThreadActive"], "col_a1_des_sites' activateFlag")

		Objectives.refresh()
		assert_true(GameState.state["objectives"]["col_a1_des_sites"]["active"], "S4 activates col_a1_des_sites")
		assert_true(GameState.state["objectives"]["col_a1_hakim_rescue"]["active"], "S4 activates col_a1_hakim_rescue")
		# Regression: on_complete must navigate off the event screen (see S1's
		# comment above).
		assert_eq(GameState.state["currentScreen"], "phone", "S4 -> Des's conversation, where the pending text was tapped from")
	)

	run_case("col_a1_hub_does_not_move_collective_relation_on_its_own", func():
		GameState.reset()
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		_play_event("col_a1_hub")

		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before, "S4's spec §8.5 award table has no entry for S4 itself")
	)

	# ── §4.1: a player who stops after S4 keeps the lane and never advances ──

	run_case("stopping_after_S4_keeps_the_trading_lane_open_and_relation_never_moves_further", func():
		GameState.reset()
		_play_event("col_a1_intro")
		_play_event("col_a1_hub")
		var relation_after_hub: int = GameState.state["factions"]["collective"]["relation"]

		# Time passes. Nothing the player does (short of trading or the
		# authored thread events, neither of which fires here) should move
		# the Collective's opinion of them.
		for i in range(10):
			TimeSystem.daily_tick()

		assert_true(GameState.state["flags"]["collectiveLaneUnlocked"], "the trading lane stays open")
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_after_hub, "relation never moves on its own")
	)
