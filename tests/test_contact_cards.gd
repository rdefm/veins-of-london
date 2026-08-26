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
