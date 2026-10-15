extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")
const UiSim := preload("res://tests/support/ui_sim.gd")

# scenes/screens/bench_prototype.gd on the Lab plate, built off-tree like
# tests/test_hq_lab_bench.gd (scale 1, no bands).


func _screen() -> BenchPrototypeScreen:
	var screen := BenchPrototypeScreen.new()
	screen._ready()
	return screen


func run() -> void:
	run_case("plate_badges_read_the_prototype_pool_and_every_apparatus_shows", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["life"] = 99
		GameState.state["benchPrototype"]["pool"]["life"] = 7
		var screen := _screen()
		assert_true(NodeQuery.label_texts(screen.get_node("OreBadge_life")).has("7"), "badge reads the prototype pool")
		assert_true(NodeQuery.label_texts(screen.get_node("OreBadge_physics")).has("0"), "a type outside the pool reads 0")
		for approach in ["heat", "grinding", "compression", "distilling"]:
			assert_true(screen._diorama._plate["regions"].has(LabBenchNav.APPARATUS_REGION_PREFIX + approach), "%s shown" % approach)
		screen.free()
	)

	run_case("notebook_zone_opens_a_book_of_known_recipes_only", func():
		GameState.reset()
		var screen := _screen()
		UiSim.tap_zone(screen, "notebookRecipes")
		var texts := NodeQuery.label_texts(screen)
		assert_true(texts.has("Healing Salve"), "known recipe listed")
		assert_true(not texts.has("Time Pearl"), "unknown recipe not listed")
		BenchPrototype.set_known("timePearl", true)
		assert_true(NodeQuery.label_texts(screen).has("Time Pearl"), "a recipe toggled known joins the book")
		screen.free()
	)

	run_case("recipe_page_gates_auto_craft_on_rank_and_manual_is_disabled", func():
		GameState.reset()
		var screen := _screen()
		screen._open_recipe("healingSalve")
		assert_true(NodeQuery.find_button(screen, "Auto-craft ×1").disabled, "no rank yet")
		assert_true(NodeQuery.find_button(screen, "Craft manually").disabled)
		GameState.state["benchPrototype"]["bestRanks"]["healingSalve"] = 3
		EventBus.state_changed.emit()
		var craft := NodeQuery.find_button(screen, "Auto-craft ×1")
		assert_true(not craft.disabled, "enabled once ranked")
		craft.pressed.emit()
		var root: Dictionary = GameState.state["benchPrototype"]
		assert_eq(root["ledger"][-1]["kind"], "batch", "auto-craft logs a batch")
		assert_eq(root["pool"]["life"], 37, "and spends the pool")
		screen.free()
	)

	run_case("debug_page_is_reachable_from_the_book", func():
		GameState.reset()
		var screen := _screen()
		UiSim.tap_zone(screen, "notebookRecipes")
		NodeQuery.find_button(screen, "Debug page").pressed.emit()
		for text in ["Refill pool", "Rewind", "Use real skill", "‹ Recipes"]:
			assert_true(NodeQuery.find_button(screen, text) != null, "%s on the back page" % text)
		screen.free()
	)
