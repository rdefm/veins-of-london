extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")

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
			assert_true(NodeQuery.find_button_by_effective_text(screen, "Seed as \"%s\"" % haft["name"]) != null, "a Seed button must render for haft %s" % haft_id)

		screen.free()
	)

	run_case("hq_dial_screen_shows_a_waiting_message_when_no_dial_is_seeded_and_no_gift_has_been_granted", func():
		GameState.reset()

		var screen := HqDialScreen.new()
		screen._ready()

		assert_true(NodeQuery.label_texts_with_symbols(screen).has("No Dial. Nothing's offered you the gift yet."), "must show the waiting message, not a seeding UI, before the gift is granted")

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
			NodeQuery.find_button_by_effective_text(screen, "Seed as \"%s\"" % haft["name"]).pressed.emit()
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

		assert_true(NodeQuery.label_texts_with_symbols(screen).any(func(t: String): return t.begins_with("Level %d Dial" % dial["level"])), "the Dial's level/haft heading must render")
		assert_true(NodeQuery.label_texts_with_symbols(screen).has("Charge 3/10 (regen 0/day)"), "the Dial's charge stat must render off the device readout, not a bar")
		assert_true(NodeQuery.label_texts_with_symbols(screen).has("Capacity %d/%d" % [Dial.capacity_used(dial), dial["capacityMax"]]), "the Dial's capacity stat must render")
		assert_true(NodeQuery.find_button_by_effective_text(screen, "Craft new Movement") != null, "must expose a Craft new Movement button in the consolidated top block")

		screen.free()
	)

	run_case("hq_dial_screen_craft_new_movement_hands_off_to_the_craft_components_menu_modal", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _fresh_dial()

		var screen := HqDialScreen.new()
		screen._ready()

		NodeQuery.find_button_by_effective_text(screen, "Craft new Movement").pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "craft_components_menu", "Craft new Movement must open the unchanged archetype-list -> movement_craft chain")

		screen.free()
	)

	run_case("hq_dial_screen_swap_button_disabled_with_an_empty_movement_inventory", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _fresh_dial()

		var screen := HqDialScreen.new()
		screen._ready()

		assert_true(NodeQuery.find_button_by_effective_text(screen, "Swap").disabled, "Swap must be disabled when movementInventory is empty -- nothing to swap to")

		screen.free()
	)

	run_case("hq_dial_screen_swap_opens_the_movement_swap_picker_which_seats_via_dial_system", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = _fresh_dial()
		player["movementInventory"] = [{ "archetype": "recharge", "oreType": "time", "tier": 1 }]

		var screen := HqDialScreen.new()
		screen._ready()

		var swap_button := NodeQuery.find_button_by_effective_text(screen, "Swap")
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

		NodeQuery.find_button_by_effective_text(screen, "Unseat").pressed.emit()
		assert_eq(GameState.state["player"]["dial"]["movement"], null, "screen's Unseat button should unseat via Dial.unseat_movement")
		assert_eq(GameState.state["player"]["movementInventory"].size(), 1, "unseating should return the Movement to movementInventory")

		screen.free()
	)

	# hq-diorama ticket 17: the bottom tray is gone -- an Empty housing is
	# now itself the load entry point, opening modal_layer.gd's "dial_load_
	# complication" picker (that modal's own pick-a-recipe -> Dial.load_
	# complication behaviour is covered by tests/test_modal_layer.gd, not
	# duplicated here).
	run_case("hq_dial_screen_tapping_an_empty_housing_opens_the_load_complication_modal", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _fresh_dial()

		var screen := HqDialScreen.new()
		screen._ready()

		NodeQuery.find_button_by_effective_text(screen, "Empty").pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "dial_load_complication", "tapping an Empty housing must open the load-complication picker")

		screen.free()
	)

	run_case("hq_dial_screen_tapping_a_loaded_housing_unloads_it_via_dial_system", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		player["dial"] = _fresh_dial()
		player["inventory"]["timePearl"] = { "1": 1 }
		Dial.load_complication("timePearl", 1)

		var screen := HqDialScreen.new()
		screen._ready()

		NodeQuery.find_button_by_effective_text(screen, "⧖Time Pearl t1").pressed.emit()
		assert_eq(GameState.state["player"]["dial"]["loadedComplications"], [], "tapping a loaded housing tile should unload it via Dial.unload_complication")
		assert_eq(Crafting.inventory_qty("timePearl"), 1, "unloading should return the unit to regular inventory")

		screen.free()
	)

	run_case("hq_dial_screen_loaded_complication_shows_in_a_socket_tile_and_the_rest_stay_empty", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		var dial := _fresh_dial()
		dial["capacityMax"] = 4
		player["dial"] = dial
		player["inventory"]["timePearl"] = { "1": 1 }
		Dial.load_complication("timePearl", 1)

		var screen := HqDialScreen.new()
		screen._ready()

		assert_true(NodeQuery.label_texts_with_symbols(screen).any(func(t: String): return t.begins_with("⧖Time Pearl t1")), "a loaded Complication must show in its housing tile")
		var empties := screen.find_children("", "Button", true, false).filter(func(b): return (b as Button).text == "Empty")
		assert_eq(empties.size(), 3, "the remaining 3 housings must show Empty")

		screen.free()
	)

	# hq-diorama ticket 17: the old "4 housings for now" UI-only display cap
	# (independent of the real capacityMax) is gone -- exactly capacityMax
	# housings render now, no more, no less, and no separate cap can block
	# loading ahead of the real one.
	run_case("hq_dial_screen_renders_exactly_capacity_max_housings_no_separate_display_cap", func():
		GameState.reset()
		var player: Dictionary = GameState.state["player"]
		var dial := _fresh_dial()
		dial["capacityMax"] = 2
		player["dial"] = dial

		var screen := HqDialScreen.new()
		screen._ready()

		var empties := screen.find_children("", "Button", true, false).filter(func(b): return (b as Button).text == "Empty")
		assert_eq(empties.size(), 2, "exactly capacityMax housings should render")

		screen.free()
	)

	# hq-diorama ticket 17: "Craft Components" (recipes.json Complications,
	# distinct from Movements) has no other affordance on this screen once
	# the bottom tray/dock is gone.
	run_case("hq_dial_screen_craft_components_opens_the_lab_bench_recipe_book_modal", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _fresh_dial()

		var screen := HqDialScreen.new()
		screen._ready()

		NodeQuery.find_button_by_effective_text(screen, "Craft Components").pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "lab_bench_recipe_book", "Craft Components must open the Lab Bench's recipe book modal")

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

		NodeQuery.find_button_by_effective_text(screen, "‹ Back").pressed.emit()
		assert_eq(GameState.state["currentScreen"], "hq", "Back must return to the HQ room")

		screen.free()
	)
