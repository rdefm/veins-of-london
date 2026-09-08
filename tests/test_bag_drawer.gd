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
# equip/unequip weapon actions. Helpers below mirror tests/test_inventory.gd's
# _label_texts/_find_button_in_card, since this drawer now renders the same
# equip card that screen did.
#
# hq-diorama ticket 09: the Dial-lifecycle half of this file (seat/unseat
# Movement, wind, load/unload Complications, and their own _fresh_dial()
# fixture) is deleted -- that management moved entirely to
# tests/test_hq_dial.gd, covering the new scenes/screens/hq_dial.gd screen.
# This file keeps only the read-only Dial-summary assertions (still rendered
# by _build_dial_summary_label(), untouched by that ticket).


# Ticket 114: symbol_row()/symbol_button() split what used to be one Label's
# raw-symbol string into a Label per text part plus a SymbolGlyph glyph (see
# ui.gd's own comment on symbol_row()) -- reconstructs the row's displayed
# text by walking a symbol_row/symbol_button's direct children in order,
# substituting SymbolGlyph.symbol for the glyph's drawn text, with no
# separator added (call sites already author any needed space into their
# text parts; the hbox's own pixel gap covers the rest visually).
static func _effective_text(control: Control) -> String:
	var out := ""
	for child in control.get_children():
		if child is SymbolGlyph:
			out += (child as SymbolGlyph).symbol
		elif child is Label:
			out += (child as Label).text
	return out


static func _label_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		texts.append((l as Label).text)
	for g in root.find_children("", "SymbolGlyph", true, false):
		var parent := (g as SymbolGlyph).get_parent() as Control
		if parent:
			texts.append(_effective_text(parent))
	return texts


static func _find_button(root: Node, button_text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		var btn := b as Button
		if btn.text == button_text:
			return btn
		if btn.get_child_count() > 0 and _effective_text(btn.get_child(0) as Control) == button_text:
			return btn
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

	# hq-diorama ticket 09: the drawer's Seat/Unseat/Load/Unload Dial cases
	# used to live here -- moved (not deleted) to tests/test_hq_dial.gd, since
	# that management now lives entirely on the full-bleed hq_dial.gd screen.

	run_case("healing_salve_and_healing_burst_get_use_buttons_outside_combat_and_events", func():
		GameState.reset()
		Bag.open()
		var player: Dictionary = GameState.state["player"]
		player["inventory"]["healingSalve"] = { "1": 1 }
		player["inventory"]["healingBurst"] = { "1": 1 }

		var drawer := BagDrawer.new()
		drawer._ready()

		assert_true(_find_button(drawer, "♥Healing Salve (1) — 2-day heal-over-time") != null, "healingSalve should get a Use button outside combat/events")
		assert_true(_find_button(drawer, "✚Healing Burst (1) — instant heal") != null, "healingBurst should get a Use button outside combat/events")

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

		assert_true(_find_button(drawer, "♥Healing Salve (1) — 2-day heal-over-time") == null, "no out-of-combat healingSalve Use button during combat")

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

		assert_true(_find_button(drawer, "♥Healing Salve (1) — 2-day heal-over-time") == null, "no out-of-combat healingSalve Use button while the current event card carries itemHooks")

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
		var button := _find_button(drawer, "♥Healing Salve (1) — 2-day heal-over-time")
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
		assert_true(_find_button(drawer, "♥Healing Salve (0) — 2-day heal-over-time") == null, "no Use button once stock is 0")

		drawer.free()
	)

	# hq-diorama ticket 09: "movement_crafted_at_hq_appears_in_the_bag_drawer_
	# seat_view" (the drawer's Seat button for a freshly-crafted Movement)
	# also moved to tests/test_hq_dial.gd, same reasoning as above.

	run_case("weapon_card_stays_drag_to_scroll_safe", func():
		GameState.reset()
		Bag.open()
		var player: Dictionary = GameState.state["player"]
		player["items"] = [{ "id": "item1", "type": "crowbar" }]

		var drawer := BagDrawer.new()
		drawer._ready()

		for panel in drawer._content.find_children("", "PanelContainer", true, false):
			assert_eq((panel as PanelContainer).mouse_filter, Control.MOUSE_FILTER_PASS, "a management card must not swallow a drag that starts on top of it")

		drawer.free()
	)
