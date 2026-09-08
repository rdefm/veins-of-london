extends "res://tests/test_base.gd"

# hq-diorama ticket 06, docs/hq-diorama-vision.md §5: the Lab bench's own
# diegetic sub-view, reached from hq.gd's "lab" zone tap (see
# tests/test_hq_screen.gd's own "hq_lab_zone_tap_navigates_to_the_hq_lab_
# bench_screen"). Tap simulation follows the same pattern
# tests/test_hq_screen.gd's own _tap_zone() established: a synthetic
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


static func _find_button(root: Node, text: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null


static func _tap_at(pos: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.pressed = true
	event.position = pos
	return event


static func _tap_zone(screen: HqLabBenchScreen, zone_id: String) -> void:
	var rect: Rect2 = screen._diorama.region_rects()[zone_id]
	screen._on_diorama_gui_input(_tap_at(rect.get_center()))


func run() -> void:
	run_case("hq_lab_bench_back_button_returns_to_hq", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq_lab_bench"

		var screen := HqLabBenchScreen.new()
		screen._ready()

		_find_button(screen, "‹ Back").pressed.emit()
		assert_eq(GameState.state["currentScreen"], "hq", "Back must return to the HQ room, not the phone home grid")

		screen.free()
	)

	run_case("hq_lab_bench_opens_on_the_books_stop_with_the_left_arrow_disabled", func():
		GameState.reset()
		GameState.state["labBenchNav"]["stop"] = "books"

		var screen := HqLabBenchScreen.new()
		screen._ready()

		assert_true(_find_button(screen, "‹").disabled, "§5.1: the left arrow must be disabled at the first (books) stop")
		assert_true(not _find_button(screen, "›").disabled, "the right arrow must stay enabled with 2 more stops ahead")

		screen.free()
	)

	run_case("hq_lab_bench_right_arrow_steps_to_the_ore_stop", func():
		GameState.reset()

		var screen := HqLabBenchScreen.new()
		screen._ready()

		_find_button(screen, "›").pressed.emit()

		assert_eq(GameState.state["labBenchNav"]["stop"], "ore", "tapping the right arrow must advance exactly one stop")

		screen.free()
	)

	run_case("hq_lab_bench_right_arrow_is_disabled_on_the_apparatus_stop", func():
		GameState.reset()
		GameState.state["labBenchNav"]["stop"] = "apparatus"

		var screen := HqLabBenchScreen.new()
		screen._ready()

		assert_true(_find_button(screen, "›").disabled, "§5.1: the right arrow must be disabled at the last (apparatus) stop")
		assert_true(not _find_button(screen, "‹").disabled, "the left arrow must stay enabled with stops behind it")

		screen.free()
	)

	run_case("hq_lab_bench_left_arrow_steps_back_from_the_apparatus_stop", func():
		GameState.reset()
		GameState.state["labBenchNav"]["stop"] = "apparatus"

		var screen := HqLabBenchScreen.new()
		screen._ready()

		_find_button(screen, "‹").pressed.emit()

		assert_eq(GameState.state["labBenchNav"]["stop"], "ore", "tapping the left arrow must step back exactly one stop")

		screen.free()
	)

	run_case("hq_lab_bench_tapping_the_recipes_notebook_sets_the_mode", func():
		GameState.reset()

		var screen := HqLabBenchScreen.new()
		screen._ready()

		_tap_zone(screen, "notebookRecipes")

		assert_eq(GameState.state["labBenchNav"]["mode"], "recipes", "tapping the Recipes notebook must set the mode (§5.2)")

		screen.free()
	)

	run_case("hq_lab_bench_tapping_the_experiments_notebook_sets_the_mode", func():
		GameState.reset()

		var screen := HqLabBenchScreen.new()
		screen._ready()

		_tap_zone(screen, "notebookExperiments")

		assert_eq(GameState.state["labBenchNav"]["mode"], "experiments")

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

	run_case("hq_lab_bench_tapping_the_held_notebook_again_returns_to_the_fork", func():
		GameState.reset()
		GameState.state["labBenchNav"]["mode"] = "recipes"

		var screen := HqLabBenchScreen.new()
		screen._ready()

		_tap_zone(screen, "notebookRecipes")

		assert_eq(GameState.state["labBenchNav"]["mode"], null, "§5.2: tapping the held notebook again must return to the fork")

		screen.free()
	)

	run_case("hq_lab_bench_switches_modes_freely_with_no_confirmation", func():
		GameState.reset()
		GameState.state["labBenchNav"]["mode"] = "recipes"

		var screen := HqLabBenchScreen.new()
		screen._ready()

		_tap_zone(screen, "notebookExperiments")

		assert_eq(GameState.state["labBenchNav"]["mode"], "experiments", "§5.2: the player can switch modes freely")

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

		_tap_zone(screen, "ore_life")

		assert_eq(GameState.state["labBenchNav"]["selectedOre"], ["life"], "§5.4: tap-to-select is the primary, always-available path")

		screen.free()
	)

	run_case("hq_lab_bench_selected_ore_container_label_shows_selected", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		_tap_zone(screen, "ore_life")

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

		_tap_zone(screen, "ore_life")

		assert_true(screen._diorama._plate["regions"]["ore_life"]["label"].contains("costs 5–6"), "ambiguous until an apparatus is tapped -- shows the min-max range rather than falling silent")

		screen.free()
	)

	run_case("hq_lab_bench_selected_ore_container_shows_the_probe_cost_in_experiments_mode", func():
		GameState.reset()
		LabBenchNav.tap_notebook(LabBenchNav.MODE_EXPERIMENTS)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		_tap_zone(screen, "ore_life")

		assert_true(screen._diorama._plate["regions"]["ore_life"]["label"].contains("costs %d" % Bench.ORE_COST_PER_TYPE), "§5.4: a selected chip must communicate the cost it will incur")

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

		_tap_zone(screen, "apparatus_heat")

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

		_tap_zone(screen, "ore_life")
		_tap_zone(screen, "apparatus_heat")

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

		_tap_zone(screen, "ore_life")

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

		_tap_zone(screen, "ore_time")
		_tap_zone(screen, "apparatus_heat")

		assert_eq(GameState.state["modal"]["type"], "craft_result", "§5.2: the manual path crafts quantity 1 via the normal Crafting.attempt_craft path")

		screen.free()
	)

	run_case("hq_lab_bench_recipes_manual_path_apparatus_names_the_armed_recipe", func():
		GameState.reset()
		LabBenchNav.tap_notebook(LabBenchNav.MODE_RECIPES)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		_tap_zone(screen, "ore_time")

		assert_true(screen._diorama._plate["regions"]["apparatus_heat"]["label"].contains("Rewind"), "§5.3: crafting mode names the exact recipe waiting there")

		screen.free()
	)

	run_case("hq_lab_bench_recipes_manual_path_apparatus_is_inert_for_an_unknown_combination", func():
		GameState.reset()
		LabBenchNav.tap_notebook(LabBenchNav.MODE_RECIPES)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		_tap_zone(screen, "ore_physics")  # shield lives at physics|heat but is untried, not Found
		_tap_zone(screen, "apparatus_heat")

		assert_eq(GameState.state["modal"], null, "§5.3: an unknown combination is silently inert -- no craft, no side effect")

		screen.free()
	)

	# ── ticket 07, §5.2: recipe book / notebook entry points ───────────────

	run_case("hq_lab_bench_shows_no_mode_button_at_the_fork", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		assert_true(_find_button(screen, "Recipe book") == null)
		assert_true(_find_button(screen, "Notebook") == null)

		screen.free()
	)

	run_case("hq_lab_bench_recipes_mode_shows_a_recipe_book_button_that_opens_the_book", func():
		GameState.reset()
		LabBenchNav.tap_notebook(LabBenchNav.MODE_RECIPES)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		var book_button := _find_button(screen, "Recipe book")
		assert_true(book_button != null)
		book_button.pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "lab_bench_recipe_book")

		screen.free()
	)

	run_case("hq_lab_bench_experiments_mode_shows_a_notebook_button_that_opens_bench_notes", func():
		GameState.reset()
		LabBenchNav.tap_notebook(LabBenchNav.MODE_EXPERIMENTS)
		var screen := HqLabBenchScreen.new()
		screen._ready()

		var notebook_button := _find_button(screen, "Notebook")
		assert_true(notebook_button != null)
		notebook_button.pressed.emit()
		assert_eq(GameState.state["modal"]["type"], "lab_bench_notes")

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
