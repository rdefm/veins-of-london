extends "res://tests/test_base.gd"

const RaidAlarmsSystem := preload("res://systems/raid_alarms.gd")


func _vein(id: String, district: String, ore_type: String) -> Dictionary:
	return {
		"id": id, "siteId": "site_" + id, "district": district,
		"oreType": ore_type, "growth": 40, "security": "none",
		"alarmUpgrades": ["alarm"], "location": "Test Street",
	}


func run() -> void:
	run_case("simultaneous_pending_raids_have_stable_grouped_summary_rows", func():
		GameState.reset()
		var first := _vein("v1", "camden", "time")
		var second := _vein("v2", "shoreditch", "life")
		GameState.state["player"]["veins"] = [first, second]
		GameState.state["world"]["pendingDefendRaids"] = [
			{ "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "outcomeType": "claim", "notificationId": "n1" },
			{ "attackerId": "guild", "veinId": "v2", "siteId": "site_v2", "success": true, "outcomeType": "loot", "notificationId": "n2" },
		]
		var rows := RaidAlarmsSystem.summary_rows()
		assert_eq(rows.size(), 2)
		assert_eq(rows[0]["id"], "vein:n1")
		assert_eq(rows[1]["id"], "vein:n2")
		assert_true(rows[0]["title"].contains("Test Street"))
		assert_true(rows[1]["consequence"].contains("8 calc"))
		assert_eq(rows, RaidAlarmsSystem.summary_rows(), "refresh derives the same rows and identities")
	)

	run_case("deferral_and_phone_back_leave_pending_alarm_unchanged", func():
		GameState.reset()
		var vein := _vein("v1", "camden", "time")
		var outcome := { "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "notificationId": "n1" }
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["pendingDefendRaids"] = [outcome]
		RaidAlarmsSystem.open()
		PhoneNav.go_home()
		assert_eq(GameState.state["world"]["pendingDefendRaids"], [outcome])
		assert_true(RaidAlarmsSystem.has_unresolved())
	)

	run_case("defend_revalidates_and_stale_situation_cannot_start_combat", func():
		GameState.reset()
		var vein := _vein("v1", "camden", "time")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "notificationId": "n1" }]
		assert_true(RaidAlarmsSystem.defend("vein:n1"))
		assert_true(GameState.state["combat"]["active"])
		GameState.reset()
		assert_true(not RaidAlarmsSystem.defend("vein:n1"))
		assert_true(not GameState.state["combat"]["active"])
	)

	run_case("leave_undefended_consumes_only_the_confirmed_raid_once", func():
		GameState.reset()
		var first := _vein("v1", "camden", "time")
		var second := _vein("v2", "shoreditch", "life")
		GameState.state["player"]["veins"] = [first, second]
		GameState.state["world"]["sites"] = [
			{ "id": "site_v1", "claimed": true, "factionVein": null },
			{ "id": "site_v2", "claimed": true, "factionVein": null },
		]
		GameState.state["world"]["pendingDefendRaids"] = [
			{ "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "outcomeType": "claim", "notificationId": "n1" },
			{ "attackerId": "guild", "veinId": "v2", "siteId": "site_v2", "success": true, "outcomeType": "loot", "notificationId": "n2" },
		]
		assert_true(RaidAlarmsSystem.leave_undefended("vein:n1"))
		assert_eq(GameState.state["world"]["pendingDefendRaids"].size(), 1)
		assert_eq(GameState.state["world"]["pendingDefendRaids"][0]["notificationId"], "n2")
		assert_eq(GameState.state["player"]["veins"].size(), 1)
		assert_eq(GameState.state["player"]["veins"][0]["id"], "v2")
		assert_true(not RaidAlarmsSystem.leave_undefended("vein:n1"), "duplicate confirmation must no-op")
	)

	run_case("leave_undefended_stale_response_and_cancel_leave_raid_actionable", func():
		GameState.reset()
		var vein := _vein("v1", "camden", "time")
		GameState.state["player"]["veins"] = [vein]
		var outcome := { "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "notificationId": "n1" }
		GameState.state["world"]["pendingDefendRaids"] = [outcome]
		assert_true(not RaidAlarmsSystem.leave_undefended("vein:wrong"))
		assert_eq(GameState.state["world"]["pendingDefendRaids"], [outcome])
		assert_true(RaidAlarmsSystem.defend("vein:n1"), "no confirmation/cancel mutation leaves defence available")
	)

	run_case("pending_alarm_survives_save_load_then_leave_undefended_resolves_once", func():
		const test_slot := 92
		GameState.reset()
		var vein := _vein("v1", "camden", "time")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["sites"] = [{ "id": "site_v1", "claimed": true, "factionVein": null }]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "notificationId": "n1" }]
		assert_true(SaveManager.save_to_slot(test_slot)["ok"])
		GameState.state["world"]["pendingDefendRaids"] = []
		assert_true(SaveManager.load_from_slot(test_slot)["ok"])
		assert_true(RaidAlarmsSystem.leave_undefended("vein:n1"))
		assert_true(not RaidAlarmsSystem.leave_undefended("vein:n1"))
		assert_eq(GameState.state["player"]["veins"].size(), 0)
		SaveManager.delete_slot(test_slot)
	)

	run_case("alarm_app_badge_and_rows_survive_screen_refresh", func():
		GameState.reset()
		var vein := _vein("v1", "camden", "time")
		GameState.state["player"]["veins"] = [vein]
		GameState.state["world"]["pendingDefendRaids"] = [{ "attackerId": "firm", "veinId": "v1", "siteId": "site_v1", "success": true, "notificationId": "n1" }]
		GameState.state["phoneNav"]["app"] = "alarms"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(phone._badge_for("alarms"))
		assert_true(phone.find_children("", "Button", true, false).any(func(button): return button.text == "Go and defend"))
		assert_true(phone.find_children("", "Button", true, false).any(func(button): return button.text == "Leave undefended"))
		var leave_button: Button = phone.find_children("", "Button", true, false).filter(func(button): return button.text == "Leave undefended")[0]
		leave_button.pressed.emit()
		assert_true(phone.find_children("", "Button", true, false).any(func(button): return button.text == "Confirm leave undefended"))
		assert_true(phone.find_children("", "Button", true, false).any(func(button): return button.text == "Cancel"))
		assert_true(RaidAlarmsSystem.has_unresolved(), "opening confirmation cannot abandon defence")
		phone._refresh()
		assert_true(RaidAlarmsSystem.has_unresolved())
		phone.free()
	)
