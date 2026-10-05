extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")
const UiSim := preload("res://tests/support/ui_sim.gd")

# hq-diorama ticket 06, docs/hq-diorama-vision.md §5: the Lab bench's own
# diegetic sub-view, reached from hq.gd's "lab" zone tap (see
# tests/test_hq_screen.gd's own "hq_lab_zone_tap_navigates_to_the_hq_lab_
# bench_screen"). Tap simulation follows the same pattern
# tests/test_hq_screen.gd's own UiSim.tap_zone() established: a synthetic
# InputEventScreenTouch at a region's own centre point (read from
# HqDiorama.region_rects(), never a hardcoded coordinate), fed through the
# screen's own _on_diorama_gui_input(). Region label assertions read
# HqDiorama's own _plate directly, same convention
# tests/test_hq_screen.gd's own hostile-door-label cases document (the
# underscore is convention, not enforcement).
#
# HqLabBenchScreen.new() is safe to call _ready() on directly without
# adding it to a live scene tree, same reasoning tests/test_hq_floorplan.gd
# already relies on for HqFloorplanScreen. Off-tree the screen has no size,
# so it lays the plate out at its own native size (scale 1, no bands).


func run() -> void:
	run_case("hq_lab_bench_back_button_returns_to_hq", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq_lab_bench"

		var screen := HqLabBenchScreen.new()
		screen._ready()

		NodeQuery.find_button(screen, "‹ Back").pressed.emit()
		assert_eq(GameState.state["currentScreen"], "hq", "Back must return to the HQ room, not the phone home grid")

		screen.free()
	)

	# ── §5.1: one portrait plate, no stops ─────────────────────────────────

	run_case("hq_lab_bench_has_no_stop_arrows_or_caption", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		assert_true(NodeQuery.find_button(screen, "‹") == null, "§5.1: no left arrow -- the bench is one screen")
		assert_true(NodeQuery.find_button(screen, "›") == null, "§5.1: no right arrow")
		assert_true(not NodeQuery.label_texts(screen).has("Books & ore containers"), "no stop caption")
		assert_true(not NodeQuery.label_texts(screen).has("Apparatus"), "no stop caption")

		screen.free()
	)

	run_case("hq_lab_bench_an_old_save_carrying_a_stop_still_loads_and_renders", func():
		GameState.reset()
		var save: Dictionary = GameState.state.duplicate(true)
		save["labBenchNav"] = { "stop": "apparatus", "mode": "recipes", "selectedOre": [] }
		var result := SaveManager._load_save_dict(save)
		assert_true(result["ok"], "a save from before the single-screen bench must still load")

		var screen := HqLabBenchScreen.new()
		screen._ready()
		UiSim.tap_zone(screen, "ore_life")
		assert_eq(GameState.state["labBenchNav"]["selectedOre"], ["life"], "the bench still works on the loaded state")

		screen.free()
	)

	run_case("hq_lab_bench_fits_the_plate_to_width_centred_with_filled_bands", func():
		GameState.reset()
		var plate: Dictionary = GameData.HQ_VISUALS["labBench"]
		var screen := HqLabBenchScreen.new()
		screen._ready()
		screen.size = Vector2(390.0, 844.0)
		screen._build()

		var frame: Control = screen._diorama.get_parent()
		var scale_factor: float = 390.0 / float(plate["width"])
		var scaled_height: float = plate["height"] * scale_factor
		assert_almost_eq(frame.scale.x, scale_factor, 0.001, "§5.1: the plate is width-fit")
		assert_almost_eq(frame.position.y, (844.0 - scaled_height) / 2.0, 0.01, "§5.1: the plate is vertically centred")

		var bands: Array = []
		for child in screen.get_children():
			if child is ColorRect and not child.is_queued_for_deletion():
				bands.append(child)
		assert_eq(bands.size(), 2, "one band above the plate, one below")
		assert_eq(bands[0].color, GameData.PALETTE[plate["bandTopColor"]], "the top band matches the art's wall")
		assert_almost_eq(bands[0].size.y, frame.position.y, 0.01, "the top band fills down to the plate")
		assert_eq(bands[1].color, GameData.PALETTE[plate["bandBottomColor"]], "the bottom band matches the art's floor")
		assert_almost_eq(bands[1].position.y, frame.position.y + scaled_height, 0.01, "the bottom band starts where the plate ends")
		assert_almost_eq(bands[1].position.y + bands[1].size.y, 844.0, 0.01, "the bottom band fills to the screen's bottom edge")

		screen.free()
	)

	run_case("hq_lab_bench_every_bench_object_is_a_region_with_no_placeholder_box", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		var regions: Dictionary = screen._diorama._plate["regions"]
		var expected := ["ore_time", "ore_fate", "ore_life", "ore_physics", "ore_emotion",
			"apparatus_heat", "apparatus_distilling", "apparatus_grinding", "apparatus_compression",
			"notebookRecipes", "notebookExperiments"]
		assert_eq(regions.size(), expected.size(), "exactly the 11 bench objects are tappable")
		for region_id in expected:
			assert_true(regions.has(region_id), "%s must be a region" % region_id)
			assert_true(not screen._diorama._should_draw_placeholder(region_id, regions[region_id]), "%s: the art is the visual, no placeholder box" % region_id)

		screen.free()
	)

	run_case("hq_lab_bench_debug_toggle_turns_on_the_region_overlay", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		assert_true(not screen._diorama.is_debug_overlay_enabled())
		NodeQuery.find_button(screen, "Debug regions").pressed.emit()
		assert_true(screen._diorama.is_debug_overlay_enabled(), "the debug chip shows the hit shapes on the bench too")

		screen.free()
	)

	run_case("hq_lab_bench_the_retort_is_a_traced_polygon_not_its_bounding_box", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		var region: Dictionary = screen._diorama._plate["regions"]["apparatus_distilling"]
		assert_true(region.has("polygon"), "the retort spans the middle -- its hit shape must be traced")
		assert_eq(screen._zone_at(UiSim.zone_point(screen._diorama, "apparatus_distilling")), "apparatus_distilling")
		var bounds := HqDiorama.polygon_bounds(region["polygon"])
		var outside := Vector2(bounds.end.x - 10.0, bounds.position.y + 10.0)
		assert_eq(screen._zone_at(outside), "", "bare table inside the retort's bounding box is not the retort")

		screen.free()
	)

	run_case("hq_lab_bench_tapping_the_recipes_notebook_opens_the_recipe_book", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "notebookRecipes")

		assert_eq(GameState.state["modal"]["type"], "lab_bench_recipe_book")
		assert_true(not GameState.state["labBenchNav"].has("mode"), "§5.2: books hold no mode")

		screen.free()
	)

	run_case("hq_lab_bench_tapping_the_experiments_notebook_opens_the_notes", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "notebookExperiments")

		assert_eq(GameState.state["modal"]["type"], "lab_bench_notes")

		screen.free()
	)

	run_case("hq_lab_bench_notebook_labels_carry_no_open_marker", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()
		UiSim.tap_zone(screen, "notebookRecipes")

		assert_eq(screen._diorama._plate["regions"]["notebookRecipes"]["label"], "Recipes")
		assert_eq(screen._diorama._plate["regions"]["notebookExperiments"]["label"], "Experiments")

		screen.free()
	)

	run_case("hq_lab_bench_tapping_a_notebook_twice_opens_its_book_both_times", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "notebookRecipes")
		Modal.close()
		UiSim.tap_zone(screen, "notebookRecipes")

		assert_eq(GameState.state["modal"]["type"], "lab_bench_recipe_book", "the second tap must not silently toggle the book shut")

		screen.free()
	)

	# ── ticket 07, §5.4: ore containers ────────────────────────────────────

	run_case("hq_lab_bench_ore_containers_exist_for_all_five_types", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		var rects: Dictionary = screen._diorama.region_rects()
		for ore_type in GameData.ORE_TYPES.keys():
			assert_true(rects.has("ore_%s" % ore_type), "ore container region must exist for %s" % ore_type)

		screen.free()
	)

	run_case("hq_lab_bench_each_jar_shows_a_count_badge_of_ore_held", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 7
		GameState.state["player"]["orichalchum"]["time"] = 0

		var screen := HqLabBenchScreen.new()
		screen._ready()

		for ore_type in GameData.ORE_TYPES.keys():
			var badge := screen.get_node_or_null("OreBadge_%s" % ore_type)
			assert_true(badge != null, "§5.4: %s's jar must carry a count badge" % ore_type)
		assert_true(NodeQuery.label_texts(screen.get_node("OreBadge_life")).has("7"), "the badge reads player.orichalchum[type]")
		assert_true(NodeQuery.label_texts(screen.get_node("OreBadge_time")).has("0"), "an empty jar still reads 0")

		screen.free()
	)

	run_case("hq_lab_bench_count_badges_let_taps_through_to_the_jar", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		var badge: Control = screen.get_node("OreBadge_life")
		assert_eq(badge.mouse_filter, Control.MOUSE_FILTER_IGNORE, "a badge over a jar must not swallow the jar's tap")
		for child in badge.find_children("*", "Control", true, false):
			assert_eq((child as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s must not swallow the jar's tap" % child.name)

		screen.free()
	)

	run_case("hq_lab_bench_tapping_an_ore_container_selects_it", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_life")

		assert_eq(GameState.state["labBenchNav"]["selectedOre"], ["life"], "§5.4: tap-to-select is the primary, always-available path")

		screen.free()
	)

	run_case("hq_lab_bench_selected_ore_container_label_shows_selected", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_life")

		assert_true(screen._diorama._plate["regions"]["ore_life"]["label"].contains("selected"), "a selected container's own label must say so")

		screen.free()
	)

	run_case("hq_lab_bench_selected_ore_container_is_flagged_for_the_outline_cue", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_life")
		assert_true(screen._diorama._plate["regions"]["ore_life"].get("selected", false), "a selected container must carry the diorama's outline flag")
		assert_true(not screen._diorama._plate["regions"]["ore_time"].get("selected", false))

		UiSim.tap_zone(screen, "ore_life")
		assert_true(not screen._diorama._plate["regions"]["ore_life"].get("selected", false), "tapping again deselects")

		screen.free()
	)

	run_case("hq_lab_bench_ignores_touch_emulated_mouse_twin_of_a_tap", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()
		var center: Vector2 = UiSim.zone_point(screen._diorama, "ore_life")

		screen._on_diorama_gui_input(UiSim.tap_at(center))
		var twin := InputEventMouseButton.new()
		twin.button_index = MOUSE_BUTTON_LEFT
		twin.pressed = true
		twin.position = center
		twin.device = InputEvent.DEVICE_ID_EMULATION
		screen._on_diorama_gui_input(twin)

		assert_eq(GameState.state["labBenchNav"]["selectedOre"], ["life"], "one physical tap (touch + emulated mouse) must select once, not toggle on and off")

		screen.free()
	)

	run_case("hq_lab_bench_apparatus_with_no_selection_hints_to_pick_ore", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()
		var before: int = GameState.state["notifications"].size()

		UiSim.tap_zone(screen, "apparatus_heat")

		var notifications: Array = GameState.state["notifications"]
		assert_eq(notifications.size(), before + 1, "a zero-selection apparatus tap must say why nothing happened")
		assert_eq(notifications[-1]["text"], HqLabBenchScreen._SELECT_ORE_HINT)
		assert_eq(GameState.state["modal"], null)

		screen.free()
	)

	run_case("hq_lab_bench_apparatus_tap_opens_the_confirm_modal_and_spends_nothing", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 3
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_life")
		UiSim.tap_zone(screen, "apparatus_heat")

		assert_eq(GameState.state["player"]["orichalchum"]["life"], 3, "the tap alone never spends ore")
		assert_eq(GameState.state["modal"]["type"], "lab_bench_confirm")
		assert_eq(GameState.state["modal"]["data"], { "types": ["life"], "approach": "heat" })

		screen.free()
	)

	run_case("hq_lab_bench_blocked_probe_still_opens_the_confirm_modal", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 1
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_life")
		UiSim.tap_zone(screen, "apparatus_heat")

		assert_eq(GameState.state["modal"]["type"], "lab_bench_confirm", "the modal carries the disabled Confirm + reason")
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 1)

		screen.free()
	)

	run_case("hq_lab_bench_inert_gear_tap_opens_the_warning_and_spends_nothing", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["fate"] = 5
		GameState.state["player"]["bench"]["cells"]["fate|heat"] = { "state": "inert", "misses": 0, "tier": 1, "progress": 0 }
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_fate")
		UiSim.tap_zone(screen, "apparatus_heat")

		assert_eq(GameState.state["modal"]["type"], "lab_bench_confirm")
		assert_eq(LabBenchNav.confirm_variant(["fate"], "heat"), LabBenchNav.CONFIRM_INERT)
		assert_eq(GameState.state["player"]["orichalchum"]["fate"], 5)

		screen.free()
	)

	# ── ticket 07, §5.3: apparatus ──────────────────────────────────────────

	run_case("hq_lab_bench_all_four_apparatus_regions_exist_on_a_fresh_save", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		var rects: Dictionary = screen._diorama.region_rects()
		for approach_id in ["heat", "grinding", "compression", "distilling"]:
			assert_true(rects.has("apparatus_" + approach_id), "§5.3: %s is known from the start" % approach_id)

		screen.free()
	)

	run_case("hq_lab_bench_apparatus_region_for_an_unknown_approach_is_dropped", func():
		GameData.APPROACHES["_testGated"] = { "name": "Gated", "symbol": "?", "source": { "type": "room", "id": "lab" } }
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		var regions := { "apparatus__testGated": { "label": "Gated" }, "apparatus_heat": { "label": "Burner" } }
		screen._filter_and_label_apparatus_regions(regions, { "selectedOre": [] })
		assert_true(not regions.has("apparatus__testGated"), "no region at all for an unknown approach, not a dimmed one")
		assert_true(regions.has("apparatus_heat"), "known approaches keep their region")
		GameData.APPROACHES.erase("_testGated")
		screen.free()
	)

	run_case("hq_lab_bench_apparatus_is_inert_with_no_selection", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 3
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "apparatus_heat")

		assert_eq(GameState.state["player"]["orichalchum"]["life"], 3, "§5.3: an unarmed apparatus spends no ore")
		assert_eq(GameState.state["modal"], null)

		screen.free()
	)

	run_case("hq_lab_bench_unprobed_apparatus_never_names_the_recipe_in_its_label", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 3
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_life")

		assert_true(not screen._diorama._plate["regions"]["apparatus_heat"]["label"].contains("Healing Salve"), "naming the recipe before it's probed would spoil the discovery M3 §3 is built around")
		assert_true(screen._diorama._plate["regions"]["apparatus_heat"]["label"].contains("ready"), "the apparatus still shows it's armed, just not with what")

		screen.free()
	)

	run_case("hq_lab_bench_found_apparatus_names_its_recipe", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_time")

		assert_true(screen._diorama._plate["regions"]["apparatus_heat"]["label"].contains("Rewind"), "§5.3: a found cell names the exact recipe waiting there")

		screen.free()
	)

	run_case("hq_lab_bench_ready_gear_carries_the_outline_flag", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 0
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_time")

		var regions: Dictionary = screen._diorama._plate["regions"]
		assert_true(regions["apparatus_heat"].get("selected", false), "found rewind: ready")
		assert_true(not regions["apparatus_grinding"].get("selected", false), "no ore to probe with: not ready")

		screen.free()
	)

	run_case("hq_lab_bench_status_line_summarises_the_selection", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 0
		GameState.state["player"]["orichalchum"]["life"] = 0
		var screen := HqLabBenchScreen.new()
		screen._ready()
		assert_eq((screen.get_node("StatusLine") as Label).text, HqLabBenchScreen._SELECT_ORE_HINT, "no selection yet")

		# rewind (time|heat) and timePearl (time|compression) are tutorial-found.
		UiSim.tap_zone(screen, "ore_time")
		assert_eq(HqLabBenchScreen.status_line(["time"]), "Time · Burner, Press ready", "only the found gear is ready with no ore")
		assert_eq(HqLabBenchScreen.status_line(["time", "life"]), "Time + Life · nothing ready")

		screen.free()
	)

	# ── ticket 07, §5.4: drag-and-drop flourish ─────────────────────────────

	run_case("hq_lab_bench_dragging_ore_onto_an_apparatus_selects_and_runs_it_same_as_two_taps", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 6
		var screen := HqLabBenchScreen.new()
		screen._ready()

		var ore_center: Vector2 = UiSim.zone_point(screen._diorama, "ore_time")
		var apparatus_center: Vector2 = UiSim.zone_point(screen._diorama, "apparatus_heat")

		var press := InputEventScreenTouch.new()
		press.pressed = true
		press.position = ore_center
		screen._on_diorama_gui_input(press)

		var release := InputEventScreenTouch.new()
		release.pressed = false
		release.position = apparatus_center
		screen._on_diorama_gui_input(release)

		assert_eq(GameState.state["labBenchNav"]["selectedOre"], ["time"], "the drag's press half selects the origin container, same as a plain tap would")
		assert_eq(GameState.state["modal"]["type"], "lab_bench_confirm", "the drag's release half opens the same confirm modal a tap would")

		screen.free()
	)

	run_case("hq_lab_bench_a_press_and_release_in_the_same_ore_container_is_a_plain_tap_not_a_drag", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		var ore_center: Vector2 = UiSim.zone_point(screen._diorama, "ore_life")

		var press := InputEventScreenTouch.new()
		press.pressed = true
		press.position = ore_center
		screen._on_diorama_gui_input(press)

		var release := InputEventScreenTouch.new()
		release.pressed = false
		release.position = ore_center
		screen._on_diorama_gui_input(release)

		assert_eq(GameState.state["labBenchNav"]["selectedOre"], ["life"], "press+release in the same region selects exactly once, not twice (toggle-replace would have deselected it on a double-fire)")

		screen.free()
	)
