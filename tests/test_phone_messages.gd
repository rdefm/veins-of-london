extends "res://tests/test_base.gd"

# collective1-03: screen-level tests for the Phone's Messages app
# (conversation list + a single conversation's history/action bar),
# same headless-scene pattern as tests/test_phone_bank.gd. The staged
# reveal itself (get_tree().create_timer awaits) is explicitly not tested
# headless (spec §12.3) -- these only exercise the instant-render/state
# paths: which conversations list, what a row shows, what opening/tapping
# an entry does to state.


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
	# 83-contacts-archie-james-sms-port: Archie and James are full members of
	# the Messages app now -- their old bespoke SMS screens are gone.
	run_case("conversation_list_includes_archie_and_james_once_unlocked", func():
		GameState.reset()
		GameState.state["contacts"]["james"]["unlocked"] = true
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["phoneNav"]["app"] = "messages"

		var phone := PhoneScreen.new()
		phone._ready()

		var texts := _label_texts(phone)
		assert_true(texts.has("Archie"), "archie appears in the new Messages app (unlocked from game start)")
		assert_true(texts.has("James"), "james appears in the new Messages app once unlocked")
		assert_true(texts.has("Des"), "a new-shape unlocked contact appears")

		phone.free()
	)

	run_case("conversation_row_shows_an_unread_dot_and_the_latest_message_preview", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		Messages.append("des", "them", "Got something for you.")
		GameState.state["phoneNav"]["app"] = "messages"

		var phone := PhoneScreen.new()
		phone._ready()

		var texts := _label_texts(phone)
		assert_true(texts.has("Des ●"), "unread dot appended to the contact's name")
		assert_true(texts.has("Got something for you."), "row shows the latest message as a preview")

		phone.free()
	)

	run_case("empty_state_shown_when_no_conversations_are_unlocked_yet", func():
		GameState.reset()
		# archie is unlocked by default (data/constants.json) -- lock him out
		# here so this case is a genuine zero-conversations state.
		GameState.state["contacts"]["archie"]["unlocked"] = false
		GameState.state["phoneNav"]["app"] = "messages"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(_label_texts(phone).has("No conversations yet."), "empty state message")

		phone.free()
	)

	run_case("opening_a_conversation_marks_it_read_and_shows_its_history_and_trade_button", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		Messages.append("des", "them", "Got something for you.")
		Messages.append("des", "player", "On my way.")
		GameState.state["phoneNav"]["app"] = "messages"

		var phone := PhoneScreen.new()
		phone._ready()

		var open_button := _find_button(phone, "Open →")
		assert_true(open_button != null, "conversation list has an Open button")
		open_button.pressed.emit()

		assert_eq(GameState.state["phoneNav"]["selectedContactId"], "des", "opening navigates into the conversation")
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
		GameState.state["phoneNav"]["app"] = "messages"
		GameState.state["phoneNav"]["selectedContactId"] = "archie"

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
		GameState.state["phoneNav"]["app"] = "messages"
		GameState.state["phoneNav"]["selectedContactId"] = "james"

		var phone := PhoneScreen.new()
		phone._ready()

		var button_texts := _button_texts(phone)
		assert_true(not button_texts.has("🤝 Trade (not unlocked yet)") and not button_texts.has("🤝 Trade"), "james's thread never shows the Collective Trade door")
		assert_true(not button_texts.has("💰 Find a buyer (not unlocked yet)") and not button_texts.has("💰 Find a buyer"), "james's thread has no sell action of its own")

		phone.free()
	)

	run_case("back_from_a_conversation_returns_to_the_list", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		GameState.state["phoneNav"]["app"] = "messages"
		GameState.state["phoneNav"]["selectedContactId"] = "des"

		var phone := PhoneScreen.new()
		phone._ready()

		var back_button := _find_button(phone, "‹ Back")
		assert_true(back_button != null, "conversation view has a Back button")
		back_button.pressed.emit()

		assert_eq(GameState.state["phoneNav"]["selectedContactId"], null, "back clears the drill-down")

		phone.free()
	)

	run_case("a_pending_message_action_button_resolves_the_entry_and_starts_its_event", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		Messages.queue_pending("des", "col_a1_des_report", "Got something for you.", { "site_id": "s1" })
		GameState.state["phoneNav"]["app"] = "messages"
		GameState.state["phoneNav"]["selectedContactId"] = "des"

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

	run_case("messages_app_is_reachable_from_the_app_grid_via_the_messages_tile", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		var messages_tile: AppTile = null
		for t in phone.find_children("", "AppTile", true, false):
			if (t as AppTile)._app_id == "messages":
				messages_tile = t
		assert_true(messages_tile != null, "the app grid must include a Messages tile")

		var event := InputEventScreenTouch.new()
		event.pressed = true
		messages_tile._on_gui_input(event)

		assert_eq(GameState.state["phoneNav"]["app"], "messages", "tapping the tile opens the messages app via PhoneNav")

		phone.free()
	)
