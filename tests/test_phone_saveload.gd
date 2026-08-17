extends "res://tests/test_base.gd"

# 11-phone-os-shell ticket 09: Save/Load app -- absorbs the You tab's
# save/load/export/import/new-game content, screen-level-tested against a
# real PhoneScreen instance with state.phoneNav.app = "saveload", same
# headless-scene pattern as tests/test_phone_profile.gd. Slot 1 is used for
# the slot-action cases (the UI only ever shows slots 1..SaveManager.
# SLOT_COUNT) and is deleted before/after each such case, same cleanup
# convention tests/test_savemanager.gd documents for its own TEST_SLOT.

const TEST_SLOT := 1


static func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


static func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		texts.append((l as Label).text)
	return texts


func run() -> void:
	run_case("saveload_is_reachable_from_the_app_grid_via_the_saveload_tile", func():
		GameState.reset()

		var phone := PhoneScreen.new()
		phone._ready()

		var tile: AppTile = null
		for t in phone.find_children("", "AppTile", true, false):
			if (t as AppTile)._app_id == "saveload":
				tile = t
		assert_true(tile != null, "the app grid must include a Save/Load tile")

		var event := InputEventScreenTouch.new()
		event.pressed = true
		tile._on_gui_input(event)

		assert_eq(GameState.state["phoneNav"]["app"], "saveload", "tapping the Save/Load tile opens the Save/Load app via PhoneNav")

		phone.free()
	)

	run_case("saveload_shows_all_three_slots", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "saveload"

		var phone := PhoneScreen.new()
		phone._ready()

		var texts := _label_texts(phone)
		for slot in range(1, SaveManager.SLOT_COUNT + 1):
			assert_true(texts.has("Slot %d" % slot), "Slot %d heading must be rendered" % slot)

		phone.free()
	)

	run_case("empty_slot_shows_no_load_or_delete_button", func():
		GameState.reset()
		SaveManager.delete_slot(TEST_SLOT)
		GameState.state["phoneNav"]["app"] = "saveload"

		var phone := PhoneScreen.new()
		phone._ready()

		assert_true(_find_button(phone, "Save") != null, "Save button must always be present")
		assert_true(_find_button(phone, "Load") == null, "an empty slot must not show a Load button")
		assert_true(_find_button(phone, "Delete") == null, "an empty slot must not show a Delete button")

		phone.free()
	)

	run_case("save_then_load_button_round_trips_state_identically_to_SaveManager", func():
		GameState.reset()
		SaveManager.delete_slot(TEST_SLOT)
		GameState.state["player"]["cash"] = 4242
		GameState.state["world"]["day"] = 6
		GameState.state["phoneNav"]["app"] = "saveload"

		var phone := PhoneScreen.new()
		phone._ready()
		_find_button(phone, "Save").pressed.emit()

		assert_true(SaveManager.slot_exists(TEST_SLOT), "Save button must call through to SaveManager.save_to_slot")

		GameState.state["player"]["cash"] = 1
		GameState.state["world"]["day"] = 1
		phone.free()

		phone = PhoneScreen.new()
		phone._ready()
		_find_button(phone, "Load").pressed.emit()

		assert_eq(GameState.state["player"]["cash"], 4242, "Load button must call through to SaveManager.load_from_slot")
		assert_eq(GameState.state["world"]["day"], 6, "Load button must call through to SaveManager.load_from_slot")

		SaveManager.delete_slot(TEST_SLOT)
		phone.free()
	)

	run_case("delete_button_removes_the_slot", func():
		GameState.reset()
		SaveManager.save_to_slot(TEST_SLOT)
		assert_true(SaveManager.slot_exists(TEST_SLOT), "slot should exist before deleting")
		GameState.state["phoneNav"]["app"] = "saveload"

		var phone := PhoneScreen.new()
		phone._ready()
		_find_button(phone, "Delete").pressed.emit()

		assert_true(not SaveManager.slot_exists(TEST_SLOT), "Delete button must call through to SaveManager.delete_slot")

		phone.free()
	)

	run_case("export_button_fills_the_export_box_with_SaveManagers_export_string", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 999
		GameState.state["phoneNav"]["app"] = "saveload"

		var phone := PhoneScreen.new()
		phone._ready()
		_find_button(phone, "Generate export string").pressed.emit()

		assert_eq(phone._export_box.text, SaveManager.export_string(), "export box must hold exactly SaveManager.export_string()'s output")

		phone.free()
	)

	run_case("import_button_calls_through_to_SaveManager_import_string", func():
		GameState.reset()
		var exported := SaveManager.export_string()
		GameState.state["player"]["cash"] = 1
		GameState.state["phoneNav"]["app"] = "saveload"

		var phone := PhoneScreen.new()
		phone._ready()
		phone._import_box.text = exported
		_find_button(phone, "Import").pressed.emit()

		assert_eq(GameState.state["player"]["cash"], 40, "Import button must call through to SaveManager.import_string, restoring the exported cash value")

		phone.free()
	)

	run_case("new_game_button_alone_does_not_reset_state_or_navigate", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 4321
		GameState.state["phoneNav"]["app"] = "saveload"

		var phone := PhoneScreen.new()
		phone._ready()
		_find_button(phone, "New Game").pressed.emit()

		assert_eq(GameState.state["player"]["cash"], 4321, "a single tap on New Game must not reset player state")
		assert_true(GameState.state["currentScreen"] != "intro", "a single tap on New Game must not navigate away")

		phone.free()
	)

	run_case("new_game_button_swaps_to_confirm_cancel_pair_once_armed", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "saveload"

		var phone := PhoneScreen.new()
		phone._ready()
		_find_button(phone, "New Game").pressed.emit()

		phone.free()
		phone = PhoneScreen.new()
		phone._ready()

		assert_true(_find_button(phone, "New Game") == null, "the plain New Game button must be gone once armed")
		assert_true(_find_button(phone, "Confirm") != null, "a Confirm button must appear once armed")
		assert_true(_find_button(phone, "Cancel") != null, "a Cancel button must appear once armed")

		phone.free()
	)

	run_case("cancel_disarms_the_confirm_gate_without_resetting", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 777
		GameState.state["phoneNav"]["app"] = "saveload"
		PhoneNav.arm_new_game_confirm()

		var phone := PhoneScreen.new()
		phone._ready()
		_find_button(phone, "Cancel").pressed.emit()

		assert_eq(GameState.state["player"]["cash"], 777, "Cancel must not reset player state")
		assert_true(not GameState.state["phoneNav"]["confirmingNewGame"], "Cancel must disarm the confirm gate")

		phone.free()
		phone = PhoneScreen.new()
		phone._ready()
		assert_true(_find_button(phone, "New Game") != null, "the plain New Game button must return after Cancel")

		phone.free()
	)

	run_case("confirm_resets_state_and_navigates_to_intro", func():
		GameState.reset()
		GameState.state["player"]["cash"] = 999
		GameState.state["phoneNav"]["app"] = "saveload"
		PhoneNav.arm_new_game_confirm()

		var phone := PhoneScreen.new()
		phone._ready()
		_find_button(phone, "Confirm").pressed.emit()

		assert_eq(GameState.state["player"]["cash"], 40, "Confirm must reset player state to a fresh game")
		assert_eq(GameState.state["currentScreen"], "intro", "Confirm must navigate to intro, same as the old You tab's New Game action")

		phone.free()
	)

	run_case("opening_a_different_app_disarms_a_pending_new_game_confirm", func():
		GameState.reset()
		GameState.state["phoneNav"]["app"] = "saveload"
		PhoneNav.arm_new_game_confirm()

		PhoneNav.open_app("profile")

		assert_true(not GameState.state["phoneNav"]["confirmingNewGame"], "navigating away must disarm a pending confirm gate")
	)
