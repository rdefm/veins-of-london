extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")

# Ticket 12: tapping outside the Bag drawer (_dim's gui_input) must close it,
# same as its own Close button — which is a bare Bag.close() with no other
# side effect (unlike sell_menu/james_job_offer in ModalLayer).
#
# BagDrawer.new() is safe to call _ready() on directly without adding it to
# a live scene tree, same reasoning tests/test_map_controls.gd already
# relies on for MapControls.
#
# 05-bag-drawer-promotion: management-mode gating and the ported
# equip/unequip weapon actions, queried via tests/support/node_query.gd.
#
# hq-diorama ticket 09: the Dial-lifecycle half of this file (seat/unseat
# Movement, wind, load/unload Complications, and their own _fresh_dial()
# fixture) is deleted -- that management moved entirely to
# tests/test_hq_dial.gd, covering the new scenes/screens/hq_dial.gd screen.
# This file keeps only the read-only Dial-summary assertions (still rendered
# by _build_dial_summary_label(), untouched by that ticket).


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


func _latest_button_containing(root: Node, text: String) -> Button:
	var latest: Button = null
	for b in root.find_children("", "Button", true, false):
		if not b.is_queued_for_deletion() and b.get_child_count() > 0 and NodeQuery.effective_text(b.get_child(0)).contains(text):
			latest = b
	return latest


func _button_effective_texts(root: Node) -> Array[String]:
	var texts: Array[String] = []
	for b in root.find_children("", "Button", true, false):
		var btn := b as Button
		texts.append(btn.text if btn.get_child_count() == 0 else NodeQuery.effective_text(btn.get_child(0) as Control))
	return texts


