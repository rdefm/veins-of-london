extends "res://tests/test_base.gd"

# collective1-03: screen-level tests for the Phone's Messages app (a single
# conversation's history/action bar), same headless-scene pattern as
# tests/test_phone_bank.gd. The staged reveal itself (get_tree().
# create_timer awaits) is explicitly not tested headless (spec §12.3) --
# these only exercise the instant-render/state paths: what a conversation
# shows, what tapping its action bar does.
#
# 84-contacts-retire-messages-tile: the conversation-list view these used to
# exercise (row rendering, "Open ->", the empty state, the top-level tile)
# is gone -- Contacts is the only way in now (tests/test_contact_cards.gd
# covers that button), so every case here opens its conversation the same
# way that button does: PhoneNav.select_conversation() directly.


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
	run_case("selecting_a_conversation_marks_it_read_and_renders_its_history_and_trade_button", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		Messages.append("des", "them", "Got something for you.")
		Messages.append("des", "player", "On my way.")

		PhoneNav.select_conversation("des")

		var phone := PhoneScreen.new()
		phone._ready()

		assert_eq(GameState.state["phoneNav"]["selectedContactId"], "des", "select_conversation opens that contact's thread")
		assert_true(not Messages.has_unread("des"), "opening marks the conversation read")

		var texts := _label_texts(phone)
		assert_true(texts.has("Got something for you."), "already-there history renders instantly")
		assert_true(texts.has("On my way."), "player's own message renders too")

		var button_texts := _button_texts(phone)
		assert_true(button_texts.has("🤝 Trade (not unlocked yet)"), "Trade action bar entry reuses ContactCards.build_trade_action() (collective1-07)")

		phone.free()
	)

	# 83-contacts-archie-james-sms-port: Archie/James aren't Collective doors
	# -- their conversation action bar must not fall through to the generic
	# build_trade_action() (the Collective faction lane). Archie keeps his
	# own build_sell_action(); James gets neither (job-offer flow is
	# card-only, out of this ticket's scope).
	run_case("archie_conversation_action_bar_shows_his_own_sell_action_not_the_collective_trade_door", func():
		GameState.reset()
		PhoneNav.select_conversation("archie")

		var phone := PhoneScreen.new()
		phone._ready()

		var button_texts := _button_texts(phone)
		assert_true(not button_texts.has("🤝 Trade (not unlocked yet)") and not button_texts.has("🤝 Trade"), "archie's thread never shows the Collective Trade door")
		assert_true(button_texts.has("💰 Find a buyer (not unlocked yet)"), "archie's thread shows his own sell action instead, same as his Contacts card")

		phone.free()
	)

	run_case("james_conversation_action_bar_shows_neither_trade_nor_sell", func():
		GameState.reset()
		GameState.state["contacts"]["james"]["unlocked"] = true
		PhoneNav.select_conversation("james")

		var phone := PhoneScreen.new()
		phone._ready()

		var button_texts := _button_texts(phone)
		assert_true(not button_texts.has("🤝 Trade (not unlocked yet)") and not button_texts.has("🤝 Trade"), "james's thread never shows the Collective Trade door")
		assert_true(not button_texts.has("💰 Find a buyer (not unlocked yet)") and not button_texts.has("💰 Find a buyer"), "james's thread has no sell action of its own")

		phone.free()
	)

	# 84-contacts-retire-messages-tile: back from a conversation has nowhere
	# left to return to but the app grid -- the conversation-list it used to
	# return to is gone.
	run_case("back_from_a_conversation_returns_to_the_phone_home_grid", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		PhoneNav.select_conversation("des")

		var phone := PhoneScreen.new()
		phone._ready()

		var back_button := _find_button(phone, "‹ Back")
		assert_true(back_button != null, "conversation view has a Back button")
		back_button.pressed.emit()

		assert_eq(GameState.state["phoneNav"]["app"], "home", "back from a conversation lands on the app grid")
		assert_eq(GameState.state["phoneNav"]["selectedContactId"], null, "back clears the drill-down")

		phone.free()
	)

	run_case("a_pending_message_action_button_resolves_the_entry_and_starts_its_event", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		Messages.queue_pending("des", "col_a1_des_report", "Got something for you.", { "site_id": "s1" })
		PhoneNav.select_conversation("des")

		var phone := PhoneScreen.new()
		phone._ready()

		var action_button := _find_button(phone, "Continue →")
		assert_true(action_button != null, "a pending entry surfaces its own action-bar button")
		action_button.pressed.emit()

		assert_eq(GameState.state["pendingMessages"].size(), 0, "the entry is removed once its action is taken")
		assert_eq(GameState.state["event"]["eventId"], "col_a1_des_report", "tapping it starts the event")
		assert_eq(GameState.state["event"]["context"], { "site_id": "s1" }, "the payload travels as the event's context")

		phone.free()
	)
