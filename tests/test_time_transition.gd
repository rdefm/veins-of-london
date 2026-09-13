extends "res://tests/test_base.gd"

const Overlay := preload("res://scenes/components/time_transition.gd")


func _overlay() -> Control:
	GameState.reset()
	GameState.state["currentScreen"] = "hq"
	var overlay := Overlay.new()
	overlay.size = Vector2(390, 844)
	overlay._ready()
	return overlay


func _advance(overlay: Control, seconds: float) -> void:
	for i in range(int(ceil(seconds / 0.05))):
		overlay._process(0.05)


func run() -> void:
	run_case("paid_train_captures_once_and_notifies_before_overlay_without_replaying_effects", func():
		var overlay := _overlay()
		var result := Combat.train()
		assert_true(result["ok"])
		assert_eq(overlay.pending.size(), 1)
		assert_eq(overlay.pending[0]["source"], {"day": 1, "phase": 0})
		assert_eq(overlay.pending[0]["destination"], {"day": 1, "phase": 1})
		assert_true(not overlay.visible)
		assert_true(GameState.state["notifications"].back()["text"].contains("tomorrow"))
		var resolved := SaveManager.export_string()
		_advance(overlay, 0.8)
		assert_true(overlay.active)
		assert_eq(overlay.destination.text, "Day 1 — Afternoon")
		_advance(overlay, 1.6)
		assert_true(overlay.active, "non-skippable duration has not elapsed")
		_advance(overlay, 0.2)
		assert_true(not overlay.active)
		assert_eq(SaveManager.export_string(), resolved, "playback owns no gameplay effects")
		assert_eq(overlay.pending.size(), 0)
		overlay.free()
	)
	run_case("event_combat_result_and_bag_boundaries_hold_the_queue", func():
		var overlay := _overlay()
		TimeSystem.advance_time_block()
		GameState.state["event"] = {"id": "test"}
		_advance(overlay, 3)
		assert_true(not overlay.active)
		GameState.state["event"] = null
		GameState.state["combat"]["active"] = true
		_advance(overlay, 3)
		assert_true(not overlay.active)
		GameState.state["combat"]["active"] = false
		GameState.state["currentScreen"] = "combat"
		_advance(overlay, 3)
		assert_true(not overlay.active, "combat result playback still owns screen")
		GameState.state["currentScreen"] = "hq"
		Modal.open("james_job_complete", {"earned": 10})
		_advance(overlay, 3)
		assert_true(not overlay.active)
		Modal.close()
		GameState.state["bagDrawerOpen"] = true
		_advance(overlay, 3)
		assert_true(not overlay.active)
		GameState.state["bagDrawerOpen"] = false
		_advance(overlay, 0.8)
		assert_true(overlay.active)
		overlay.free()
	)
	run_case("rollover_and_rest_each_capture_one_transition_and_one_daily_tick", func():
		for phase in range(3):
			for rest in [false, true]:
				var overlay := _overlay()
				GameState.state["world"]["timeBlock"] = phase
				var ticks: Array = []
				var record := func(day: int): ticks.append(day)
				EventBus.day_ticked.connect(record)
				if rest:
					TimeSystem.do_rest()
				else:
					TimeSystem.advance_time_block()
				assert_eq(overlay.pending.size(), 1)
				assert_eq(overlay.pending[0]["source"]["phase"], phase)
				assert_eq(ticks.size(), 1 if rest or phase == 2 else 0)
				var resolved_account = GameState.deep_copy(GameState.state["morningAccounts"].get("latest"))
				var resolved_cash: int = GameState.state["player"]["cash"]
				_advance(overlay, 3)
				assert_true(not overlay.active)
				assert_eq(GameState.state["morningAccounts"].get("latest"), resolved_account, "playback never reruns or edits the account")
				assert_eq(GameState.state["player"]["cash"], resolved_cash, "playback never reruns daily effects")
				if rest or phase == 2:
					assert_eq(GameState.state["phoneNav"]["app"], "bizbrief", "overnight completion opens the brief")
				assert_eq(ticks.size(), 1 if rest or phase == 2 else 0)
				EventBus.day_ticked.disconnect(record)
				overlay.free()
	)
	run_case("free_and_blocked_actions_do_not_queue", func():
		var overlay := _overlay()
		Travel.ensure_district("shoreditch", 0)
		assert_eq(overlay.pending.size(), 0)
		GameState.state["world"]["timeBlocksDone"] = [0, 1, 2]
		assert_true(not Combat.train()["ok"])
		_advance(overlay, 3)
		assert_eq(overlay.pending.size(), 0)
		assert_true(not overlay.active)
		overlay.free()
	)
	run_case("reduced_motion_holds_destination_frame_and_preference_survives_load", func():
		var overlay := _overlay()
		preload("res://systems/preferences.gd").set_reduced_motion(true)
		TimeSystem.advance_time_block()
		_advance(overlay, 0.8)
		var region: Rect2 = overlay.picture.texture.region
		_advance(overlay, 1.0)
		assert_eq(overlay.picture.texture.region, region)
		assert_true(overlay.active)
		var saved := SaveManager.export_string()
		assert_true(SaveManager.import_string(saved)["ok"])
		overlay._process(0.05)
		assert_true(not overlay.active)
		assert_eq(overlay.pending.size(), 0)
		assert_true(GameState.state["meta"]["reducedMotion"])
		assert_eq(SaveManager.export_string(), saved)
		overlay.free()
	)
	run_case("atlas_ranges_fit_and_preserve_authored_frame_dimensions", func():
		var overlay := _overlay()
		var config: Dictionary = GameData.DAILY_CYCLE
		assert_eq(overlay.atlas.get_width(), int(config["columns"]) * int(config["cellSize"]))
		assert_eq(overlay.atlas.get_height(), int(config["rows"]) * int(config["cellSize"]))
		for entry in config["ranges"].values():
			assert_true(entry["start"] + entry["count"] <= config["frameCount"])
			assert_true(entry["size"][0] <= config["cellSize"])
			assert_true(entry["size"][1] <= config["cellSize"])
		overlay.free()
	)
	await run_case("live_overlay_blocks_press_and_held_release_then_returns_input", func():
		GameState.reset()
		GameState.state["currentScreen"] = "hq"
		var tree: SceneTree = Engine.get_main_loop()
		var host := Control.new()
		host.size = Vector2(390, 844)
		var button := Button.new()
		button.size = Vector2(390, 844)
		var presses: Array = []
		button.pressed.connect(func(): presses.append(true))
		host.add_child(button)
		var overlay := Overlay.new()
		host.add_child(overlay)
		tree.root.add_child(host)
		await tree.process_frame
		overlay.set_process(false)
		TimeSystem.advance_time_block()
		_advance(overlay, 0.8)
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.position = Vector2(20, 20)
		press.pressed = true
		tree.root.push_input(press, true)
		assert_true(overlay.active)
		assert_eq(presses.size(), 0)
		# A paused SceneTree cannot strand the always-processing overlay.
		tree.paused = true
		assert_true(overlay.can_process())
		_advance(overlay, 1.8)
		tree.paused = false
		press.pressed = false
		tree.root.push_input(press, true)
		assert_eq(presses.size(), 0)
		var motion := InputEventMouseMotion.new()
		motion.position = press.position
		tree.root.push_input(motion, true)
		press.pressed = true
		tree.root.push_input(press, true)
		press.pressed = false
		tree.root.push_input(press, true)
		assert_eq(presses.size(), 1)
		host.free()
	)
