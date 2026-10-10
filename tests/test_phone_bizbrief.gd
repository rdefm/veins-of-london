extends "res://tests/test_base.gd"

const MorningAccountsSystem := preload("res://systems/morning_accounts.gd")
const NodeQuery := preload("res://tests/support/node_query.gd")
const Fixtures := preload("res://tests/support/fixtures.gd")

static func _button_with_text(root: Node, text: String) -> Button:
	for candidate in root.find_children("", "Button", true, false):
		if (candidate as Button).text == text:
			return candidate as Button
	return null


static func _label_with_text(root: Node, text: String) -> Label:
	for candidate in root.find_children("", "Label", true, false):
		if (candidate as Label).text == text:
			return candidate as Label
	return null


# Opens every collapsed Brief section (accounts, Treasury, Operations feed).
static func _expand_brief_sections(root: Node) -> void:
	for key in ["accounts", "treasury", "operations"]:
		var section: Node = root.find_child("BizBriefSection_%s" % key, true, false)
		var header := section.get_child(0) as Button
		if header.text.ends_with("▸"):
			header.pressed.emit()


static func _assign_button(root: Node) -> Button:
	for candidate in root.find_children("", "Button", true, false):
		if (candidate as Button).text.begins_with("Assign "):
			return candidate as Button
	return null


# The bizbrief's own vein: no site link, and a real street for the location line.
static func _brief_vein() -> Dictionary:
	return Fixtures.player_vein_with({ "location": "Vallance Rd, by the bus stop", "siteId": null })


