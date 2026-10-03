extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")


static func _wages(ids: Array) -> Array:
	var wages: Array = []
	for candidate_id in ids:
		wages.append(Hiring.weekly_wage(candidate_id))
	return wages


static func _open_app(phone: PhoneScreen) -> LodedInnitApp:
	GameState.state["flags"]["bizA1JamesJoined"] = true
	GameState.state["phoneNav"]["app"] = "lodedinnit"
	phone._ready()
	return phone._apps["lodedinnit"] as LodedInnitApp


func run() -> void:
	run_case("brand_ink_and_tabs_follow_displayed_page", func():
		GameState.reset()
		var phone := PhoneScreen.new()
		var app := _open_app(phone)
		var root := phone.find_child(LodedInnitApp.ROOT_NODE_NAME, true, false)
		var brand := phone.find_child(LodedInnitApp.BRAND_BAR_NODE_NAME, true, false)
		var tabs := phone.find_child(LodedInnitApp.TABS_NODE_NAME, true, false)
		assert_eq(root.get_child(0), brand)
		assert_eq(root.get_child(1), tabs)
		var feed := phone.find_child(LodedInnitApp.FEED_TAB_NODE_NAME, true, false) as Button
		var people := phone.find_child(LodedInnitApp.PEOPLE_TAB_NODE_NAME, true, false) as Button
		assert_true(not feed.disabled and not people.disabled)
		assert_true(people.button_pressed and not feed.button_pressed)
		assert_eq(people.get_theme_color("font_color"), GameData.PALETTE["phone_text_primary"])
		assert_eq(feed.get_theme_color("font_color"), GameData.PALETTE["phone_text_muted"])
		assert_eq((people.get_theme_stylebox("normal") as StyleBoxFlat).border_width_bottom, 2)
		assert_eq((people.get_theme_stylebox("normal") as StyleBoxFlat).border_color, GameData.PALETTE["lodedinnit_plum"])
		assert_eq((feed.get_theme_stylebox("normal") as StyleBoxFlat).border_width_bottom, 0)
		assert_eq((feed.get_theme_stylebox("normal") as StyleBoxFlat).bg_color.a, 0.0)
		var name_button := NodeQuery.find_button(phone, "Priya Sandhu")
		assert_eq(name_button.get_theme_color("font_color"), GameData.PALETTE["phone_text_primary"])
		feed.pressed.emit()
		assert_eq(app._tab, LodedInnitApp.FEED_TAB)
		root = phone.find_child(LodedInnitApp.ROOT_NODE_NAME, true, false)
		assert_eq(root.get_child(0).name, LodedInnitApp.BRAND_BAR_NODE_NAME)
		assert_eq(root.get_child(1).name, LodedInnitApp.TABS_NODE_NAME)
		feed = phone.find_child(LodedInnitApp.FEED_TAB_NODE_NAME, true, false) as Button
		people = phone.find_child(LodedInnitApp.PEOPLE_TAB_NODE_NAME, true, false) as Button
		assert_true(feed.button_pressed and not people.button_pressed)
		assert_true(not feed.disabled and not people.disabled)
		assert_eq((feed.get_theme_stylebox("normal") as StyleBoxFlat).border_width_bottom, 2)
		assert_eq((people.get_theme_stylebox("normal") as StyleBoxFlat).border_width_bottom, 0)
		people.pressed.emit()
		assert_eq(app._tab, LodedInnitApp.PEOPLE_TAB)
		phone.free()
	)

	run_case("groups_follow_roster_by_enabled_role", func():
		GameState.reset()
		var groups := LodedInnitDirectory.groups("all", "all", "roster")
		assert_eq(groups.size(), 2)
		assert_eq(groups[0]["label"], "Cultivators")
		assert_eq(groups[0]["ids"], ["marcia", "tomasz", "bernie", "saoirse"])
		assert_eq(groups[1]["label"], "Crafters")
		assert_eq(LodedInnitDirectory.visible_count(groups), 8)
	)

	run_case("options_are_all_plus_roles_and_five_ores", func():
		GameState.reset()
		var roles: Array = LodedInnitDirectory.role_options().map(func(o): return o["label"])
		assert_eq(roles, ["All", "Cultivators", "Crafters"])
		var ores: Array = LodedInnitDirectory.ore_options().map(func(o): return o["id"])
		assert_eq(ores, ["all", "time", "physics", "life", "fate", "emotion"])
	)

	run_case("role_and_ore_filters_combine", func():
		GameState.reset()
		var life := LodedInnitDirectory.groups("all", "life", "roster")
		var life_ids: Array = []
		for group in life:
			life_ids.append_array(group["ids"])
		assert_true(life_ids.has("marcia") and life_ids.has("bernie"), "specialities include life")
		assert_true(not life_ids.has("tomasz"), "physics-only excluded")
		var crafters := LodedInnitDirectory.groups("production", "all", "roster")
		assert_eq(crafters.size(), 1)
		assert_eq(crafters[0]["label"], "Crafters")
		var ray := LodedInnitDirectory.groups("production", "fate", "roster")
		assert_eq(ray[0]["ids"], ["ray"])
		assert_true(LodedInnitDirectory.groups("cultivation", "time", "roster").is_empty(), "no cultivator specialises in time")
	)

	run_case("wage_order_sorts_within_each_group_and_alternates", func():
		GameState.reset()
		assert_eq(LodedInnitDirectory.next_wage_order("roster"), "desc")
		assert_eq(LodedInnitDirectory.next_wage_order("desc"), "asc")
		assert_eq(LodedInnitDirectory.next_wage_order("asc"), "desc")
		for group in LodedInnitDirectory.groups("all", "all", "desc"):
			var wages := _wages(group["ids"])
			var expected := wages.duplicate()
			expected.sort()
			expected.reverse()
			assert_eq(wages, expected, "%s high to low" % group["label"])
		for group in LodedInnitDirectory.groups("all", "all", "asc"):
			var wages := _wages(group["ids"])
			var expected := wages.duplicate()
			expected.sort()
			assert_eq(wages, expected, "%s low to high" % group["label"])
		assert_eq(LodedInnitDirectory.groups("all", "all", "desc").size(), 2, "groups kept")
	)

	run_case("people_tab_controls_filter_sort_and_survive_profile_round_trip", func():
		GameState.reset()
		var phone := PhoneScreen.new()
		var app := _open_app(phone)
		assert_true(phone.find_child("LodedInnitBrandBar", true, false) != null)
		assert_true(phone.find_child("LodedInnitTabs", true, false) != null)
		assert_true(phone.find_child("DeviceStatusBar", true, false) != null)
		assert_true(phone.find_child(LodedInnitApp.row_node_name("priya"), true, false) != null)
		var role := phone.find_child("LodedInnitRoleFilter", true, false) as OptionButton
		assert_eq(role.item_count, 3)
		role.item_selected.emit(2)
		assert_true(phone.find_child(LodedInnitApp.row_node_name("priya"), true, false) != null)
		assert_true(phone.find_child(LodedInnitApp.row_node_name("marcia"), true, false) == null)
		var ore := phone.find_child("LodedInnitOreFilter", true, false) as OptionButton
		assert_eq(ore.item_count, 6)
		ore.item_selected.emit(5)
		assert_true(phone.find_child(LodedInnitApp.row_node_name("ray"), true, false) != null)
		assert_true(phone.find_child(LodedInnitApp.row_node_name("priya"), true, false) == null)
		(phone.find_child("LodedInnitWageSort", true, false) as Button).pressed.emit()
		assert_true(NodeQuery.button_texts(phone).has("Wage · high to low"))
		(phone.find_child("LodedInnitWageSort", true, false) as Button).pressed.emit()
		assert_true(NodeQuery.button_texts(phone).has("Wage · low to high"))

		app._role_filter = "all"
		app._ore_filter = "all"
		phone._refresh()
		var name_button := NodeQuery.find_button(phone, "Priya Sandhu")
		name_button.pressed.emit()
		assert_true(NodeQuery.button_texts(phone).has("‹ People"))
		assert_true(phone.find_child("LodedInnitTabs", true, false) == null)
		NodeQuery.find_button(phone, "‹ People").pressed.emit()
		assert_true(NodeQuery.button_texts(phone).has("Wage · low to high"), "wage order survives round trip")
		phone.free()
	)

	run_case("empty_filter_result_shows_message", func():
		GameState.reset()
		var phone := PhoneScreen.new()
		var app := _open_app(phone)
		app._role_filter = "cultivation"
		app._ore_filter = "time"
		phone._refresh()
		assert_true(phone.find_child("LodedInnitEmpty", true, false) != null)
		phone.free()
	)
