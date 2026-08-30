extends "res://tests/test_base.gd"

# collective1-08, spec.md §4/§6.1-6.4: Act 1 Phase 1 -- the mandatory tuition
# chain (S1-S4). Drives the real col_a1_intro/col_a1_prospecting/
# col_a1_seeding/col_a1_hub event JSON card-by-card, same idiom
# tests/test_playthrough.gd already uses for archie_cultivation.


func _play_event(event_id: String) -> void:
	Events.start_event(event_id)
	for i in range(GameData.EVENTS[event_id]["cards"].size()):
		Events.advance()


# Same idiom as tests/test_events.gd's own _has_notification().
func _has_notification(text: String) -> bool:
	for n in GameState.state["notifications"]:
		if n["text"] == text:
			return true
	return false


func _collective_section() -> Variant:
	for section in Todo.get_active_questlines():
		if section["questline"] == "collective":
			return section
	return null


# Looks an item up by title rather than a fixed index -- S4 (col_a1_hub)
# also flips colA1HubReached/colA1DesThreadActive, which simultaneously
# activates col_a1_des_sites and col_a1_hakim_rescue (their own activateFlags
# per data/objectives.json), so the Collective section's item count grows
# past MAX_ITEMS_PER_SECTION and the cap trims from the front -- a positional
# index into "items" would be fragile to that unrelated activation.
func _find_item(items: Array, title: String) -> Variant:
	for item in items:
		if item["title"] == title:
			return item
	return null


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
		# 83-contacts-archie-james-sms-port: Archie's card now surfaces every
		# pendingMessages entry with the same generic "Continue →" label
		# Des/Nadia/Hakim's cards use -- the actual S1 text lives in the
		# message thread itself (previous test case), not the button.
		var button := _find_button(card, "Continue →")
		assert_true(button != null, "Archie's contacts card should surface the pending S1 entry as a button")

		button.pressed.emit()

		assert_eq(GameState.state["event"]["eventId"], "col_a1_intro", "pressing the button should start col_a1_intro")
		assert_eq(Messages.pending_for("archie").size(), 0, "the pending entry should be resolved once its action is taken")
	)

	run_case("archie_card_shows_no_pending_button_before_archie_cultivation_fires", func():
		GameState.reset()
		var card := ContactCards.build_archie_card()
		assert_true(_find_button(card, "Continue →") == null, "no pending entry yet -- no button")
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

	# ── ticket 90: Notes never goes silent through the S1-S4 tuition chain ──

	run_case("col_a1_intro_on_complete_notifies_the_player_to_check_the_map_and_notes_goes_from_empty_to_showing_the_chain", func():
		GameState.reset()
		assert_true(_collective_section() == null, "no Collective section before Des is even met")

		_play_event("col_a1_intro")

		assert_true(_has_notification("Des reckons there's ground worth a look. Check the map."), "S1 should notify the player where to look next, not leave them silent")

		var section: Variant = _collective_section()
		assert_true(section != null, "Notes' Collective section should appear the instant colA1DesMet flips true")
		assert_eq(section["items"].size(), 1)
		assert_eq(section["items"][0]["title"], "Des is waiting on the map. He'll teach you to prospect.")
		assert_eq(section["items"][0]["done"], false)
	)

	run_case("notes_tracks_the_full_tuition_chain_through_S2_S3_S4", func():
		GameState.reset()
		_play_event("col_a1_intro")

		_play_event("col_a1_prospecting")
		var items: Array = _collective_section()["items"]
		assert_eq(_find_item(items, "Des is waiting on the map. He'll teach you to prospect.")["done"], true, "S2 taught -- the prospecting step should render checked")
		assert_eq(_find_item(items, "Des is waiting on the map. He'll teach you to seed a patch.")["done"], false)

		_play_event("col_a1_seeding")
		items = _collective_section()["items"]
		assert_eq(_find_item(items, "Des is waiting on the map. He'll teach you to seed a patch.")["done"], true, "S3 taught -- the seeding step should render checked")
		assert_eq(_find_item(items, "Des has texted — three things he needs help with. Check Contacts.")["done"], false)

		_play_event("col_a1_hub")
		items = _collective_section()["items"]
		assert_eq(_find_item(items, "Des has texted — three things he needs help with. Check Contacts.")["done"], true, "S4 reached -- the hub step should render checked")
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

	# ── ticket 103: phone shortcut is a second path to the same pin-gated event ──

	run_case("col_a1_prospecting_reaches_the_same_outcome_via_the_phone_shortcut_as_via_the_map_pin", func():
		# Map-pin path (existing precedent: this is exactly what
		# MapCanvas._activate_pin() does when the player taps the pin).
		GameState.reset()
		GameState.state["flags"]["colA1DesMet"] = true
		_play_event("col_a1_prospecting")
		var via_pin_taught: bool = GameState.state["flags"]["colA1ProspectingTaught"]
		var via_pin_screen: String = GameState.state["currentScreen"]

		# Phone-shortcut path: same event, reached instead by pressing the
		# button ContactCards.build_des_card() surfaces (ticket 103) -- no
		# travel, no map pin tapped.
		GameState.reset()
		GameState.state["flags"]["colA1DesMet"] = true
		var button := _find_button(ContactCards.build_des_card(), "📍 Go prospecting with Des")
		assert_true(button != null, "phone shortcut must be available whenever the map pin is")
		button.pressed.emit()
		for i in range(GameData.EVENTS["col_a1_prospecting"]["cards"].size()):
			Events.advance()
		var via_phone_taught: bool = GameState.state["flags"]["colA1ProspectingTaught"]
		var via_phone_screen: String = GameState.state["currentScreen"]

		assert_true(via_pin_taught, "sanity: map-pin path teaches prospecting")
		assert_eq(via_phone_taught, via_pin_taught, "phone shortcut must leave the same flag outcome as the map pin")
		assert_eq(via_phone_screen, via_pin_screen, "phone shortcut must leave the same on_complete navigation as the map pin")

		# The map pin itself keeps working unchanged -- this is an additional
		# access path, not a replacement.
		var pins := MapPins.active_contact_pins()
		var ids: Array = []
		for pin in pins:
			ids.append(pin["eventId"])
		assert_true(not ids.has("col_a1_prospecting"), "pin gone once taught, exactly as before -- both paths converge on the same flag")
	)

	run_case("col_a1_seeding_reaches_the_same_outcome_via_the_phone_shortcut_as_via_the_map_pin", func():
		# Map-pin path.
		GameState.reset()
		GameState.state["flags"]["colA1ProspectingTaught"] = true
		_play_event("col_a1_seeding")
		var via_pin_taught: bool = GameState.state["flags"]["colA1SeedingTaught"]
		var via_pin_screen: String = GameState.state["currentScreen"]
		var via_pin_pending: Array = Messages.pending_for("des")

		# Phone-shortcut path.
		GameState.reset()
		GameState.state["flags"]["colA1ProspectingTaught"] = true
		var button := _find_button(ContactCards.build_des_card(), "📍 Go seed a patch with Des")
		assert_true(button != null, "phone shortcut must be available whenever the map pin is")
		button.pressed.emit()
		for i in range(GameData.EVENTS["col_a1_seeding"]["cards"].size()):
			Events.advance()
		var via_phone_taught: bool = GameState.state["flags"]["colA1SeedingTaught"]
		var via_phone_screen: String = GameState.state["currentScreen"]
		var via_phone_pending: Array = Messages.pending_for("des")

		assert_true(via_pin_taught, "sanity: map-pin path teaches seeding")
		assert_eq(via_phone_taught, via_pin_taught, "phone shortcut must leave the same flag outcome as the map pin")
		assert_eq(via_phone_screen, via_pin_screen, "phone shortcut must leave the same on_complete navigation as the map pin")
		assert_eq(via_phone_pending.size(), via_pin_pending.size(), "both paths queue the same col_a1_hub pending message for des")

		var pins := MapPins.active_contact_pins()
		var ids: Array = []
		for pin in pins:
			ids.append(pin["eventId"])
		assert_true(not ids.has("col_a1_seeding"), "pin gone once taught, exactly as before -- both paths converge on the same flag")
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
