extends "res://tests/test_base.gd"

# 11-phone-os-shell ticket 10: Notifications app -- browses the full
# persistent log ticket 04's Notify.push() built (GameState.state
# ["notifications"]), screen-level-tested against a real PhoneScreen
# instance with state.phoneNav.app = "notifications", same headless-scene
# pattern as tests/test_phone_profile.gd.


static func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		texts.append((l as Label).text)
	return texts


func run() -> void:
	run_case("notifications_shows_the_full_log_newest_first", func():
		GameState.reset()
		Notify.push("First.")
		Notify.push("Second.")
		Notify.push("Third.")
		GameState.state["phoneNav"]["app"] = "notifications"

		var phone := PhoneScreen.new()
		phone._ready()

		var texts := _label_texts(phone)
		var idx_first := texts.find("First.")
		var idx_second := texts.find("Second.")
		var idx_third := texts.find("Third.")
		assert_true(idx_first != -1 and idx_second != -1 and idx_third != -1, "all three entries render")
		assert_true(idx_third < idx_second, "the newest entry (Third.) renders above the middle one")
		assert_true(idx_second < idx_first, "the middle entry renders above the oldest one")

		phone.free()
	)

	run_case("notifications_respects_the_50_entry_cap", func():
		GameState.reset()
		for i in range(55):
			Notify.push("Notification %d." % i)
		GameState.state["phoneNav"]["app"] = "notifications"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_eq(GameState.state["notifications"].size(), Notify.LOG_CAP, "sanity: the underlying log is capped at 50")

		var texts := _label_texts(phone)
		assert_true(not texts.has("Notification 0."), "entries evicted from the log below the cap must not render")
		assert_true(texts.has("Notification 5."), "the oldest surviving entry renders")
		assert_true(texts.has("Notification 54."), "the newest entry renders")

		phone.free()
	)

	run_case("notifications_shows_entries_regardless_of_seen_state", func():
		GameState.reset()
		var a := Notify.push("Seen one.")
		Notify.push("Unseen one.")
		Notify.dismiss(a["id"])
		GameState.state["phoneNav"]["app"] = "notifications"

		var phone := PhoneScreen.new()
		phone._ready()

		var texts := _label_texts(phone)
		assert_true(texts.has("Seen one."), "a seen entry still renders in the log")
		assert_true(texts.has("Unseen one."), "an unseen entry renders in the log")

		phone.free()
	)

	run_case("notifications_entries_are_read_only_with_no_action_buttons", func():
		GameState.reset()
		Notify.push("Only one.")
		GameState.state["phoneNav"]["app"] = "notifications"

		var phone := PhoneScreen.new()
		phone._ready()

		for b in phone.find_children("", "Button", true, false):
			assert_eq((b as Button).text, "‹ Back", "the only button on the Notifications app is the back button -- entries expose no actions")

		phone.free()
	)

	run_case("notifications_shows_an_empty_state_when_the_log_is_empty", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "notifications"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(_label_texts(phone).has("Nothing yet."), "an empty log shows an empty-state message")

		phone.free()
	)

	run_case("notifications_is_reachable_from_the_app_grid_via_the_notifications_tile", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		var notifications_tile: AppTile = null
		for t in phone.find_children("", "AppTile", true, false):
			if (t as AppTile)._app_id == "notifications":
				notifications_tile = t
		assert_true(notifications_tile != null, "the app grid must include a Notifications tile")

		var event := InputEventScreenTouch.new()
		event.pressed = true
		notifications_tile._on_gui_input(event)

		assert_eq(GameState.state["phoneNav"]["app"], "notifications", "tapping the Notifications tile opens the Notifications app via PhoneNav")

		phone.free()
	)
