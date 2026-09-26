extends "res://tests/test_base.gd"

const NodeQuery := preload("res://tests/support/node_query.gd")

# docs/hq-diorama-vision.md §5.3: the gear-tap confirm modal
# (scenes/modals/lab_bench_confirm_modal.gd). Built straight into a bare
# VBoxContainer — the modal layer's chrome is covered by test_modal_layer.gd.
# Fixtures: rewind (time|heat) is tutorial-taught, so Found on a fresh save;
# shield (physics|heat) is untried.


func _build(types: Array, approach: String) -> VBoxContainer:
	var container := VBoxContainer.new()
	LabBenchConfirmModal.build(container, { "types": types, "approach": approach })
	return container


func _find_button_prefix(root: Node, prefix: String) -> Button:
	for b in root.find_children("", "Button", true, false):
		if (b as Button).text.begins_with(prefix):
			return b
	return null


func run() -> void:
	run_case("untried_cell_shows_a_probe_modal_with_no_stepper", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["physics"] = 5
		var modal := _build(["physics"], "heat")

		assert_true(NodeQuery.find_button(modal, "Confirm") != null, "a probe confirms once")
		assert_true(NodeQuery.find_button(modal, "+") == null, "a probe has no quantity stepper")
		assert_true(NodeQuery.symbol_row_texts(modal).any(func(t: String): return t.contains("5 held · costs %d" % Bench.ORE_COST_PER_TYPE)), "ore held and per-type probe cost are shown")
		modal.free()
	)

	run_case("hot_cell_still_shows_the_probe_modal", func():
		GameState.reset()
		GameState.state["player"]["bench"]["cells"]["physics|heat"] = { "state": "hot", "misses": 1, "refine": 0 }
		assert_eq(LabBenchNav.confirm_variant(["physics"], "heat"), LabBenchNav.CONFIRM_PROBE)
	)

	run_case("probe_confirm_probes_once_and_shows_the_result_card", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["physics"] = 5
		var modal := _build(["physics"], "heat")

		NodeQuery.find_button(modal, "Confirm").pressed.emit()

		assert_eq(GameState.state["player"]["orichalchum"]["physics"], 5 - Bench.ORE_COST_PER_TYPE, "one probe's cost, spent once")
		assert_eq(GameState.state["modal"]["type"], "lab_bench_probe_result")
		modal.free()
	)

	run_case("blocked_probe_disables_confirm_and_shows_the_reason", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["physics"] = 1
		var modal := _build(["physics"], "heat")

		assert_true(NodeQuery.find_button(modal, "Confirm").disabled)
		assert_true(NodeQuery.label_texts(modal).has(Bench.probe_block_reason(["physics"], "heat")))
		modal.free()
	)

	run_case("found_cell_shows_a_craft_modal_with_a_stepper", func():
		GameState.reset()
		var modal := _build(["time"], "heat")

		assert_true(NodeQuery.label_texts(modal).has(GameData.RECIPES["rewind"]["name"]), "the recipe is named")
		assert_true(NodeQuery.find_button(modal, "+") != null, "a craft carries the batch stepper")
		assert_true(_find_button_prefix(modal, "Confirm ×1") != null)
		modal.free()
	)

	run_case("craft_stepper_shares_the_recipe_books_batch_qty", func():
		GameState.reset()
		var modal := _build(["time"], "heat")
		NodeQuery.find_button(modal, "+").pressed.emit()
		modal.free()

		assert_eq(Crafting.get_craft_qty("rewind"), 2)
		modal = _build(["time"], "heat")
		assert_true(_find_button_prefix(modal, "Confirm ×2") != null)
		modal.free()
	)

	run_case("craft_confirm_crafts_n_via_the_batch", func():
		GameState.reset()
		var cost: int = Crafting.calc_cost("rewind", GameState.state["player"]["craftingSkill"])["time"]
		GameState.state["player"]["orichalchum"]["time"] = cost * 3
		Crafting.adjust_craft_qty("rewind", 2)
		var modal := _build(["time"], "heat")

		_find_button_prefix(modal, "Confirm ×3").pressed.emit()

		assert_eq(GameState.state["modal"]["type"], "craft_batch_result")
		assert_eq(GameState.state["modal"]["data"]["completed"], 3)
		assert_eq(GameState.state["player"]["orichalchum"]["time"], 0)
		modal.free()
	)

	run_case("craft_confirm_is_disabled_when_the_batch_is_unaffordable", func():
		GameState.reset()
		var cost: int = Crafting.calc_cost("rewind", GameState.state["player"]["craftingSkill"])["time"]
		GameState.state["player"]["orichalchum"]["time"] = cost
		Crafting.adjust_craft_qty("rewind", 1)
		var modal := _build(["time"], "heat")

		var confirm := _find_button_prefix(modal, "Confirm ×2")
		assert_true(confirm.disabled, "enough for one, not for two")
		assert_true(NodeQuery.label_texts(modal).has("Not enough calc for ×2."))
		modal.free()
	)

	run_case("inert_cell_shows_a_warning_with_no_action", func():
		GameState.reset()
		GameState.state["player"]["orichalchum"]["fate"] = 5
		GameState.state["player"]["bench"]["cells"]["fate|heat"] = { "state": "inert", "misses": 0, "refine": 0 }
		var modal := _build(["fate"], "heat")

		assert_true(NodeQuery.label_texts(modal).has(LabBenchConfirmModal.INERT_TEXT))
		assert_true(_find_button_prefix(modal, "Confirm") == null, "nothing to confirm")
		NodeQuery.find_button(modal, "Close").pressed.emit()
		assert_eq(GameState.state["player"]["orichalchum"]["fate"], 5, "no ore spent")
		modal.free()
	)
