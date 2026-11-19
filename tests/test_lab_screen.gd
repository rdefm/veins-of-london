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
		EventBus.flush_now()
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
		assert_true(NodeQuery.label_texts(screen).has(_name("timePearl")), "the header repeats the name")
		assert_true(NodeQuery.label_texts(screen).has("Stock: 0"), "and the stock")
		assert_true(NodeQuery.label_texts(screen).has("Page 1/2"), "page 1 of the recipe")
		assert_true(NodeQuery.find_button(screen, "Craft manually") != null, "Craft manually in the bar")
		assert_true(NodeQuery.find_button(screen, "Rewind").disabled, "Rewind with nothing to pay")
		assert_eq(screen.find_child("LadderRegion", true, false), null, "the ladder waits on page 2")
		NodeQuery.find_button(screen, "Next ›").pressed.emit()
		assert_true(NodeQuery.label_texts(screen).has("Page 2/2"), "Next turns to page 2")
		var ladder := screen.find_child("LadderRegion", true, false)
		assert_true(ladder != null, "the ladder region shows")
		var strings: Dictionary = GameData.RECIPE_KNOWLEDGE["ladder"]
		var rows := RecipeKnowledge.ladder_rows("timePearl")
		for row in rows:
			var rung := str(row["rung"])
			var rung_label := ladder.find_child("Rung_%s" % rung, true, false) as Label
			assert_true(rung_label != null and rung_label.text == row["label"], "%s rung rendered" % rung)
			assert_eq((ladder.find_child("Rung_%s_Ceiling" % rung, true, false) as Label).text, row["ceiling"], "%s max rank" % rung)
			var state := ladder.find_child("Rung_%s_State" % rung, true, false) as Label
			var note := ladder.find_child("Rung_%s_Note" % rung, true, false) as Label
			if row["state"] == "locked":
				assert_true(state == null, "%s locked: no state word" % rung)
				assert_true(note != null and note.text == row["note"], "%s locked: its note pencilled" % rung)
			else:
				assert_eq(state.text, strings["pageStates"][row["state"]], "%s owned: its state word" % rung)
				assert_true(note == null, "%s owned: no note" % rung)
		assert_eq(rows[1]["state"], "vague", "hint1 owned rough")
		assert_eq((ladder.find_child("ReachLine", true, false) as Label).text, strings["reach"] % str(RecipeKnowledge.rank_ceiling("timePearl")), "You can reach the rank ceiling")
		RecipeKnowledge.grant_rung("timePearl", "hint2", "vague")
		EventBus.flush_now()
		ladder = screen.find_child("LadderRegion", true, false)
		assert_eq((ladder.find_child("Rung_hint2_State", true, false) as Label).text, strings["pageStates"]["vague"], "a grant redraws page 2")
		assert_true(ladder.find_child("Rung_hint2_Note", true, false) == null, "hint2's lock note gone")
		assert_eq((ladder.find_child("ReachLine", true, false) as Label).text, strings["reach"] % str(RecipeKnowledge.rank_ceiling("timePearl")), "and the reach line rises")
		assert_eq(RecipeKnowledge.rank_ceiling("timePearl"), 4, "to hint2's ceiling")
		assert_true(NodeQuery.find_button(screen, "Craft manually") != null)
		assert_true(NodeQuery.find_button(screen, "Auto-craft").disabled, "no batch before a hand run")
		assert_true(NodeQuery.label_texts(screen).has("Craft one by hand first."), "with its reason")
		screen.free()
	)

	run_case("page_1_draws_exact_and_rough_bands_as_pencil_scales_beside_margin_notes", func():
		GameState.reset()
		Lab.grant_recipe("timePearl")
		RecipeKnowledge.grant_rung("timePearl", "hint1", "vague")
		RecipeKnowledge.grant_rung("timePearl", "hint2", "exact")
		var screen := _screen()
		screen._open_recipe("timePearl")
		var book: RecipeBookPage = _find_of(screen, func(n): return n is RecipeBookPage)
		var scales := []
		var notes := []
		for entry in book._placed:
			if entry["node"] is LabGauges.PencilScale:
				scales.append(entry)
			elif entry["node"] is Label and entry["node"].autowrap_mode != TextServer.AUTOWRAP_OFF:
				notes.append(entry)
		assert_eq(_find_of(book, func(n): return n is LabGauges.BandGauge), null, "no grey band track on the page")
		var vague := []
		var regions := 0
		for step in Lab.known_procedure("timePearl"):
			var region := Lab.step_region("timePearl", step)
			if not region.is_empty():
				regions += 1
				vague.append(region["vague"])
		assert_eq(scales.map(func(e): return e["node"].band_vague), vague, "one scale per banded step, rough ones hatched")
		assert_true(vague.has(true) and vague.has(false), "both kinds drawn")
		assert_eq(notes.size(), 2, "both hints pencilled in")
		for note in notes:
			var beside := scales.filter(func(e): return absf(e["rect"].end.y - note["rect"].position.y) < 10.0)
			assert_true(not beside.is_empty() and note["rect"].position.x >= beside[0]["rect"].end.x, "note sits right of its step's scale")
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
		var auto := NodeQuery.find_button(screen, "Auto-craft")
		assert_true(not auto.disabled, "enabled once performed")
		assert_eq(screen.find_child("BatchSheet", true, false), null, "the sheet waits for a tap")
		auto.pressed.emit()
		assert_true(screen.find_child("BatchSheet", true, false) != null, "Auto-craft opens the sheet")
		var slider := _find_of(screen, func(n): return n is HSlider) as HSlider
		assert_eq(int(slider.max_value), Lab.max_batch("timePearl"), "slider runs to max batch")
		assert_eq(int(slider.min_value), 1)
		assert_true(_has_label_starting(screen, "Total: "), "the total line shows")
		NodeQuery.find_button(screen, "Craft ×1").pressed.emit()
		assert_eq(Crafting.inventory_qty("timePearl"), 1, "one item filed")
		assert_eq(int(GameState.state["player"]["inventory"]["timePearl"].get("2", 0)), 1, "at best rank")
		assert_eq(Lab.calc_available("time"), 5, "base calc spent")
		assert_eq(screen.find_child("BatchSheet", true, false), null, "confirm closes the sheet")
		NodeQuery.find_button(screen, "Auto-craft").pressed.emit()
		NodeQuery.find_button(screen, "Cancel").pressed.emit()
		assert_eq(screen.find_child("BatchSheet", true, false), null, "Cancel closes the sheet")
		NodeQuery.find_button(screen, "Auto-craft").pressed.emit()
		var dim := screen.find_child("BatchSheet", true, false) as Control
		var tap := InputEventMouseButton.new()
		tap.button_index = MOUSE_BUTTON_LEFT
		tap.pressed = true
		dim.gui_input.emit(tap)
		assert_eq(screen.find_child("BatchSheet", true, false), null, "the dim closes the sheet")
		assert_eq(Crafting.inventory_qty("timePearl"), 1, "cancelling crafts nothing")
		assert_eq(Lab.calc_available("time"), 5)
		screen.free()
	)

	run_case("auto_craft_is_closed_when_calc_is_short", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 0
		Lab.grant_recipe("timePearl")
		GameState.state["lab"]["performedOnce"].append("timePearl")
		var screen := _screen()
		screen._open_recipe("timePearl")
		assert_true(NodeQuery.find_button(screen, "Auto-craft").disabled, "closed without calc")
		assert_true(NodeQuery.label_texts(screen).has("Not enough calc."), "with its reason")
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
		for ore in Lab.base_calc(key).keys():
			GameState.state["player"]["orichalchum"][ore] = 100
		var screen := _screen()
		screen._open_recipe(key)
		NodeQuery.find_button(screen, "Auto-craft").pressed.emit()
		assert_true(_find_checkbox(screen, "Multi-target").disabled, "locked below the multi tier")
		assert_true(NodeQuery.label_texts(screen).has("Best rank %d unlocks multi-target." % int(cfg["minTier"])), "with its gate line")
		GameState.state["lab"]["bestRanks"][key] = int(cfg["minTier"])
		EventBus.state_changed.emit()
		assert_true(not _find_checkbox(screen, "Multi-target").disabled, "open at the multi tier")
		screen.free()
	)

	run_case("multi_target_toggle_only_for_offered_recipes", func():
		GameState.reset()
		var cfg: Dictionary = GameData.LOADOUT["multiTarget"]
		var key := ""
		for candidate in GameData.RECIPES.keys():
			if Lab.procedure_def(candidate).size() > 0 and not cfg["craftable"].has(candidate):
				key = candidate
				break
		if key == "":
			return
		Lab.grant_recipe(key)
		GameState.state["lab"]["performedOnce"].append(key)
		for ore in Lab.base_calc(key).keys():
			GameState.state["player"]["orichalchum"][ore] = 100
		var screen := _screen()
		screen._open_recipe(key)
		NodeQuery.find_button(screen, "Auto-craft").pressed.emit()
		assert_true(screen.find_child("BatchSheet", true, false) != null, "sheet open")
		assert_eq(_find_checkbox(screen, "Multi-target"), null, "no toggle for a recipe that doesn't offer it")
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
		NodeQuery.find_button(screen, "Next ›").pressed.emit()
		var hint2 := screen.find_child("Rung_hint2_Note", true, false) as Label
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
		EventBus.flush_now()
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

		Crafting.inventory_add(ActiveEffects.PROPHETS_BREATH, 5, 1)  # level 5: current steps and clues both exact
		Lab.use_effect(ActiveEffects.PROPHETS_BREATH)
		_assert_gauge_band(screen, "compression", { "low": 82.0 - Lab.band_half_width("timePearl"), "high": 82.0 +Lab.band_half_width("timePearl"), "vague": false }, "Breath: the true band")
		_assert_gauge_band(screen, "grinding", Lab.step_region("timePearl", Lab.known_procedure("timePearl")[1]), "Breath reveals the hidden grind's band")

		UiSim.tap_zone(screen, "apparatus_heat")
		_find_gauge(screen).committed.emit(25.0)
		screen._bench_guard_until_msec = 0  # the commit's tap guard would swallow the next tap
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
		var plate: Dictionary = GameData.HQ_VISUALS["labBench"]
		var scale_factor: float = screen.size.x / float(plate["width"])
		var plate_top: float = screen._diorama.get_parent().position.y
		assert_true(plate_top < top, "the plate lifts under the top bar")
		var jar_top := INF
		for ore_type in GameData.ORE_TYPES.keys():
			jar_top = minf(jar_top, float(plate["regions"]["ore_" + ore_type]["y"]))
		assert_almost_eq(plate_top + jar_top * scale_factor, top + HqLabBenchScreen._INSET, 0.01, "the top jars sit just below the top bar, fully on screen")
		var press: Dictionary = plate["regions"]["apparatus_compression"]
		var press_bottom: float = plate_top + (float(press["y"]) + float(press["height"])) * scale_factor
		var book_top := _docked_book_rect(screen).position.y
		assert_true(book_top >= press_bottom - 0.01, "the step-section notebook sits below the Press, leaving a gap for the controls")
		assert_true(book_top >= screen._jar_bottom(screen._diorama.get_parent(), plate["regions"]) - 0.01, "and never over the jars")
		assert_true(screen.find_child("NotebookControls", true, false) != null, "the controls sit above the book")
		UiSim.tap_zone(screen, "apparatus_compression")
		var centre := _find_gauge(screen) as Node
		while centre.get_parent() != screen:
			centre = centre.get_parent()
		assert_true(centre is CenterContainer, "the gauge is centred")
		assert_eq((centre as Control).offset_top, top, "below the top bar")
		assert_almost_eq((centre as Control).offset_bottom, book_top, 0.01, "above the book")
		screen.free()
	)

	run_case("on_a_short_screen_the_docked_result_card_keeps_its_minimum_height_over_the_press", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["time"] = 10
		Lab.grant_recipe("timePearl")
		Lab.add_ore("timePearl", "time")
		var screen := _screen()
		screen.size = Vector2(390.0, 640.0)
		screen._result = {"outcome": "cracked", "xp": 1}
		screen._refresh()
		var book := _docked_book_rect(screen)
		assert_true(book.size.y >= HqLabBenchScreen._DOCK_MIN_HEIGHT, "the dock keeps at least its minimum height")
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

	run_case("book_returns_to_the_list_page_and_tab_and_a_recipe_reopens_on_page_1", func():
		GameState.reset()
		for recipe_key in GameData.RECIPES.keys():
			Lab.grant_recipe(recipe_key)
		var ore := ""
		for candidate in HqLabBenchScreen.ORE_ORDER:
			if Lab.known_recipes(candidate).size() > HqLabBenchScreen.PER_PAGE:
				ore = candidate
				break
		var picked: String = Lab.known_recipes(ore)[HqLabBenchScreen.PER_PAGE]
		var screen := _screen()
		screen._open_tab(ore)
		NodeQuery.find_button(screen, "Next ›").pressed.emit()
		screen._open_recipe(picked)
		NodeQuery.find_button(screen, "Next ›").pressed.emit()
		NodeQuery.find_button(screen, "‹ Book").pressed.emit()
		assert_eq(screen._page, HqLabBenchScreen.Page.BOOK, "‹ Book shows the list")
		assert_true(NodeQuery.label_texts(screen).has(_name(picked)), "on the list page the recipe came from")
		assert_true(NodeQuery.find_button(screen, "‹ Prev") != null, "still page 2 of the tab")
		screen._open_recipe(picked)
		assert_true(NodeQuery.label_texts(screen).has("Page 1/2"), "a reopened recipe starts on page 1")
		var other: String = HqLabBenchScreen.ORE_ORDER[(HqLabBenchScreen.ORE_ORDER.find(ore) + 1) % HqLabBenchScreen.ORE_ORDER.size()]
		for button in screen.find_children("*", "Button", true, false):
			if button.get_meta("ore", "") == other:
				button.pressed.emit()
				break
		assert_eq(screen._page, HqLabBenchScreen.Page.BOOK, "a tab on a recipe page opens a list")
		assert_eq(screen._selected_ore(), other, "that ore's list")
		screen.free()
	)

	run_case("every_recipe_procedure_fits_page_1_at_every_specificity", func():
		var body := RecipeBookPage.RECIPE_BODY_LINES.size()
		for specificity in GameData.LAB["specificities"]:
			GameState.reset()
			var screen := _screen()
			for recipe_key in GameData.LAB["procedures"].keys():
				Lab.grant_recipe(recipe_key)
				for rung in RecipeKnowledge.rungs():
					if rung != "base":
						RecipeKnowledge.grant_rung(recipe_key, rung, specificity)
				var rows: Array = screen._procedure_rows(recipe_key)
				var last: Dictionary = rows[-1]
				assert_true(int(last["line"]) + int(last["lines"]) <= body, "%s (%s) fits page 1" % [recipe_key, specificity])
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


# First node under root (root included) that `match` accepts, or null.
func _find_of(root: Node, match: Callable) -> Node:
	if match.call(root):
		return root
	for child in root.get_children():
		var found := _find_of(child, match)
		if found != null:
			return found
	return null
