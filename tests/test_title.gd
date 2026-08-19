extends "res://tests/test_base.gd"

# 32-load-game-button-on-title-screen: title screen tested against a real
# TitleScreen instance, same screen-level pattern tests/test_phone_saveload.gd
# uses for its slot rows. TEST_SLOT/cleanup convention matches that file too
# -- the title UI only ever shows slots 1..SaveManager.SLOT_COUNT, so a
# real slot within that range is unavoidable, deleted before/after each case
# that touches it.

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


static func _delete_all_slots() -> void:
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		SaveManager.delete_slot(slot)


func run() -> void:
	run_case("load_game_button_is_present_alongside_new_game_and_debug_start", func():
		GameState.reset()

		var title := TitleScreen.new()
		title._ready()

		assert_true(_find_button(title, "New Game") != null, "New Game button must still be present")
		assert_true(_find_button(title, "Load Game") != null, "Load Game button must be present")
		assert_true(_find_button(title, "Debug Start") != null, "Debug Start button must still be present")

		title.free()
	)

	run_case("load_game_button_is_disabled_when_no_save_slots_exist", func():
		GameState.reset()
		_delete_all_slots()

		var title := TitleScreen.new()
		title._ready()

		assert_true(_find_button(title, "Load Game").disabled, "Load Game must be disabled with no saves")

		title.free()
	)

	run_case("load_game_button_is_enabled_once_a_slot_exists", func():
		GameState.reset()
		_delete_all_slots()
		SaveManager.save_to_slot(TEST_SLOT)

		var title := TitleScreen.new()
		title._ready()

		assert_true(not _find_button(title, "Load Game").disabled, "Load Game must be enabled once a slot exists")

		SaveManager.delete_slot(TEST_SLOT)
		title.free()
	)

	run_case("tapping_load_game_reveals_the_slot_summary", func():
		GameState.reset()
		_delete_all_slots()
		GameState.state["player"]["cash"] = 555
		GameState.state["world"]["day"] = 3
		SaveManager.save_to_slot(TEST_SLOT)

		var title := TitleScreen.new()
		title._ready()

		assert_true(not title._slot_list.visible, "slot summary must stay hidden until Load Game is tapped")

		_find_button(title, "Load Game").pressed.emit()

		assert_true(title._slot_list.visible, "tapping Load Game must reveal the slot summary")
		var texts := _label_texts(title)
		assert_true(texts.has("Slot %d" % TEST_SLOT), "the summary must name the slot")
		assert_true(texts.has("Day 3 · £555"), "the summary must show the saved day/cash")

		SaveManager.delete_slot(TEST_SLOT)
		title.free()
	)

	run_case("loading_a_slot_restores_state_and_navigates_into_the_session", func():
		GameState.reset()
		_delete_all_slots()
		GameState.state["player"]["cash"] = 4242
		GameState.state["world"]["day"] = 6
		GameState.state["currentScreen"] = "phone"
		SaveManager.save_to_slot(TEST_SLOT)

		GameState.reset()
		assert_eq(GameState.state["currentScreen"], "title", "sanity check: a fresh reset starts on title")

		var title := TitleScreen.new()
		title._ready()
		_find_button(title, "Load Game").pressed.emit()

		var received := [""]
		var on_screen := func(screen: String): received[0] = screen
		EventBus.screen_changed.connect(on_screen)
		_find_button(title, "Load").pressed.emit()
		EventBus.screen_changed.disconnect(on_screen)

		assert_eq(GameState.state["player"]["cash"], 4242, "loading must restore the saved cash")
		assert_eq(GameState.state["world"]["day"], 6, "loading must restore the saved day")
		assert_eq(GameState.state["currentScreen"], "phone", "loading must restore the saved screen")
		assert_eq(received[0], "phone", "loading from title must emit screen_changed so Main actually swaps off the title screen")

		SaveManager.delete_slot(TEST_SLOT)
		title.free()
	)
