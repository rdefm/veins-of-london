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
		var root := phone.find_child(LodedInnitApp.ROOT_NODE_NAME, true, false)
		assert_eq(root.get_child(0).name, LodedInnitApp.PROFILE_NAV_NODE_NAME)
		assert_true(phone.find_child(LodedInnitApp.BRAND_BAR_NODE_NAME, true, false) == null)
		assert_true(phone.find_child(LodedInnitApp.TABS_NODE_NAME, true, false) == null)
		assert_eq(root.get_child(2).name, LodedInnitApp.HIRE_AREA_NODE_NAME, "hire area stays outside scroll")
		assert_eq((root.get_child(1) as ScrollContainer).vertical_scroll_mode, ScrollContainer.SCROLL_MODE_SHOW_NEVER)
		assert_true(NodeQuery.find_button(phone, "‹ People") != null)
		assert_eq(_text(phone, "LodedInnitProfileWage"), "£%d" % Hiring.weekly_wage("priya"))
		assert_eq(_text(phone, "LodedInnitProfileLevel"), "%d / %d" % [Hiring.level("priya"), Hiring.level_cap("priya")])
		assert_eq(_text(phone, "LodedInnitProfileSeats"), LodedInnitProfile.seat_text("priya"))
		assert_eq(_text(phone, "LodedInnitProfileExperience"), LodedInnitProfile.experience_text("priya"))
		assert_true(NodeQuery.label_texts(phone).has("WEEKLY WAGE\nFIRST WEEK PREPAID"))
		var avatar := phone.find_child(LodedInnitApp.PROFILE_AVATAR_NODE_NAME, true, false) as PanelContainer
		assert_eq(avatar.custom_minimum_size, Vector2(56, 56))
		var badge := phone.find_child(LodedInnitApp.PROFILE_BADGE_NODE_NAME, true, false) as PanelContainer
		assert_eq((badge.get_theme_stylebox("panel") as StyleBoxFlat).border_color, Color("#735785"))
		assert_true(NodeQuery.label_texts(badge).has("●  OPEN TO WORK"))
		var grid := phone.find_child(LodedInnitApp.PROFILE_GRID_NODE_NAME, true, false) as GridContainer
		assert_eq(grid.columns, 2)
		assert_eq(grid.get_child_count(), 4)
		assert_eq(_text(phone, "LodedInnitProfileRole"), Hiring.role("priya")["label"])
		assert_true(NodeQuery.label_texts(phone).has(Hiring.candidate("priya")["about"]))
		assert_true(root.get_combined_minimum_size().x <= 390.0, "profile fits narrow phone width")
		var hire := phone.find_child("LodedInnitHireButton", true, false) as Button
		assert_true(not hire.disabled)
		assert_eq(hire.text, "Hire · £%d first week" % Hiring.weekly_wage("priya"))
		assert_eq((hire.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, LodedInnitApp.plum())
		hire.pressed.emit()
		assert_true(GameState.state["contacts"]["priya"]["recruited"])
		assert_true(phone.find_child("LodedInnitHireButton", true, false) == null)
		assert_true(NodeQuery.label_texts(phone).has("●  WORKS FOR YOU"))
		phone.free()
	)

	run_case("all_specialities_have_readable_labels", func():
		_setup()
		var phone := PhoneScreen.new()
		_open_profile(phone, "ray")
		var list := phone.find_child(LodedInnitApp.PROFILE_SPECIALITIES_NODE_NAME, true, false)
		assert_eq(list.get_child_count(), Hiring.candidate("ray")["specialities"].size())
		for ore_type in Hiring.candidate("ray")["specialities"]:
			assert_true(NodeQuery.label_texts(list).has(str(ore_type).capitalize()))
		assert_eq(list.find_children("", "SymbolGlyph", true, false).size(), 3)
		phone.free()
	)

	run_case("employed_profile_shows_poach_wage_and_employer", func():
		_setup()
		var faction_id: String = GameData.FACTIONS.keys()[0]
		GameState.state["hiring"]["status"]["priya"] = {"state": Hiring.STATUS_EMPLOYED, "employer": faction_id, "since": 8}
		var phone := PhoneScreen.new()
		_open_profile(phone, "priya")
		assert_true(NodeQuery.label_texts(phone).has("●  EMPLOYED AT %s" % GameData.FACTIONS[faction_id]["name"].to_upper()))
		assert_eq(_text(phone, "LodedInnitProfileWage"), "£%d" % Hiring.weekly_wage("priya"))
		var hire := phone.find_child("LodedInnitHireButton", true, false) as Button
		assert_true(not hire.disabled)
		assert_eq(hire.text, "Poach · £%d first week" % Hiring.weekly_wage("priya"))
		assert_true(NodeQuery.label_texts(phone).has("Wage +%d%% for good. Costs %d relation with %s." % [roundi((Hiring.poach_mult() - 1.0) * 100.0), Hiring.poach_relation_cost(), GameData.FACTIONS[faction_id]["name"]]))
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
		assert_eq(_text(phone, "LodedInnitProfileSeats"), "Improved Lab not built")
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
		assert_eq(_text(phone, "LodedInnitTopUpReason"), "Not enough cash.")
		assert_true((phone.find_child(LodedInnitApp.ROOT_NODE_NAME, true, false).get_child(2) as Control).get_combined_minimum_size().x <= 390.0)
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
		app._ore_filter = "physics"
		app._wage_order = LodedInnitDirectory.WAGE_DESC
		(NodeQuery.find_button(phone, "‹ People") as Button).pressed.emit()
		assert_eq(app._role_filter, "production")
		assert_eq(app._ore_filter, "physics")
		assert_eq(app._wage_order, LodedInnitDirectory.WAGE_DESC)
		assert_true(phone.find_child("LodedInnitWageSort", true, false) != null)
		assert_eq((phone.find_child("LodedInnitRoleFilter", true, false) as OptionButton).text, "Role: Crafters")
		assert_eq((phone.find_child("LodedInnitOreFilter", true, false) as OptionButton).text, "Ore: Physics")
		phone.free()
	)
