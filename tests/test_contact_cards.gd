extends "res://tests/test_base.gd"

# collective1-07: ContactCards' static builders return plain Controls with
# no scene-tree dependency, so they're testable directly -- same reasoning
# tests/test_modal_layer.gd gives for instantiating ModalLayer.new() without
# adding it to a live tree.


static func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		texts.append((l as Label).text)
	return texts


static func _button_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for b in root.find_children("", "Button", true, false):
		texts.append((b as Button).text)
	return texts


static func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


func run() -> void:
	# ── §7.1: the recruit row is suppressed, not shown-disabled ──────────

	run_case("build_recruit_row_returns_null_for_a_non_recruitable_contact", func():
		GameState.reset()
		for key in ["des", "nadia", "hakim"]:
			assert_eq(ContactCards.build_recruit_row(key), null, "%s's recruit row must not exist at all" % key)
	)

	run_case("build_recruit_row_is_unchanged_for_archie_and_james", func():
		GameState.reset()
		assert_true(ContactCards.build_recruit_row("archie") != null, "archie keeps a recruit row")
		GameState.state["contacts"]["james"]["unlocked"] = true
		assert_true(ContactCards.build_recruit_row("james") != null, "james keeps a recruit row")
	)

	# ── §5.5/§7.2: the Trade door ─────────────────────────────────────────

	run_case("build_trade_action_is_locked_before_collectiveLaneUnlocked", func():
		GameState.reset()
		var b := ContactCards.build_trade_action("des") as Button
		assert_eq(b.text, "🤝 Trade (not unlocked yet)")
		assert_true(b.disabled, "locked until flags.collectiveLaneUnlocked")
	)

	run_case("build_trade_action_opens_sell_menu_routed_to_the_collective_lane_once_unlocked", func():
		GameState.reset()
		GameState.state["flags"]["collectiveLaneUnlocked"] = true
		var b := ContactCards.build_trade_action("nadia") as Button
		assert_eq(b.text, "🤝 Trade")
		assert_true(not b.disabled)

		b.pressed.emit()

		assert_eq(GameState.state["modal"]["type"], "sell_menu")
		assert_eq(GameState.state["modal"]["data"], { "factionId": "collective", "contactId": "nadia" })
	)

	# ── 82-contacts-des-nadia-hakim-cards: Des/Nadia/Hakim's Contacts cards ──

	run_case("des_nadia_hakim_cards_show_a_relation_heading_and_card_line", func():
		GameState.reset()
		var des_texts := _label_texts(ContactCards.build_des_card())
		assert_true(des_texts.has("Des — Relation 0"), "des heading")
		assert_true(des_texts.has("Prospector · Crystal Palace"), "des card line, spec.md §3.1")

		var nadia_texts := _label_texts(ContactCards.build_nadia_card())
		assert_true(nadia_texts.has("Nadia — Relation 0"), "nadia heading")
		assert_true(nadia_texts.has("Fixer · Hackney"), "nadia card line, spec.md §3.2")

		var hakim_texts := _label_texts(ContactCards.build_hakim_card())
		assert_true(hakim_texts.has("Hakim — Relation 0"), "hakim heading")
		assert_true(hakim_texts.has("Newsagent · Whitechapel"), "hakim card line, spec.md §3.3")
	)

	run_case("des_nadia_hakim_cards_never_show_a_recruit_row", func():
		GameState.reset()
		for text in _button_texts(ContactCards.build_des_card()):
			assert_true(not text.begins_with("⭐"), "des card must not surface a recruit button: %s" % text)
		for text in _button_texts(ContactCards.build_nadia_card()):
			assert_true(not text.begins_with("⭐"), "nadia card must not surface a recruit button: %s" % text)
		for text in _button_texts(ContactCards.build_hakim_card()):
			assert_true(not text.begins_with("⭐"), "hakim card must not surface a recruit button: %s" % text)
	)

	run_case("des_card_surfaces_its_story_actions_same_as_the_conversation_action_bar", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesSitesFound"] = true
		assert_true(_find_button(ContactCards.build_des_card(), "Tell Des about the ground") != null, "report action reused from build_des_report_action()")

		GameState.state["flags"]["colA1DeferredJoin"] = true
		assert_true(_find_button(ContactCards.build_des_card(), "Ask Des about joining") != null, "deferred-join action reused from build_ask_des_joining_action()")
	)

	# ── 103-phone-shortcut-for-pin-gated-quests ──────────────────────────

	run_case("des_card_surfaces_a_phone_shortcut_for_a_pin_gated_event_and_starts_it_directly", func():
		GameState.reset()
		assert_true(_find_button(ContactCards.build_des_card(), "📍 Go prospecting with Des") == null, "hidden before colA1DesMet -- pin isn't active yet")

		GameState.state["flags"]["colA1DesMet"] = true
		var button := _find_button(ContactCards.build_des_card(), "📍 Go prospecting with Des")
		assert_true(button != null, "shown once the map pin's own gate is met -- same data, second surface")

		button.pressed.emit()

		assert_eq(GameState.state["event"]["eventId"], "col_a1_prospecting", "tapping starts the event directly, no travel required")
	)

	run_case("des_card_phone_shortcut_moves_on_to_the_seeding_pin_once_prospecting_is_taught", func():
		GameState.reset()
		GameState.state["flags"]["colA1ProspectingTaught"] = true

		assert_true(_find_button(ContactCards.build_des_card(), "📍 Go prospecting with Des") == null, "prospecting pin is gone once taught")
		var button := _find_button(ContactCards.build_des_card(), "📍 Go seed a patch with Des")
		assert_true(button != null, "seeding pin's own gate is now met")

		button.pressed.emit()

		assert_eq(GameState.state["event"]["eventId"], "col_a1_seeding")
	)

	run_case("build_pin_shortcut_actions_is_generic_not_hardcoded_to_des", func():
		GameState.reset()
		GameState.state["flags"]["colA1DesMet"] = true
		assert_true(ContactCards.build_pin_shortcut_actions("archie").is_empty(), "archie has no active pin-gated event right now -- must not pick up des's")
		assert_true(ContactCards.build_pin_shortcut_actions("nadia").is_empty())
	)

	run_case("nadia_card_surfaces_its_story_action_same_as_the_conversation_action_bar", func():
		GameState.reset()
		assert_true(_find_button(ContactCards.build_nadia_card(), "Go and see Nadia") != null, "meet action visible by default (colA1NadiaMet starts false)")

		GameState.state["flags"]["colA1NadiaMet"] = true
		assert_true(_find_button(ContactCards.build_nadia_card(), "Go and see Nadia") == null, "vanishes once met")
	)

	run_case("hakim_card_surfaces_its_story_action_same_as_the_conversation_action_bar", func():
		GameState.reset()
		assert_true(_find_button(ContactCards.build_hakim_card(), "Hand Hakim's vein back") == null, "hidden before colA1HakimRescued")

		GameState.state["flags"]["colA1HakimRescued"] = true
		assert_true(_find_button(ContactCards.build_hakim_card(), "Hand Hakim's vein back") != null, "reused from build_hakim_done_action()")
	)

	run_case("messages_button_opens_the_pressed_contacts_own_thread", func():
		for contact_id in ["des", "nadia", "hakim"]:
			GameState.reset()
			var builder: Callable
			match contact_id:
				"des":
					builder = ContactCards.build_des_card
				"nadia":
					builder = ContactCards.build_nadia_card
				"hakim":
					builder = ContactCards.build_hakim_card

			var button := _find_button(builder.call(), "💬 Messages")
			assert_true(button != null, "%s card has a Messages button" % contact_id)

			button.pressed.emit()

			assert_eq(GameState.state["currentScreen"], "phone", "%s: Messages button navigates to the phone screen" % contact_id)
			assert_eq(GameState.state["phoneNav"]["app"], "messages", "%s: lands in the Messages app" % contact_id)
			assert_eq(GameState.state["phoneNav"]["selectedContactId"], contact_id, "%s: opens that contact's own thread, not another's" % contact_id)
	)

	run_case("des_card_surfaces_a_pending_message_as_a_continue_button", func():
		GameState.reset()
		Messages.queue_pending("des", "col_a1_hub", "When you've got a minute.")

		var button := _find_button(ContactCards.build_des_card(), "Continue →")
		assert_true(button != null, "pendingMessages entries surface the same way build_archie_card()'s own loop does")

		button.pressed.emit()

		assert_eq(GameState.state["event"]["eventId"], "col_a1_hub", "pressing it resolves the pending entry and starts its event")
		assert_true(Messages.pending_for("des").is_empty(), "the pending entry is resolved once acted on")
	)

	run_case("messages_button_shows_an_unread_dot_and_pressing_it_marks_the_thread_read", func():
		GameState.reset()
		Messages.append("des", "them", "Got something for you.")

		var button := _find_button(ContactCards.build_des_card(), "💬 Messages ●")
		assert_true(button != null, "unread dot appended while the thread has an unread message")

		button.pressed.emit()

		assert_true(not Messages.has_unread("des"), "opening the thread marks it read (PhoneNav.select_conversation)")
	)

	# ── 83-contacts-archie-james-sms-port ─────────────────────────────────

	run_case("archie_and_james_cards_get_a_messages_button", func():
		GameState.reset()
		assert_true(_find_button(ContactCards.build_archie_card(), "💬 Messages") != null, "archie card has a Messages button")

		GameState.state["contacts"]["james"]["unlocked"] = true
		assert_true(_find_button(ContactCards.build_james_card(), "💬 Messages") != null, "james card has a Messages button")
	)

	run_case("archie_card_no_longer_surfaces_its_old_bespoke_sms_buttons", func():
		GameState.reset()
		GameState.state["flags"]["archieMotionPending"] = true
		GameState.state["flags"]["tutorialStage"] = "sms_archie"
		var texts := _button_texts(ContactCards.build_archie_card())
		for text in texts:
			assert_true(not text.begins_with("💬 Archie texted") and not text.begins_with("💬 Message Archie") and not text.begins_with("💬 Archie wants to meet"), "no bespoke flag-driven SMS button survives: %s" % text)
	)

	run_case("james_card_no_longer_surfaces_its_old_visit_james_button", func():
		GameState.reset()
		GameState.state["contacts"]["james"]["unlocked"] = true
		GameState.state["flags"]["archieMotionEventSeen"] = true
		var texts := _button_texts(ContactCards.build_james_card())
		assert_true(not texts.has("💬 Visit James — ask about new recipes"), "the old flag-driven button is gone")
	)

	run_case("archie_card_surfaces_a_pending_message_as_a_generic_continue_button", func():
		GameState.reset()
		Messages.queue_pending("archie", "archie_motion", "good output. call me.")

		var button := _find_button(ContactCards.build_archie_card(), "Continue →")
		assert_true(button != null, "pendingMessages entries surface the same generic way build_des_card()'s loop does")

		button.pressed.emit()

		assert_eq(GameState.state["event"]["eventId"], "archie_motion", "pressing it resolves the pending entry and starts its event")
		assert_true(Messages.pending_for("archie").is_empty(), "the pending entry is resolved once acted on")
	)

	run_case("james_card_surfaces_a_pending_message_as_a_generic_continue_button", func():
		GameState.reset()
		GameState.state["contacts"]["james"]["unlocked"] = true
		Messages.queue_pending("james", "james_motion", "Overflow work, if you're capable of it. Come by.")

		var button := _find_button(ContactCards.build_james_card(), "Continue →")
		assert_true(button != null, "pendingMessages entries surface the same generic way on james's card")

		button.pressed.emit()

		assert_eq(GameState.state["event"]["eventId"], "james_motion", "pressing it resolves the pending entry and starts its event")
		assert_true(Messages.pending_for("james").is_empty(), "the pending entry is resolved once acted on")
	)

	# ── bugfixes-95: Archie's tag-along deal offer ────────────────────────

	run_case("archie_card_surfaces_a_deal_offer_as_accept_decline_not_a_generic_continue_button", func():
		GameState.reset()
		Messages.queue_pending("archie", ArchieDeals.PENDING_KIND, "Fancy tagging along for a cut?")

		var card := ContactCards.build_archie_card()
		assert_true(_find_button(card, "Accept") != null, "should show an Accept button")
		assert_true(_find_button(card, "Decline") != null, "should show a Decline button")
		assert_true(_find_button(card, "Continue →") == null, "an archie_deal offer must not fall into the generic Continue loop -- it has no event to start")
	)

	run_case("pressing_accept_on_archie_card_accepts_the_deal", func():
		GameState.reset()
		GameState.state["flags"]["archieDealActive"] = true
		Messages.queue_pending("archie", ArchieDeals.PENDING_KIND, "Fancy tagging along for a cut?")

		var button := _find_button(ContactCards.build_archie_card(), "Accept")
		button.pressed.emit()

		assert_true(Messages.pending_for("archie").is_empty(), "the pending entry is resolved once acted on")
		assert_true(GameState.state["contacts"]["archie"]["relation"] != 10 or GameState.state["combat"]["active"], "accepting should have moved state forward (relation award and/or a mugging)")
	)

	run_case("pressing_decline_on_archie_card_declines_the_deal", func():
		GameState.reset()
		GameState.state["flags"]["archieDealActive"] = true
		Messages.queue_pending("archie", ArchieDeals.PENDING_KIND, "Fancy tagging along for a cut?")
		var relation_before: int = GameState.state["contacts"]["archie"]["relation"]

		var button := _find_button(ContactCards.build_archie_card(), "Decline")
		button.pressed.emit()

		assert_true(Messages.pending_for("archie").is_empty(), "the pending entry is resolved once acted on")
		assert_eq(GameState.state["flags"]["archieDealActive"], false, "archieDealActive cleared")
		assert_eq(GameState.state["contacts"]["archie"]["relation"], relation_before + ArchieDeals.DECLINE_RELATION_LOSS, "declining docks relation")
	)
