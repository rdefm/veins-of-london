extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")
const UiSim := preload("res://tests/support/ui_sim.gd")

# scenes/screens/hq_lab_bench.gd over the live Lab: the recipe book, the
# recipe page and a docked manual run. Built off-tree like
# tests/test_hq_lab_bench.gd (scale 1, no bands).


func _screen() -> HqLabBenchScreen:
	var screen := HqLabBenchScreen.new()
	screen._ready()
	return screen


func _name(recipe_key: String) -> String:
	return GameData.RECIPES[recipe_key]["name"]


func _has_label_starting(root: Node, prefix: String) -> bool:
	for text in NodeQuery.label_texts(root):
		if text.begins_with(prefix):
			return true
	return false


func _has_label_containing(root: Node, part: String) -> bool:
	for text in NodeQuery.label_texts(root):
		if text.contains(part):
			return true
	return false


func run() -> void:
	run_case("notebook_opens_a_book_of_known_recipes_by_ore_tab", func():
		GameState.reset()
		var screen := _screen()
		UiSim.tap_zone(screen, "notebookRecipes")
		assert_true(NodeQuery.label_texts(screen).has("No Time recipes known."), "a new game knows nothing")
		Lab.grant_recipe("timePearl")
		assert_true(NodeQuery.label_texts(screen).has(_name("timePearl")), "a granted recipe joins its ore tab")
		assert_true(not NodeQuery.label_texts(screen).has(_name("healingSalve")), "an unknown recipe stays out")
		screen._open_tab("life")
		assert_true(NodeQuery.label_texts(screen).has("No Life recipes known."), "the life tab lists only life recipes")
		assert_true(not NodeQuery.label_texts(screen).has(_name("timePearl")))
		screen.free()
	)

	run_case("recipe_page_shows_the_procedure_as_known_best_rank_and_the_ladder", func():
		GameState.reset()
		Lab.grant_recipe("timePearl")
		Lab.grant_steps("timePearl", Lab.rung_steps("timePearl", "hint1"), "vague")
		var screen := _screen()
		screen._open_recipe("timePearl")
		assert_true(NodeQuery.label_texts(screen).has("Best rank: —"), "no rank yet")
		assert_true(_has_label_starting(screen, "1. %s" % Lab.apparatus_name("compression")), "a base step shows")
		assert_true(_has_label_containing(screen, "≈ "), "a vague step shows a faded region")
		var hint1: Dictionary = GameData.LAB["procedures"]["timePearl"]["hints"][0]
		var hint2: Dictionary = GameData.LAB["procedures"]["timePearl"]["hints"][1]
		assert_true(NodeQuery.label_texts(screen).has(hint1["vague"]["note"]), "with its direction note")
		assert_true(not NodeQuery.label_texts(screen).has(hint2["vague"]["note"]), "an unknown step stays hidden")
		var ladder := screen.find_child("LadderRegion", true, false)
		assert_true(ladder != null, "the ladder region shows")
		var rows := RecipeKnowledge.ladder_rows("timePearl")
		for row in rows:
			var rung_label := ladder.find_child("Rung_%s" % row["rung"], true, false) as Label
			assert_true(rung_label != null and rung_label.text == row["text"], "%s rung rendered" % row["rung"])
		RecipeKnowledge.grant_rung("timePearl", "hint2", "vague")
		ladder = screen.find_child("LadderRegion", true, false)
		var hint2_text: String = RecipeKnowledge.ladder_rows("timePearl")[2]["text"]
		assert_eq((ladder.find_child("Rung_hint2", true, false) as Label).text, hint2_text, "a grant redraws the ladder")
		assert_true(hint2_text != rows[2]["text"], "with hint2 now owned")
		assert_true(NodeQuery.find_button(screen, "Craft manually") != null)
		assert_true(NodeQuery.find_button(screen, "Batch ×1").disabled, "no batch before a hand run")
		screen.free()
	)

	run_case("batch_crafts_at_best_rank_once_performed", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 10
		Lab.grant_recipe("timePearl")
		GameState.state["lab"]["performedOnce"].append("timePearl")
		GameState.state["lab"]["bestRanks"]["timePearl"] = 2
		var screen := _screen()
		screen._open_recipe("timePearl")
		var batch := NodeQuery.find_button(screen, "Batch ×1")
		assert_true(not batch.disabled, "enabled once performed")
		batch.pressed.emit()
		assert_eq(Crafting.inventory_qty("timePearl"), 1, "one item filed")
		assert_eq(int(GameState.state["player"]["inventory"]["timePearl"].get("2", 0)), 1, "at best rank")
		assert_eq(Lab.calc_available("time"), 5, "base calc spent")
		screen.free()
	)

	run_case("multi_target_is_gated_on_best_rank", func():
		GameState.reset()
		var cfg: Dictionary = GameData.LOADOUT["multiTarget"]
		var key := ""
		for candidate in cfg["craftable"]:
			if Lab.procedure_def(candidate).size() > 0 and not Crafting.is_always_multi(candidate):
				key = candidate
				break
		if key == "":
			return
		Lab.grant_recipe(key)
		GameState.state["lab"]["performedOnce"].append(key)
		GameState.state["lab"]["bestRanks"][key] = int(cfg["minTier"]) - 1
		var screen := _screen()
		screen._open_recipe(key)
		assert_true(_find_checkbox(screen, "Multi-target").disabled, "locked below the multi tier")
		GameState.state["lab"]["bestRanks"][key] = int(cfg["minTier"])
		EventBus.state_changed.emit()
		assert_true(not _find_checkbox(screen, "Multi-target").disabled, "open at the multi tier")
		screen.free()
	)

	run_case("an_insight_shows_in_the_result_and_on_the_recipe_page_without_a_band", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 10
		Lab.grant_recipe("timePearl")
		var cfg: Dictionary = GameData.RECIPE_KNOWLEDGE["insight"]
		var real_base: float = cfg["base"]
		cfg["base"] = 1.0
		var screen := _screen()
		screen._open_recipe("timePearl")
		NodeQuery.find_button(screen, "Craft manually").pressed.emit()
		UiSim.tap_zone(screen, "ore_time")
		NodeQuery.find_button(screen, "Finish").pressed.emit()
		cfg["base"] = real_base
		var line := screen.find_child("InsightLine", true, false) as Label
		assert_true(line != null, "the result has an insight line")
		assert_eq(line.text, screen._result["insight"]["text"], "reading the roll's text")
		NodeQuery.find_button(screen, "Done").pressed.emit()
		assert_true(NodeQuery.label_texts(screen).has("2. %s · ?" % Lab.apparatus_name("grinding")), "the book shows the step, no band")
		assert_true(NodeQuery.label_texts(screen).has(GameData.LAB["insightNote"]), "with the insight note")
		var hint2 := screen.find_child("Rung_hint2", true, false) as Label
		assert_true(hint2.text.contains("insight: "), "the ladder names the insight")
		screen.free()
	)

	run_case("craft_manually_docks_the_book_and_finish_shows_the_result", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 10
		Lab.grant_recipe("timePearl")
		var screen := _screen()
		screen._open_recipe("timePearl")
		NodeQuery.find_button(screen, "Craft manually").pressed.emit()
		assert_true(NodeQuery.find_button(screen, "Finish") != null, "the docked book has Finish")
		assert_eq(NodeQuery.find_button(screen, "‹ Back"), null, "no way off the plate but Finish")
		UiSim.tap_zone(screen, "apparatus_heat")
		assert_true(NodeQuery.label_texts(screen).has("Add calc from a jar first."), "apparatus before a jar: notice")
		assert_eq(_find_gauge(screen), null, "and no gauge")
		UiSim.tap_zone(screen, "ore_life")
		assert_true(NodeQuery.label_texts(screen).has("%s doesn't use %s." % [_name("timePearl"), GameData.ORE_TYPES["life"]["name"]]), "off-recipe jar: notice")
		assert_eq(Lab.active_run(), null, "an off-recipe jar starts nothing")
		UiSim.tap_zone(screen, "ore_time")
		assert_eq(Lab.calc_available("time"), 5, "a recipe jar spends real calc")
		assert_true(NodeQuery.label_texts(screen.get_node("OreBadge_time")).has("5"), "the badge reads real calc")
		UiSim.tap_zone(screen, "apparatus_heat")
		var gauge = _find_gauge(screen)
		assert_true(gauge is LabGauges.HoldGauge, "heat pops its hold gauge")
		gauge.committed.emit(25.0)
		assert_eq(Lab.active_run()["performed"][0]["apparatus"], "heat", "the gauge's release performs the step")
		assert_eq(_find_gauge(screen), null, "and closes the gauge")
		NodeQuery.find_button(screen, "Finish").pressed.emit()
		assert_eq(Lab.active_run(), null, "Finish ends the run")
		assert_eq(Crafting.inventory_qty("timePearl"), int(screen._result["items"]), "the run's item(s) filed")
		assert_true(NodeQuery.find_button(screen, "Done") != null, "the result shows on the book")
		assert_true(_has_label_starting(screen, "Score "), "with the score")
		assert_true(_has_label_starting(screen, "1. %s · " % Lab.apparatus_name("heat")), "a clue per performed step")
		assert_true(NodeQuery.find_button(screen, "Rewind") != null, "one Rewind button offered")
		assert_eq(NodeQuery.find_button(screen, "Rewind last craft"), null, "its choices wait behind it")
		NodeQuery.find_button(screen, "Done").pressed.emit()
		assert_true(NodeQuery.find_button(screen, "Craft manually") != null, "Done returns to the recipe page")
		screen.free()
	)

	run_case("the_gauge_shows_the_band_of_the_known_step_it_is_about_to_perform", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 10
		Lab.grant_recipe("timePearl")
		var screen := _screen()
		screen._open_recipe("timePearl")
		NodeQuery.find_button(screen, "Craft manually").pressed.emit()
		UiSim.tap_zone(screen, "ore_time")
		var steps := Lab.known_procedure("timePearl")
		_assert_gauge_band(screen, "compression", Lab.step_region("timePearl", steps[0]), "an exact known step: its band, solid")
		_assert_gauge_band(screen, "grinding", {}, "no known grind step: no band")

		Lab.grant_steps("timePearl", Lab.rung_steps("timePearl", "hint1"), "vague")
		var vague: Dictionary = Lab.step_region("timePearl", Lab.known_procedure("timePearl")[0])
		assert_true(vague["vague"])
		_assert_gauge_band(screen, "compression", vague, "a vague step: its faded region")

		Crafting.inventory_add(ActiveEffects.PROPHETS_BREATH, 1, 1)
		Lab.use_effect(ActiveEffects.PROPHETS_BREATH)
		_assert_gauge_band(screen, "compression", { "low": 82.0 - Lab.band_half_width("timePearl"), "high": 82.0 +Lab.band_half_width("timePearl"), "vague": false }, "Breath: the true band")
		_assert_gauge_band(screen, "grinding", Lab.step_region("timePearl", Lab.known_procedure("timePearl")[1]), "Breath reveals the hidden grind's band")

		UiSim.tap_zone(screen, "apparatus_heat")
		_find_gauge(screen).committed.emit(25.0)
		_assert_gauge_band(screen, "grinding", {}, "a grind after the heat matches no known step left")
		screen.free()
	)

	run_case("the_docked_book_ends_above_the_nav_bar_with_its_footer_outside_the_scroll", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 10
		Lab.grant_recipe("timePearl")
		var screen := _screen()
		screen.size = Vector2(390.0, 844.0)
		screen._open_recipe("timePearl")
		NodeQuery.find_button(screen, "Craft manually").pressed.emit()
		var nav := Rect2(0.0, screen.size.y - UI.nav_bar_clearance(), screen.size.x, UI.nav_bar_clearance())
		assert_true(not _docked_book_rect(screen).intersects(nav), "the docked book stops at the nav bar's top")
		assert_true(not _inside_scroll(NodeQuery.find_button(screen, "Finish")), "Finish stays put while the steps scroll")
		UiSim.tap_zone(screen, "ore_time")
		NodeQuery.find_button(screen, "Finish").pressed.emit()
		assert_true(not _docked_book_rect(screen).intersects(nav), "the result page stops at the nav bar's top too")
		assert_true(not _inside_scroll(NodeQuery.find_button(screen, "Done")), "Done stays put while the result scrolls")
		screen.free()
	)

	run_case("the_docked_plate_sits_below_the_top_bar_and_the_book_starts_at_the_press_bottom", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 10
		Lab.grant_recipe("timePearl")
		Lab.add_ore("timePearl", "time")
		var screen := _screen()
		screen.size = Vector2(390.0, 844.0)
		screen._refresh()
		var top := UI.top_bar_clearance()
		assert_eq(screen._diorama.get_parent().position.y, top, "the plate's top is the top bar's bottom")
		var plate: Dictionary = GameData.HQ_VISUALS["labBench"]
		var press: Dictionary = plate["regions"]["apparatus_compression"]
		var scale_factor: float = screen.size.x / float(plate["width"])
		var press_bottom: float = top + (float(press["y"]) + float(press["height"])) * scale_factor
		assert_almost_eq(_docked_book_rect(screen).position.y, press_bottom, 0.01, "the book starts at the Press's bottom edge")
		UiSim.tap_zone(screen, "apparatus_compression")
		var centre := _find_gauge(screen) as Node
		while centre.get_parent() != screen:
			centre = centre.get_parent()
		assert_true(centre is CenterContainer, "the gauge is centred")
		assert_eq((centre as Control).offset_top, top, "below the top bar")
		assert_almost_eq((centre as Control).offset_bottom, press_bottom, 0.01, "above the book")
		screen.free()
	)

	run_case("on_a_short_screen_the_docked_book_keeps_its_minimum_height_over_the_press", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 10
		Lab.grant_recipe("timePearl")
		Lab.add_ore("timePearl", "time")
		var screen := _screen()
		screen.size = Vector2(390.0, 640.0)
		screen._refresh()
		var book := _docked_book_rect(screen)
		assert_almost_eq(book.size.y, HqLabBenchScreen._DOCK_MIN_HEIGHT, 0.01, "the dock keeps its minimum height")
		assert_almost_eq(book.end.y, screen.size.y - UI.nav_bar_clearance() - HqLabBenchScreen._OVERLAY_MARGIN, 0.01, "still ending above the nav bar")
		screen.free()
	)

	run_case("an_open_run_reopens_docked_and_a_crack_shows_the_lost_calc_result", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 10
		Lab.grant_recipe("timePearl")
		Lab.add_ore("timePearl", "time")
		var screen := _screen()
		assert_true(NodeQuery.find_button(screen, "Finish") != null, "an open run opens docked")
		UiSim.tap_zone(screen, "apparatus_compression")
		_find_gauge(screen).committed.emit(99.0)
		assert_true(NodeQuery.label_texts(screen).has("The vessel cracked. No item, and the calc is lost."), "crack result on the book")
		assert_eq(Crafting.inventory_qty("timePearl"), 0)
		screen.free()
	)

	run_case("rewind_last_craft_spends_a_rewind_and_restores_the_calc", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 10
		Crafting.inventory_add("rewind", 1, 1)
		Lab.grant_recipe("timePearl")
		var screen := _screen()
		screen._open_recipe("timePearl")
		NodeQuery.find_button(screen, "Craft manually").pressed.emit()
		UiSim.tap_zone(screen, "ore_time")
		NodeQuery.find_button(screen, "Finish").pressed.emit()
		NodeQuery.find_button(screen, "Rewind").pressed.emit()
		assert_true(screen.find_child("RewindChoice", true, false) != null, "Rewind opens the choice popup")
		assert_true(NodeQuery.find_button(screen, "Rewind time block").disabled, "no block point yet")
		NodeQuery.find_button(screen, "Cancel").pressed.emit()
		assert_eq(screen.find_child("RewindChoice", true, false), null, "Cancel closes it")
		NodeQuery.find_button(screen, "Rewind").pressed.emit()
		NodeQuery.find_button(screen, "Rewind last craft").pressed.emit()
		assert_eq(Lab.calc_available("time"), 10, "calc back")
		assert_eq(Crafting.inventory_qty("timePearl"), 0, "item gone")
		assert_eq(Crafting.inventory_qty("rewind"), 0, "one Rewind spent")
		assert_true(NodeQuery.find_button(screen, "Craft manually") != null, "back on the recipe page")
		assert_eq(screen.find_child("RewindChoice", true, false), null, "the popup closes")
		assert_true(NodeQuery.find_button(screen, "Rewind").disabled, "no Rewind left to spend")
		screen.free()
	)

	run_case("a_touch_and_its_emulated_mouse_twin_tap_a_jar_once", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 10
		Lab.grant_recipe("timePearl")
		var screen := _screen()
		screen._open_recipe("timePearl")
		NodeQuery.find_button(screen, "Craft manually").pressed.emit()
		var center: Vector2 = UiSim.zone_point(screen._diorama, "ore_time")
		screen._on_diorama_gui_input(UiSim.tap_at(center))
		var twin := InputEventMouseButton.new()
		twin.button_index = MOUSE_BUTTON_LEFT
		twin.pressed = true
		twin.position = center
		twin.device = InputEvent.DEVICE_ID_EMULATION
		screen._on_diorama_gui_input(twin)
		assert_eq(Lab.calc_available("time"), 5, "one physical tap spends once")
		screen.free()
	)


