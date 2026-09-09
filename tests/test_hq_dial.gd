extends "res://tests/test_base.gd"

# hq-diorama ticket 09, docs/hq-diorama-vision.md §4: the Dial's own diegetic
# loadout sub-view, reached from hq.gd's "dial" zone tap (see
# tests/test_hq_screen.gd's own "hq_dial_zone_tap_navigates_to_the_hq_dial_
# screen"). Cases below are the direct port of the old modal_layer.gd
# "hq_dial" modal cases and bag_drawer.gd's old _build_dial_management()
# cases (both deleted this ticket) onto this screen -- same system calls,
# same assertions, minus the Modal.open()/Modal.close() or Bag.open()
# plumbing a full-bleed screen doesn't have.
#
# HqDialScreen.new() is safe to call _ready() on directly without adding it
# to a live scene tree, same reasoning tests/test_hq_door.gd already relies
# on for HqDoorScreen.


static func _find_button(root: Node, button_text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		var btn := b as Button
		if btn.text == button_text:
			return btn
		if btn.get_child_count() > 0 and _effective_text(btn.get_child(0) as Control) == button_text:
			return btn
	return null


# symbol_row()/symbol_button() split what used to be one Label's raw-symbol
# string into a Label per text part plus a SymbolGlyph glyph (ticket 114) --
# reconstructs a row/button's displayed text by walking its direct children
# in order, same helper tests/test_bag_drawer.gd already relies on.
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


# Mirrors the deleted modal_layer.gd/bag_drawer.gd tests' own _fresh_dial()
# fixtures -- a minimal inert-but-seeded Dial, same shape Dial.new_dial()
# produces. capacityMax comes from Dial.capacity_max(1) so it's never out of
# sync with the real level-1 lookup; callers override it directly when a
# test needs more budget than a level-1 Dial actually has.
static func _fresh_dial() -> Dictionary:
	return {
		"level": 1, "xp": 0, "currentCharge": 0, "maxCharge": 0, "rechargeRate": 0,
		"combatRegenTurnCounter": 0, "lastRegenDay": GameState.state["world"]["day"],
		"capacityMax": Dial.capacity_max(1), "movement": null, "loadedComplications": [],
		"haftId": "collective_brolly",
	}


func run() -> void:
	run_case("hq_dial_screen_shows_seeding_ui_when_no_dial_is_seeded_and_the_gift_has_been_granted", func():
		GameState.reset()
		GameState.state["flags"]["dialGiftGranted"] = true

		var screen := HqDialScreen.new()
		screen._ready()

		for haft_id in GameData.DIAL_HAFTS.keys():
			var haft: Dictionary = GameData.DIAL_HAFTS[haft_id]
			assert_true(_find_button(screen, "Seed as \"%s\"" % haft["name"]) != null, "a Seed button must render for haft %s" % haft_id)

		screen.free()
	)

	run_case("hq_dial_screen_shows_a_waiting_message_when_no_dial_is_seeded_and_no_gift_has_been_granted", func():
		GameState.reset()

		var screen := HqDialScreen.new()
		screen._ready()

		assert_true(_label_texts(screen).has("No Dial. Nothing's offered you the gift yet."), "must show the waiting message, not a seeding UI, before the gift is granted")

		screen.free()
	)

	run_case("hq_dial_screen_seed_button_seeds_via_dial_system", func():
		GameState.reset()
		GameState.state["flags"]["dialGiftGranted"] = true
		GameState.state["player"]["craftingSkill"] = 5
		GameState.state["player"]["cultivatingSkill"] = 5
		var haft_id: String = GameData.DIAL_HAFTS.keys()[0]
		var haft: Dictionary = GameData.DIAL_HAFTS[haft_id]

		var success := false
		var seed := 0
		while not success and seed < 2000:
			var snapshot: Dictionary = GameState.deep_copy(GameState.state)
			Rng.set_seed(seed)
			for ore_type in GameData.DIAL_SEED_COST:
				GameState.state["player"]["orichalchum"][ore_type] = GameData.DIAL_SEED_COST[ore_type]

			var screen := HqDialScreen.new()
			screen._ready()
			_find_button(screen, "Seed as \"%s\"" % haft["name"]).pressed.emit()
			screen.free()

			seed += 1
			if GameState.state["player"]["dial"] != null:
				success = true
			else:
				GameState.state = snapshot

		assert_true(success, "should find a successful seed within 2000 tries at high combined skill")
	)

	run_case("hq_dial_screen_shows_level_charge_and_capacity_readouts_once_a_dial_is_seeded", func():
		GameState.reset()
		var dial := _fresh_dial()
		dial["currentCharge"] = 3
		dial["maxCharge"] = 10
		GameState.state["player"]["dial"] = dial

		var screen := HqDialScreen.new()
		screen._ready()

		assert_true(_label_texts(screen).any(func(t: String): return t.begins_with("Level %d Dial" % dial["level"])), "the Dial's level/haft heading must render")
		assert_true(_label_texts(screen).has("Charge 3/10 (regen 0/day)"), "the Dial's charge stat must render off the device readout, not a bar")
		assert_true(_label_texts(screen).has("Capacity %d/%d" % [Dial.capacity_used(dial), dial["capacityMax"]]), "the Dial's capacity stat must render")
		assert_true(_find_button(screen, "Craft new Movement") != null, "must expose a Craft new Movement button in the consolidated top block")

		screen.free()
	)

	run_case("hq_dial_screen_craft_new_movement_hands_off_to_the_craft_components_menu_modal", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _fresh_dial()

		var screen := HqDialScreen.new()
		screen._ready()

		_find_button(screen, "Craft new Movement").pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "craft_components_menu", "Craft new Movement must open the unchanged archetype-list -> movement_craft chain")

		screen.free()
	)

	run_case("hq_dial_screen_swap_button_disabled_with_an_empty_movement_inventory", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _fresh_dial()

		var screen := HqDialScreen.new()
		screen._ready()

		assert_true(_find_button(screen, "Swap").disabled, "Swap must be disabled when movementInventory is empty -- nothing to swap to")

		screen.free()
	)

	run_case("hq_dial_screen_swap_opens_the_movement_swap_picker_which_seats_via_dial_system", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = _fresh_dial()
		player["movementInventory"] = [{ "archetype": "recharge", "oreType": "time", "tier": 1 }]

		var screen := HqDialScreen.new()
		screen._ready()

		var swap_button := _find_button(screen, "Swap")
		assert_true(not swap_button.disabled, "Swap must be enabled once movementInventory has an entry")
		swap_button.pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "movement_swap", "Swap must open the movement_swap picker modal")

		screen.free()
	)

	run_case("hq_dial_screen_unseat_matches_dial_system", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		var dial := _fresh_dial()
		dial["movement"] = { "archetype": "recharge", "oreType": "time", "tier": 1 }
		player["dial"] = dial

		var screen := HqDialScreen.new()
		screen._ready()

		_find_button(screen, "Unseat").pressed.emit()
		assert_eq(GameState.state["player"]["dial"]["movement"], null, "screen's Unseat button should unseat via Dial.unseat_movement")
		assert_eq(GameState.state["player"]["movementInventory"].size(), 1, "unseating should return the Movement to movementInventory")

		screen.free()
	)

	run_case("hq_dial_screen_load_and_unload_complication_matches_dial_system", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = _fresh_dial()
		player["inventory"]["timePearl"] = { "1": 1 }

		var screen := HqDialScreen.new()
		screen._ready()

		_find_button(screen, "⧖Time Pearl tier 1 (1)").pressed.emit()
		var loaded: Array = GameState.state["player"]["dial"]["loadedComplications"]
		assert_eq(loaded.size(), 1, "screen's Load button should load via Dial.load_complication")
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "loading should move the unit out of regular inventory")

		var screen2 := HqDialScreen.new()
		screen2._ready()
		_find_button(screen2, "⧖Time Pearl t1").pressed.emit()
		assert_eq(GameState.state["player"]["dial"]["loadedComplications"], [], "tapping a loaded housing tile should unload it via Dial.unload_complication")
		assert_eq(Crafting.inventory_qty("timePearl"), 1, "unloading should return the unit to regular inventory")

		screen.free()
		screen2.free()
	)

	run_case("hq_dial_screen_loaded_complication_shows_in_a_socket_tile", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = _fresh_dial()
		player["inventory"]["timePearl"] = { "1": 1 }
		Dial.load_complication("timePearl", 1)

		var screen := HqDialScreen.new()
		screen._ready()

		assert_true(_label_texts(screen).any(func(t: String): return t.begins_with("⧖Time Pearl t1")), "a loaded Complication must show in its housing tile")
		assert_eq(_label_texts(screen).filter(func(t: String): return t == "Empty").size(), 3, "the remaining 3 housings must show Empty")

		screen.free()
	)

	# hq-diorama ticket 09's own human decision (2026-09-08): Complication
	# housings on this screen are capped at 4 for now, regardless of the
	# Dial's real capacityMax -- a UI-only display cap layered on top of (never
	# replacing) Dial.capacity_max()'s own real budget check.
	run_case("hq_dial_screen_load_button_disabled_once_4_housings_are_shown_full_even_with_capacity_left", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		var dial := _fresh_dial()
		dial["capacityMax"] = 20  # plenty of real budget left after 4 cost-1 loads
		dial["loadedComplications"] = [
			{ "recipeKey": "timePearl", "tier": 1, "detent": 0 },
			{ "recipeKey": "timePearl", "tier": 1, "detent": 1 },
			{ "recipeKey": "timePearl", "tier": 1, "detent": 2 },
			{ "recipeKey": "timePearl", "tier": 1, "detent": 3 },
		]
		player["dial"] = dial
		player["inventory"]["enhancementPowder"] = { "1": 1 }

		var screen := HqDialScreen.new()
		screen._ready()

		assert_true(Dial.capacity_used(dial) + 1 <= dial["capacityMax"], "sanity: real capacity budget has room for a 5th complication")
		var load_button := _find_button(screen, "↯Enhancement Powder tier 1 (1)")
		assert_true(load_button != null, "the tray entry must still render even though housings are full")
		assert_true(load_button.disabled, "loading a 5th complication must be blocked once all 4 shown housings are full")

		screen.free()
	)

	run_case("hq_dial_screen_needle_rotation_reflects_current_charge_fraction", func():
		GameState.reset()
		var screen := HqDialScreen.new()

		var dial := _fresh_dial()
		dial["currentCharge"] = 0
		dial["maxCharge"] = 10
		assert_eq(screen._needle_rotation_degrees(dial), HqDialScreen.NEEDLE_MIN_DEG, "empty charge should point the needle to its minimum")

		dial["currentCharge"] = 5
		var midpoint := (HqDialScreen.NEEDLE_MIN_DEG + HqDialScreen.NEEDLE_MAX_DEG) / 2.0
		assert_eq(screen._needle_rotation_degrees(dial), midpoint, "half charge should point the needle to the midpoint between min and max")

		dial["currentCharge"] = 10
		assert_eq(screen._needle_rotation_degrees(dial), HqDialScreen.NEEDLE_MAX_DEG, "full charge should point the needle to its maximum")

		dial["currentCharge"] = 3
		dial["maxCharge"] = 0
		assert_eq(screen._needle_rotation_degrees(dial), HqDialScreen.NEEDLE_MIN_DEG, "a Dial with no maxCharge yet should not divide by zero, and should read as empty")

		screen.free()
	)

	run_case("hq_dial_screen_back_button_returns_to_hq", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq_dial"

		var screen := HqDialScreen.new()
		screen._ready()

		_find_button(screen, "‹ Back").pressed.emit()
		assert_eq(GameState.state["currentScreen"], "hq", "Back must return to the HQ room")

		screen.free()
	)
