extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")


static func _setup() -> void:
	GameState.reset()
	GameState.state["world"]["day"] = 9
	Business.activate()
	GameState.state["flags"]["bizA1JamesJoined"] = true
	GameState.state["home"]["rooms"] = ["veinStation", "lab"]


static func _open_profile(phone: PhoneScreen, candidate_id: String) -> LodedInnitApp:
	GameState.state["phoneNav"]["app"] = "lodedinnit"
	phone._ready()
	var app := phone._apps["lodedinnit"] as LodedInnitApp
	app._open_profile(candidate_id)
	return app


static func _text(phone: PhoneScreen, node_name: String) -> String:
	return (phone.find_child(node_name, true, false) as Label).text


func run() -> void:
	run_case("projection_reads_live_experience_and_seats", func():
		_setup()
		assert_eq(LodedInnitProfile.seat_text("priya"), "Improved Lab · 1 of 1 seats free")
		GameState.state["home"]["rooms"].erase("lab")
		assert_eq(LodedInnitProfile.seat_text("priya"), "Improved Lab not built")
		var e := LodedInnitProfile.experience("priya")
		assert_eq(e["xp"], int(GameState.state["contacts"]["priya"]["craftingXP"]))
		assert_true(LodedInnitProfile.experience_text("priya").contains(" XP"))
	)

	run_case("profile_shows_live_values_and_open_hire", func():
		_setup()
		GameState.state["business"]["float"] = 5000
		var phone := PhoneScreen.new()
		_open_profile(phone, "priya")
		assert_eq(_text(phone, "LodedInnitProfileWage"), "£%d a week" % Hiring.weekly_wage("priya"))
		assert_eq(_text(phone, "LodedInnitProfileLevel"), "%d / %d" % [Hiring.level("priya"), Hiring.level_cap("priya")])
		assert_eq(_text(phone, "LodedInnitProfileSeats"), LodedInnitProfile.seat_text("priya"))
		var hire := phone.find_child("LodedInnitHireButton", true, false) as Button
		assert_true(not hire.disabled)
		hire.pressed.emit()
		assert_true(GameState.state["contacts"]["priya"]["recruited"])
		assert_true(phone.find_child("LodedInnitHireButton", true, false) == null)
		phone.free()
	)

	run_case("blocked_hire_shows_system_reason_and_cannot_hire", func():
		_setup()
		GameState.state["home"]["rooms"].erase("lab")
		var phone := PhoneScreen.new()
		_open_profile(phone, "priya")
		var hire := phone.find_child("LodedInnitHireButton", true, false) as Button
		assert_true(hire.disabled)
		assert_eq(_text(phone, "LodedInnitHireReason"), Hiring.hire_block_reason("priya"))
		phone.free()
	)

	run_case("top_up_prompt_yes_no_and_cash_gate", func():
		_setup()
		GameState.state["business"]["float"] = 100
		GameState.state["player"]["cash"] = 1000
		var phone := PhoneScreen.new()
		var app := _open_profile(phone, "priya")
		(phone.find_child("LodedInnitHireButton", true, false) as Button).pressed.emit()
		assert_eq(_text(phone, "LodedInnitTopUpQuestion"), "Top up the float by £220 to cover this hire?")
		(phone.find_child("LodedInnitTopUpNo", true, false) as Button).pressed.emit()
		assert_true(phone.find_child("LodedInnitHireButton", true, false) != null)
		assert_true(not GameState.state["contacts"]["priya"]["recruited"])
		GameState.state["player"]["cash"] = 50
		(phone.find_child("LodedInnitHireButton", true, false) as Button).pressed.emit()
		assert_true((phone.find_child("LodedInnitTopUpYes", true, false) as Button).disabled)
		GameState.state["player"]["cash"] = 1000
		app._on_top_up_no()
		(phone.find_child("LodedInnitHireButton", true, false) as Button).pressed.emit()
		(phone.find_child("LodedInnitTopUpYes", true, false) as Button).pressed.emit()
		assert_true(GameState.state["contacts"]["priya"]["recruited"])
		phone.free()
	)

	run_case("back_keeps_people_filters", func():
		_setup()
		var phone := PhoneScreen.new()
		var app := _open_profile(phone, "priya")
		app._role_filter = "production"
		app._wage_order = LodedInnitDirectory.WAGE_DESC
		app._close_profile()
		assert_eq(app._role_filter, "production")
		assert_eq(app._wage_order, LodedInnitDirectory.WAGE_DESC)
		assert_true(phone.find_child("LodedInnitWageSort", true, false) != null)
		phone.free()
	)
