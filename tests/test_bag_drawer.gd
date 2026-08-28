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
# equip/unequip/Dial-lifecycle actions (Dial half replaced at dial-device
# ticket 07). Helpers below mirror tests/test_inventory.gd's
# _label_texts/_find_button_in_card, since this drawer now renders the same
# equip/Dial cards that screen does.


# dial-device ticket 07: a minimal inert-but-seeded Dial, same shape
# Dial._new_dial() produces -- callers add "movement"/"loadedComplications"
# as needed. capacityMax comes from Dial.capacity_max(1) so it's never out
# of sync with the real level-1 lookup.
func _fresh_dial() -> Dictionary:
	return {
		"level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 0, "rechargeRate": 0,
		"combatRegenTurnCounter": 0, "lastRegenDay": GameState.state["world"]["day"],
		"capacityMax": Dial.capacity_max(1), "movement": null, "loadedComplications": [],
		"haftId": "collective_brolly",
	}


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
		assert_true(_label_texts(drawer).has("No Dial. Seed one from HQ."), "the Dial management section should be present")
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
		assert_true(_label_texts(drawer).has("Weapon: none equipped"), "falls back to the read-only equipped summary")
		assert_true(_label_texts(drawer).has("Dial: none"), "falls back to the read-only Dial summary")
		assert_true(not _label_texts(drawer).has("No Dial. Seed one from HQ."), "no Dial management section during combat")
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
		assert_true(not _label_texts(drawer).has("No Dial. Seed one from HQ."), "no Dial management section while the current event card carries itemHooks")
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

	run_case("seat_and_unseat_movement_from_the_drawer_matches_dial_system", func():
		GameState.reset()
		Bag.open()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = _fresh_dial()
		player["movementInventory"] = [{ "archetype": "recharge", "oreType": "time", "tier": 1 }]

		var drawer := BagDrawer.new()
		drawer._ready()

		_find_button(drawer, "Seat").pressed.emit()
		assert_eq(GameState.state["player"]["dial"]["movement"]["archetype"], "recharge", "drawer's Seat button should seat via Dial.seat_movement")
		assert_eq(GameState.state["player"]["movementInventory"], [], "the seated Movement should leave movementInventory")

		Bag.open()
		var drawer2 := BagDrawer.new()
		drawer2._ready()
		_find_button(drawer2, "Unseat").pressed.emit()
		assert_eq(GameState.state["player"]["dial"]["movement"], null, "drawer's Unseat button should unseat via Dial.unseat_movement")
		assert_eq(GameState.state["player"]["movementInventory"].size(), 1, "unseating should return the Movement to movementInventory")

		drawer.free()
		drawer2.free()
	)

	run_case("load_and_unload_complication_from_the_drawer_matches_dial_system", func():
		GameState.reset()
		Bag.open()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = _fresh_dial()
		player["inventory"]["timePearl"] = { "1": 1 }

		var drawer := BagDrawer.new()
		drawer._ready()

		_find_button(drawer, "⧖ Time Pearl tier 1 (1) — cost 1").pressed.emit()
		var loaded: Array = GameState.state["player"]["dial"]["loadedComplications"]
		assert_eq(loaded.size(), 1, "drawer's Load button should load via Dial.load_complication")
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "loading should move the unit out of regular inventory")

		Bag.open()
		var drawer2 := BagDrawer.new()
		drawer2._ready()
		_find_button(drawer2, "Unload").pressed.emit()
		assert_eq(GameState.state["player"]["dial"]["loadedComplications"], [], "drawer's Unload button should unload via Dial.unload_complication")
		assert_eq(Crafting.inventory_qty("timePearl"), 1, "unloading should return the unit to regular inventory")

		drawer.free()
		drawer2.free()
	)

	run_case("load_complication_from_the_drawer_matches_dial_system_directly", func():
		GameState.reset()
		Bag.open()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = _fresh_dial()
		player["inventory"]["timePearl"] = { "1": 2 }

		var drawer := BagDrawer.new()
		drawer._ready()

		var snapshot: Dictionary = GameState.deep_copy(GameState.state)

		_find_button(drawer, "⧖ Time Pearl tier 1 (2) — cost 1").pressed.emit()
		var loaded_via_button: Array = GameState.state["player"]["dial"]["loadedComplications"]

		GameState.state = snapshot
		Dial.load_complication("timePearl", 1)
		var loaded_via_system: Array = GameState.state["player"]["dial"]["loadedComplications"]

		assert_eq(loaded_via_button, loaded_via_system, "drawer's Load button should produce the same loadedComplications entry as calling Dial.load_complication directly")

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

	run_case("movement_crafted_at_hq_appears_in_the_bag_drawer_seat_view", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = _fresh_dial()
		player["craftingSkill"] = 10
		player["orichalchum"]["time"] = 1000000

		Rng.set_seed(1)
		var guard := 0
		while player["movementInventory"].is_empty() and guard < 1000:
			Dial.attempt_craft_movement("recharge", "time")
			guard += 1

		assert_true(guard < 1000, "crafting a Movement should succeed within a reasonable number of attempts")
		assert_eq(player["movementInventory"].size(), 1, "the crafted Movement should land in movementInventory")

		Bag.open()
		var drawer := BagDrawer.new()
		drawer._ready()

		assert_true(_find_button(drawer, "Seat") != null, "the newly crafted Movement should offer a Seat button in the Bag drawer")

		drawer.free()
	)

	run_case("weapon_and_dial_cards_stay_drag_to_scroll_safe", func():
		GameState.reset()
		Bag.open()
		var player: Dictionary = GameState.state["player"]
		player["items"] = [{ "id": "item1", "type": "crowbar" }]
		player["dial"] = _fresh_dial()
		player["movementInventory"] = [{ "archetype": "recharge", "oreType": "time", "tier": 1 }]
		player["inventory"]["timePearl"] = { "1": 1 }

		var drawer := BagDrawer.new()
		drawer._ready()

		for panel in drawer._content.find_children("", "PanelContainer", true, false):
			assert_eq((panel as PanelContainer).mouse_filter, Control.MOUSE_FILTER_PASS, "a management card must not swallow a drag that starts on top of it")

		drawer.free()
	)
