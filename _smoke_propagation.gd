extends SceneTree

var _clicked := false

func _initialize() -> void:
	root.size = Vector2i(390, 844)

	var button := Button.new()
	button.text = "Test"
	button.position = Vector2(50, 50)
	button.size = Vector2(100, 40)
	button.pressed.connect(func(): _clicked = true)
	root.add_child(button)
	await process_frame
	await process_frame

	print("button global_rect=%s" % [button.get_global_rect()])

	var t := InputEventMouseButton.new()
	t.button_index = MOUSE_BUTTON_LEFT
	t.pressed = true
	t.position = Vector2(100, 70)
	root.push_input(t)
	await process_frame

	var t2 := InputEventMouseButton.new()
	t2.button_index = MOUSE_BUTTON_LEFT
	t2.pressed = false
	t2.position = Vector2(100, 70)
	root.push_input(t2)
	await process_frame

	print("clicked via mouse push_input = %s" % [_clicked])

	_clicked = false
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = Vector2(100, 70)
	root.push_input(touch)
	await process_frame
	var touch2 := InputEventScreenTouch.new()
	touch2.index = 0
	touch2.pressed = false
	touch2.position = Vector2(100, 70)
	root.push_input(touch2)
	await process_frame

	print("clicked via touch push_input = %s" % [_clicked])

	quit()
