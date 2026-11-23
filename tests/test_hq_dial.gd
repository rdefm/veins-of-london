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
	}


func run() -> void:
	run_case("hq_dial_screen_shows_seeding_ui_when_no_dial_is_seeded_and_the_gift_has_been_granted", func():
		GameState.reset()
		GameState.state["flags"]["dialGiftGranted"] = true

		var screen := HqDialScreen.new()
		screen._ready()

		var seed_button := NodeQuery.find_button_by_effective_text(screen, "Seed")
		assert_true(seed_button != null, "a single Seed button must render")
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
			var seed_button := NodeQuery.find_button_by_effective_text(screen, "Seed")
			assert_true(not seed_button.disabled, "Seed is enabled once a lens ore is picked")
			seed_button.pressed.emit()
			screen.free()

			seed += 1
			if GameState.state["player"]["dial"] != null:
				success = true
			else:
				GameState.state = snapshot

		assert_true(success, "should find a successful seed within 2000 tries at high combined skill")
		assert_eq(GameState.state["player"]["dial"]["lenses"][0]["ore"], "fate", "the seeded Dial carries the picked lens ore")
		assert_true(not GameState.state["player"]["dial"].has("haftId"), "the seeded Dial stores no haft")
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
		assert_true(NodeQuery.find_button_by_effective_text(menu, "Craft Components") == null, "no Craft Components on the overview")
		assert_true(not menu._section_craft.visible, "no Craft on the overview")
		menu.open_section("movement")
		assert_true(menu._section_craft.visible, "the section offers Craft")
		menu.close_section()

		screen.free()
	)

	run_case("dial_menu_section_zoom_snaps_to_spec_rect_dims_others_and_back_reverses", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _fresh_dial()
		var menu := DialMenu.new()
		menu._ready()

		menu.open_section("lenses")
		var spec: Dictionary = DialMenu.sections()["lenses"]
		var sc: float = float(spec["scale"])
		assert_eq(menu._canvas.scale, Vector2(sc, sc), "lenses zoom at the data's integer scale")
		assert_eq(menu._canvas.position, DialMenu.zoom_position(DialMenu.section_frame("lenses"), sc), "canvas pans to the section frame")
		assert_eq(menu._groups["head"].position, menu._base["head"] + DialMenu.v2(spec["offsets"]["head"]), "head moves to its exploded offset")
		assert_true(is_equal_approx(menu._groups["head"].modulate.a, float(DialMenu.layout("dim_alpha"))), "non-target parts dim")
		assert_eq(menu._groups["collar"].modulate.a, 1.0, "the target stays bright")

		menu.close_section()
		assert_eq(menu._canvas.scale, Vector2(2, 2), "Back zooms out")
		assert_eq(menu._groups["head"].position, menu._base["head"], "parts reassemble")
		assert_eq(menu._groups["head"].modulate.a, 1.0, "dim clears")

		menu.free()
	)

	run_case("dial_menu_lenses_emerge_and_hover_ghosts_mark_locked_slots", func():
		GameState.reset()
		var dial := _fresh_dial()
		dial["level"] = 3
		dial["lenses"] = [{ "ore": "time", "tier": 2 }]
		GameState.state["player"]["dial"] = dial
		var slots: int = Dial.lens_slots(3)
		var menu := DialMenu.new()
		menu._ready()

		var size := DialMenu.v2(GameData.DIAL_ART["component_sizes"]["lens"])
		assert_eq(menu._seated[0].position, menu._hidden_position("collar", size, 0), "in the overview the Lens sits inside the collar")
		menu.open_section("lenses")
		for p in range(3):
			assert_eq(menu._ghosts[p].visible, p >= slots, "slot %d ghosted only above lens_slots" % p)
		assert_true(menu._seated[0].visible, "the loaded Lens shows")
		assert_eq(menu._seated[0].position, menu._hover_in_clip("collar", size, 0), "it hovers above the collar lip")
		assert_true(menu._seated[0].position.y + size.y <= menu._clips["collar"].size.y, "hovering above the clip line")
		assert_true(menu._lens_glass[0].texture != null, "the Lens sprite loads")
		assert_true(not (menu._seated[1].visible), "empty slots show no Lens")
		menu.close_section()
		assert_eq(menu._seated[0].position, menu._hidden_position("collar", size, 0), "Back slides it back into the lip")
		for p in range(3):
			assert_true(not menu._ghosts[p].visible, "ghosts hide on Back")

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

	run_case("dial_menu_info_tag_stays_inside_the_screen_gutter", func():
		var screen := DialMenu.SCREEN
		var g := DialMenu.TAG_GUTTER
		var tag_size := Vector2(DialMenu.tag_width(screen), 180.0)
		var inside := func(p: Vector2) -> bool:
			return p.x >= g and p.y >= g and p.x + tag_size.x <= screen.x - g and p.y + tag_size.y <= screen.y - g
		var anchors := {
			"left edge": Rect2(0.0, 300.0, 40.0, 40.0),
			"right edge": Rect2(screen.x - 30.0, 300.0, 30.0, 40.0),
			"top edge": Rect2(150.0, 0.0, 40.0, 10.0),
			"bottom edge": Rect2(150.0, screen.y - 20.0, 40.0, 20.0),
			"list item": Rect2(DialMenu.LIST_X, 700.0, DialMenu.LIST_WIDTH, 44.0),
		}
		for key in anchors:
			assert_true(inside.call(DialMenu.tag_position(anchors[key], tag_size, screen)), "tag inside gutter near the %s" % key)
		var low: Rect2 = anchors["bottom edge"]
		assert_true(DialMenu.tag_position(low, tag_size, screen).y + tag_size.y <= low.position.y, "near the bottom the tag flips above its anchor")
		var mid := Rect2(150.0, 200.0, 40.0, 40.0)
		assert_eq(DialMenu.tag_position(mid, tag_size, screen).y, mid.end.y + DialMenu.TAG_GAP, "with room the tag sits below its anchor")
		assert_true(DialMenu.tag_width(Vector2(240.0, 844.0)) <= 240.0 - 2.0 * g, "width capped on a narrow screen")

		GameState.reset()
		GameState.state["player"]["dial"] = _fresh_dial()
		GameState.state["player"]["lensInventory"] = [{ "ore": "emotion", "tier": 3 }]
		var menu := DialMenu.new()
		menu._ready()
		menu.open_section("lenses")
		menu.show_held_tag(0)
		var tag := menu.find_child("InfoTag", true, false) as PanelContainer
		assert_eq(tag.custom_minimum_size.x, DialMenu.tag_width(screen), "tag width capped")
		var title := tag.find_child("InfoTagTitle", true, false) as Label
		assert_eq(title.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART, "title wraps")
		assert_eq(title.get_theme_font_size("font_size"), DialMenu.TAG_TITLE_SIZE, "title uses the small tag size")
		var effect := tag.find_child("LensEffect_always_on", true, false) as Label
		assert_eq(effect.get_theme_font_size("font_size"), DialMenu.TAG_BODY_SIZE, "body uses the small tag size")
		assert_eq(effect.custom_minimum_size.x, 0.0, "body text doesn't force the tag wider")
		assert_true(tag.position.x >= g and tag.position.x + tag.custom_minimum_size.x <= screen.x - g, "held-list tag inside the side gutters")
		menu.free()
	)

	run_case("dial_menu_movement_section_frames_face_with_grip_and_movement_hovers", func():
		GameState.reset()
		var dial := _fresh_dial()
		dial["movement"] = { "archetype": "recharge", "tier": 2 }
		GameState.state["player"]["dial"] = dial
		var menu := DialMenu.new()
		menu._ready()

		var size := DialMenu.v2(GameData.DIAL_ART["component_sizes"]["movement_frame"])
		menu.open_section("movement")
		var sc: float = float(DialMenu.sections()["movement"]["scale"])
		assert_eq(menu._canvas.scale, Vector2(sc, sc), "movement zooms at the data's integer scale")
		assert_eq(menu._groups["head"].modulate.a, 1.0, "face stays bright")
		assert_eq(menu._groups["grip"].modulate.a, 1.0, "grip stays bright")
		assert_eq(menu._movement_holder.position, menu._hover_in_clip("grip", size), "the Movement hovers above the grip lip")
		assert_eq(menu._movement_atlas.region, Rect2(Vector2.ZERO, size), "frame 0 (still) shows")
		assert_true(menu._movement_atlas.atlas != null, "the Movement strip loads")
		var head_bottom: float = menu._groups["head"].position.y + menu._groups["head"].size.y
		var movement_top: float = menu._groups["grip"].position.y + menu._clips["grip"].position.y + menu._movement_holder.position.y
		assert_true(head_bottom <= movement_top, "the head lifts clear of the hovering Movement")
		assert_true(menu._charge_label.visible, "charge readout shows")
		assert_true(menu._list_scroll.visible and menu._section_craft.visible, "list and Craft show")
		menu.close_section()
		assert_eq(menu._movement_holder.position, menu._hidden_position("grip", size), "Back slides it back into the lip")

		menu.free()
	)

	run_case("dial_menu_movement_load_swap_unload_via_dial_system", func():
		GameState.reset()
		var dial := _fresh_dial()
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["movementInventory"] = [{ "archetype": "recharge", "tier": 1 }, { "archetype": "capacitor", "tier": 2 }]
		var menu := DialMenu.new()
		menu._ready()
		menu.open_section("movement")

		assert_true(menu.can_drop_on_seat({ "type": "held_movement", "inv": 0 }), "held Movement can drop on the seat")
		assert_true(not (menu.can_drop_on_seat({ "type": "held_lens", "inv": 0 })), "a Lens can't")
		menu.drop_on_seat({ "type": "held_movement", "inv": 0 })
		assert_eq(dial["movement"]["archetype"], "recharge", "seated")
		menu._refresh()
		assert_true(menu._movement_holder.visible, "seat shows it")
		menu.drop_on_seat({ "type": "held_movement", "inv": 0 })
		assert_eq(dial["movement"]["archetype"], "capacitor", "drop on a filled seat swaps")
		assert_eq(GameState.state["player"]["movementInventory"][0]["archetype"], "recharge", "old one returns to the list")
		assert_true(menu.unload_movement()["ok"], "unload")
		assert_true(dial["movement"] == null, "seat empty")
		assert_eq(GameState.state["player"]["movementInventory"].size(), 2, "both held")

		var item := menu.find_child("MovementItem_0", true, false) as Button
		item.pressed.emit()
		var tag := menu.find_child("InfoTag", true, false)
		assert_true(tag != null, "list item opens a tag")
		NodeQuery.find_button_by_effective_text(tag, "Fit").pressed.emit()
		assert_true(dial["movement"] != null, "Fit seats it")

		menu.free()
	)

	run_case("dial_menu_wind_pays_the_single_lens_and_choice_opens_with_two", func():
		GameState.reset()
		var dial := _fresh_dial()
		dial["level"] = 5
		dial["movement"] = { "archetype": "recharge", "tier": 1 }
		Dial._activate_charge_pool(dial)
		dial["currentCharge"] = 0
		dial["lenses"] = [{ "ore": "time", "tier": 1 }]
		GameState.state["player"]["dial"] = dial
		GameState.state["player"]["orichalchum"]["time"] = 500
		var menu := DialMenu.new()
		menu._ready()
		menu.open_section("movement")

		var before: int = GameState.state["player"]["orichalchum"]["time"]
		var result := menu.wind()
		assert_true(result["ok"], "wind with one Lens pays directly")
		assert_eq(dial["currentCharge"], 1.0, "charge up by one")
		assert_true(GameState.state["player"]["orichalchum"]["time"] < before, "calc spent")
		menu._refresh()
		assert_true(is_equal_approx(menu._needle.rotation_degrees, DialMenu.needle_rotation_degrees(dial)), "needle follows the charge")

		dial["lenses"].append({ "ore": "fate", "tier": 1 })
		var choice := menu.wind()
		assert_true(choice.get("choice", false), "2+ Lenses: ore choice comes first")
		assert_eq(dial["currentCharge"], 1.0, "no charge until the ore is chosen")
		Modal.close()

		dial["lenses"] = []
		assert_true(not (menu.wind()["ok"]), "no Lens: refused")
		dial["movement"] = null
		assert_true(not (menu.wind()["ok"]), "no Movement: refused")

		menu.free()
	)

	run_case("dial_menu_complications_chambers_block_above_capacity_and_light_studs", func():
		GameState.reset()
		var dial := _fresh_dial()
		dial["level"] = 3
		dial["capacityMax"] = 2
		GameState.state["player"]["dial"] = dial
		var recipe_key: String = GameData.RECIPES.keys()[0]
		Crafting.inventory_add(Crafting.inventory_key(recipe_key, false), 1, 3)
		var menu := DialMenu.new()
		menu._ready()
		menu.open_section("complications")

		assert_eq(menu._groups["canopy"].position, menu._base["canopy"] + Vector2(0, 40), "canopy drops away")
		assert_eq(menu._groups["canopy"].modulate.a, 1.0, "canopy cut face not dimmed")
		assert_eq(menu._chambers.size(), 4, "four chambers")
		for i in range(4):
			assert_eq(menu._blanks[i].visible, i >= 2, "chamber %d blanked only above capacityMax" % i)
			assert_eq(menu._rings[i].visible, i < 2, "chamber %d marked only when it can take one" % i)
		assert_true(not (menu.can_drop_on_chamber(2, { "type": "held_complication", "held": 0 })), "blanked chamber refuses the drag")
		assert_true(not (menu.drop_complication_on_chamber(0, 3)["ok"]), "blanked chamber refuses the handler")

		assert_true(menu.drop_complication_on_chamber(0, 0)["ok"], "drop on an empty chamber loads")
		assert_eq(dial["loadedComplications"].size(), 1, "loaded")
		menu._refresh()
		assert_true(menu._labels[0].visible and menu._labels[0].texture != null, "label icon seated in chamber 0")
		assert_true(not menu._rings[0].visible, "a filled chamber is no longer marked")
		assert_true(menu._studs[0].visible, "stud 0 lit = chamber 0 loaded")
		assert_true(not menu._studs[1].visible, "stud 1 stays dark")
		assert_true(menu.drop_complication_on_chamber(0, 0)["ok"], "drop on a filled chamber swaps")
		assert_eq(dial["loadedComplications"].size(), 1, "still one loaded")
		assert_true(menu.fit_complication(0)["ok"], "Fit loads the next chamber")
		assert_true(not (menu.fit_complication(0)["ok"]), "full dial refuses")
		assert_true(menu.unload_complication(0)["ok"], "unload")
		assert_eq(dial["loadedComplications"].size(), 1, "one left")

		menu.show_seated_complication_tag(0)
		assert_true(menu.find_child("InfoTag", true, false) != null, "seated cartridge shows its tag")

		menu.free()
	)

	run_case("dial_menu_section_craft_opens_modal_tab_or_lab_bench_and_back_returns", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq_dial"
		GameState.state["player"]["dial"] = _fresh_dial()
		var menu := DialMenu.new()
		menu._ready()

		menu.open_section("movement")
		menu.craft_section()
		assert_eq(GameState.state["modal"]["type"], "craft_components_menu", "Movement Craft opens the craft modal")
		assert_eq(GameState.state["modal"]["data"].get("tab"), "movement", "on the Movement tab")
		Modal.close()
		menu.open_section("lenses")
		menu.craft_section()
		assert_eq(GameState.state["modal"]["data"].get("tab"), "lens", "Lenses Craft opens the Lens tab")
		Modal.close()
		assert_eq(menu.section, "lenses", "the section is kept after the modal")

		menu.open_section("complications")
		menu.craft_section()
		assert_eq(GameState.state["currentScreen"], "hq_lab_bench", "Complications Craft goes to the lab bench")
		assert_eq(DialMenu.craft_return, "complications", "remembering the section")
		menu.free()

		var again := DialMenu.new()
		again._ready()
		assert_eq(again.section, "complications", "coming back reopens the same section")
		assert_eq(DialMenu.craft_return, "", "consumed")
		again.free()
	)

	run_case("dial_menu_assembles_module_sprites_from_anchors", func():
		var origins := DialMenu.assembled_origins()
		var measured: Dictionary = GameData.DIAL_ART["assembled_origin"]
		var lo := Vector2(INF, INF)
		for m in measured.keys():
			lo = Vector2(minf(lo.x, measured[m][0]), minf(lo.y, measured[m][1]))
		for m in measured.keys():
			assert_eq(origins[m], DialMenu.v2(measured[m]) - lo, "%s seats where the measured assembly put it" % m)
		GameState.reset()
		GameState.state["player"]["dial"] = _fresh_dial()
		var menu := DialMenu.new()
		menu._ready()
		for m in ["head", "grip", "collar", "canopy"]:
			var sprite := menu._groups[m].get_node("Sprite_%s" % m) as TextureRect
			assert_true(sprite.texture != null, "%s sprite loads" % m)
			assert_eq(menu._groups[m].position, origins[m], "%s assembled in the overview" % m)
		assert_eq(menu._canvas.size, DialMenu.canvas_size(), "canvas spans the assembled Dial")
		menu.free()
	)

	run_case("dial_menu_wind_spin_frames_and_hover_bob_are_whole_steps", func():
		assert_eq(DialMenu.spin_frame_at(-0.1), 0, "still before the spin")
		assert_eq(DialMenu.spin_frame_at(0.0), 1, "spin starts on frame 1")
		var fps: float = DialMenu.timing("wind_spin_fps")
		assert_eq(DialMenu.spin_frame_at(1.0 / fps), 2, "advances at wind_spin_fps")
		assert_eq(DialMenu.spin_frame_at(3.0 / fps), 1, "frames 1-3 loop")
		assert_eq(DialMenu.spin_frame_at(DialMenu.timing("wind_spin")), 0, "still again when the spin ends")
		var bob_px: int = int(GameData.DIAL_ART["hover"]["bob_px"])
		for i in range(24):
			assert_true(absi(DialMenu.bob_offset(i * 0.05, 0.0)) <= bob_px, "bob stays within bob_px")
		assert_true(DialMenu.lens_texture("emotion") != null, "every ore shares the base Lens sprite")
		assert_true(DialMenu.label_texture("nearMiss") != null, "a Complication without an icon falls back")
	)

	run_case("dial_menu_lens_material_tints_glass_with_ore_colour", func():
		for ore in GameData.ORE_TYPES:
			var mat := DialMenu.lens_material(ore)
			assert_true(mat.shader != null, "%s: lens tint shader loads" % ore)
			var c: Color = MapPalette.ore_colour(ore)
			assert_eq(mat.get_shader_parameter("glass_colour"), Vector3(c.r, c.g, c.b), "%s: glass takes the ore colour" % ore)
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

	run_case("dial_menu_needle_is_the_sprite_pivoting_on_the_face_and_overview_shows_charge", func():
		GameState.reset()
		var dial := _fresh_dial()
		dial["currentCharge"] = 3
		dial["maxCharge"] = 8
		GameState.state["player"]["dial"] = dial
		var menu := DialMenu.new()
		menu._ready()
		var comps: Dictionary = DialMenu.art()["components"]
		var needle: TextureRect = menu._needle
		assert_true(needle.texture != null, "needle draws the dial_needle sprite")
		assert_eq(needle.size, DialMenu.v2(comps["needle_size"]), "native needle size from dial_art.json")
		assert_eq(needle.position + needle.pivot_offset, DialMenu.v2(DialMenu.module("head")["face_centre"]), "pivot sits on the face centre")
		var face: Label = menu.get_node("FaceCharge")
		assert_eq(face.text, "3/8", "overview shows X/Y charge")
		assert_true(face.visible, "charge number shows on the overview")
		menu.open_section("lenses")
		assert_true(not face.visible, "face charge hides inside a section")
		menu.free()
	)

	run_case("dial_menu_overview_shows_level_xp_and_next_level_gains_and_max_level", func():
		GameState.reset()
		var dial := _fresh_dial()
		dial["level"] = 2
		dial["xp"] = 70
		GameState.state["player"]["dial"] = dial
		var menu := DialMenu.new()
		menu._ready()
		var level: Label = menu.get_node("LevelPanel/LevelLabel")
		assert_eq(level.text, "Level 2", "overview shows the Dial level")
		assert_eq((menu.get_node("LevelPanel/XpText") as Label).text, "70/%d XP" % int(GameData.DIAL_XP_LEVELS[3]), "XP X/Y toward the next threshold")
		var bar: ProgressBar = menu.get_node("LevelPanel/XpBar")
		assert_eq(bar.value, 70.0 - float(GameData.DIAL_XP_LEVELS[2]), "bar fills from the current level's floor")
		assert_true((menu.get_node("LevelPanel/XpHow") as Label).text.contains("per cast"), "says how XP is earned")
		var next: Node = menu.get_node("NextLevelPanel")
		var lines := DialMenu.next_level_lines(Dial.level_progress(dial))
		assert_eq(next.get_child_count(), lines.size() + 1, "Next level title plus one row per gain")
		assert_eq((next.get_child(0) as Label).text, "Next level", "panel titled Next level")
		assert_true(menu._level_panel.visible and menu._next_panel.visible, "panels show on the overview")
		menu.open_section("movement")
		assert_true(not menu._level_panel.visible and not menu._next_panel.visible, "panels hide inside a section")
		menu.close_section()
		dial["level"] = GameData.DIAL_XP_LEVELS.size() - 1
		dial["xp"] = int(GameData.DIAL_XP_LEVELS[dial["level"]])
		menu._refresh()
		var shown: Array = []
		for c in menu._next_panel.get_children():
			if not c.is_queued_for_deletion():
				shown.append((c as Label).text)
		assert_eq(shown, ["Max level"], "max level shows Max level only")
		menu.free()
	)

	run_case("dial_menu_overview_level_panel_reads_the_contacts_dial", func():
		GameState.reset()
		Dial.grant_contact_dial("james")
		var menu := DialMenu.new()
		menu.owner_id = "james"
		menu._ready()
		var lvl: int = int(Dial.dial_of("james")["level"])
		assert_eq((menu.get_node("LevelPanel/LevelLabel") as Label).text, "Level %d" % lvl, "contact Dial's own level")
		menu.free()
	)

	run_case("dial_menu_section_back_button_returns_to_overview_not_host", func():
		GameState.reset()
		GameState.state["player"]["dial"] = _fresh_dial()
		var menu := DialMenu.new()
		var exits := [0]
		menu.on_back = func(): exits[0] += 1
		menu._ready()

		var back := NodeQuery.find_button_by_effective_text(menu, "‹ Back")
		assert_true(back.position.y >= UI.top_bar_clearance(), "Back sits below the TopBar, not under it")
		for s in DialMenu.sections().keys():
			menu.open_section(s)
			assert_true(back.visible, "%s shows Back" % s)
			back.pressed.emit()
			assert_eq(menu.section, "", "%s Back returns to the overview" % s)
			assert_eq(menu._canvas.scale, Vector2.ONE * DialMenu.overview_scale(), "%s Back zooms out" % s)
			assert_true(menu._bands[s].visible, "%s band is tappable again" % s)
		assert_eq(exits[0], 0, "section Back never exits the Dial")
		back.pressed.emit()
		assert_eq(exits[0], 1, "overview Back exits to the host")

		menu.free()
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
