extends "res://tests/test_base.gd"

# 01-debug-app: the Debug phone app's shell + its two simplest actions,
# screen-level-tested against a real PhoneScreen instance, same
# headless-scene pattern as tests/test_phone_bank.gd.


static func _find_tiles(root: Node) -> Array[AppTile]:
	var tiles: Array[AppTile] = []
	for t in root.find_children("", "AppTile", true, false):
		tiles.append(t as AppTile)
	return tiles


static func _find_line_edits(root: Node) -> Array[LineEdit]:
	var fields: Array[LineEdit] = []
	for n in root.find_children("", "LineEdit", true, false):
		fields.append(n as LineEdit)
	return fields


static func _find_option_buttons(root: Node) -> Array[OptionButton]:
	var buttons: Array[OptionButton] = []
	for n in root.find_children("", "OptionButton", true, false):
		buttons.append(n as OptionButton)
	return buttons


static func _find_buttons_by_text(root: Node, text: String) -> Array[Button]:
	var buttons: Array[Button] = []
	for n in root.find_children("", "Button", true, false):
		if (n as Button).text == text:
			buttons.append(n as Button)
	return buttons


# 02-debug-app-relation-adjusters: total LineEdit count on the debug screen
# once relation cards are added -- 2 (add-money, add-calc) plus one delta
# field per contact and per faction, in that fixed build order (see
# scenes/screens/phone.gd's _build_debug()).
static func _expected_field_count() -> int:
	return 2 + GameData.CONTACTS_DEFAULTS.size() + GameData.FACTIONS.size()


