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

	run_case("recipe_page_gates_auto_craft_on_rank_and_offers_manual", func():
		GameState.reset()
		var screen := _screen()
		screen._open_recipe("healingSalve")
		assert_true(NodeQuery.find_button(screen, "Auto-craft ×1").disabled, "no rank yet")
		assert_true(not NodeQuery.find_button(screen, "Craft manually").disabled)
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

	run_case("craft_manually_docks_the_book_and_a_run_plays_on_the_plate", func():
		GameState.reset()
		var root: Dictionary = GameState.state["benchPrototype"]
		var screen := _screen()
		screen._open_recipe("healingSalve")
		NodeQuery.find_button(screen, "Craft manually").pressed.emit()
		assert_true(NodeQuery.find_button(screen, "Finish") != null, "the docked book has Finish")
		assert_eq(NodeQuery.find_button(screen, "‹ Exit"), null, "no way off the plate but Finish")
		UiSim.tap_zone(screen, "apparatus_heat")
		assert_true(NodeQuery.label_texts(screen).has("Add calc from a jar first."), "apparatus before a jar: notice")
		assert_eq(_find_gauge(screen), null, "and no gauge")
		UiSim.tap_zone(screen, "ore_time")
		assert_true(NodeQuery.label_texts(screen).has("Healing Salve doesn't use Time Orichalchum."), "off-recipe jar: notice")
		assert_eq(root["activeRun"], null, "an inert jar starts nothing")
		UiSim.tap_zone(screen, "ore_life")
		assert_eq(root["pool"]["life"], 37, "a recipe jar taps its calc in")
		UiSim.tap_zone(screen, "apparatus_heat")
		var gauge = _find_gauge(screen)
		assert_true(gauge is LabGauges.HoldGauge, "heat pops its hold gauge")
		gauge.committed.emit(62.0)
		assert_eq(root["activeRun"]["performed"][0]["apparatus"], "heat", "the gauge's release performs the step")
		assert_eq(_find_gauge(screen), null, "and closes the gauge")
		NodeQuery.find_button(screen, "Finish").pressed.emit()
		assert_eq(root["activeRun"], null, "Finish ends the run")
		assert_true(NodeQuery.find_button(screen, "Done") != null, "the result shows on the book")
		assert_true(NodeQuery.find_button(screen, "Rewind") != null, "with Rewind")
		assert_true(NodeQuery.label_texts(screen).has("1. %s · ✓" % LabBenchNav.apparatus_name("heat")), "a clue per performed step")
		NodeQuery.find_button(screen, "Done").pressed.emit()
		assert_true(NodeQuery.find_button(screen, "Craft manually") != null, "Done returns to the recipe page")
		screen.free()
	)

	run_case("an_open_run_keeps_the_book_docked_and_a_crack_shows_its_result", func():
		GameState.reset()
		BenchPrototype.set_known("timePearl", true)
		BenchPrototype.add_ore("timePearl", "time")
		var screen := _screen()
		assert_true(NodeQuery.find_button(screen, "Finish") != null, "an open run opens docked")
		UiSim.tap_zone(screen, "apparatus_compression")
		_find_gauge(screen).committed.emit(99.0)
		assert_true(NodeQuery.label_texts(screen).has("The vessel cracked. No item, and the calc is lost."), "crack result on the book")
		screen.free()
	)


func _find_gauge(node: Node) -> Node:
	if node is LabGauges.StepGauge and not node is LabGauges.BandGauge:
		return node
	for child in node.get_children():
		var found := _find_gauge(child)
		if found != null:
			return found
	return null
