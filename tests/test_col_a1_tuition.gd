extends "res://tests/test_base.gd"

const Fixtures := preload("res://tests/support/fixtures.gd")
const EventPlay := preload("res://tests/support/event_play.gd")
const NodeQuery := preload("res://tests/support/node_query.gd")

# Act 1 Phase 1 -- the mandatory tuition chain (S1-S4), which plays as one
# continuous event: col_a1_intro -> col_a1_prospecting -> col_a1_seeding ->
# col_a1_hub, each started by the previous one's on_complete. Drives the real
# event JSON card-by-card.


# Starts event_id (or, given "", keeps playing the live one) and presses
# Continue until state.event clears, returning each event id seen in order.
# Asserts the screen never leaves "event" while one is live.
func _play_chain_from(event_id: String) -> Array:
	if event_id != "":
		Events.start_event(event_id)
	var played: Array = []
	var guard := 0
	while GameState.state["event"] != null and guard < 200:
		var live_id: String = GameState.state["event"]["eventId"]
		if played.is_empty() or played[played.size() - 1] != live_id:
			played.append(live_id)
		assert_eq(GameState.state["currentScreen"], "event", "%s: never sent off the event screen mid-chain" % live_id)
		Events.advance()
		guard += 1
	return played


func run() -> void:
	# ── S1 delivery: archie_cultivation queues the real pendingMessages road ──

	run_case("archie_cultivation_queues_a_pending_message_for_archie_carrying_col_a1_intro", func():
		GameState.reset()
		GameState.state["flags"]["archiePartnerSeen"] = true

		EventPlay.play_event("archie_cultivation")

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
		EventPlay.play_event("archie_cultivation")

		var card := ContactCards.build_archie_card()
		# 83-contacts-archie-james-sms-port: Archie's card now surfaces every
		# pendingMessages entry with the same generic "Continue →" label
		# Des/Nadia/Hakim's cards use -- the actual S1 text lives in the
		# message thread itself (previous test case), not the button.
		var button := NodeQuery.find_button(card, "Continue →")
		assert_true(button != null, "Archie's contacts card should surface the pending S1 entry as a button")

		button.pressed.emit()

		assert_eq(GameState.state["event"]["eventId"], "col_a1_intro", "pressing the button should start col_a1_intro")
		assert_eq(Messages.pending_for("archie").size(), 0, "the pending entry should be resolved once its action is taken")
	)

	run_case("archie_card_shows_no_pending_button_before_archie_cultivation_fires", func():
		GameState.reset()
		var card := ContactCards.build_archie_card()
		assert_true(NodeQuery.find_button(card, "Continue →") == null, "no pending entry yet -- no button")
	)

	# ── S1-S4: one continuous event, intro -> prospecting -> seeding -> hub ──

	run_case("col_a1_intro_plays_through_to_hub_as_one_sequence_and_lands_on_phone", func():
		GameState.reset()
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]
		var sites_before: int = GameState.state["world"]["sites"].size()

		var played := _play_chain_from("col_a1_intro")

		assert_eq(played, ["col_a1_intro", "col_a1_prospecting", "col_a1_seeding", "col_a1_hub"], "each event starts the moment the previous one ends")
		assert_eq(GameState.state["currentScreen"], "phone", "hub's on_complete is the chain's only screen change")
		assert_true(GameState.state["contacts"]["des"]["unlocked"])
		assert_true(GameState.state["contacts"]["nadia"]["unlocked"])
		assert_true(GameState.state["contacts"]["hakim"]["unlocked"])
		for flag in ["colA1DesMet", "collectiveLaneUnlocked", "colA1ProspectingTaught", "colA1SeedingTaught", "colA1DesThreadActive", "colA1HubReached", "colA1ArchiePryAvailable"]:
			assert_true(GameState.state["flags"][flag], "%s set by the chain" % flag)
		assert_eq(GameState.state["flags"]["colA1Stage"], "hub")
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before + 5, "S1's +5 is the chain's only relation award")
		assert_eq(GameState.state["world"]["sites"].size(), sites_before, "the tuition teaches, it doesn't call Sites.prospect()")
		assert_true(Messages.pending_for("des").is_empty(), "no three-things pending message -- hub already played")
		assert_true(not Fixtures.has_notification("Des reckons there's ground worth a look. Check the map."), "no map nudge -- the player never leaves the event")
	)

	run_case("tuition_events_declare_no_map_pin_or_phone_shortcut", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesMet"] = true
		var ids: Array = []
		for pin in MapPins.active_contact_pins():
			ids.append(pin["eventId"])
		assert_true(not ids.has("col_a1_prospecting"))
		assert_true(not ids.has("col_a1_seeding"))
		assert_true(MapPins.active_phone_shortcuts_for("des").is_empty())
	)

	run_case("rewind_inside_a_chained_event_stays_inside_that_event", func():
		GameState.reset()
		GameState.state["player"]["inventory"]["rewind"] = { "1": 2 }
		EventPlay.play_event("col_a1_intro")

		assert_eq(GameState.state["event"]["eventId"], "col_a1_prospecting")
		assert_true(not Events.can_rewind(), "a chained event's first card has no snapshot reaching back into the previous event")

		Events.advance()
		assert_true(Events.rewind()["ok"])
		assert_eq(GameState.state["event"]["eventId"], "col_a1_prospecting", "rewind lands back inside the same event")
		assert_eq(GameState.state["event"]["cardIndex"], 0)
		assert_eq(GameState.state["currentScreen"], "event")

		var played := _play_chain_from("")
		assert_eq(played, ["col_a1_prospecting", "col_a1_seeding", "col_a1_hub"], "the chain still runs to hub after a rewind")
		assert_eq(GameState.state["currentScreen"], "phone")
	)

	# ── S4: col_a1_hub ───────────────────────────────────────────────────

	run_case("col_a1_hub_on_complete_unlocks_nadia_and_hakim_and_activates_des_and_hakim_objectives", func():
		GameState.reset()

		EventPlay.play_event("col_a1_hub")

		assert_true(GameState.state["contacts"]["nadia"]["unlocked"])
		assert_true(GameState.state["contacts"]["hakim"]["unlocked"])
		assert_eq(GameState.state["flags"]["colA1Stage"], "hub")
		assert_true(GameState.state["flags"]["colA1ArchiePryAvailable"])
		assert_true(GameState.state["flags"]["colA1HubReached"], "hub-reached flag gates S11's Whitechapel pin (ticket 13)")
		assert_true(GameState.state["flags"]["colA1DesThreadActive"], "col_a1_des_sites' activateFlag")

		Objectives.refresh()
		assert_true(GameState.state["objectives"]["col_a1_des_sites"]["active"], "S4 activates col_a1_des_sites")
		assert_true(GameState.state["objectives"]["col_a1_hakim_rescue"]["active"], "S4 activates col_a1_hakim_rescue")
		assert_eq(GameState.state["currentScreen"], "phone", "S4 navigates off the event screen")
	)

	run_case("col_a1_hub_does_not_move_collective_relation_on_its_own", func():
		GameState.reset()
		var relation_before: int = GameState.state["factions"]["collective"]["relation"]

		EventPlay.play_event("col_a1_hub")

		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_before, "S4's spec §8.5 award table has no entry for S4 itself")
	)

	# ── §4.1: a player who stops after S4 keeps the lane and never advances ──

	run_case("stopping_after_S4_keeps_the_trading_lane_open_and_relation_never_moves_further", func():
		GameState.reset()
		_play_chain_from("col_a1_intro")
		var relation_after_hub: int = GameState.state["factions"]["collective"]["relation"]

		# Time passes. Nothing the player does (short of trading or the
		# authored thread events, neither of which fires here) should move
		# the Collective's opinion of them.
		for i in range(10):
			TimeSystem.daily_tick()

		assert_true(GameState.state["flags"]["collectiveLaneUnlocked"], "the trading lane stays open")
		assert_eq(GameState.state["factions"]["collective"]["relation"], relation_after_hub, "relation never moves on its own")
	)