func run() -> void:
	run_case("debug_tile_is_absent_on_a_normal_new_game", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		var found := false
		for t in _find_tiles(phone):
			if t._app_id == "debug":
				found = true
		assert_true(not found, "a normally-started game never shows the debug tile")

		phone.free()
	)

	run_case("debug_tile_is_present_and_reachable_after_debug_start", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true

		var phone := PhoneScreen.new()
		phone._ready()

		var debug_tile: AppTile = null
		for t in _find_tiles(phone):
			if t._app_id == "debug":
				debug_tile = t
		assert_true(debug_tile != null, "debug tile must exist once debugStartUsed is true")
		assert_true(not debug_tile._lock_overlay.visible, "the debug tile itself is never locked")

		var event := InputEventScreenTouch.new()
		event.pressed = true
		debug_tile._on_gui_input(event)

		assert_eq(GameState.state["phoneNav"]["app"], "debug", "tapping the tile opens the debug app via PhoneNav")

		phone.free()
	)

	run_case("add_money_control_adds_the_entered_amount_to_cash", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["player"]["cash"] = 100
		GameState.state["phoneNav"]["app"] = "debug"

		var phone := PhoneScreen.new()
		phone._ready()

		var fields := _find_line_edits(phone)
		assert_eq(fields.size(), _expected_field_count(), "add-money and add-calc fields plus one relation-delta field per contact and faction")
		fields[0].text = "500"

		var add_buttons := _find_buttons_by_text(phone, "Add")
		assert_eq(add_buttons.size(), 2, "one Add button for money, one for calc")
		add_buttons[0].pressed.emit()

		assert_eq(GameState.state["player"]["cash"], 600, "cash increased by the entered amount")

		phone.free()
	)

	run_case("add_calc_control_adds_the_entered_amount_to_the_selected_ore_type", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["phoneNav"]["app"] = "debug"

		var phone := PhoneScreen.new()
		phone._ready()

		var fields := _find_line_edits(phone)
		assert_eq(fields.size(), _expected_field_count(), "add-money and add-calc fields plus one relation-delta field per contact and faction")
		fields[1].text = "40"

		var options := _find_option_buttons(phone)
		assert_eq(options.size(), 1, "one ore-type selector")
		options[0].selected = 1
		var chosen_ore := options[0].get_item_text(1)

		var add_buttons := _find_buttons_by_text(phone, "Add")
		add_buttons[1].pressed.emit()

		assert_eq(GameState.state["player"]["orichalchum"].get(chosen_ore, 0), 40, "the selected ore type increased by the entered amount")

		phone.free()
	)

	# 02-debug-app-relation-adjusters: contact and faction relation cards land
	# after the add-money/add-calc cards in a fixed order (contacts, in
	# GameData.CONTACTS_DEFAULTS' key order, then factions, in GameData.
	# FACTIONS' key order) -- so field index 2 is the first contact's delta
	# field, and the Nth contact/faction's Adjust button is the (N+2)th
	# "Adjust"-labelled button overall.

	run_case("debug_screen_lists_a_relation_control_for_every_contact_and_faction_regardless_of_lock_state", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["phoneNav"]["app"] = "debug"

		var phone := PhoneScreen.new()
		phone._ready()

		var expected: int = GameData.CONTACTS_DEFAULTS.size() + GameData.FACTIONS.size()
		assert_eq(_find_line_edits(phone).size(), _expected_field_count(), "one delta field per contact and per faction, plus the two 01-debug-app fields")
		assert_eq(_find_buttons_by_text(phone, "Adjust").size(), expected, "one Adjust button per contact and per faction")

		# des/nadia/hakim start unlocked=false; guild/firm/etc start joined=false --
		# both must still show up, per ticket 02's "regardless of unlock/join
		# state" requirement.
		assert_true(not GameState.state["contacts"]["des"]["unlocked"], "sanity: des starts locked")
		assert_true(not GameState.state["factions"]["guild"]["joined"], "sanity: guild starts unjoined")

		phone.free()
	)

	run_case("contact_relation_control_calls_award_relation_with_the_entered_delta", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["phoneNav"]["app"] = "debug"

		var phone := PhoneScreen.new()
		phone._ready()

		var starting_relation: int = GameState.state["contacts"]["archie"]["relation"]
		var contact_ids: Array = GameData.CONTACTS_DEFAULTS.keys()
		var archie_index: int = contact_ids.find("archie")

		var fields := _find_line_edits(phone)
		fields[2 + archie_index].text = "15"

		var adjust_buttons := _find_buttons_by_text(phone, "Adjust")
		adjust_buttons[archie_index].pressed.emit()

		assert_eq(GameState.state["contacts"]["archie"]["relation"], starting_relation + 15, "archie's relation increased by the entered delta via Contacts.award_relation")

		phone.free()
	)

	run_case("locked_contact_relation_control_still_calls_award_relation", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["phoneNav"]["app"] = "debug"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(not GameState.state["contacts"]["des"]["unlocked"], "sanity: des starts locked")
		var starting_relation: int = GameState.state["contacts"]["des"]["relation"]
		var contact_ids: Array = GameData.CONTACTS_DEFAULTS.keys()
		var des_index: int = contact_ids.find("des")

		var fields := _find_line_edits(phone)
		fields[2 + des_index].text = "90"

		var adjust_buttons := _find_buttons_by_text(phone, "Adjust")
		adjust_buttons[des_index].pressed.emit()

		assert_eq(GameState.state["contacts"]["des"]["relation"], starting_relation + 90, "a locked contact's relation is still adjustable, raising it past recruitThreshold to test the unlock gate")

		phone.free()
	)

	run_case("faction_relation_control_calls_adjust_player_relation_with_the_entered_delta", func():
		GameState.reset()
		GameState.state["flags"]["debugStartUsed"] = true
		GameState.state["phoneNav"]["app"] = "debug"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(not GameState.state["factions"]["guild"]["joined"], "sanity: guild starts unjoined")
		var starting_relation: int = GameState.state["factions"]["guild"]["relation"]
		var contact_count: int = GameData.CONTACTS_DEFAULTS.size()
		var faction_ids: Array = GameData.FACTIONS.keys()
		var guild_index: int = faction_ids.find("guild")

		var fields := _find_line_edits(phone)
		fields[2 + contact_count + guild_index].text = "40"

		var adjust_buttons := _find_buttons_by_text(phone, "Adjust")
		adjust_buttons[contact_count + guild_index].pressed.emit()

		assert_eq(GameState.state["factions"]["guild"]["relation"], starting_relation + 40, "guild's relation increased by the entered delta via Factions.adjust_player_relation, still unjoined")

		phone.free()
	)
