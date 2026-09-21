extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")


func run() -> void:
	run_case("settings_owns_both_saved_preference_controls", func():
		GameState.reset()
		PhoneNav.open_app("settings")
		var phone := PhoneScreen.new()
		phone._ready()
		var checks := phone.find_children("", "CheckButton", true, false)
		assert_eq(checks.size(), 2, "Settings has exactly the two existing preferences")
		assert_eq((checks[0] as CheckButton).text, GameData.DAILY_CYCLE["reducedMotionLabel"])
		assert_eq((checks[1] as CheckButton).text, "Vibrate for alarms")
		(checks[0] as CheckButton).toggled.emit(true)
		(checks[1] as CheckButton).toggled.emit(false)
		assert_true(GameState.state["meta"]["reducedMotion"], "reduced motion persists through Preferences")
		assert_true(not GameState.state["meta"]["vibrationEnabled"], "alarm vibration persists through Preferences")
		phone.free()
	)

	run_case("profile_keeps_stats_skills_equipment_but_no_preferences", func():
		GameState.reset()
		PhoneNav.open_app("profile")
		var phone := PhoneScreen.new()
		phone._ready()
		assert_eq(phone.find_children("", "CheckButton", true, false).size(), 0, "preferences moved out of Profile")
		var texts := NodeQuery.symbol_row_texts(phone)
		assert_true(texts.has("Skills") and texts.has("Equipment"), "Profile content remains")
		phone.free()
	)
