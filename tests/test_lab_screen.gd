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

	run_case("recipe_page_shows_the_procedure_as_known_best_rank_and_an_empty_ladder", func():
		GameState.reset()
		Lab.grant_recipe("timePearl")
		Lab.grant_steps("timePearl", Lab.rung_steps("timePearl", "hint1"), "vague")
		var screen := _screen()
		screen._open_recipe("timePearl")
		assert_true(NodeQuery.label_texts(screen).has("Best rank: —"), "no rank yet")
		assert_true(_has_label_starting(screen, "1. %s" % LabBenchNav.apparatus_name("compression")), "a base step shows")
		assert_true(_has_label_containing(screen, "≈ "), "a vague step shows a faded region")
		var hint1: Dictionary = GameData.LAB["procedures"]["timePearl"]["hints"][0]
		var hint2: Dictionary = GameData.LAB["procedures"]["timePearl"]["hints"][1]
		assert_true(NodeQuery.label_texts(screen).has(hint1["vague"]["note"]), "with its direction note")
		assert_true(not NodeQuery.label_texts(screen).has(hint2["vague"]["note"]), "an unknown step stays hidden")
		var ladder := screen.find_child("LadderRegion", true, false)
		assert_true(ladder != null, "the ladder region is reserved")
		assert_eq(ladder.get_child_count(), 0, "and empty")
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
		assert_eq(Lab.calc_available("time"), 7, "base calc spent")
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
		assert_eq(Lab.calc_available("time"), 7, "a recipe jar spends real calc")
		assert_true(NodeQuery.label_texts(screen.get_node("OreBadge_time")).has("7"), "the badge reads real calc")
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
		assert_true(_has_label_starting(screen, "1. %s · " % LabBenchNav.apparatus_name("heat")), "a clue per performed step")
		assert_true(NodeQuery.find_button(screen, "Rewind") != null, "one Rewind button offered")
		assert_eq(NodeQuery.find_button(screen, "Rewind last craft"), null, "its choices wait behind it")
		NodeQuery.find_button(screen, "Done").pressed.emit()
		assert_true(NodeQuery.find_button(screen, "Craft manually") != null, "Done returns to the recipe page")
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
		assert_eq(Lab.calc_available("time"), 7, "one physical tap spends once")
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


func _find_checkbox(root: Node, text: String) -> CheckBox:
	for box in root.find_children("*", "CheckBox", true, false):
		if box.text == text and not box.is_queued_for_deletion():
			return box
	return null