# The live docked book's rect in screen space, from its full-rect anchors
# and offsets (off-tree, so no layout pass to read it from).
func _docked_book_rect(screen: Control) -> Rect2:
	for child in screen.get_children():
		if child.name == "DockedBook" and not child.is_queued_for_deletion():
			var book := child as Control
			return Rect2(book.offset_left, book.offset_top,
				screen.size.x + book.offset_right - book.offset_left,
				screen.size.y + book.offset_bottom - book.offset_top)
	assert_true(false, "a docked book is on screen")
	return Rect2()


func _inside_scroll(node: Node) -> bool:
	var parent := node.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			return true
		parent = parent.get_parent()
	return false


func _assert_gauge_band(screen: HqLabBenchScreen, apparatus: String, region: Dictionary, context: String) -> void:
	UiSim.tap_zone(screen, "apparatus_" + apparatus)
	var gauge = _find_gauge(screen)
	assert_eq([gauge.band_low, gauge.band_high, gauge.band_vague], [region.get("low", 0.0), region.get("high", 0.0), region.get("vague", false)], context)
	screen._close_gauge()


func _find_gauge(node: Node) -> Node:
	if node is LabGauges.StepGauge and not node is LabGauges.BandGauge:
		return node
	for child in node.get_children():
		var found := _find_gauge(child)
		if found != null:
			return found
	return null


func _find_checkbox(root: Node, text: String) -> CheckBox:
	for box in root.find_children("*", "CheckBox", true, false):
		if box.text == text and not box.is_queued_for_deletion():
			return box
	return null
