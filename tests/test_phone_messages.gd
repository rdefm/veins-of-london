extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")

# collective1-03: screen-level tests for the Phone's Messages app (a single
# conversation's history/action bar), same headless-scene pattern as
# tests/test_phone_bank.gd. The staged reveal itself (get_tree().
# create_timer awaits) is explicitly not tested headless (spec §12.3) --
# these only exercise the instant-render/state paths: what a conversation
# shows, what tapping its action bar does.
#
# The home dock restores a conversation index while Contacts remains a
# direct route into the same threads.


func run() -> void:
	run_case("messages_index_lists_names_latest_previews_and_unread_counts", func():
		GameState.reset()
		Messages.append("archie", "them", "First")
		Messages.append("archie", "them", "Latest")
		PhoneNav.open_app("messages")
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has(Contacts.display_name("archie")), "row shows contact name")
		assert_true(texts.has("Latest"), "row shows latest message preview")
		assert_true(texts.has("2"), "row shows unread count")
		phone.free()
	)

	run_case("messages_index_row_opens_thread_and_thread_back_returns_to_index", func():
		GameState.reset()
		Messages.append("archie", "them", "Hello")
		PhoneNav.open_app("messages")
		var phone := PhoneScreen.new()
		phone._ready()
		var rows := phone.find_children("", "Button", true, false)
		var conversation_row: Button = null
		for candidate in rows:
			if candidate != NodeQuery.find_button(phone, "‹ Back"):
				conversation_row = candidate
				break
		assert_true(conversation_row != null, "index has a tappable conversation row")
		conversation_row.pressed.emit()
		assert_eq(GameState.state["phoneNav"]["selectedContactId"], "archie")
		NodeQuery.find_button(phone, "‹ Back").pressed.emit()
		assert_eq(GameState.state["phoneNav"]["app"], "messages")
		assert_eq(GameState.state["phoneNav"]["selectedContactId"], null)
		phone.free()
	)
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

		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("Got something for you."), "already-there history renders instantly")
		assert_true(texts.has("On my way."), "player's own message renders too")

		var button_texts := NodeQuery.button_texts(phone)
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
		GameState.state["flags"]["buyerEventSeen"] = true
		GameState.state["player"]["orichalchum"]["time"] = 1
		PhoneNav.select_conversation("archie")

		var phone := PhoneScreen.new()
		phone._ready()

		var trade := NodeQuery.find_button(phone, "🤝 Trade")
		assert_true(trade != null and not trade.disabled, "Archie's Trade action is available with ore")
		trade.pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "sell_menu")
		assert_eq(GameState.state["modal"]["data"], {}, "Archie's Trade action uses his own lane")

		phone.free()
	)

	run_case("james_conversation_action_bar_shows_neither_trade_nor_sell", func():
		GameState.reset()
		GameState.state["contacts"]["james"]["unlocked"] = true
		PhoneNav.select_conversation("james")

		var phone := PhoneScreen.new()
		phone._ready()

		var button_texts := NodeQuery.button_texts(phone)
		assert_true(not button_texts.has("🤝 Trade (not unlocked yet)") and not button_texts.has("🤝 Trade"), "james's thread never shows the Collective Trade door")

		phone.free()
	)

	run_case("back_from_a_contact_card_conversation_returns_to_messages_index", func():
		GameState.reset()
		GameState.state["contacts"]["des"] = { "unlocked": true, "relation": 0 }
		PhoneNav.select_conversation("des")

		var phone := PhoneScreen.new()
		phone._ready()

		var back_button := NodeQuery.find_button(phone, "‹ Back")
		assert_true(back_button != null, "conversation view has a Back button")
		back_button.pressed.emit()

		assert_eq(GameState.state["phoneNav"]["app"], "messages", "back from a conversation lands on the Messages index")
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

		var action_button := NodeQuery.find_button(phone, "Continue →")
		assert_true(action_button != null, "a pending entry surfaces its own action-bar button")
		action_button.pressed.emit()

		assert_eq(GameState.state["pendingMessages"].size(), 0, "the entry is removed once its action is taken")
		assert_eq(GameState.state["event"]["eventId"], "col_a1_des_report", "tapping it starts the event")
		assert_eq(GameState.state["event"]["context"], { "site_id": "s1" }, "the payload travels as the event's context")

		phone.free()
	)
