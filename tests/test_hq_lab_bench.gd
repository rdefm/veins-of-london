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
# screen's own _on_diorama_gui_input(). Held-notebook label assertions read
# HqDiorama's own _plate directly, same convention
# tests/test_hq_screen.gd's own hostile-door-label cases document (the
# underscore is convention, not enforcement).
#
# HqLabBenchScreen.new() is safe to call _ready() on directly without
# adding it to a live scene tree, same reasoning tests/test_hq_floorplan.gd
# already relies on for HqFloorplanScreen. This ticket delivers navigation
# and mode state only -- no ore-container/apparatus content exists yet
# (ticket 07), so there's nothing to assert about the ore/apparatus stops
# beyond "the arrows reach them".


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

	run_case("hq_lab_bench_opens_on_the_books_ore_stop_with_the_left_arrow_disabled", func():
		GameState.reset()
		GameState.state["labBenchNav"]["stop"] = "books_ore"

		var screen := HqLabBenchScreen.new()
		screen._ready()

		assert_true(NodeQuery.find_button(screen, "‹").disabled, "§5.1: the left arrow must be disabled at the first (books+ore) stop")
		assert_true(not NodeQuery.find_button(screen, "›").disabled, "the right arrow must stay enabled with the apparatus stop ahead")

		screen.free()
	)

	run_case("hq_lab_bench_right_arrow_steps_to_the_apparatus_stop", func():
		GameState.reset()

		var screen := HqLabBenchScreen.new()
		screen._ready()

		NodeQuery.find_button(screen, "›").pressed.emit()

		assert_eq(GameState.state["labBenchNav"]["stop"], "apparatus", "tapping the right arrow must advance exactly one stop")

		screen.free()
	)

	run_case("hq_lab_bench_right_arrow_is_disabled_on_the_apparatus_stop", func():
		GameState.reset()
		GameState.state["labBenchNav"]["stop"] = "apparatus"

		var screen := HqLabBenchScreen.new()
		screen._ready()

		assert_true(NodeQuery.find_button(screen, "›").disabled, "§5.1: the right arrow must be disabled at the last (apparatus) stop")
		assert_true(not NodeQuery.find_button(screen, "‹").disabled, "the left arrow must stay enabled with the books+ore stop behind it")

		screen.free()
	)

	run_case("hq_lab_bench_left_arrow_steps_back_from_the_apparatus_stop", func():
		GameState.reset()
		GameState.state["labBenchNav"]["stop"] = "apparatus"

		var screen := HqLabBenchScreen.new()
		screen._ready()

		NodeQuery.find_button(screen, "‹").pressed.emit()

		assert_eq(GameState.state["labBenchNav"]["stop"], "books_ore", "tapping the left arrow must step back exactly one stop")

		screen.free()
	)

	# ── ticket 11: arrow nav tweens the pan instead of snapping ───────────

	await run_case("hq_lab_bench_right_arrow_tweens_the_diorama_pan_when_in_a_live_tree", func():
		GameState.reset()
		var tree := Engine.get_main_loop() as SceneTree
		var screen := HqLabBenchScreen.new()
		tree.root.add_child(screen)
		await tree.process_frame

		var stop_width: float = GameData.HQ_VISUALS["labBench"]["width"] / float(LabBenchNav.STOPS.size())

		NodeQuery.find_button(screen, "›").pressed.emit()

		assert_true(screen._active_pan_tween != null, "ticket 11: an arrow step must kick off a tween rather than snap instantly")
		assert_almost_eq(screen._diorama.position.x, 0.0, 0.01, "mid-tween, the diorama must still be at its pre-step position")

		screen._active_pan_tween.custom_step(999999.0)
		assert_almost_eq(screen._diorama.position.x, -stop_width, 0.01, "once the tween finishes, the diorama must have arrived at the apparatus stop")

		tree.root.remove_child(screen)
		screen.free()
	)

	# code-review (ticket 11): _refresh() rebuilds the diorama on *every*
	# state_changed, not only an arrow step -- an unrelated state change
	# (e.g. an impatient tap on a notebook) firing mid-pan must resume the
	# same pan from wherever it actually is, not snap straight to the
	# destination early (which is what happens if the rebuild trusts a
	# _pan_x already overwritten with the tween's target rather than the
	# diorama's live position).
	await run_case("hq_lab_bench_an_unrelated_refresh_mid_pan_resumes_toward_the_same_target_instead_of_snapping_there", func():
		GameState.reset()
		var tree := Engine.get_main_loop() as SceneTree
		var screen := HqLabBenchScreen.new()
		tree.root.add_child(screen)
		await tree.process_frame

		var stop_width: float = GameData.HQ_VISUALS["labBench"]["width"] / float(LabBenchNav.STOPS.size())

		NodeQuery.find_button(screen, "›").pressed.emit()
		screen._active_pan_tween.custom_step(0.2)  # halfway through _PAN_DURATION -- still mid-flight

		var mid_x: float = screen._diorama.position.x
		assert_true(mid_x < -1.0 and mid_x > -(stop_width - 1.0), "sanity: the fixture must actually be mid-flight, not at either end (%s)" % mid_x)

		LabBenchNav.tap_notebook(LabBenchNav.MODE_RECIPES)  # unrelated state_changed, same stop

		assert_almost_eq(screen._diorama.position.x, mid_x, 0.01, "the rebuilt diorama must resume from where the pan actually was, not jump ahead to the destination")
		assert_true(screen._active_pan_tween != null, "the rebuild must still be animating toward the apparatus stop, not have already arrived")

		screen._active_pan_tween.custom_step(999999.0)
		assert_almost_eq(screen._diorama.position.x, -stop_width, 0.01, "the resumed tween must still land on the apparatus stop")

		tree.root.remove_child(screen)
		screen.free()
	)

	run_case("hq_lab_bench_tapping_the_recipes_notebook_sets_the_mode_and_opens_the_recipe_book", func():
		GameState.reset()

		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "notebookRecipes")

		assert_eq(GameState.state["labBenchNav"]["mode"], "recipes", "tapping the Recipes notebook must set the mode (§5.2)")
		assert_eq(GameState.state["modal"]["type"], "lab_bench_recipe_book", "ticket 22: the same tap must open the recipe book, not require a second tap on a separate button")

		screen.free()
	)

	run_case("hq_lab_bench_tapping_the_experiments_notebook_sets_the_mode_and_opens_the_notebook", func():
		GameState.reset()

		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "notebookExperiments")

		assert_eq(GameState.state["labBenchNav"]["mode"], "experiments")
		assert_eq(GameState.state["modal"]["type"], "lab_bench_notes", "ticket 22: the same tap must open the notebook, not require a second tap on a separate button")

		screen.free()
	)

	run_case("hq_lab_bench_held_notebook_region_label_reads_open", func():
		GameState.reset()
		GameState.state["labBenchNav"]["mode"] = "experiments"

		var screen := HqLabBenchScreen.new()
		screen._ready()

		var recipes_region: Dictionary = screen._diorama._plate["regions"]["notebookRecipes"]
		var experiments_region: Dictionary = screen._diorama._plate["regions"]["notebookExperiments"]
		assert_eq(recipes_region["label"], "Recipes", "the unheld notebook's label must render normally")
		assert_eq(experiments_region["label"], "Experiments (open)", "§5.2: the held notebook must stay visibly open, since no notebook art exists yet")
		assert_eq(GameData.HQ_VISUALS["labBench"]["regions"]["notebookExperiments"]["label"], "Experiments", "the source manifest itself must be untouched -- GameData.HQ_VISUALS is loaded once at boot and must never be mutated")

		screen.free()
	)

	run_case("hq_lab_bench_tapping_the_held_notebook_again_returns_to_the_fork_and_opens_no_modal", func():
		GameState.reset()
		GameState.state["labBenchNav"]["mode"] = "recipes"

		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "notebookRecipes")

		assert_eq(GameState.state["labBenchNav"]["mode"], null, "§5.2: tapping the held notebook again must return to the fork")
		assert_eq(GameState.state["modal"], null, "ticket 22: closing the fork must not also pop the modal it's closing")

		screen.free()
	)

	run_case("hq_lab_bench_switches_modes_freely_with_no_confirmation", func():
		GameState.reset()
		GameState.state["labBenchNav"]["mode"] = "recipes"

		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "notebookExperiments")

		assert_eq(GameState.state["labBenchNav"]["mode"], "experiments", "§5.2: the player can switch modes freely")
		assert_eq(GameState.state["modal"]["type"], "lab_bench_notes", "ticket 22: switching modes via a notebook tap opens that mode's modal same as the fork case")

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

	run_case("hq_lab_bench_ore_container_label_reads_empty_at_zero_count", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 0

		var screen := HqLabBenchScreen.new()
		screen._ready()

		assert_true(screen._diorama._plate["regions"]["ore_life"]["label"].contains("empty"), "§5.4: zero count is the empty visual state")

		screen.free()
	)

	run_case("hq_lab_bench_ore_container_label_reads_some_at_a_middling_count", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 5

		var screen := HqLabBenchScreen.new()
		screen._ready()

		assert_true(screen._diorama._plate["regions"]["ore_life"]["label"].contains("some"), "§5.4: a middling count is the some visual state")

		screen.free()
	)

	run_case("hq_lab_bench_ore_container_label_reads_plenty_at_a_high_count", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 25

		var screen := HqLabBenchScreen.new()
		screen._ready()

		assert_true(screen._diorama._plate["regions"]["ore_life"]["label"].contains("plenty"), "§5.4: a high count is the plenty visual state")

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

	run_case("hq_lab_bench_selected_ore_container_shows_a_cost_range_when_multiple_known_recipes_match", func():
		GameState.reset()
		# enhancementPowder (life|grinding) is already Found (tutorial-taught);
		# force healingSalve (life|heat) Found too, so "life" alone resolves to
		# two different Found recipes across the two start-known approaches.
		GameState.state["player"]["bench"]["cells"]["life|heat"] = { "state": "found", "misses": 0, "refine": 0 }
		LabBenchNav.tap_notebook(LabBenchNav.MODE_RECIPES)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_life")

		assert_true(screen._diorama._plate["regions"]["ore_life"]["label"].contains("costs 5–6"), "ambiguous until an apparatus is tapped -- shows the min-max range rather than falling silent")

		screen.free()
	)

	run_case("hq_lab_bench_selected_ore_container_shows_the_probe_cost_in_experiments_mode", func():
		GameState.reset()
		LabBenchNav.tap_notebook(LabBenchNav.MODE_EXPERIMENTS)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_life")

		assert_true(screen._diorama._plate["regions"]["ore_life"]["label"].contains("costs %d" % Bench.ORE_COST_PER_TYPE), "§5.4: a selected chip must communicate the cost it will incur")

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
		var center: Vector2 = screen._diorama.region_rects()["ore_life"].get_center()

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

	run_case("hq_lab_bench_apparatus_probes_with_no_notebook_open", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 3
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_life")
		UiSim.tap_zone(screen, "apparatus_heat")

		assert_eq(GameState.state["labBenchNav"]["mode"], null)
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 0, "experimenting must not need a notebook held first")
		assert_eq(GameState.state["modal"]["type"], "lab_bench_probe_result")

		screen.free()
	)

	run_case("hq_lab_bench_blocked_probe_reports_the_block_reason", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 1
		var screen := HqLabBenchScreen.new()
		screen._ready()
		var reason := Bench.probe_block_reason(["life"], "heat")

		UiSim.tap_zone(screen, "ore_life")
		UiSim.tap_zone(screen, "apparatus_heat")

		assert_true(reason != "", "precondition: 1 life can't cover a probe")
		assert_eq(GameState.state["notifications"][-1]["text"], reason)
		assert_eq(GameState.state["player"]["orichalchum"]["life"], 1, "a blocked probe spends nothing")
		assert_eq(GameState.state["modal"], null)

		screen.free()
	)

	# ── ticket 07, §5.3: apparatus ──────────────────────────────────────────

	run_case("hq_lab_bench_apparatus_regions_only_exist_for_known_approaches", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		var rects: Dictionary = screen._diorama.region_rects()
		assert_true(rects.has("apparatus_heat"), "heat is known from the start")
		assert_true(rects.has("apparatus_grinding"), "grinding is known from the start")
		assert_true(not rects.has("apparatus_compression"), "§3.2: compression needs the Workshop room -- no region at all on a fresh bedsit save, not a dimmed one")
		assert_true(not rects.has("apparatus_distilling"), "distilling needs Improved Lab -- same rule")

		screen.free()
	)

	run_case("hq_lab_bench_apparatus_region_appears_once_its_room_is_built", func():
		GameState.reset()
		GameState.state["home"]["rooms"].append("workshop")
		var screen := HqLabBenchScreen.new()
		screen._ready()

		assert_true(screen._diorama.region_rects().has("apparatus_compression"), "§5.3: apparatus appear on the bench as the property is upgraded")

		screen.free()
	)

	run_case("hq_lab_bench_experiments_mode_apparatus_is_inert_with_no_selection", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 3
		LabBenchNav.tap_notebook(LabBenchNav.MODE_EXPERIMENTS)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "apparatus_heat")

		assert_eq(GameState.state["player"]["orichalchum"]["life"], 3, "§5.3: an unarmed apparatus spends no ore -- no error, no wasted tap")
		assert_eq(GameState.state["modal"], null)

		screen.free()
	)

	run_case("hq_lab_bench_experiments_mode_apparatus_probes_once_ore_is_selected", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 3
		LabBenchNav.tap_notebook(LabBenchNav.MODE_EXPERIMENTS)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_life")
		UiSim.tap_zone(screen, "apparatus_heat")

		assert_eq(GameState.state["player"]["orichalchum"]["life"], 0, "a probe always spends the discovery cost regardless of outcome (M3 §7)")
		assert_eq(GameState.state["modal"]["type"], "lab_bench_probe_result", "the outcome is reported the instant the probe resolves")

		screen.free()
	)

	run_case("hq_lab_bench_experiments_mode_apparatus_never_names_the_recipe_in_its_label", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 3
		LabBenchNav.tap_notebook(LabBenchNav.MODE_EXPERIMENTS)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_life")

		assert_true(not screen._diorama._plate["regions"]["apparatus_heat"]["label"].contains("Healing Salve"), "naming the recipe before it's probed would spoil the discovery M3 §3 is built around")
		assert_true(screen._diorama._plate["regions"]["apparatus_heat"]["label"].contains("ready"), "the apparatus still shows it's armed, just not with what")

		screen.free()
	)

	run_case("hq_lab_bench_recipes_manual_path_crafts_qty_1_at_the_matching_apparatus", func():
		GameState.reset()
		# rewind (time|heat) is taughtBy: tutorial -- already Found with no setup.
		GameState.state["player"]["orichalchum"]["time"] = 6
		LabBenchNav.tap_notebook(LabBenchNav.MODE_RECIPES)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_time")
		UiSim.tap_zone(screen, "apparatus_heat")

		assert_eq(GameState.state["modal"]["type"], "craft_result", "§5.2: the manual path crafts quantity 1 via the normal Crafting.attempt_craft path")

		screen.free()
	)

	run_case("hq_lab_bench_recipes_manual_path_apparatus_names_the_armed_recipe", func():
		GameState.reset()
		LabBenchNav.tap_notebook(LabBenchNav.MODE_RECIPES)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_time")

		assert_true(screen._diorama._plate["regions"]["apparatus_heat"]["label"].contains("Rewind"), "§5.3: crafting mode names the exact recipe waiting there")

		screen.free()
	)

	run_case("hq_lab_bench_recipes_manual_path_apparatus_is_inert_for_an_unknown_combination", func():
		GameState.reset()
		LabBenchNav.tap_notebook(LabBenchNav.MODE_RECIPES)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		UiSim.tap_zone(screen, "ore_physics")  # shield lives at physics|heat but is untried, not Found
		UiSim.tap_zone(screen, "apparatus_heat")

		assert_eq(GameState.state["modal"], null, "§5.3: an unknown combination is silently inert -- no craft, no side effect")

		screen.free()
	)

	# ── ticket 07, §5.4: drag-and-drop flourish ─────────────────────────────

	run_case("hq_lab_bench_dragging_ore_onto_an_apparatus_selects_and_runs_it_same_as_two_taps", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 6
		LabBenchNav.tap_notebook(LabBenchNav.MODE_RECIPES)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		var rects: Dictionary = screen._diorama.region_rects()
		var ore_center: Vector2 = (rects["ore_time"] as Rect2).get_center()
		var apparatus_center: Vector2 = (rects["apparatus_heat"] as Rect2).get_center()

		var press := InputEventScreenTouch.new()
		press.pressed = true
		press.position = ore_center
		screen._on_diorama_gui_input(press)

		var release := InputEventScreenTouch.new()
		release.pressed = false
		release.position = apparatus_center
		screen._on_diorama_gui_input(release)

		assert_eq(GameState.state["labBenchNav"]["selectedOre"], ["time"], "the drag's press half selects the origin container, same as a plain tap would")
		assert_eq(GameState.state["modal"]["type"], "craft_result", "the drag's release half runs the apparatus with that selection, same as tapping it separately would")

		screen.free()
	)

	run_case("hq_lab_bench_a_press_and_release_in_the_same_ore_container_is_a_plain_tap_not_a_drag", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		var ore_center: Vector2 = (screen._diorama.region_rects()["ore_life"] as Rect2).get_center()

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
