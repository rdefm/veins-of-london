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
			var seed_button := NodeQuery.find_button_by_effective_text(screen, "Seed as \"%s\"" % haft["name"])
			assert_true(seed_button != null, "a Seed button must render for haft %s" % haft_id)
			assert_true(seed_button.disabled, "Seed is disabled until a lens ore is picked")
		for ore in GameData.ORE_TYPES.keys():
			assert_true(screen.find_child("SeedOre_%s" % ore, true, false) is Button, "an ore choice must render for %s" % ore)

		screen.free()
	)

	run_case("hq_dial_screen_ore_choice_picks_the_seed_lens_ore", func():
		GameState.reset()
		GameState.state["flags"]["dialGiftGranted"] = true

		var screen := HqDialScreen.new()
		screen._ready()
		(screen.find_child("SeedOre_life", true, false) as Button).pressed.emit()
		assert_eq(screen._seed_ore, "life", "pressing an ore glyph picks that lens ore")
		assert_true(GameState.state["player"]["dial"] == null, "picking an ore seeds nothing")

		screen.free()
	)

	run_case("hq_dial_screen_shows_a_waiting_message_when_no_dial_is_seeded_and_no_gift_has_been_granted", func():
		GameState.reset()

		var screen := HqDialScreen.new()
		screen._ready()

		assert_true(NodeQuery.label_texts_with_symbols(screen).has(HqDialScreen.NO_DIAL_TEXT), "must show the waiting message, not a seeding UI, before the gift is granted")

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
			screen._seed_ore = "fate"
			screen._ready()
			NodeQuery.find_button_by_effective_text(screen, "Seed as \"%s\"" % haft["name"]).pressed.emit()
			screen.free()

			seed += 1
			if GameState.state["player"]["dial"] != null:
				success = true
			else:
				GameState.state = snapshot

		assert_true(success, "should find a successful seed within 2000 tries at high combined skill")
		assert_eq(GameState.state["player"]["dial"]["lenses"][0]["ore"], "fate", "the seeded Dial carries the picked lens ore")
	)

	# Dial menu (ui-previews-dial 07): overview + Lens section. DialMenu is built via
	# _ready() directly (no live tree), so tweens snap to their end state.
	run_case("hq_dial_screen_seeded_hosts_the_dial_menu_overview_with_three_bands", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _fresh_dial()

		var screen := HqDialScreen.new()
		screen._ready()
		var menu: DialMenu = screen._menu
		assert_true(menu != null, "a seeded Dial shows the Dial menu")
		menu._ready()
		assert_eq(menu.section, "", "opens on the overview")
		for s in ["movement", "lenses", "complications"]:
			assert_true(menu.find_child("Band_%s" % s, true, false) != null, "band %s" % s)
		assert_eq(menu._canvas.scale, Vector2(2, 2), "overview is x2")
		assert_true(NodeQuery.find_button_by_effective_text(menu, "Craft Components") != null, "Craft Components stays reachable")

		screen.free()
	)

	run_case("dial_menu_section_zoom_snaps_to_spec_rect_dims_others_and_back_reverses", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _fresh_dial()
		var menu := DialMenu.new()
		menu._ready()

		menu.open_section("lenses")
		var spec: Dictionary = DialMenu.SECTIONS["lenses"]
		assert_eq(menu._canvas.scale, Vector2(4, 4), "lenses zoom at integer x4")
		assert_eq(menu._canvas.position, DialMenu.zoom_position(spec["rect"], 4.0), "canvas pans to the spec rect")
		assert_eq(menu._groups["head"].position, Vector2(-12, -40), "head moves to its exploded offset")
		assert_true(is_equal_approx(menu._groups["head"].modulate.a, DialMenu.DIM_ALPHA), "non-target parts dim")
		assert_eq(menu._groups["collar"].modulate.a, 1.0, "the target stays bright")

		menu.close_section()
		assert_eq(menu._canvas.scale, Vector2(2, 2), "Back zooms out")
		assert_eq(menu._groups["head"].position, Vector2.ZERO, "parts reassemble")
		assert_eq(menu._groups["head"].modulate.a, 1.0, "dim clears")

		menu.free()
	)

	run_case("dial_menu_lens_ports_open_unlocked_and_plug_the_rest", func():
		GameState.reset()
		var dial := _fresh_dial()
		dial["level"] = 3
		dial["lenses"] = [{ "ore": "time", "tier": 2 }]
		GameState.state["player"]["dial"] = dial
		var slots: int = Dial.lens_slots(3)
		var menu := DialMenu.new()
		menu._ready()

		menu.open_section("lenses")
		for p in range(3):
			assert_eq(menu._plugs[p].visible, p >= slots, "port %d plugged only above lens_slots" % p)
			if p < slots:
				assert_true(menu._irises[p].scale.x < 0.01, "unlocked port %d shutter is open" % p)
		assert_true(menu._seated[0].visible, "the loaded Lens sits in port 0")
		assert_true(not (menu._seated[1].visible), "empty ports show no Lens")
		menu.close_section()
		assert_eq(menu._irises[0].scale, Vector2.ONE, "Back closes the shutters")

		menu.free()
	)

	run_case("dial_menu_drop_on_port_loads_swaps_and_unload_via_dial_system", func():
		GameState.reset()
		var dial := _fresh_dial()
		dial["level"] = 5
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["lensInventory"] = [{ "ore": "time", "tier": 1 }, { "ore": "fate", "tier": 2 }]
		var menu := DialMenu.new()
		menu._ready()
		menu.open_section("lenses")

		assert_true(menu.can_drop_on_port(0, { "type": "held_lens", "inv": 0 }), "a held Lens can drop on an unlocked port")
		assert_true(not (menu.can_drop_on_port(0, { "type": "seated_lens", "slot": 0 })), "a seated Lens can't drop on a port")
		assert_true(menu.drop_lens_on_port(0, 0)["ok"], "drop on an empty port loads")
		assert_eq(dial["lenses"][0]["ore"], "time", "time Lens loaded")
		assert_eq(GameState.state["player"]["lensInventory"].size(), 1, "it left the held list")

		assert_true(menu.drop_lens_on_port(0, 0)["ok"], "drop on a filled port swaps")
		assert_eq(dial["lenses"][0]["ore"], "fate", "fate Lens now seated")
		assert_eq(GameState.state["player"]["lensInventory"][0]["ore"], "time", "the old Lens returns to the held list")

		assert_true(menu.unload_lens(0)["ok"], "unload returns the seated Lens")
		assert_eq(dial["lenses"].size(), 0, "port empty")
		assert_eq(GameState.state["player"]["lensInventory"].size(), 2, "both held again")

		assert_true(menu.fit_lens(0)["ok"], "Fit loads into the first empty port")
		assert_eq(dial["lenses"].size(), 1, "one Lens seated")

		menu.free()
	)

	run_case("dial_menu_plugged_port_rejects_drops", func():
		GameState.reset()
		var dial := _fresh_dial()
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["lensInventory"] = [{ "ore": "time", "tier": 1 }]
		var menu := DialMenu.new()
		menu._ready()
		menu.open_section("lenses")

		var plugged: int = Dial.lens_slots(1)
		assert_true(not (menu.can_drop_on_port(plugged, { "type": "held_lens", "inv": 0 })), "plugged port refuses the drag")
		assert_true(not (menu.drop_lens_on_port(0, plugged)["ok"]), "plugged port refuses the handler")
		assert_eq(GameState.state["player"]["lensInventory"].size(), 1, "nothing moved")

		menu.free()
	)

	run_case("dial_menu_lens_list_item_opens_info_tag_with_effects_and_fit", func():
		GameState.reset()
		var dial := _fresh_dial()
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["lensInventory"] = [{ "ore": "life", "tier": 1 }]
		var menu := DialMenu.new()
		menu._ready()
		menu.open_section("lenses")

		var item := menu.find_child("LensItem_0", true, false) as Button
		assert_true(item != null, "held Lens listed")
		item.pressed.emit()
		var tag := menu.find_child("InfoTag", true, false)
		assert_true(tag != null, "tapping a list item shows the info tag")
		assert_true(tag.find_child("LensEffect_always_on", true, false) is Label, "tag lists the Lens's effects")
		NodeQuery.find_button_by_effective_text(tag, "Fit").pressed.emit()
		assert_eq(dial["lenses"][0]["ore"], "life", "Fit loads the Lens")
		assert_true(menu.find_child("InfoTag", true, false) == null, "tag closes after loading")

		menu.show_seated_tag(0)
		assert_true(menu.find_child("InfoTag", true, false) != null, "a seated Lens shows its tag")

		menu.free()
	)

	run_case("dial_menu_needle_rotation_reflects_current_charge_fraction", func():
		var dial := _fresh_dial()
		dial["currentCharge"] = 0
		dial["maxCharge"] = 10
		assert_eq(DialMenu.needle_rotation_degrees(dial), DialMenu.NEEDLE_MIN_DEG, "empty -> min")
		dial["currentCharge"] = 5
		assert_eq(DialMenu.needle_rotation_degrees(dial), (DialMenu.NEEDLE_MIN_DEG + DialMenu.NEEDLE_MAX_DEG) / 2.0, "half -> midpoint")
		dial["currentCharge"] = 10
		assert_eq(DialMenu.needle_rotation_degrees(dial), DialMenu.NEEDLE_MAX_DEG, "full -> max")
		dial["maxCharge"] = 0
		assert_eq(DialMenu.needle_rotation_degrees(dial), DialMenu.NEEDLE_MIN_DEG, "no maxCharge reads empty")
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
