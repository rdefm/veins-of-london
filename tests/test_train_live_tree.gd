extends "res://tests/test_base.gd"

# The real Main tree: the Gym modal is open when Train spends the block.

const MainScript := preload("res://scenes/Main.gd")
const Overlay := preload("res://scenes/components/time_transition.gd")


func run() -> void:
	await run_case("train_overlay_plays_and_sits_above_the_open_gym_modal_in_main", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var root := (Engine.get_main_loop() as SceneTree).root
		var main := MainScript.new()
		root.add_child(main)
		var overlay: Control = null
		var modal_layer: Control = main.modal_layer
		for child in main.get_children():
			if child.get_script() == Overlay:
				overlay = child
		assert_true(overlay != null, "overlay is in Main")
		Modal.open("hq_gym")
		assert_true(modal_layer.visible, "modal layer visible")
		var train := _find_button(modal_layer, "Train")
		assert_true(train != null, "Train button present")
		train.pressed.emit()
		for i in 20:
			overlay._process(0.05)
		assert_true(overlay.active and overlay.visible, "overlay plays over the open Gym modal")
		assert_true(overlay.get_index() > modal_layer.get_index(), "overlay draws above the modal layer")
		assert_eq(GameState.state["modal"]["type"], "hq_gym")
		main.free()
	)


func _find_button(node: Node, prefix: String) -> Button:
	if node is Button and (node as Button).text.begins_with(prefix):
		return node
	for child in node.get_children():
		var found := _find_button(child, prefix)
		if found != null:
			return found
	return null
