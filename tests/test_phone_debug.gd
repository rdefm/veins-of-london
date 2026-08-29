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
		assert_eq(fields.size(), 2, "one amount field for add-money, one for add-calc")
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
		assert_eq(fields.size(), 2, "one amount field for add-money, one for add-calc")
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
