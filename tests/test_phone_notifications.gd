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


# 75-vein-raid-defend-button fixture: a player-owned, alarmed, site-tied
# vein -- the shape Raiding._queue_defend_raid()/trigger_defend() need.
static func _player_vein_with_pending_raid() -> Dictionary:
	var vein := {
		"id": "pv_test", "oreType": "time", "growth": 30, "security": "none",
		"alarmUpgrades": [Cultivating.ALARM_UPGRADE_ID], "location": "Test Alley",
		"claimedOnDay": 1, "district": "shoreditch", "siteId": "s_player",
		"rampantDays": 0, "hospitability": { "tier": "fair", "bonuses": [] },
	}
	GameState.state["player"]["veins"] = [vein]
	GameState.state["world"]["sites"] = [{ "id": "s_player", "district": "shoreditch", "tier": "fair", "oreType": "time", "bonuses": [], "discoveredDay": 1, "claimed": true, "factionVein": null, "hasNaturalVein": false }]
	return vein


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

	# 75-vein-raid-defend-button: an ordinary notification (no veinId meta,
	# or a veinId with nothing pending) still exposes no action buttons -- the
	# Defend button only ever appears on the specific alarm-raid warning
	# entry, tested separately below.
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

	# ── 75-vein-raid-defend-button: the notification's own Defend button ──

	run_case("notification_with_a_pending_defend_raid_shows_its_own_defend_button", func():
		GameState.reset()
		var vein := _player_vein_with_pending_raid()
		Raiding._queue_defend_raid({ "attackerId": "firm", "veinId": vein["id"], "siteId": vein["siteId"], "success": true }, vein)
		GameState.state["phoneNav"]["app"] = "notifications"

		var phone := PhoneScreen.new()
		phone._ready()

		var defend_buttons: Array = []
		for b in phone.find_children("", "Button", true, false):
			if (b as Button).text == "Defend":
				defend_buttons.append(b)
		assert_eq(defend_buttons.size(), 1, "the alarm-raid warning notification must show exactly one Defend button")

		phone.free()
	)

	run_case("notification_defend_button_absent_once_the_raid_is_no_longer_pending", func():
		GameState.reset()
		var vein := _player_vein_with_pending_raid()
		Raiding._queue_defend_raid({ "attackerId": "firm", "veinId": vein["id"], "siteId": vein["siteId"], "success": true }, vein)
		GameState.state["world"]["pendingDefendRaids"] = []  # resolved/expired since the notification was pushed
		GameState.state["phoneNav"]["app"] = "notifications"

		var phone := PhoneScreen.new()
		phone._ready()

		for b in phone.find_children("", "Button", true, false):
			assert_eq((b as Button).text, "‹ Back", "an old notification for a raid that's no longer pending must not show a Defend button")

		phone.free()
	)

	run_case("notification_defend_button_tap_triggers_the_defend_combat_immediately", func():
		GameState.reset()
		var vein := _player_vein_with_pending_raid()
		Raiding._queue_defend_raid({ "attackerId": "firm", "veinId": vein["id"], "siteId": vein["siteId"], "success": true }, vein)
		GameState.state["phoneNav"]["app"] = "notifications"

		var phone := PhoneScreen.new()
		phone._ready()

		var defend_button: Button = null
		for b in phone.find_children("", "Button", true, false):
			if (b as Button).text == "Defend":
				defend_button = b
		assert_true(defend_button != null)
		defend_button.pressed.emit()

		assert_true(GameState.state["combat"]["active"], "tapping the notification's Defend button should start combat immediately")
		assert_eq(GameState.state["combat"]["context"], "defend_vein")
		assert_eq(GameState.state["world"]["pendingDefendRaids"], [], "the triggered raid should be popped from the queue")

		phone.free()
	)

	# Regression pin: matching a notification's Defend button on veinId alone
	# would resurrect the button on an old, already-resolved warning once the
	# same vein is raided again later (the log is capped, not cleared).
	# Notifications/pendingDefendRaids set up directly (not via two real
	# _queue_defend_raid() calls) with explicit, guaranteed-distinct ids --
	# Notify.push()'s id is ticks_usec+rand with no counter, so two pushes
	# with no real wall-clock time between them could otherwise coincide,
	# which isn't the thing being pinned here.
	run_case("old_resolved_notification_for_a_vein_does_not_show_defend_once_the_same_vein_is_raided_again", func():
		GameState.reset()
		var vein := _player_vein_with_pending_raid()
		GameState.state["notifications"] = [
			{ "id": "n_old", "text": "Old warning.", "seen": true, "day": 1, "category": "warning", "veinId": vein["id"] },
			{ "id": "n_new", "text": "New warning.", "seen": false, "day": 2, "category": "warning", "veinId": vein["id"] },
		]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "collective", "veinId": vein["id"], "siteId": vein["siteId"], "success": true, "notificationId": "n_new" }]
		GameState.state["phoneNav"]["app"] = "notifications"

		var phone := PhoneScreen.new()
		phone._ready()

		var defend_buttons: Array = []
		for b in phone.find_children("", "Button", true, false):
			if (b as Button).text == "Defend":
				defend_buttons.append(b)
		assert_eq(defend_buttons.size(), 1, "only the fresh warning's Defend button should show -- the old, resolved one must not reactivate")

		phone.free()
	)