# Label texts outside any Button (headings, ore/consumable/summary rows).
func _non_button_texts(root: Node) -> String:
	var texts: Array[String] = []
	for l in root.find_children("", "Label", true, false):
		var inside_button := false
		var node: Node = l.get_parent()
		while node != null and node != root:
			if node is Button:
				inside_button = true
				break
			node = node.get_parent()
		if not inside_button:
			texts.append((l as Label).text)
	return "\n".join(texts)


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

		var drawer := BagDrawer.new()
		drawer._ready()

		assert_true(NodeQuery.find_button_by_effective_text(drawer, "Equip") == null, "no weapon controls exist")
		assert_eq(drawer._card.offset_top, -BagDrawer.MANAGEMENT_DRAWER_HEIGHT, "drawer grows to the management height")

		drawer.free()
	)

	run_case("management_controls_hidden_and_drawer_shorter_during_combat", func():
		GameState.reset()
		Bag.open()
		GameState.state["combat"]["active"] = true

		var drawer := BagDrawer.new()
		drawer._ready()

		assert_eq(drawer._card.offset_top, -BagDrawer.DRAWER_HEIGHT, "drawer stays the short read-only height")

		drawer.free()
	)

	run_case("combat_drawer_lists_only_in_stock_combat_item_buttons", func():
		GameState.reset()
		Bag.open()
		GameState.state["combat"]["active"] = true
		var player: Dictionary = GameState.state["player"]
		player["inventory"]["timePearl"] = { "1": 1 }
		player["inventory"]["shield"] = { "1": 2 }
		player["inventory"]["blast"] = { "1": 0 }
		player["inventory"]["healingSalve"] = { "1": 1 }
		player["shieldPool"] = 5

		var drawer := BagDrawer.new()
		drawer._ready()

		var labels := _non_button_texts(drawer)
		for absent in ["Ore", "Consumables", "Equipped", "Weapon: none equipped", "Dial: none", "Healing Salve", "Blast"]:
			assert_true(not labels.contains(absent), "combat drawer shows no '%s'" % absent)

		var buttons := _button_effective_texts(drawer)
		assert_eq(buttons.size(), 3, "only Time Pearl, Shield and Close: %s" % [buttons])
		assert_true(buttons[0].contains("Time Pearl (1)"), "in-stock Time Pearl gets a use button")
		assert_true(buttons[1].contains("Shield (2)"), "in-stock Shield gets a use button")
		assert_eq(buttons[2], "Close", "Close footer stays")
		var shield_button := NodeQuery.find_button_by_effective_text(drawer, buttons[1])
		assert_true(shield_button.disabled, "Shield greyed while shieldPool > 0")

		drawer.free()
	)

	run_case("combat_item_uses_are_greyed_while_beats_play_and_live_again_after", func():
		GameState.reset()
		Bag.open()
		GameState.state["combat"]["active"] = true
		GameState.state["combat"]["snapshots"] = [{}]
		var player: Dictionary = GameState.state["player"]
		player["inventory"]["timePearl"] = { "1": 1 }
		player["inventory"]["rewind"] = { "1": 1 }

		var drawer := BagDrawer.new()
		drawer._ready()

		EventBus.combat_playback_changed.emit(true)
		for label in ["Time Pearl (1)", "Rewind (1)"]:
			assert_true(_latest_button_containing(drawer, label).disabled, "%s greyed during playback" % label)

		EventBus.combat_playback_changed.emit(false)
		for label in ["Time Pearl (1)", "Rewind (1)"]:
			assert_true(not _latest_button_containing(drawer, label).disabled, "%s live again after playback" % label)

		drawer.free()
	)

	run_case("item_hook_event_drawer_keeps_the_full_read_only_view", func():
		GameState.reset()
		Bag.open()
		var original_events := _install_item_hook_event()

		var drawer := BagDrawer.new()
		drawer._ready()

		var labels := NodeQuery.label_texts_with_symbols(drawer)
		assert_true(labels.has("Ore"), "Ore section outside combat")
		assert_true(labels.has("Consumables"), "Consumables section outside combat")
		assert_true(labels.has("Equipped"), "read-only equipped summary outside combat")
		assert_true(labels.has("Dial: none"), "read-only Dial summary outside combat")

		drawer.free()
		GameData.EVENTS = original_events
		GameState.state["event"] = null
	)

	run_case("management_controls_hidden_during_an_item_hook_event_card", func():
		GameState.reset()
		Bag.open()
		var original_events := _install_item_hook_event()

		var drawer := BagDrawer.new()
		drawer._ready()

		assert_eq(drawer._card.offset_top, -BagDrawer.DRAWER_HEIGHT, "drawer stays the short read-only height")

		drawer.free()
		GameData.EVENTS = original_events
		GameState.state["event"] = null
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

		assert_true(NodeQuery.find_button_by_effective_text(drawer, "♥Healing Salve (1) — 2-day heal-over-time") != null, "healingSalve should get a Use button outside combat/events")
		assert_true(NodeQuery.find_button_by_effective_text(drawer, "✚Healing Burst (1) — instant heal") != null, "healingBurst should get a Use button outside combat/events")

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

		assert_true(NodeQuery.find_button_by_effective_text(drawer, "♥Healing Salve (1) — 2-day heal-over-time") == null, "no out-of-combat healingSalve Use button during combat")

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

		assert_true(NodeQuery.find_button_by_effective_text(drawer, "♥Healing Salve (1) — 2-day heal-over-time") == null, "no out-of-combat healingSalve Use button while the current event card carries itemHooks")

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
		var button := NodeQuery.find_button_by_effective_text(drawer, "♥Healing Salve (1) — 2-day heal-over-time")
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

		var joined := "\n".join(NodeQuery.label_texts_with_symbols(drawer))
		assert_true(joined.contains("Healing Salve active"), "an active HoT should stay visible even once stock (qty 0) stops offering a Use button")
		assert_true(NodeQuery.find_button_by_effective_text(drawer, "♥Healing Salve (0) — 2-day heal-over-time") == null, "no Use button once stock is 0")

		drawer.free()
	)

	# hq-diorama ticket 09: "movement_crafted_at_hq_appears_in_the_bag_drawer_
	# seat_view" (the drawer's Seat button for a freshly-crafted Movement)
	# also moved to tests/test_hq_dial.gd, same reasoning as above.

