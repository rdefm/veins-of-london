extends "res://tests/test_base.gd"

# collective1-03: unit seams for systems/messages.gd (spec §12.2's
# "pendingMessages / messages" row — append, unread, mark-read, 50-message
# cap eviction), plus the conversation-list ordering/exclusion rule and the
# push_message/unlock_contact effect ops (Events._apply_one()).

# Contacts default to only archie/james (data/constants.json) -- ticket 07
# adds the real new-shape roster. A synthetic contact injected straight
# into GameState.state["contacts"] (not GameData.CONTACTS_DEFAULTS) keeps
# these tests independent of that ticket, same reasoning test_events.gd's
# _install_choice_event() documents for synthetic events.
func _add_test_contact(contact_id: String, unlocked: bool = true) -> void:
	GameState.state["contacts"][contact_id] = { "unlocked": unlocked, "relation": 0 }


func run() -> void:
	run_case("append_marks_an_incoming_message_unread_and_a_player_message_read", func():
		GameState.reset()
		_add_test_contact("des")

		Messages.append("des", "them", "Hello.")
		Messages.append("des", "player", "Hi.")

		var thread: Array = GameState.state["messages"]["des"]
		assert_eq(thread.size(), 2, "both messages recorded")
		assert_eq(thread[0]["read"], false, "an incoming message starts unread")
		assert_eq(thread[1]["read"], true, "a player message is already read")
		assert_eq(thread[0]["day"], GameState.state["world"]["day"], "message stamped with the current day")
	)

	run_case("has_unread_and_has_any_unread_reflect_read_state", func():
		GameState.reset()
		_add_test_contact("des")
		_add_test_contact("nadia")

		assert_true(not Messages.has_unread("des"), "no messages yet -- not unread")
		assert_true(not Messages.has_any_unread(), "nothing unread anywhere yet")

		Messages.append("des", "them", "Hello.")
		assert_true(Messages.has_unread("des"), "an incoming message is unread")
		assert_true(Messages.has_any_unread(), "unread in at least one conversation")
		assert_true(not Messages.has_unread("nadia"), "unread is per-conversation")
	)

	run_case("mark_read_clears_unread_across_the_whole_conversation", func():
		GameState.reset()
		_add_test_contact("des")

		Messages.append("des", "them", "One.")
		Messages.append("des", "them", "Two.")
		Messages.mark_read("des")

		assert_true(not Messages.has_unread("des"), "mark_read clears every message in the thread")
	)

	run_case("append_evicts_from_the_front_once_the_50_message_cap_is_exceeded", func():
		GameState.reset()
		_add_test_contact("des")

		for i in range(55):
			Messages.append("des", "them", "Message %d" % i)

		var thread: Array = GameState.state["messages"]["des"]
		assert_eq(thread.size(), Messages.CAP, "capped at 50")
		assert_eq(thread[0]["text"], "Message 5", "the oldest 5 were evicted from the front")
		assert_eq(thread[thread.size() - 1]["text"], "Message 54", "the newest message survives")
	)

	run_case("queue_pending_appends_an_unread_message_and_a_pendingMessages_entry", func():
		GameState.reset()
		_add_test_contact("des")

		Messages.queue_pending("des", "col_a1_des_report", "Got something for you.", { "site_id": "s1" })

		var thread: Array = GameState.state["messages"]["des"]
		assert_eq(thread.size(), 1, "the text lands in the conversation")
		assert_eq(thread[0]["read"], false, "and is unread")
		assert_eq(GameState.state["pendingMessages"].size(), 1, "one pending entry queued")

		var entry: Dictionary = GameState.state["pendingMessages"][0]
		assert_eq(entry["contactId"], "des")
		assert_eq(entry["kind"], "col_a1_des_report")
		assert_eq(entry["payload"], { "site_id": "s1" })
	)

	run_case("pending_for_filters_to_the_given_contact", func():
		GameState.reset()
		_add_test_contact("des")
		_add_test_contact("nadia")

		Messages.queue_pending("des", "event_a", "A.")
		Messages.queue_pending("nadia", "event_b", "B.")

		var des_pending := Messages.pending_for("des")
		assert_eq(des_pending.size(), 1, "only des's entry")
		assert_eq(des_pending[0]["kind"], "event_a")
	)

	run_case("resolve_pending_removes_only_the_matching_entry", func():
		GameState.reset()
		_add_test_contact("des")

		Messages.queue_pending("des", "event_a", "A.")
		Messages.queue_pending("des", "event_b", "B.")
		var id_to_remove: String = GameState.state["pendingMessages"][0]["id"]

		Messages.resolve_pending(id_to_remove)

		assert_eq(GameState.state["pendingMessages"].size(), 1, "one entry removed")
		assert_eq(GameState.state["pendingMessages"][0]["kind"], "event_b", "the other entry survives")
	)

	# 83-contacts-archie-james-sms-port: archie/james are full members of the
	# conversation list now -- their old bespoke SMS screens are gone.
	run_case("conversation_contact_ids_includes_archie_and_james_once_unlocked", func():
		GameState.reset()
		GameState.state["contacts"]["archie"]["unlocked"] = true
		GameState.state["contacts"]["james"]["unlocked"] = true
		_add_test_contact("des")

		var ids := Messages.conversation_contact_ids()
		assert_true(ids.has("archie"), "archie appears once unlocked")
		assert_true(ids.has("james"), "james appears once unlocked")
		assert_true(ids.has("des"), "a new-shape unlocked contact appears")
	)

	run_case("conversation_contact_ids_excludes_locked_contacts", func():
		GameState.reset()
		_add_test_contact("des", false)

		assert_true(not Messages.conversation_contact_ids().has("des"), "locked contacts don't appear")
	)

	run_case("conversation_contact_ids_sorts_most_recent_activity_first", func():
		GameState.reset()
		# archie is unlocked by default (data/constants.json) -- lock him out
		# here so he doesn't join the no-activity tail this case is scoped to.
		GameState.state["contacts"]["archie"]["unlocked"] = false
		_add_test_contact("des")
		_add_test_contact("nadia")
		_add_test_contact("hakim")

		Messages.append("des", "them", "Old.")
		GameState.state["world"]["day"] = 5
		Messages.append("hakim", "them", "New.")
		# nadia never gets a message -- should sort last.

		var ids := Messages.conversation_contact_ids()
		assert_eq(ids, ["hakim", "des", "nadia"], "most recent activity first, no-activity contacts last")
	)

	run_case("push_message_op_appends_an_unread_text_via_Events_apply_effects", func():
		GameState.reset()
		_add_test_contact("des")

		Events.apply_effects([{ "op": "push_message", "contact": "des", "text": "The site's clean." }])

		var thread: Array = GameState.state["messages"]["des"]
		assert_eq(thread.size(), 1, "message appended")
		assert_eq(thread[0]["text"], "The site's clean.")
		assert_eq(thread[0]["from"], "them")
		assert_eq(thread[0]["read"], false, "marked unread")
	)

	run_case("unlock_contact_op_sets_contacts_id_unlocked_via_Events_apply_effects", func():
		GameState.reset()
		_add_test_contact("des", false)
		assert_eq(GameState.state["contacts"]["des"]["unlocked"], false, "sanity: starts locked")

		Events.apply_effects([{ "op": "unlock_contact", "contact": "des" }])

		assert_eq(GameState.state["contacts"]["des"]["unlocked"], true)
	)