func run() -> void:
	calendar_start_weekday = 0  # fixtures count days from a Monday day 1
	run_case("bizbrief_chrome_keeps_device_and_live_header", func():
		GameState.reset()
		GameState.state["world"]["day"] = 24
		GameState.state["world"]["timeBlock"] = 1
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(phone.find_child("DeviceFrame", true, false) != null)
		assert_true(phone.find_child("DeviceStatusBar", true, false) != null)
		assert_true(phone.find_child("BizBriefIcon", true, false) is TextureRect)
		assert_eq((phone.find_child("BizBriefDayBlock", true, false) as Label).text, "DAY 24 · AFTERNOON")
		assert_true(_label_with_text(phone, "BizBrief") != null)
		_button_with_text(phone, "‹ Phone").pressed.emit()
		assert_eq(GameState.state["phoneNav"]["app"], "home")
		phone.free()
	)

	run_case("bizbrief_tabs_keep_gates_selection_and_view_state", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(_button_with_text(phone, "Staff") == null)
		assert_true(_button_with_text(phone, "Stats") == null)
		var brief := _button_with_text(phone, "Brief")
		assert_true(brief.disabled)
		assert_eq((brief.get_theme_stylebox("disabled") as StyleBoxFlat).border_width_bottom, 3)
		_button_with_text(phone, "Manage").pressed.emit()
		assert_true(_button_with_text(phone, "Manage").disabled)
		assert_true(NodeQuery.label_texts(phone).has("SALES PIPELINE"))
		GameState.state["flags"]["bizStaffTabOpen"] = true
		Business.activate()
		phone._refresh()
		assert_true(_button_with_text(phone, "Manage").disabled)
		assert_true(_button_with_text(phone, "Staff") != null)
		assert_true(_button_with_text(phone, "Stats") != null)
		_button_with_text(phone, "Staff").pressed.emit()
		assert_true(_button_with_text(phone, "Staff").disabled)
		assert_true(NodeQuery.label_texts(phone).has("Staff"))
		_button_with_text(phone, "Stats").pressed.emit()
		assert_true(_button_with_text(phone, "Stats").disabled)
		assert_true(NodeQuery.label_texts(phone).has("Expense analysis"))
		GameState.state["business"]["potActive"] = false
		GameState.state["flags"]["bizStaffTabOpen"] = false
		phone._refresh()
		assert_true(_button_with_text(phone, "Brief").disabled, "closed selected tab falls back to Brief")
		assert_true(_button_with_text(phone, "Staff") == null)
		assert_true(_button_with_text(phone, "Stats") == null)
		phone.free()
	)

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

	run_case("brief_renders_today_card_first_and_expands_collapsed_accounts_treasury_operations", func():
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
		var page: Node = phone.find_child("BizBriefPage", true, false)
		assert_eq(page.get_child(0).name, &"BizBriefToday", "the Today card leads the Brief")
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("Today"))
		assert_true(page.find_child("BizBriefHero", true, false) == null, "lower sections start collapsed")
		for key in ["accounts", "treasury", "operations"]:
			var body: Control = page.find_child("BizBriefSection_%s" % key, true, false).get_child(1)
			assert_true(not body.visible and body.get_child_count() == 0, "%s starts collapsed" % key)
		assert_true(not NodeQuery.button_texts(phone).any(func(t: String): return t.find("unread") != -1), "unread messages are not Today rows")
		_expand_brief_sections(phone)
		texts = NodeQuery.label_texts(phone)
		for expected in ["BizBrief", "Morning Brief", "£145", "−£55", "Reynard's", "Operations", "Opening £200 · Closing £145", "Income +£20 · Expenses −£75"]:
			assert_true(texts.has(expected), "missing %s" % expected)
		assert_true(_button_with_text(phone, "Full brief →") != null)
		_button_with_text(phone, "Full brief →").pressed.emit()
		phone.free()
	)

	run_case("today_surfaces_a_live_development_eligible_vein_and_its_action_opens_the_vein", func():
		GameState.reset()
		Fixtures.seed_vein("eligible", 95)
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.any(func(t: String): return t.find("ready to develop") != -1), "development-eligible vein is a Today row")
		assert_true(texts.any(func(t: String): return t.find("Raid exposure") != -1), "with its raid exposure")
		var row: Node = phone.find_child("TodayRow_development_eligible", true, false)
		assert_true(row != null, "row keyed by vein")
		_button_with_text(row, "Manage").pressed.emit()
		assert_eq(GameState.state["currentScreen"], "map")
		assert_eq(GameState.state["mapNav"]["selectedSiteId"], "site_eligible")
		phone.free()
	)

	run_case("brief_lead_is_live_before_rollover_and_treasury_moves_funds", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 300
		Messages.append("archie", "them", "Call me.")
		Business.activate()
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(NodeQuery.label_texts(phone).has("Today"), "Today card before rollover")
		_expand_brief_sections(phone)
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("£300"), "live cash in hero")
		assert_true(texts.has("Business pot · £0"))
		assert_true(texts.has("Bill float · £0"))
		assert_true(texts.has("No overnight operations to report."))
		_button_with_text(phone, "Donate").pressed.emit()
		assert_eq(GameState.state["business"]["float"], 1)
		assert_eq(GameState.state["player"]["cash"], 299)
		_button_with_text(phone, "Withdraw").pressed.emit()
		assert_eq(GameState.state["business"]["float"], 0)
		assert_eq(GameState.state["player"]["cash"], 300)
		phone.free()
	)

	run_case("short_pay_keeps_back_stepper_totals_and_confirmation", func():
		GameState.reset()
		var vein := Fixtures.seed_vein("shortpay", 50)
		vein["security"] = "guarded"
		GameState.state["world"]["day"] = Calendar.monday_on_or_after(8)
		GameState.state["player"]["cash"] = 0
		GuardUpkeep.pay_monday_bill()
		PhoneNav.open_short_pay()
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(phone.find_child("BizBriefShortPay", true, false) != null)
		assert_true(NodeQuery.label_texts(phone).has("Short Pay"))
		assert_true(NodeQuery.label_texts(phone).has("Keep 1"))
		assert_true(NodeQuery.label_texts(phone).has("This week £500 · Reserve £0"))
		assert_true(_button_with_text(phone, "Confirm").disabled)
		_button_with_text(phone, "‹ BizBrief").pressed.emit()
		assert_eq(GameState.state["phoneNav"]["bizbriefView"], null)
		PhoneNav.open_short_pay()
		_button_with_text(phone, "−").pressed.emit()
		assert_true(NodeQuery.label_texts(phone).has("Keep 0"))
		assert_true(NodeQuery.label_texts(phone).has("This week £0 · Reserve £0"))
		_button_with_text(phone, "Confirm").pressed.emit()
		assert_eq(GuardUpkeep.pending_shortfall(), null)
		assert_eq(GameState.state["phoneNav"]["bizbriefView"], null)
		phone.free()
	)

	run_case("today_never_lists_a_vein_already_at_its_level_cap", func():
		GameState.reset()
		var capped := Fixtures.seed_vein("capped", 95)
		capped["level"] = 3  # fair cap 3: already maxed
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
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
		GameState.state["world"]["day"] = 2
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
			"Owen is owed £214 and has stopped working. Top up the float by £214?",
		]:
			assert_true(texts.has(expected), "missing %s" % expected)
		_button_with_text(phone, "Yes").pressed.emit()
		assert_eq(Business.owed("owen"), 0, "Yes tops up the float and pays from it")
		assert_eq(GameState.state["player"]["cash"], 786)
		assert_eq(GameState.state["business"]["float"], 0)
		phone.free()
	)

	run_case("brief_no_leaves_owen_unpaid_and_drops_the_prompt", func():
		GameState.reset()
		GameState.state["world"]["day"] = 2
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

	run_case("quiet_lead_sections_show_empty_states", func():
		GameState.reset()
		MorningAccountsSystem.finish_rollover(MorningAccountsSystem.begin_rollover())
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(NodeQuery.label_texts(phone).has(DailyBrief.empty_text()))
		_expand_brief_sections(phone)
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("Reynard's"))
		assert_true(texts.has("No overnight operations to report."))
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
		for expected in ["BizBrief", "Operations / Sales pipeline", "SALES PIPELINE", "Production", "Procurement"]:
			assert_true(texts.has(expected), "missing %s" % expected)
		assert_true(not texts.has("Morning Brief"), "Manage does not duplicate the Brief tab")
		var brief := _button_with_text(phone, "Brief")
		assert_true(brief != null, "Manage keeps the Brief tab available")
		brief.pressed.emit()
		assert_true(NodeQuery.label_texts(phone).has("Morning Brief"), "Brief preserves the existing account view")
		phone.free()
	)

	# 30-production-contract-coverage-toggle
	run_case("manage_sales_offer_actions_use_live_terms_and_pipeline_counts", func():
		GameState.reset()
		var offer: Dictionary = Offers.create_scripted_offer("scripted_life_order")["offer"]
		var payment: int = offer["quote"]["payment"]
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("Sales · 0 active"))
		assert_true(texts.has("1 OFFER"))
		assert_true(texts.has("Offered contracts · 1"))
		assert_true(texts.has("expires %s · £%d per delivery" % [Calendar.format_day(int(offer["expiresDay"])), payment]))
		_button_with_text(phone, "Accept").pressed.emit()
		assert_eq(Contracts.active_contracts().size(), 1)
		assert_true(NodeQuery.label_texts(phone).has("Sales · 1 active"))
		assert_true(NodeQuery.label_texts(phone).has("0 OFFERS"))
		assert_true(_button_with_text(phone, "Details →") != null)
		_button_with_text(phone, "Details →").pressed.emit()
		assert_true(NodeQuery.label_texts(phone).has("£%d per delivery" % payment))
		_button_with_text(phone, "Buy missing calc: off").pressed.emit()
		assert_true(bool(Contracts.active_contracts()[0].get("buyCalc", false)))
		phone.free()
	)

	run_case("manage_sales_poach_decline_priority_history_and_cancel", func():
		GameState.reset()
		var declined: Dictionary = Offers.create_scripted_offer("scripted_life_order")["offer"]
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()
		_button_with_text(phone, "Decline").pressed.emit()
		assert_true(Offers.pending_offers().is_empty())
		var first: Dictionary = Offers.accept_offer(Offers.create_scripted_offer("scripted_life_order")["offer"]["id"])["contract"]
		var second: Dictionary = Offers.accept_offer(Offers.create_scripted_offer("scripted_life_order")["offer"]["id"])["contract"]
		var cards: Array = phone.find_children("", "ContractCard", true, false)
		assert_eq(cards.size(), 2)
		cards[0]._drop_data(Vector2.ZERO, { "contractId": second["id"] })
		assert_eq(Contracts.active_contracts()[0]["id"], second["id"])
		_button_with_text(phone, "Details →").pressed.emit()
		_button_with_text(phone, "Cancel contract").pressed.emit()
		var layer := ModalLayer.new()
		layer._ready()
		assert_true((layer._card.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.is_equal_approx(Color("#172431")))
		_button_with_text(layer, "Keep").pressed.emit()
		assert_eq(Contracts.active_contracts().size(), 2)
		_button_with_text(phone, "Cancel contract").pressed.emit()
		_button_with_text(layer, "Confirm").pressed.emit()
		assert_eq(Contracts.active_contracts().size(), 1)
		_button_with_text(phone, "History →").pressed.emit()
		assert_true(NodeQuery.label_texts(phone).any(func(t: String): return t.contains("cancelled")))
		layer.free()
		phone.free()
	)

	run_case("manage_sales_poached_renewal_matches_the_rival_quote", func():
		GameState.reset()
		var offer: Dictionary = Offers.create_scripted_offer("scripted_life_order")["offer"]
		offer["source"] = "renewal"
		offer["poach"] = { "factionId": "firm", "payment": 12 }
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()
		assert_true(NodeQuery.label_texts(phone).has("Renewal. Same order, today's price."))
		assert_true(_button_with_text(phone, "Accept") == null)
		_button_with_text(phone, "Match £12").pressed.emit()
		assert_eq(Contracts.active_contracts()[0]["signedQuote"]["payment"], 12)
		phone.free()
	)

	run_case("production_shows_a_room_gate_message_when_lab_not_installed", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()

		assert_true(NodeQuery.label_texts(phone).has("Requires the Improved Lab."))
		phone.free()
	)

	run_case("production_with_no_crafters_lists_nothing", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("lab")
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()

		assert_true(NodeQuery.label_texts(phone).has("Nothing your crafters can make yet."))
		assert_eq(phone.find_children("", "HSlider", true, false).size(), 0)
		phone.free()
	)

	run_case("production_lists_james_speciality_recipes_and_adjusts_target_and_toggle", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("lab")
		GameState.state["contacts"]["james"]["recruited"] = true
		GameState.state["flags"]["bizJamesProductionRole"] = true
		var created: Dictionary = Offers.create_offer({ "id": "manage_need", "source": "random", "contractType": "oneOff", "request": { "kind": "consumable", "type": "timePearl", "qty": 3 } })
		Offers.accept_offer(created["offer"]["id"])
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()

		var texts := NodeQuery.label_texts(phone)
		for name in ["Time Pearl", "Enhancement Powder", "Rewind", "Healing Salve", "Healing Burst"]:
			assert_true(texts.has(name), "%s within time+life is listed" % name)
		assert_true(not texts.has("Blast"), "physics recipe stays off James's list")
		assert_true(not texts.has("Wormhole"), "time+physics recipe stays off James's list")
		assert_true(texts.has("Personal target: 0"))
		assert_true(texts.has("Contract need: 3"))

		var sliders: Array = phone.find_children("", "HSlider", true, false)
		assert_eq(sliders.size(), Rooms.producible_recipes("james").size(), "one target slider per listed recipe")
		var slider := sliders[0] as HSlider
		assert_eq([int(slider.min_value), int(slider.max_value)], [0, GameData.PRODUCTION_TARGET_MAX], "target spans 0..the data cap")
		slider.value = 5
		slider.value_changed.emit(5.0)
		assert_true(NodeQuery.label_texts(phone).has("Personal target: 5"), "label follows the drag")
		slider.drag_ended.emit(true)
		assert_eq(GameState.state["labThresholds"]["timePearl"], 5)

		var cover := _button_with_text(phone, "Cover contract needs")
		assert_true(cover != null)
		cover.pressed.emit()
		assert_true(GameState.state["labCoverContracts"]["timePearl"])
		assert_true(NodeQuery.label_texts(phone).has("Personal target: 5 · contract need: 3 · crafting to: 8"))
		phone.free()
	)

	run_case("production_log_rows_are_collapsed_and_expand_on_tap", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("lab")
		GameState.state["flags"]["craftingUnlocked"] = true
		GameState.state["productionLog"] = [
			{ "day": 2, "blocks": [{ "block": 0, "entries": [{ "contactId": "james", "made": { "timePearl": { "3": 7 } }, "failed": { "timePearl": 2 }, "oreShort": { "recipeKey": "timePearl", "ore": ["time"] } }] }] },
			{ "day": 3, "blocks": [] },
		]
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Manage").pressed.emit()
		assert_true(_button_with_text(phone, "Log →") != null)
		assert_true(_button_with_text(phone, "TUE 2 APR · 7 made · 2 failed ▸") == null)
		_button_with_text(phone, "Log →").pressed.emit()
		assert_true(_button_with_text(phone, "Log ▾") != null)

		var row := _button_with_text(phone, "TUE 2 APR · 7 made · 2 failed ▸")
		assert_true(row != null, "day row shows a collapsed summary")
		assert_true(_button_with_text(phone, "WED 3 APR · 0 made · 0 failed ▸") != null)
		var entry_label := _label_with_text(phone, "James made 7 Time Pearl (tier 3)")
		assert_true(entry_label != null and not entry_label.get_parent().visible, "collapsed hides entries")
		var before: Dictionary = GameState.deep_copy(GameState.state)
		row.pressed.emit()
		assert_eq(GameState.state, before, "expanding only changes view state")
		assert_true(entry_label.get_parent().visible, "tap expands the day")

		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("Morning"), "block heading")
		assert_true(texts.has("James failed 2 Time Pearl"))
		assert_true(texts.has("James stopped: not enough Time Orichalchum for Time Pearl"), "ore-short note")
		row.pressed.emit()
		assert_true(not entry_label.get_parent().visible, "tap again collapses")
		_button_with_text(phone, "Log ▾").pressed.emit()
		assert_true(_button_with_text(phone, "TUE 2 APR · 7 made · 2 failed ▸") == null)
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
		assert_true(_button_with_text(phone, "ASSIGN VEINS →") != null)
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

	run_case("staff_tab_hidden_until_beat_3_flag", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(_button_with_text(phone, "Staff") == null)
		phone.free()

		GameState.state["flags"]["bizStaffTabOpen"] = true
		phone = PhoneScreen.new()
		phone._ready()
		assert_true(_button_with_text(phone, "Staff") != null)
		phone.free()
	)

	run_case("stats_tab_appears_with_the_business_pot_and_toggles_ore_source", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(_button_with_text(phone, "Stats") == null)
		phone.free()

		Business.activate()
		GameState.state["world"]["day"] = 13
		GameState.state["businessStats"]["days"] = [
			{ "day": 3, "revenue": 400, "expenses": 90, "expensesStaff": 20, "expensesGuard": 50, "expensesCalc": 20, "oreCultivator": 8, "orePlayer": 2, "items": 3 },
			{ "day": 11, "revenue": 150, "expenses": 60, "expensesStaff": 30, "expensesGuard": 0, "expensesCalc": 30, "oreCultivator": 4, "orePlayer": 7, "items": 2 },
		]
		phone = PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Stats").pressed.emit()
		var charts := phone.find_children("*", "LineChart", true, false)
		assert_eq(charts.size(), 3, "daily trend, ore yield, item production")
		assert_eq((charts[0] as LineChart)._values, BusinessStats.series("revenue"))
		assert_eq((charts[0] as LineChart)._extra_series[0]["values"], BusinessStats.series("expenses"))
		assert_eq((charts[0] as LineChart)._colour, BizBriefApp.SIGNAL)
		assert_eq((charts[0] as LineChart)._values[1], 0, "missing completed day is zero filled")
		var texts := NodeQuery.label_texts(phone)
		for expected in ["£550", "£150", "£50", "5", "● REVENUE", "● EXPENSES", "STAFF WAGES", "CALC BOUGHT", "Expense analysis", "Ore yield", "Items produced"]:
			assert_true(texts.has(expected), "missing stats value %s" % expected)
		assert_true(_button_with_text(phone, "GUARD WAGES ↗") != null, "guard expense opens Guard Costs")
		assert_true(_button_with_text(phone, "Cultivators").disabled)
		assert_eq((charts[1] as LineChart)._values, BusinessStats.series("oreCultivator"))
		assert_eq((_button_with_text(phone, "Cultivators").get_theme_stylebox("disabled") as StyleBoxFlat).border_color, BizBriefApp.SIGNAL)
		_button_with_text(phone, "You").pressed.emit()
		assert_true(_button_with_text(phone, "You").disabled)
		assert_true(not _button_with_text(phone, "Cultivators").disabled)
		charts = phone.find_children("*", "LineChart", true, false)
		assert_eq((charts[1] as LineChart)._values, BusinessStats.series("orePlayer"))
		assert_eq((charts[2] as LineChart)._values, BusinessStats.series("items"))
		assert_eq((_button_with_text(phone, "You").get_theme_stylebox("disabled") as StyleBoxFlat).border_color, BizBriefApp.SIGNAL)
		phone.free()
	)

	run_case("guard_costs_view_opens_from_the_guard_legend_and_filters_lines", func():
		GameState.reset()
		Business.activate()
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Stats").pressed.emit()
		_button_with_text(phone, "GUARD WAGES ↗").pressed.emit()
		assert_eq(GameState.state["phoneNav"]["bizbriefView"], PhoneNav.BIZBRIEF_GUARD_COSTS_VIEW)
		assert_true(phone.find_child("BizBriefGuardCosts", true, false) != null)
		_button_with_text(phone, "‹ BizBrief").pressed.emit()
		assert_eq(GameState.state["phoneNav"]["bizbriefView"], null)
		assert_true(_button_with_text(phone, "Stats").disabled, "back returns to Stats")
		phone.free()
	)

	run_case("guard_costs_view_renders_before_the_pot_with_header_and_filter", func():
		GameState.reset()
		var vein := Fixtures.seed_vein("v1", 50)
		vein["security"] = "guarded"
		GameState.state["world"]["day"] = Calendar.monday_on_or_after(8)
		GuardUpkeep.record_payment("v1", 500)
		PhoneNav.open_guard_costs()
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(_label_with_text(phone, "Next Monday: £500") != null, "next bill header")
		assert_eq(phone.find_children("*", "LineChart", true, false).size(), 1)
		var hq := _button_with_text(phone, "● HQ")
		assert_true(hq != null, "HQ in the filter, on by default")
		hq.pressed.emit()
		assert_true(_button_with_text(phone, "○ HQ") != null, "toggled off")
		phone.free()

		var view: RefCounted = preload("res://scenes/phone_apps/guard_costs_view.gd").new()
		assert_eq(view.chart_lines().map(func(l): return l["placeId"]), ["home", "v1"], "all places by default")
		view.toggle_place("home")
		var lines: Array = view.chart_lines()
		assert_eq(lines.map(func(l): return l["placeId"]), ["v1"], "a subset limits the chart")
		assert_eq(lines[0]["values"][-1], 500)
		view.toggle_place("v1")
		assert_eq(view.chart_lines(), [])
	)

	run_case("guard_costs_header_shows_a_pending_shortfall", func():
		GameState.reset()
		var vein := Fixtures.seed_vein("v1", 50)
		vein["security"] = "guarded"
		GameState.state["world"]["day"] = Calendar.monday_on_or_after(8)
		GameState.state["player"]["cash"] = 0
		GuardUpkeep.pay_monday_bill()
		PhoneNav.open_guard_costs()
		var phone := PhoneScreen.new()
		phone._ready()
		var deadline := Calendar.format_day(int(GuardUpkeep.pending_shortfall()["deadline"]))
		assert_true(_label_with_text(phone, "Unpaid this week: £500 · reserve £0 · decide by %s" % deadline) != null)
		_button_with_text(phone, "Choose who stays ›").pressed.emit()
		assert_eq(GameState.state["phoneNav"]["bizbriefView"], PhoneNav.BIZBRIEF_SHORT_PAY_VIEW)
		phone.free()
	)

	run_case("staff_tab_lists_recruited_contacts_with_terms_skills_and_status", func():
		GameState.reset()
		GameState.state["flags"]["bizStaffTabOpen"] = true
		GameState.state["flags"]["bizOwenCultivationRole"] = true
		GameState.state["contacts"]["archie"]["recruited"] = true
		GameState.state["contacts"]["owen"]["recruited"] = true
		GameState.state["contacts"]["owen"]["cultivatingSkill"] = 2
		GameState.state["contacts"]["owen"]["cultivatingXP"] = 40
		Contacts.set_role("owen", "cultivation")
		Business.activate()
		GameState.state["business"]["wages"]["owen"]["unpaid"] = true
		GameState.state["business"]["wages"]["owen"]["owed"] = 120
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Staff").pressed.emit()

		var texts := NodeQuery.label_texts(phone)
		for expected in ["ROSTER / 02 RECRUITED", "PAYROLL EXPOSURE", "£120 owed", "01 / Archie", "02 / Owen", "Archie", "Owen", "No role · ⅓ share", "Cultivation · £%d a week" % int(GameData.BUSINESS_WEEKLY_WAGES["owen"]), "Unpaid · owed £120", "CULTIVATING", "LV 2 / 40 XP · cap 3", "Assignments"]:
			assert_true(texts.has(expected), "missing %s" % expected)
		assert_true(not texts.has("James"), "unrecruited James not listed")
		phone.free()
	)

	run_case("staff_exposure_sums_wages_and_pay_disables_when_cash_short", func():
		GameState.reset()
		GameState.state["flags"]["bizStaffTabOpen"] = true
		GameState.state["contacts"]["owen"]["recruited"] = true
		GameState.state["contacts"]["james"]["recruited"] = true
		Business.activate()
		GameState.state["business"]["wages"]["owen"]["unpaid"] = true
		GameState.state["business"]["wages"]["owen"]["owed"] = 120
		GameState.state["business"]["wages"]["james"] = {
			"weekly": 80, "owed": 40, "unpaid": true, "promptPending": false,
			"hiredDay": 1, "daysWorked": 0,
		}
		GameState.state["player"]["cash"] = 50
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Staff").pressed.emit()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("£160 owed"))
		assert_true(texts.has("Unpaid · owed £40"))
		assert_true(_button_with_text(phone, "Top up £120 and pay").disabled)
		assert_true(not _button_with_text(phone, "Top up £40 and pay").disabled)
		phone.free()
	)

	run_case("staff_tab_shows_no_pay_for_a_room_hire_without_a_business_wage", func():
		GameState.reset()
		GameState.state["flags"]["bizStaffTabOpen"] = true
		GameState.state["contacts"]["des"]["recruited"] = true
		Contacts.assign_to_room("des", "lab")
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Staff").pressed.emit()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has("Production · No pay"), "only a business wage entry carries pay terms")
		phone.free()
	)

	run_case("staff_role_picker_offers_only_available_roles_and_sets_role", func():
		GameState.reset()
		GameState.state["flags"]["bizStaffTabOpen"] = true
		GameState.state["flags"]["bizOwenCultivationRole"] = true
		GameState.state["contacts"]["owen"]["recruited"] = true
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Staff").pressed.emit()

		assert_true(_button_with_text(phone, "Production") == null, "production not yet available")
		_button_with_text(phone, "Cultivation").pressed.emit()
		assert_eq(Contacts.role_of("owen"), "cultivation")

		_button_with_text(phone, "Clear role").pressed.emit()
		assert_eq(Contacts.role_of("owen"), null)
		phone.free()
	)

	run_case("staff_pay_now_shows_only_while_owed_and_tops_up_the_float", func():
		GameState.reset()
		GameState.state["flags"]["bizStaffTabOpen"] = true
		GameState.state["contacts"]["owen"]["recruited"] = true
		Business.activate()
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Staff").pressed.emit()
		assert_true(_button_with_text(phone, "Top up £120 and pay") == null)
		phone.free()

		GameState.state["business"]["wages"]["owen"]["unpaid"] = true
		GameState.state["business"]["wages"]["owen"]["owed"] = 120
		GameState.state["player"]["cash"] = 500
		phone = PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Staff").pressed.emit()
		_button_with_text(phone, "Top up £120 and pay").pressed.emit()
		assert_eq(GameState.state["player"]["cash"], 380)
		assert_eq(GameState.state["business"]["float"], 0, "the top-up is spent on the wage")
		assert_true(not Business.is_unpaid("owen"))
		assert_true(_button_with_text(phone, "Top up £120 and pay") == null, "button gone once paid")
		phone.free()
	)

	run_case("staff_procurement_link_opens_manage", func():
		GameState.reset()
		GameState.state["flags"]["bizStaffTabOpen"] = true
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		_button_with_text(phone, "Staff").pressed.emit()
		_button_with_text(phone, "Vein picking: Manage → Procurement").pressed.emit()
		assert_true(NodeQuery.label_texts(phone).has("Procurement"))
		phone.free()
	)

	run_case("brief_shows_player_shares_with_week_on_week_moves", func():
		GameState.reset()
		GameState.state["world"]["day"] = 1
		Shares.record_ore("player", "time", 1)
		Shares.record_ore("guild", "time", 1)
		GameState.state["world"]["day"] = 8
		Shares.record_ore("player", "time", 1)
		Shares.record_ore("guild", "time", 3)
		Shares.record_craft("player", { "life": 2 })
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
		for expected in ["Your share of London", "Ore 25% ▼", "Crafting 100% ▲", "Crafting 0%"]:
			assert_true(texts.has(expected), "missing %s" % expected)
		assert_eq(_label_with_text(phone, "Ore 25% ▼").get_theme_color("font_color"), PriceMove.colour(-1, Color.WHITE))
		phone.free()
	)

	run_case("brief_shows_supplier_share_per_faction_delivered_to", func():
		GameState.reset()
		Shares.record_delivery("guild", 3)
		Shares.record_delivery("collective", 1)
		Shares.record_london_buy("guild", 9)
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		var texts := NodeQuery.label_texts(phone)
		assert_true(texts.has(GameData.FACTIONS["guild"]["shortName"]), "delivered-to faction listed")
		assert_true(texts.has("75% of your deliveries · 25% of their intake"), "guild reads A and B")
		assert_true(texts.has("25% of your deliveries · 100% of their intake"), "collective reads A and B")
		assert_true(not texts.has(GameData.FACTIONS["firm"]["shortName"]), "undelivered faction omitted")
		phone.free()
	)

	run_case("brief_supplier_share_empty_without_deliveries", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "bizbrief"
		var phone := PhoneScreen.new()
		phone._ready()
		assert_true(NodeQuery.label_texts(phone).has("No contract deliveries in the last %d days." % GameData.SHARES_WINDOW_DAYS))
		phone.free()
	)
