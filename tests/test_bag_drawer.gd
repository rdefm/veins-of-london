extends "res://tests/test_base.gd"

# Ticket 12: tapping outside the Bag drawer (_dim's gui_input) must close it,
# same as its own Close button — which is a bare Bag.close() with no other
# side effect (unlike sell_menu/james_job_offer in ModalLayer).
#
# BagDrawer.new() is safe to call _ready() on directly without adding it to
# a live scene tree, same reasoning tests/test_map_controls.gd already
# relies on for MapControls.
#
# 05-bag-drawer-promotion: management-mode gating and the ported
# equip/unequip/device-lifecycle actions. Helpers below mirror
# tests/test_inventory.gd's _label_texts/_find_button_in_card, since this
# drawer now renders the same equip/device cards that screen does.


static func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		texts.append((l as Label).text)
	return texts


static func _find_button(root: Node, button_text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text == button_text:
			return b
	return null


# Mirrors tests/test_events.gd's _install_choice_event: installs a synthetic
# event whose current card carries itemHooks, on a duplicated GameData.EVENTS
# so the real roster is untouched. Caller restores with the returned dict.
func _install_item_hook_event() -> Dictionary:
	var original_events: Dictionary = GameData.EVENTS
	GameData.EVENTS = GameData.EVENTS.duplicate()
	GameData.EVENTS["test_item_hook_event"] = {
		"id": "test_item_hook_event",
		"cards": [
			{ "type": "narration", "label": null, "speaker": null, "text": "Setup", "itemHooks": ["blast"] },
		],
	}
	GameState.state["event"] = { "eventId": "test_item_hook_event", "cardIndex": 0, "snapshots": [], "choiceResults": {}, "context": {} }
	return original_events


func run() -> void:
	run_case("tap_outside_the_open_bag_drawer_closes_it", func():
		GameState.reset()
		Bag.open()

		var drawer := BagDrawer.new()
		drawer._ready()

		var tap := InputEventScreenTouch.new()
		tap.pressed = true
		drawer._on_dim_gui_input(tap)

		assert_eq(GameState.state["bagDrawerOpen"], false, "outside tap closes the drawer")

		drawer.free()
	)

	run_case("non_press_input_on_the_dim_does_not_close_the_drawer", func():
		GameState.reset()
		Bag.open()

		var drawer := BagDrawer.new()
		drawer._ready()

		var release := InputEventScreenTouch.new()
		release.pressed = false
		drawer._on_dim_gui_input(release)

		assert_eq(GameState.state["bagDrawerOpen"], true, "a release event doesn't dismiss the drawer")

		drawer.free()
	)

	run_case("management_controls_present_and_drawer_taller_outside_combat_and_events", func():
		GameState.reset()
		Bag.open()
		GameState.state["player"]["items"] = [{ "id": "item1", "type": "crowbar" }]

		var drawer := BagDrawer.new()
		drawer._ready()

		assert_true(_find_button(drawer, "Equip") != null, "an unequipped weapon should get an Equip button")
		assert_true(_find_button(drawer, "⧖ Time Device") != null, "the start-a-new-device row should be present")
		assert_eq(drawer._card.offset_top, -BagDrawer.MANAGEMENT_DRAWER_HEIGHT, "drawer grows to the management height")

		drawer.free()
	)

	run_case("management_controls_hidden_and_drawer_shorter_during_combat", func():
		GameState.reset()
		Bag.open()
		GameState.state["combat"]["active"] = true
		GameState.state["player"]["items"] = [{ "id": "item1", "type": "crowbar" }]

		var drawer := BagDrawer.new()
		drawer._ready()

		assert_true(_find_button(drawer, "Equip") == null, "no Equip button during combat")
		assert_true(_find_button(drawer, "⧖ Time Device") == null, "no start-a-new-device row during combat")
		assert_true(_label_texts(drawer).has("Weapon: none equipped"), "falls back to the read-only equipped summary")
		assert_eq(drawer._card.offset_top, -BagDrawer.DRAWER_HEIGHT, "drawer stays the short read-only height")

		drawer.free()
	)

	run_case("management_controls_hidden_during_an_item_hook_event_card", func():
		GameState.reset()
		Bag.open()
		GameState.state["player"]["items"] = [{ "id": "item1", "type": "crowbar" }]
		var original_events := _install_item_hook_event()

		var drawer := BagDrawer.new()
		drawer._ready()

		assert_true(_find_button(drawer, "Equip") == null, "no Equip button while the current event card carries itemHooks")
		assert_true(_find_button(drawer, "⧖ Time Device") == null, "no start-a-new-device row while the current event card carries itemHooks")
		assert_eq(drawer._card.offset_top, -BagDrawer.DRAWER_HEIGHT, "drawer stays the short read-only height")

		drawer.free()
		GameData.EVENTS = original_events
		GameState.state["event"] = null
	)

	run_case("equip_and_unequip_weapon_from_the_drawer_matches_equipment_system", func():
		GameState.reset()
		Bag.open()
		GameState.state["player"]["items"] = [{ "id": "item1", "type": "crowbar" }]

		var drawer := BagDrawer.new()
		drawer._ready()

		_find_button(drawer, "Equip").pressed.emit()
		assert_eq(GameState.state["player"]["equipment"]["weapon"], "item1", "drawer's Equip button should equip via Equipment.equip_weapon")

		_find_button(drawer, "Unequip").pressed.emit()
		assert_eq(GameState.state["player"]["equipment"]["weapon"], null, "drawer's Unequip button should unequip via Equipment.unequip_weapon")

		drawer.free()
	)

	run_case("equip_and_unequip_device_from_the_drawer_matches_devices_system", func():
		GameState.reset()
		Bag.open()
		GameState.state["player"]["devicesCompleted"] = [{
			"id": "dev1", "type": "timeDevice", "level": 1, "xp": 0,
			"chargesPerDay": 1, "chargesUsedToday": 0, "lastResetDay": 0,
		}]

		var drawer := BagDrawer.new()
		drawer._ready()

		_find_button(drawer, "Equip").pressed.emit()
		assert_eq(GameState.state["player"]["equipment"]["device"], "dev1", "drawer's Equip button should equip via Devices.equip_device")

		_find_button(drawer, "Unequip").pressed.emit()
		assert_eq(GameState.state["player"]["equipment"]["device"], null, "drawer's Unequip button should unequip via Devices.unequip_device")

		drawer.free()
	)

	run_case("start_and_abandon_device_from_the_drawer_matches_devices_system", func():
		GameState.reset()
		Bag.open()

		var drawer := BagDrawer.new()
		drawer._ready()

		_find_button(drawer, "⧖ Time Device").pressed.emit()
		var in_progress: Array = GameState.state["player"]["devicesInProgress"]
		assert_eq(in_progress.size(), 1, "drawer's start button should create an in-progress device via Devices.start_device")

		_find_button(drawer, "Abandon").pressed.emit()
		assert_eq(GameState.state["player"]["devicesInProgress"], [], "drawer's Abandon button should remove it via Devices.abandon_device")

		drawer.free()
	)

	run_case("build_attempt_from_the_drawer_matches_devices_system_directly", func():
		GameState.reset()
		Bag.open()
		GameState.state["player"]["craftingSkill"] = 5
		GameState.state["player"]["orichalchum"]["time"] = 100000

		var drawer := BagDrawer.new()
		drawer._ready()

		_find_button(drawer, "⧖ Time Device").pressed.emit()
		var device_id: String = GameState.state["player"]["devicesInProgress"][0]["id"]
		var snapshot: Dictionary = GameState.deep_copy(GameState.state)

		Rng.set_seed(42)
		_find_button(drawer, "Build attempt").pressed.emit()
		var progress_via_button: float = GameState.state["player"]["devicesInProgress"][0]["progress"]

		GameState.state = snapshot
		Rng.set_seed(42)
		Devices.attempt_device_build(device_id)
		var progress_via_system: float = GameState.state["player"]["devicesInProgress"][0]["progress"]

		assert_almost_eq(progress_via_button, progress_via_system, 0.001, "drawer's Build attempt button should produce the same progress change as calling Devices.attempt_device_build directly")

		drawer.free()
	)

	run_case("healing_salve_and_healing_burst_get_use_buttons_outside_combat_and_events", func():
		GameState.reset()
		Bag.open()
		var player: Dictionary = GameState.state["player"]
		player["inventory"]["healingSalve"] = { "1": 1 }
		player["inventory"]["healingBurst"] = { "1": 1 }

		var drawer := BagDrawer.new()
		drawer._ready()

		assert_true(_find_button(drawer, "♥ Healing Salve (1) — 2-day heal-over-time") != null, "healingSalve should get a Use button outside combat/events")
		assert_true(_find_button(drawer, "✚ Healing Burst (1) — instant heal") != null, "healingBurst should get a Use button outside combat/events")

		drawer.free()
	)

	run_case("healing_salve_and_healing_burst_use_buttons_hidden_during_combat", func():
		GameState.reset()
		Bag.open()
		GameState.state["combat"]["active"] = true
		var player: Dictionary = GameState.state["player"]
		player["inventory"]["healingSalve"] = { "1": 1 }
		player["inventory"]["healingBurst"] = { "1": 1 }

		var drawer := BagDrawer.new()
		drawer._ready()

		assert_true(_find_button(drawer, "♥ Healing Salve (1) — 2-day heal-over-time") == null, "no out-of-combat healingSalve Use button during combat")

		drawer.free()
	)

	run_case("healing_salve_and_healing_burst_use_buttons_hidden_during_an_item_hook_event_card", func():
		GameState.reset()
		Bag.open()
		var player: Dictionary = GameState.state["player"]
		player["inventory"]["healingSalve"] = { "1": 1 }
		var original_events := _install_item_hook_event()

		var drawer := BagDrawer.new()
		drawer._ready()

		assert_true(_find_button(drawer, "♥ Healing Salve (1) — 2-day heal-over-time") == null, "no out-of-combat healingSalve Use button while the current event card carries itemHooks")

		drawer.free()
		GameData.EVENTS = original_events
		GameState.state["event"] = null
	)

	run_case("healing_salve_use_button_calls_through_to_consumables_system", func():
		GameState.reset()
		Bag.open()
		var player: Dictionary = GameState.state["player"]
		player["inventory"]["healingSalve"] = { "1": 1 }
		player["craftingSkill"] = 3

		var drawer := BagDrawer.new()
		drawer._ready()

		Rng.set_seed(1)
		var button := _find_button(drawer, "♥ Healing Salve (1) — 2-day heal-over-time")
		button.pressed.emit()

		assert_eq(Crafting.inventory_qty("healingSalve"), 0, "pressing Use should consume the item via Consumables.use_healing_salve()")
		assert_eq(GameState.state["player"]["healingSalveDaysLeft"], 2, "use_healing_salve() should start the 2-day HoT")
		assert_eq(GameState.state["bagDrawerOpen"], false, "using an item from the drawer should close it, same as combat's Use buttons")

		drawer.free()
	)

	run_case("active_healing_salve_hot_status_stays_visible_outside_combat_after_the_last_salve_is_used", func():
		GameState.reset()
		Bag.open()
		var player: Dictionary = GameState.state["player"]
		player["inventory"]["healingSalve"] = { "1": 0 }
		player["healingSalveDaysLeft"] = 1
		player["healingSalveDailyAmount"] = 5

		var drawer := BagDrawer.new()
		drawer._ready()

		var joined := "\n".join(_label_texts(drawer))
		assert_true(joined.contains("Healing Salve active"), "an active HoT should stay visible even once stock (qty 0) stops offering a Use button")
		assert_true(_find_button(drawer, "♥ Healing Salve (0) — 2-day heal-over-time") == null, "no Use button once stock is 0")

		drawer.free()
	)

	run_case("weapon_and_device_cards_stay_drag_to_scroll_safe", func():
		GameState.reset()
		Bag.open()
		GameState.state["player"]["items"] = [{ "id": "item1", "type": "crowbar" }]
		GameState.state["player"]["devicesInProgress"] = [{ "id": "dev1", "type": "timeDevice", "progress": 10.0 }]

		var drawer := BagDrawer.new()
		drawer._ready()

		for panel in drawer._content.find_children("", "PanelContainer", true, false):
			assert_eq((panel as PanelContainer).mouse_filter, Control.MOUSE_FILTER_PASS, "a management card must not swallow a drag that starts on top of it")

		drawer.free()
	)
