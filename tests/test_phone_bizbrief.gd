extends "res://tests/test_base.gd"

const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")
const NodeQuery := preload("res://tests/support/node_query.gd")
const Fixtures := preload("res://tests/support/fixtures.gd")

static func _button_with_text(root: Node, text: String) -> Button:
	for candidate in root.find_children("", "Button", true, false):
		if (candidate as Button).text == text:
			return candidate as Button
	return null


static func _assign_button(root: Node) -> Button:
	for candidate in root.find_children("", "Button", true, false):
		if (candidate as Button).text.begins_with("Assign "):
			return candidate as Button
	return null


# The bizbrief's own vein: no site link, and a real street for the location line.
static func _brief_vein() -> Dictionary:
	return Fixtures.player_vein_with({ "location": "Vallance Rd, by the bus stop", "siteId": null })


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
		var texts := NodeQuery.label_texts(phone)
		for expected in ["BizBrief", "Morning Brief", "Reynard's", "Operations", "Attention", "Opening £200 · Closing £145", "Income +£20 · Expenses −£75"]:
			assert_true(texts.has(expected), "missing %s" % expected)
		phone.free()
	)

	run_case("attention_surfaces_a_live_development_eligible_vein_with_raid_exposure", func():
		GameState.reset()
		Fixtures.seed_vein("eligible", 95)
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.button_texts(phone)
		assert_true(texts.any(func(t: String): return t.find("ready to develop") != -1 and t.find("raid exposure") != -1), "development-eligible vein and its raid exposure are surfaced in Attention")
		phone.free()
	)

	run_case("attention_never_lists_a_vein_already_at_its_level_cap", func():
		GameState.reset()
		var capped := Fixtures.seed_vein("capped", 95)
		capped["level"] = 3  # fair cap 3: already maxed
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.button_texts(phone)
		assert_true(not texts.any(func(t: String): return t.find("ready to develop") != -1), "a capped vein is never shown as development-eligible")
		phone.free()
	)

	run_case("brief_renders_arrears_exceptions_and_countdown", func():
		GameState.reset()
		GameState.state["morningAccounts"]["latest"] = {
			"day": 5, "openingBalance": 0, "closingBalance": 0,
			"income": 0, "expenses": 0, "oreMovement": {},
			"production": { "ore": {}, "items": {} },
			"sales": {}, "losses": { "ore": {}, "veins": 0 },
			"exceptions": [
				{ "kind": "arrearsInterest", "amount": 20 },
				{ "kind": "arrearsShortfall", "amount": 80, "arrears": 500 },
				{ "kind": "forcedDowngrade", "fromTier": "flat", "toTier": "bedsit", "roomsLost": 0, "arrearsCleared": false, "arrears": 500 },
				{ "kind": "arrearsCountdown", "arrears": 500, "tier": "bedsit", "interestInDays": 6 },
			],
		}
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
		for expected in [
			"Exception: £20 interest on the arrears.",
			"Exception: £80 short on the bills. Owed £500.",
			"Exception: lost the Flat for unpaid bills. Renting the Bedsit now. Still owed £500.",
			"Interest starts in 6 days.",
		]:
			assert_true(texts.has(expected), "missing %s" % expected)
		phone.free()
	)

	run_case("brief_renders_the_payday_statement_and_the_wage_prompt", func():
		GameState.reset()
		Business.activate()
		for i in 6:
			TimeSystem.do_rest()
		GameState.state["morningAccounts"]["latest"]["payday"] = {
			"payday": "payday-1", "day": 7, "receipts": 750,
			"expenses": [{ "kind": "wage", "contactId": "owen", "amount": 250 }, { "kind": "calc", "source": "The Firm", "amount": 30 }],
			"shares": { "player": 158, "archie": 156, "james": 156 },
		}
		GameState.state["player"]["cash"] = 1000
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
		for expected in [
			"Payday", "Receipts £750", "Wages, Owen −£250", "Calc, The Firm −£30",
			"Shares: You £158 · Archie £156 · James £156",
			"Exception: the pot couldn't cover Owen's wages. Owed £214.",
			"Owen is owed £214 and has stopped working. Pay Owen from your own cash?",
		]:
			assert_true(texts.has(expected), "missing %s" % expected)
		_button_with_text(phone, "Yes").pressed.emit()
		assert_eq(Business.owed("owen"), 0, "Yes pays from cash")
		assert_eq(GameState.state["player"]["cash"], 786)
		phone.free()
	)

	run_case("brief_no_leaves_owen_unpaid_and_drops_the_prompt", func():
		GameState.reset()
		Business.activate()
		for i in 6:
			TimeSystem.do_rest()
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "No").pressed.emit()
		assert_true(Business.is_unpaid("owen"))
		assert_eq(Business.pending_wage_prompts(), [])
		phone.free()
	)

	run_case("quiet_sections_are_not_rendered", func():
		GameState.reset()
		MorningAccountsSystem.finish_rollover(MorningAccountsSystem.begin_rollover())
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
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
		var texts := NodeQuery.label_texts(phone)
		for expected in ["BizBrief", "Manage", "Sales", "Production", "Procurement"]:
			assert_true(texts.has(expected), "missing %s" % expected)
		assert_true(not texts.has("Morning Brief"), "Manage does not duplicate the Brief tab")
		var brief := _button_with_text(phone, "Brief")
		assert_true(brief != null, "Manage keeps the Brief tab available")
		brief.pressed.emit()
		assert_true(NodeQuery.label_texts(phone).has("Morning Brief"), "Brief preserves the existing account view")
		phone.free()
	)

	# 30-production-contract-coverage-toggle
	run_case("production_shows_a_room_gate_message_when_lab_not_installed", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()

		assert_true(NodeQuery.label_texts(phone).has("Requires the Improved Lab."))
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

		var texts := NodeQuery.label_texts(phone)
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
		GameState.state["player"]["veins"] = [_brief_vein()]
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()

		assert_true(NodeQuery.label_texts(phone).has("Requires the Vein Cultivation Station room."))
		assert_true(_assign_button(phone) == null, "no assign control before the room exists")
		phone.free()
	)

	run_case("procurement_lists_each_cultivator_and_assigns_a_vein_on_tap", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("veinStation")
		GameState.state["player"]["veins"] = [_brief_vein()]
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "veinStation")
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()

		assert_true(NodeQuery.label_texts(phone).has("Archie"), "cultivator section heading")
		var assign := _assign_button(phone)
		assert_true(assign != null and assign.text.contains("Time Orichalchum"), "picker identifies the ore/district")
		assign.pressed.emit()

		assert_eq(Rooms.cultivator_veins("archie"), ["v1"])
		phone.free()
	)

	run_case("procurement_shows_a_founder_cultivator_without_the_station_room", func():
		GameState.reset()
		GameState.state["player"]["veins"] = [_brief_vein()]
		GameState.state["contacts"]["owen"]["recruited"] = true
		GameState.state["flags"]["bizOwenCultivationRole"] = true
		Contacts.set_role("owen", "cultivation")
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()

		assert_true(NodeQuery.label_texts(phone).has("Owen"))
		assert_true(_assign_button(phone) != null)
		phone.free()
	)

	run_case("procurement_target_controls_adjust_and_unassign_an_assigned_vein", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("veinStation")
		GameState.state["player"]["veins"] = [_brief_vein()]
		GameState.state["contacts"]["archie"]["recruited"] = true
		Contacts.assign_to_room("archie", "veinStation")
		Rooms.assign_vein("archie", "v1")
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()

		assert_true(NodeQuery.label_texts(phone).has("Target: 70"))

		_button_with_text(phone, "+5").pressed.emit()
		assert_eq(GameState.state["veinStationTargets"]["v1"], 75)

		_button_with_text(phone, "-5").pressed.emit()
		assert_eq(GameState.state["veinStationTargets"]["v1"], 70)

		_button_with_text(phone, "Unassign").pressed.emit()
		assert_eq(Rooms.cultivator_veins("archie"), [])
		phone.free()
	)
