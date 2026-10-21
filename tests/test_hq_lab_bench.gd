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

	run_case("hq_lab_bench_fits_the_plate_to_width_centred_with_filled_bands", func():
		GameState.reset()
		var plate: Dictionary = GameData.HQ_VISUALS["labBench"]
		var screen := HqLabBenchScreen.new()
		screen._ready()
		screen.size = Vector2(390.0, 844.0)
		screen._refresh()

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

	run_case("hq_lab_bench_notebook_labels_carry_no_open_marker", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()
		UiSim.tap_zone(screen, "notebookRecipes")

		assert_eq(screen._diorama._plate["regions"]["notebookRecipes"]["label"], "Recipes")
		assert_eq(screen._diorama._plate["regions"]["notebookExperiments"]["label"], "Experiments")

		screen.free()
	)

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

	run_case("hq_lab_bench_recipe_book_pages_through_an_ore_tab", func():
		GameState.reset()
		for recipe_key in GameData.RECIPES.keys():
			Lab.grant_recipe(recipe_key)
		var ore := ""
		for candidate in HqLabBenchScreen.ORE_ORDER:
			if Lab.known_recipes(candidate).size() > HqLabBenchScreen.PER_PAGE:
				ore = candidate
				break
		assert_true(ore != "", "some ore tab needs more recipes than fit on one page")
		var known := Lab.known_recipes(ore)
		var screen := HqLabBenchScreen.new()
		screen._ready()
		screen._open_tab(ore)

		assert_true(NodeQuery.find_button(screen, "Next ›") != null, "an overfull tab offers a next page")
		assert_true(NodeQuery.find_button(screen, "‹ Prev") == null, "page 1 has no previous page")
		var beyond: String = GameData.RECIPES[known[HqLabBenchScreen.PER_PAGE]]["name"]
		assert_true(not NodeQuery.label_texts(screen).has(beyond), "page 1 holds only PER_PAGE recipes")

		NodeQuery.find_button(screen, "Next ›").pressed.emit()
		assert_true(NodeQuery.label_texts(screen).has(beyond), "the next page reveals recipes beyond page 1")
		assert_true(NodeQuery.find_button(screen, "‹ Prev") != null, "a later page offers the previous page")

		screen._open_tab(ore)
		assert_eq(screen._book_page, 0, "switching ore tab resets to page 1")

		screen.free()
	)

	run_case("hq_lab_bench_recipe_book_fitting_one_page_has_no_page_buttons", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()
		UiSim.tap_zone(screen, "notebookRecipes")

		assert_true(NodeQuery.find_button(screen, "Next ›") == null, "no next page")
		assert_true(NodeQuery.find_button(screen, "‹ Prev") == null, "no previous page")

		screen.free()
	)

	run_case("hq_lab_bench_recipe_book_close_restores_the_bench_view", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()
		UiSim.tap_zone(screen, "notebookRecipes")
		assert_eq(screen._page, HqLabBenchScreen.Page.BOOK)

		NodeQuery.find_button(screen, "Close").pressed.emit()
		assert_eq(screen._page, HqLabBenchScreen.Page.NONE, "Close returns to the default bench view")
		assert_true(NodeQuery.find_button(screen, "Close") == null, "the book is gone")
		assert_true(NodeQuery.find_button(screen, "‹ Back") != null, "the bench's own Back is showing again")

		screen.free()
	)

	run_case("hq_lab_bench_all_four_apparatus_regions_exist_on_a_fresh_save", func():
		GameState.reset()
		var screen := HqLabBenchScreen.new()
		screen._ready()

		var rects: Dictionary = screen._diorama.region_rects()
		for approach_id in ["heat", "grinding", "compression", "distilling"]:
			assert_true(rects.has("apparatus_" + approach_id), "§5.3: %s is known from the start" % approach_id)

		screen.free()
	)
