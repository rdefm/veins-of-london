extends "res://tests/test_base.gd"

const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")


static func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for label in root.find_children("", "Label", true, false):
		texts.append((label as Label).text)
	return texts


static func _button_with_text(root: Node, text: String) -> Button:
	for candidate in root.find_children("", "Button", true, false):
		if (candidate as Button).text == text:
			return candidate as Button
	return null


# 27-procurement-in-manage: same fixture shape test_rooms.gd's Vein Station
# cases use.
static func _player_vein(overrides: Dictionary = {}) -> Dictionary:
	var vein := {
		"id": "v1", "oreType": "time", "growth": 20, "security": "none",
		"alarmUpgrades": [], "location": "Vallance Rd, by the bus stop",
		"claimedOnDay": 1, "district": "shoreditch", "siteId": null,
		"hospitability": { "tier": "fair", "bonuses": [] }, "rampantDays": 0,
	}
	for key in overrides:
		vein[key] = overrides[key]
	return vein


func run() -> void:
	run_case("bizbrief_tile_opens_the_standalone_app", func():
		GameState.reset()
		var phone := PhoneScreen.new()
		phone._ready()
		var tile: AppTile = null
		for candidate in phone.find_children("", "AppTile", true, false):
			if (candidate as AppTile)._app_id == "bizbrief":
				tile = candidate
		assert_true(tile != null)
		var event := InputEventScreenTouch.new()
		event.pressed = true
		tile._on_gui_input(event)
		assert_eq(GameState.state["phoneNav"]["app"], "bizbrief")
		phone.free()
	)

	run_case("brief_renders_accounts_operations_and_current_attention", func():
		GameState.reset()
		GameState.state["morningAccounts"]["latest"] = {
			"day": 3, "openingBalance": 200, "closingBalance": 145,
			"income": 20, "expenses": 75, "oreMovement": { "time": -2 },
			"production": { "ore": {}, "items": { "timePearl": 1 } },
			"sales": {}, "losses": { "ore": { "time": 2 }, "veins": 0 },
			"exceptions": [],
		}
		Messages.append("archie", "them", "Call me.")
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := _label_texts(phone)
		for expected in ["BizBrief", "Morning Brief", "Reynard's", "Operations", "Attention", "Opening £200 · Closing £145", "Income +£20 · Expenses −£75"]:
			assert_true(texts.has(expected), "missing %s" % expected)
		phone.free()
	)

	run_case("quiet_sections_are_not_rendered", func():
		GameState.reset()
		MorningAccountsSystem.finish_rollover(MorningAccountsSystem.begin_rollover())
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := _label_texts(phone)
		assert_true(texts.has("Reynard's"))
		assert_true(not texts.has("Operations"))
		assert_true(not texts.has("Attention"))
		phone.free()
	)

	run_case("manage_tab_lists_the_three_future_business_sections", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		var manage := _button_with_text(phone, "Manage")
		assert_true(manage != null, "BizBrief exposes Manage beside Brief")
		manage.pressed.emit()
		var texts := _label_texts(phone)
		for expected in ["BizBrief", "Manage", "Sales", "Production", "Procurement"]:
			assert_true(texts.has(expected), "missing %s" % expected)
		assert_true(not texts.has("Morning Brief"), "Manage does not duplicate the Brief tab")
		var brief := _button_with_text(phone, "Brief")
		assert_true(brief != null, "Manage keeps the Brief tab available")
		brief.pressed.emit()
		assert_true(_label_texts(phone).has("Morning Brief"), "Brief preserves the existing account view")
		phone.free()
	)

	# 30-production-contract-coverage-toggle
	run_case("production_shows_a_room_gate_message_when_lab_not_installed", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()

		assert_true(_label_texts(phone).has("Requires the Improved Lab."))
		phone.free()
	)

	run_case("production_lists_only_unlocked_recipes_and_adjusts_target_and_toggle", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("lab")
		GameState.state["flags"]["craftingUnlocked"] = true
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()

		var texts := _label_texts(phone)
		assert_true(texts.has("Time Pearl"), "craftingUnlocked recipe is listed")
		assert_true(texts.has("Rewind"), "craftingUnlocked also gates rewind")
		assert_true(not texts.has("Enhancement Powder"), "enhancementUnlocked recipe stays hidden until unlocked")
		assert_true(texts.has("Personal target: 0"))

		var plus_buttons: Array = []
		for candidate in phone.find_children("", "Button", true, false):
			if (candidate as Button).text == "+5":
				plus_buttons.append(candidate)
		assert_eq(plus_buttons.size(), 2, "one +5 button per unlocked recipe")
		plus_buttons[0].pressed.emit()
		assert_eq(GameState.state["labThresholds"]["timePearl"], 5)

		var cover := _button_with_text(phone, "Cover contract needs")
		assert_true(cover != null)
		cover.pressed.emit()
		assert_true(GameState.state["labCoverContracts"]["timePearl"])
		phone.free()
	)

	# 27-procurement-in-manage
	run_case("procurement_shows_a_room_gate_message_when_vein_station_not_installed", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "bizbrief"
		GameState.state["player"]["veins"] = [_player_vein()]
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()

		assert_true(_label_texts(phone).has("Requires the Vein Cultivation Station room."))
		assert_true(_button_with_text(phone, "Assign to Vein Station") == null, "no assign control before the room exists")
		phone.free()
	)

	run_case("procurement_lists_an_unassigned_vein_and_assigns_it_on_tap", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("veinStation")
		GameState.state["player"]["veins"] = [_player_vein()]
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()

		assert_true(_label_texts(phone).any(func(t: String): return t.contains("Time Orichalchum")), "vein row identifies the ore/district")
		var assign := _button_with_text(phone, "Assign to Vein Station")
		assert_true(assign != null)
		assign.pressed.emit()

		assert_eq(GameState.state["veinStationVeins"], ["v1"])
		phone.free()
	)

	run_case("procurement_target_controls_adjust_and_unassign_an_assigned_vein", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("veinStation")
		GameState.state["player"]["veins"] = [_player_vein()]
		Rooms.toggle_vein_station_vein("v1")
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()

		assert_true(_label_texts(phone).has("Vein Station target: 70"))

		_button_with_text(phone, "+5").pressed.emit()
		assert_eq(GameState.state["veinStationTargets"]["v1"], 75)

		_button_with_text(phone, "-5").pressed.emit()
		assert_eq(GameState.state["veinStationTargets"]["v1"], 70)

		_button_with_text(phone, "Unassign").pressed.emit()
		assert_eq(GameState.state["veinStationVeins"], [])
		phone.free()
	)
