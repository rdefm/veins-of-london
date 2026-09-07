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
